import json
import logging

from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor, Json

from database import get_db_connection
from auth.dependencies import get_current_admin
from app.models.schemas import FoodCreate, FoodAutoAdd, AdminFoodReview, TempFoodApprove
from ai_models import llm_provider

logger = logging.getLogger(__name__)
router = APIRouter()


_RECIPE_SYSTEM_PROMPT = (
    "คุณเป็นเชฟไทยที่ให้คำตอบเป็น JSON เท่านั้น ห้ามมีข้อความอื่นนอกจาก JSON. "
    "เมื่อได้ชื่ออาหารไทย ให้สร้างสูตรอาหารจริงจากครัวไทยมาตรฐาน ตอบด้วยรูปแบบ: "
    '{"description": "...", "instructions": "ขั้นที่ 1 ...\\nขั้นที่ 2 ...", '
    '"prep_time_minutes": 10, "cooking_time_minutes": 15, "serving_people": 1, '
    '"ingredients": [{"name":"...","amount":"...","unit":"..."}], '
    '"tools": ["..."], "tips": ["..."]}. '
    "instructions ให้ขึ้นบรรทัดใหม่ระหว่างแต่ละขั้น ห้ามใส่ markdown."
)


def _parse_ai_recipe(raw: str) -> dict:
    """Best-effort JSON extraction — some LLMs wrap output in ```json fences."""
    text = raw.strip()
    if text.startswith("```"):
        text = text.strip("`")
        if text.lower().startswith("json"):
            text = text[4:]
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("LLM did not return JSON")
    return json.loads(text[start : end + 1])


@router.get("/foods")
def read_foods():
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT f.*,
                   COALESCE(
                       array_agg(faf.flag_id) FILTER (WHERE faf.flag_id IS NOT NULL),
                       '{}'
                   ) AS allergy_flag_ids
            FROM foods f
            LEFT JOIN food_allergy_flags faf ON faf.food_id = f.food_id
            GROUP BY f.food_id
            ORDER BY f.food_id ASC
        """)
        rows = cur.fetchall()
        result = []
        for row in rows:
            r = dict(row)
            r['allergy_flag_ids'] = list(r['allergy_flag_ids']) if r['allergy_flag_ids'] else []
            result.append(r)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/foods")
def create_food(food: FoodCreate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            INSERT INTO foods (food_name, calories, protein, carbs, fat, image_url)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING food_id
        """, (food.food_name, food.calories, food.protein, food.carbs, food.fat, food.image_url))
        new_id = cur.fetchone()['food_id']
        conn.commit()
        return {"message": "Food added", "food_id": new_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/foods/auto-add")
def user_auto_add_food(req: FoodAutoAdd):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            INSERT INTO temp_food (food_name, calories, protein, carbs, fat, user_id)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING tf_id
            """,
            (req.food_name, req.calories or 0, req.protein or 0,
             req.carbs or 0, req.fat or 0, req.user_id),
        )
        new_tf_id = cur.fetchone()["tf_id"]
        conn.commit()
        return {"message": "บันทึกเมนูด่วนสำเร็จ รอ admin ตรวจสอบ", "tf_id": new_tf_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/recommended-food")
def get_recommended_food():
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC LIMIT 20")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


def _shape_recipe_response(row: dict) -> dict:
    """Flatten DB row into the shape RecipeDetailScreen consumes."""
    instructions = (row.get("instructions") or "").strip()
    steps = [s.strip() for s in instructions.split("\n") if s.strip()]
    return {
        **row,
        "ingredients": row.get("ingredients_json") or [],
        "tools": row.get("tools_json") or [],
        "tips": row.get("tips_json") or [],
        "steps": steps,
        "reviews": [],
    }


@router.get("/recipes/{food_id}")
def get_recipe(food_id: int):
    """Return a recipe for the given food_id.

    If no recipe row exists yet, lazily generate one via the LLM and cache
    it into `recipes`. This trades the first viewer's latency (one LLM
    call, ~2-4 s) for a populated catalogue over time — no admin seeding
    required.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            SELECT r.*, f.food_name, f.calories, f.protein, f.carbs, f.fat,
                   f.image_url as food_image_url
            FROM recipes r
            JOIN foods f ON r.food_id = f.food_id
            WHERE r.food_id = %s AND r.deleted_at IS NULL
            """,
            (food_id,),
        )
        row = cur.fetchone()
        if row:
            return _shape_recipe_response(row)

        # No recipe yet — fetch food metadata and ask the LLM.
        cur.execute(
            "SELECT food_id, food_name, calories, protein, carbs, fat, image_url "
            "FROM foods WHERE food_id = %s",
            (food_id,),
        )
        food = cur.fetchone()
        if not food:
            raise HTTPException(status_code=404, detail="Food not found")

        if not llm_provider.is_configured():
            raise HTTPException(
                status_code=503,
                detail="LLM is not configured — recipe cannot be generated",
            )

        try:
            raw = llm_provider.generate(
                _RECIPE_SYSTEM_PROMPT,
                f"ชื่อเมนู: {food['food_name']}",
            )
            ai = _parse_ai_recipe(raw)
        except Exception as e:
            logger.warning("recipe LLM generation failed for food_id=%s: %s", food_id, e)
            raise HTTPException(
                status_code=502,
                detail="ไม่สามารถสร้างสูตรอาหารได้ในตอนนี้ กรุณาลองใหม่",
            )

        cur.execute(
            """
            INSERT INTO recipes (
                food_id, description, instructions,
                prep_time_minutes, cooking_time_minutes, serving_people,
                ingredients_json, tools_json, tips_json, generated_by
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'ai')
            ON CONFLICT (food_id) DO UPDATE SET
                description = EXCLUDED.description,
                instructions = EXCLUDED.instructions,
                prep_time_minutes = EXCLUDED.prep_time_minutes,
                cooking_time_minutes = EXCLUDED.cooking_time_minutes,
                serving_people = EXCLUDED.serving_people,
                ingredients_json = EXCLUDED.ingredients_json,
                tools_json = EXCLUDED.tools_json,
                tips_json = EXCLUDED.tips_json,
                generated_by = 'ai'
            RETURNING *
            """,
            (
                food_id,
                ai.get("description") or "",
                ai.get("instructions") or "",
                int(ai.get("prep_time_minutes") or 0),
                int(ai.get("cooking_time_minutes") or 0),
                float(ai.get("serving_people") or 1),
                Json(ai.get("ingredients") or []),
                Json(ai.get("tools") or []),
                Json(ai.get("tips") or []),
            ),
        )
        new_row = cur.fetchone()
        conn.commit()

        merged = {
            **dict(new_row),
            "food_name": food["food_name"],
            "calories": food["calories"],
            "protein": food["protein"],
            "carbs": food["carbs"],
            "fat": food["fat"],
            "food_image_url": food["image_url"],
        }
        return _shape_recipe_response(merged)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.put("/foods/{food_id}")
def update_food(food_id: int, food: FoodCreate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            UPDATE foods
            SET food_name = %s, calories = %s, protein = %s,
                carbs = %s, fat = %s, image_url = %s
            WHERE food_id = %s
        """, (food.food_name, food.calories, food.protein, food.carbs, food.fat, food.image_url, food_id))
        conn.commit()
        return {"message": "Food updated successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.patch("/foods/{food_id}")
def patch_food(food_id: int, data: dict, current_user: dict = Depends(get_current_admin)):
    """Partial update — อัปเดตเฉพาะ field ที่ส่งมา (admin only)"""
    allowed = {"food_name", "calories", "protein", "carbs", "fat", "image_url"}
    fields = {k: v for k, v in data.items() if k in allowed}
    if not fields:
        raise HTTPException(status_code=400, detail="ไม่มี field ที่อัปเดตได้")
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        set_clause = ", ".join(f"{k} = %s" for k in fields)
        cur.execute(
            f"UPDATE foods SET {set_clause} WHERE food_id = %s RETURNING food_id",
            [*fields.values(), food_id],
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="ไม่พบเมนูนี้")
        conn.commit()
        return {"message": "อัปเดตสำเร็จ", "food_id": food_id}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.delete("/foods/{food_id}")
def delete_food(food_id: int, current_user: dict = Depends(get_current_admin)):
    """ลบเมนูอาหารออกจากระบบ (admin only)"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM foods WHERE food_id = %s RETURNING food_id", (food_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="ไม่พบเมนูนี้")
        conn.commit()
        return {"message": "ลบเมนูเรียบร้อย", "food_id": food_id}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

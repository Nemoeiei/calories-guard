import json

from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor

from database import get_db_connection
from auth.dependencies import get_current_admin
from app.models.schemas import FoodCreate, FoodAutoAdd, AdminFoodReview, TempFoodApprove

router = APIRouter()


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


@router.get("/recipes/{food_id}")
def get_recipe(food_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT r.*, f.food_name, f.calories, f.protein, f.carbs, f.fat, f.image_url as food_image_url
            FROM recipes r
            JOIN foods f ON r.food_id = f.food_id
            WHERE r.food_id = %s
        """, (food_id,))
        recipe = cur.fetchone()
        if not recipe:
            raise HTTPException(status_code=404, detail="Recipe not found")
        return recipe
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

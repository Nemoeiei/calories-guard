import json

from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor

from database import get_db_connection
from auth.dependencies import get_current_admin
from app.models.schemas import AdminFoodReview, TempFoodApprove

router = APIRouter()


@router.get("/admin/temp-foods")
def admin_list_temp_foods(current_user: dict = Depends(get_current_admin), status: str = "pending"):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        where = ""
        if status == "pending":
            where = "WHERE is_verify = FALSE"
        elif status == "verified":
            where = "WHERE is_verify = TRUE"
        cur.execute(
            f"""
            SELECT
                tf_id, food_name, calories, protein, carbs, fat,
                submitted_by AS user_id, submitted_by_username AS requester_name,
                submitted_at, is_verify, verified_by, verified_at
            FROM v_admin_temp_food_review
            {where}
            ORDER BY submitted_at DESC
            """
        )
        return cur.fetchall()
    finally:
        if conn:
            conn.close()


@router.post("/admin/temp-foods/{tf_id}/approve")
def admin_approve_temp_food(tf_id: int, req: TempFoodApprove, current_user: dict = Depends(get_current_admin)):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM temp_food WHERE tf_id = %s", (tf_id,))
        tf = cur.fetchone()
        if not tf:
            raise HTTPException(status_code=404, detail="Temp food not found")

        updates = []
        vals = []
        if req.food_name is not None:
            updates.append("food_name = %s"); vals.append(req.food_name)
        if req.calories is not None:
            updates.append("calories = %s"); vals.append(req.calories)
        if req.protein is not None:
            updates.append("protein = %s"); vals.append(req.protein)
        if req.carbs is not None:
            updates.append("carbs = %s"); vals.append(req.carbs)
        if req.fat is not None:
            updates.append("fat = %s"); vals.append(req.fat)
        if updates:
            vals.append(tf_id)
            cur.execute(f"UPDATE temp_food SET {', '.join(updates)} WHERE tf_id = %s", tuple(vals))

        cur.execute("""
            UPDATE verified_food
            SET is_verify = TRUE, verified_by = %s, verified_at = NOW()
            WHERE tf_id = %s
        """, (req.admin_id, tf_id))

        cur.execute("""
            INSERT INTO foods (food_name, calories, protein, carbs, fat)
            SELECT food_name, calories, protein, carbs, fat
            FROM temp_food WHERE tf_id = %s
            RETURNING food_id
        """, (tf_id,))
        new_food = cur.fetchone()
        conn.commit()
        return {"message": "Approved and added to foods", "food_id": new_food["food_id"] if new_food else None}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.delete("/admin/temp-foods/{tf_id}")
def admin_reject_temp_food(tf_id: int, current_user: dict = Depends(get_current_admin)):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM temp_food WHERE tf_id = %s", (tf_id,))
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Temp food not found")
        conn.commit()
        return {"message": "Temp food rejected and deleted"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/admin/food-requests")
def get_food_requests(current_user: dict = Depends(get_current_admin)):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT fr.request_id, fr.food_name, fr.status,
                   fr.calories, fr.protein, fr.carbs, fr.fat,
                   fr.ingredients_json, fr.created_at,
                   u.username as requester_name
            FROM food_requests fr
            JOIN users u ON fr.user_id = u.user_id
            WHERE fr.status = 'pending'
            ORDER BY fr.created_at DESC
        """)
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.put("/admin/food-requests/{request_id}")
def verify_food_request(request_id: int, review: AdminFoodReview, current_user: dict = Depends(get_current_admin)):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM food_requests WHERE request_id = %s", (request_id,))
        req_record = cur.fetchone()
        if not req_record:
            raise HTTPException(status_code=404, detail="Request not found")
        cur.execute("""
            UPDATE food_requests
            SET status = %s, reviewed_by = %s
            WHERE request_id = %s
        """, (review.status, review.admin_id, request_id))
        if review.status == 'approved' and req_record['ingredients_json']:
            meta = req_record['ingredients_json']
            if isinstance(meta, str):
                meta = json.loads(meta)
            food_id = meta.get('auto_added_food_id')
            if food_id and review.calories is not None:
                cur.execute("""
                    UPDATE foods
                    SET calories = %s, protein = %s, carbs = %s, fat = %s,
                        image_url = COALESCE(%s, image_url)
                    WHERE food_id = %s
                """, (review.calories, review.protein, review.carbs, review.fat, review.image_url, food_id))
        conn.commit()
        return {"message": f"Request {review.status} successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

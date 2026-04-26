import json

from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor

from database import get_db_connection
from auth.dependencies import get_current_admin
from app.models.schemas import AdminFoodReview, RegionalNameApprove, TempFoodApprove

router = APIRouter()


@router.get("/admin/users")
def admin_list_users(search: str = "", current_user: dict = Depends(get_current_admin)):
    """ดึงรายการ user ทั้งหมด สำหรับ admin panel"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if search:
            cur.execute(
                """
                SELECT user_id, username, email, role_id, created_at,
                       last_login_date, current_streak, total_login_days
                FROM users
                WHERE username ILIKE %s OR email ILIKE %s
                ORDER BY created_at DESC
                """,
                (f"%{search}%", f"%{search}%"),
            )
        else:
            cur.execute(
                """
                SELECT user_id, username, email, role_id, created_at,
                       last_login_date, current_streak, total_login_days
                FROM users
                ORDER BY created_at DESC
                """
            )
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/admin/temp-foods/pending-count")
def admin_pending_count(current_user: dict = Depends(get_current_admin)):
    """จำนวน temp_food ที่รอ admin อนุมัติ — ใช้แสดง badge บน nav"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM v_admin_temp_food_review WHERE is_verify = FALSE")
        return {"count": cur.fetchone()[0]}
    finally:
        if conn:
            conn.close()


@router.get("/admin/foods/similar")
def admin_similar_foods(name: str = "", current_user: dict = Depends(get_current_admin)):
    """
    หาเมนูในตาราง foods ที่ชื่อคล้ายกับ name ที่ส่งมา.
    ใช้ ILIKE เพื่อ detect duplicate ก่อน admin อนุมัติ.
    """
    if not name.strip():
        return []
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            SELECT food_id, food_name, calories, protein, carbs, fat, image_url
            FROM foods
            WHERE food_name ILIKE %s
               OR food_name ILIKE %s
            ORDER BY food_name
            LIMIT 5
            """,
            (f"%{name.strip()}%", f"%{name.strip().split()[0]}%"),
        )
        return cur.fetchall()
    finally:
        if conn:
            conn.close()


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

        cur.execute(
            """
            WITH input AS (
                SELECT
                    tf.food_name,
                    tf.calories,
                    tf.protein,
                    tf.carbs,
                    tf.fat,
                    %s::varchar AS image_url,
                    COALESCE(%s::food_type, 'dish'::food_type) AS food_type,
                    COALESCE(NULLIF(BTRIM(%s), ''), COALESCE(%s::food_type, 'dish'::food_type)::text, 'uncategorized')
                        AS category_name,
                    COALESCE(NULLIF(BTRIM(%s), ''), 'serving') AS unit_name,
                    COALESCE(%s, NULL) AS sodium,
                    COALESCE(%s, NULL) AS sugar,
                    COALESCE(%s, NULL) AS cholesterol,
                    COALESCE(%s, 0) AS fiber_g,
                    COALESCE(%s, 1) AS serving_quantity
                FROM temp_food tf
                WHERE tf.tf_id = %s
            ),
            existing_unit AS (
                SELECT u.unit_id
                FROM units u, input i
                WHERE lower(u.name) = lower(i.unit_name)
                LIMIT 1
            ),
            inserted_unit AS (
                INSERT INTO units (name, quantity)
                SELECT i.unit_name, 1
                FROM input i
                WHERE NOT EXISTS (SELECT 1 FROM existing_unit)
                RETURNING unit_id
            ),
            picked_unit AS (
                SELECT unit_id FROM existing_unit
                UNION ALL
                SELECT unit_id FROM inserted_unit
                LIMIT 1
            ),
            existing_category AS (
                SELECT dc.dish_category_id
                FROM dish_categories dc, input i
                WHERE dc.category_name = i.category_name
                  AND dc.canonical_food_type IS NOT DISTINCT FROM i.food_type
                LIMIT 1
            ),
            inserted_category AS (
                INSERT INTO dish_categories (category_name, canonical_food_type)
                SELECT i.category_name, i.food_type
                FROM input i
                WHERE NOT EXISTS (SELECT 1 FROM existing_category)
                RETURNING dish_category_id
            ),
            picked_category AS (
                SELECT dish_category_id FROM existing_category
                UNION ALL
                SELECT dish_category_id FROM inserted_category
                LIMIT 1
            ),
            existing_dish AS (
                SELECT d.dish_id
                FROM dishes d, input i, picked_category pc
                WHERE d.dish_name = i.food_name
                  AND d.dish_category_id = pc.dish_category_id
                LIMIT 1
            ),
            inserted_dish AS (
                INSERT INTO dishes (dish_name, dish_category_id, canonical_food_type, image_url)
                SELECT i.food_name, pc.dish_category_id, i.food_type, COALESCE(i.image_url, NULL)
                FROM input i, picked_category pc
                WHERE NOT EXISTS (SELECT 1 FROM existing_dish)
                RETURNING dish_id
            ),
            picked_dish AS (
                SELECT dish_id FROM existing_dish
                UNION ALL
                SELECT dish_id FROM inserted_dish
                LIMIT 1
            )
            INSERT INTO foods (
                food_name, calories, protein, carbs, fat, image_url,
                food_type, sodium, sugar, cholesterol, fiber_g,
                serving_quantity, serving_unit_id, dish_id
            )
            SELECT
                i.food_name, i.calories, i.protein, i.carbs, i.fat,
                COALESCE(i.image_url, NULL),
                i.food_type,
                i.sodium, i.sugar, i.cholesterol, i.fiber_g,
                i.serving_quantity, pu.unit_id, pd.dish_id
            FROM input i, picked_unit pu, picked_dish pd
            RETURNING food_id
            """,
            (
                req.image_url,
                req.food_type,
                req.food_category,
                req.food_type,
                req.serving_unit,
                req.sodium,
                req.sugar,
                req.cholesterol,
                req.fiber_g,
                req.serving_quantity,
                tf_id,
            ),
        )
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


@router.get("/admin/regional-name-submissions")
def admin_list_regional_name_submissions(
    status: str = "pending",
    current_user: dict = Depends(get_current_admin),
):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            SELECT s.submission_id, s.food_id, f.food_name,
                   s.region::text AS region, s.name_th, s.popularity,
                   s.user_id, u.username AS requester_name,
                   s.status::text AS status, s.reviewed_by, s.reviewed_at,
                   s.created_at
            FROM food_regional_name_submissions s
            JOIN foods f ON f.food_id = s.food_id
            JOIN users u ON u.user_id = s.user_id
            WHERE s.status = %s
            ORDER BY s.created_at DESC
            """,
            (status,),
        )
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/admin/regional-name-submissions/{submission_id}/approve")
def admin_approve_regional_name_submission(
    submission_id: int,
    req: RegionalNameApprove,
    current_user: dict = Depends(get_current_admin),
):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """
            SELECT *
            FROM food_regional_name_submissions
            WHERE submission_id = %s AND status = 'pending'
            FOR UPDATE
            """,
            (submission_id,),
        )
        submission = cur.fetchone()
        if not submission:
            raise HTTPException(status_code=404, detail="Regional name submission not found")

        if req.is_primary:
            cur.execute(
                """
                UPDATE food_regional_names
                SET is_primary = FALSE, updated_at = NOW()
                WHERE food_id = %s
                  AND region = %s::thai_region
                  AND is_primary
                  AND deleted_at IS NULL
                """,
                (submission["food_id"], submission["region"]),
            )

        cur.execute(
            """
            INSERT INTO food_regional_names
                (food_id, region, name_th, is_primary, created_by, approved_by)
            VALUES (%s, %s::thai_region, %s, %s, %s, %s)
            ON CONFLICT (food_id, region, name_th) DO UPDATE SET
                is_primary = EXCLUDED.is_primary,
                approved_by = EXCLUDED.approved_by,
                updated_at = NOW(),
                deleted_at = NULL
            RETURNING variant_id
            """,
            (
                submission["food_id"],
                submission["region"],
                submission["name_th"].strip(),
                req.is_primary,
                submission["user_id"],
                req.admin_id,
            ),
        )
        variant = cur.fetchone()

        popularity = req.popularity if req.popularity is not None else submission["popularity"]
        if popularity is not None:
            if not (1 <= popularity <= 5):
                raise HTTPException(status_code=400, detail="popularity ต้องอยู่ระหว่าง 1-5")
            cur.execute(
                """
                INSERT INTO food_regional_popularity (food_id, region, popularity)
                VALUES (%s, %s::thai_region, %s)
                ON CONFLICT (food_id, region) DO UPDATE SET
                    popularity = EXCLUDED.popularity,
                    updated_at = NOW()
                """,
                (submission["food_id"], submission["region"], popularity),
            )

        cur.execute(
            """
            UPDATE food_regional_name_submissions
            SET status = 'approved', reviewed_by = %s, reviewed_at = NOW()
            WHERE submission_id = %s
            """,
            (req.admin_id, submission_id),
        )
        conn.commit()
        return {
            "message": "Regional name approved",
            "variant_id": variant["variant_id"] if variant else None,
        }
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/admin/regional-name-submissions/{submission_id}/reject")
def admin_reject_regional_name_submission(
    submission_id: int,
    req: RegionalNameApprove,
    current_user: dict = Depends(get_current_admin),
):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE food_regional_name_submissions
            SET status = 'rejected', reviewed_by = %s, reviewed_at = NOW()
            WHERE submission_id = %s AND status = 'pending'
            """,
            (req.admin_id, submission_id),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Regional name submission not found")
        conn.commit()
        return {"message": "Regional name rejected"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()



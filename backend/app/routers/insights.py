from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor

from database import get_db_connection
from auth.dependencies import get_current_user
from app.core.dependencies import check_ownership

router = APIRouter()


@router.get("/insights/{user_id}")
def get_insights_overview(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH recent_daily AS (
                SELECT
                    ds.date_record,
                    ds.total_calories_intake AS calories,
                    COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS protein,
                    COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS carbs,
                    COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS fat,
                    u.target_calories, u.target_protein, u.target_carbs,
                    u.target_fat, u.current_streak
                FROM daily_summaries ds
                LEFT JOIN meals m ON m.user_id = ds.user_id AND DATE(m.meal_time) = ds.date_record
                LEFT JOIN detail_items di ON di.meal_id = m.meal_id
                CROSS JOIN (
                    SELECT target_calories, target_protein, target_carbs,
                           target_fat, current_streak
                    FROM users WHERE user_id = %s
                ) u
                WHERE ds.user_id = %s
                  AND ds.date_record >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY ds.date_record, ds.total_calories_intake,
                         u.target_calories, u.target_protein, u.target_carbs,
                         u.target_fat, u.current_streak
            ),
            goal_flags AS (
                SELECT *,
                    ABS(calories - target_calories) AS cal_diff,
                    CASE WHEN target_calories > 0
                              AND ABS(calories - target_calories) <= target_calories * 0.1
                         THEN 1 ELSE 0 END AS on_target
                FROM recent_daily
            )
            SELECT
                COUNT(*) AS total_days_logged,
                ROUND(AVG(calories)::numeric, 0) AS avg_calories,
                SUM(on_target) AS days_on_target,
                ROUND(AVG(protein)::numeric, 1) AS avg_protein,
                ROUND(AVG(carbs)::numeric, 1) AS avg_carbs,
                ROUND(AVG(fat)::numeric, 1) AS avg_fat,
                ROUND(MIN(cal_diff)::numeric, 0) AS best_day_diff,
                MAX(current_streak) AS current_streak
            FROM goal_flags
        """, (user_id, user_id))
        row = cur.fetchone()
        if not row or row["total_days_logged"] == 0:
            return {"total_days_logged": 0, "avg_calories": 0, "days_on_target": 0,
                    "avg_protein": 0, "avg_carbs": 0, "avg_fat": 0,
                    "best_day_diff": None, "current_streak": 0}
        return dict(row)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/insights/{user_id}/top_foods")
def get_top_foods(user_id: int, current_user: dict = Depends(get_current_user), limit: int = 10):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH food_frequency AS (
                SELECT di.food_id, di.food_name,
                    COUNT(*) AS times_eaten,
                    ROUND(SUM(di.amount)::numeric, 1) AS total_amount,
                    ROUND(SUM(di.amount * di.cal_per_unit)::numeric, 0) AS total_calories,
                    f.image_url,
                    RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
                FROM meals m
                JOIN detail_items di ON di.meal_id = m.meal_id
                LEFT JOIN foods f ON f.food_id = di.food_id
                WHERE m.user_id = %s AND m.meal_time >= NOW() - INTERVAL '30 days'
                GROUP BY di.food_id, di.food_name, f.image_url
            )
            SELECT * FROM food_frequency WHERE rank <= %s ORDER BY rank
        """, (user_id, limit))
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/insights/{user_id}/calorie_trend")
def get_calorie_trend(user_id: int, current_user: dict = Depends(get_current_user), days: int = 30):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH daily_data AS (
                SELECT ds.date_record, ds.total_calories_intake AS calories, u.target_calories
                FROM daily_summaries ds
                CROSS JOIN (SELECT target_calories FROM users WHERE user_id = %s) u
                WHERE ds.user_id = %s
                  AND ds.date_record >= CURRENT_DATE - (%s || ' days')::INTERVAL
            ),
            moving_avg AS (
                SELECT date_record, calories, target_calories,
                    ROUND(AVG(calories) OVER (
                        ORDER BY date_record ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                    )::numeric, 0) AS moving_avg_7d,
                    CASE WHEN target_calories > 0
                              AND ABS(calories - target_calories) <= target_calories * 0.1
                         THEN true ELSE false END AS on_target
                FROM daily_data
            )
            SELECT * FROM moving_avg ORDER BY date_record
        """, (user_id, user_id, days))
        rows = cur.fetchall()
        return [
            {
                "date": r["date_record"].isoformat(),
                "calories": int(r["calories"]) if r["calories"] else 0,
                "target_calories": int(r["target_calories"]) if r["target_calories"] else 0,
                "moving_avg_7d": int(r["moving_avg_7d"]) if r["moving_avg_7d"] else 0,
                "on_target": r["on_target"],
            }
            for r in rows
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/insights/{user_id}/macro_balance")
def get_macro_balance(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH macro_daily AS (
                SELECT
                    DATE(m.meal_time) AS day,
                    COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS protein,
                    COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS carbs,
                    COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS fat,
                    COALESCE(SUM(di.amount * di.cal_per_unit), 0) AS total_cal
                FROM meals m
                JOIN detail_items di ON di.meal_id = m.meal_id
                WHERE m.user_id = %s AND m.meal_time >= NOW() - INTERVAL '7 days'
                GROUP BY DATE(m.meal_time)
            ),
            macro_avg AS (
                SELECT
                    ROUND(AVG(protein)::numeric, 1) AS avg_protein_g,
                    ROUND(AVG(carbs)::numeric, 1) AS avg_carbs_g,
                    ROUND(AVG(fat)::numeric, 1) AS avg_fat_g,
                    ROUND(AVG(total_cal)::numeric, 0) AS avg_calories,
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(protein) * 4 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END AS protein_pct,
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(carbs) * 4 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END AS carbs_pct,
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(fat) * 9 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END AS fat_pct
                FROM macro_daily
            )
            SELECT ma.*,
                JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'day', md.day,
                        'protein', ROUND(md.protein::numeric, 1),
                        'carbs', ROUND(md.carbs::numeric, 1),
                        'fat', ROUND(md.fat::numeric, 1),
                        'calories', ROUND(md.total_cal::numeric, 0)
                    ) ORDER BY md.day
                ) AS daily_breakdown
            FROM macro_avg ma, macro_daily md
            GROUP BY ma.avg_protein_g, ma.avg_carbs_g, ma.avg_fat_g,
                     ma.avg_calories, ma.protein_pct, ma.carbs_pct, ma.fat_pct
        """, (user_id,))
        row = cur.fetchone()
        if not row:
            return {"avg_protein_g": 0, "avg_carbs_g": 0, "avg_fat_g": 0,
                    "avg_calories": 0, "protein_pct": 0, "carbs_pct": 0,
                    "fat_pct": 0, "daily_breakdown": []}
        return dict(row)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

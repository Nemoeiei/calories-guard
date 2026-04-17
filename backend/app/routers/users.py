from datetime import date, datetime

from fastapi import APIRouter, HTTPException, Depends
from psycopg2.extras import RealDictCursor

from database import get_db_connection
from auth.dependencies import get_current_user
from app.core.dependencies import check_ownership
from app.models.schemas import UserUpdate
from app.services.nutrition_service import (
    _compute_target_calories, _compute_target_macros,
    _check_1700_calorie_warning,
)

router = APIRouter()


@router.put("/users/{user_id}")
def update_user(user_id: int, user_update: UserUpdate, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        user_fields = []
        user_values = []
        if user_update.username:
            user_fields.append("username=%s"); user_values.append(user_update.username)
        if user_update.goal_type:
            user_fields.append("goal_type=%s"); user_values.append(user_update.goal_type)
        if user_update.target_weight_kg:
            user_fields.append("target_weight_kg=%s"); user_values.append(user_update.target_weight_kg)
        if user_update.target_calories:
            user_fields.append("target_calories=%s"); user_values.append(user_update.target_calories)
        if user_update.target_protein is not None:
            user_fields.append("target_protein=%s"); user_values.append(user_update.target_protein)
        if user_update.target_carbs is not None:
            user_fields.append("target_carbs=%s"); user_values.append(user_update.target_carbs)
        if user_update.target_fat is not None:
            user_fields.append("target_fat=%s"); user_values.append(user_update.target_fat)
        if user_update.activity_level:
            user_fields.append("activity_level=%s"); user_values.append(user_update.activity_level)
        if user_update.gender:
            user_fields.append("gender=%s"); user_values.append(user_update.gender)
        if user_update.birth_date:
            user_fields.append("birth_date=%s"); user_values.append(user_update.birth_date)
        if user_update.height_cm:
            user_fields.append("height_cm=%s"); user_values.append(user_update.height_cm)
        if user_update.current_weight_kg:
            user_fields.append("current_weight_kg=%s"); user_values.append(user_update.current_weight_kg)
        if user_update.goal_target_date:
            user_fields.append("goal_target_date=%s"); user_values.append(user_update.goal_target_date)

        if user_fields:
            user_values.append(user_id)
            cur.execute(f"UPDATE users SET {', '.join(user_fields)} WHERE user_id = %s", tuple(user_values))

        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        row = cur.fetchone()
        if row:
            if user_update.target_calories is None:
                computed = _compute_target_calories(dict(row))
                cur.execute("UPDATE users SET target_calories = %s WHERE user_id = %s", (computed, user_id))
                row = {**row, 'target_calories': computed}
            if (user_update.target_protein is None
                    and user_update.target_carbs is None
                    and user_update.target_fat is None):
                p, c, f = _compute_target_macros(dict(row))
                cur.execute(
                    "UPDATE users SET target_protein = %s, target_carbs = %s, target_fat = %s WHERE user_id = %s",
                    (p, c, f, user_id),
                )

        if user_update.current_weight_kg is not None:
            cur.execute("""
                INSERT INTO weight_logs (user_id, weight_kg, recorded_date)
                VALUES (%s, %s, CURRENT_DATE)
                ON CONFLICT (user_id, recorded_date)
                DO UPDATE SET weight_kg = EXCLUDED.weight_kg
            """, (user_id, user_update.current_weight_kg))

        conn.commit()
        return {"message": "Update successful"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/users/{user_id}")
def get_user_profile(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        target_cal = user.get('target_calories')
        if target_cal is None:
            target_cal = _compute_target_calories(dict(user))
            cur.execute("UPDATE users SET target_calories = %s WHERE user_id = %s", (target_cal, user_id))
            conn.commit()
            user = {**user, 'target_calories': target_cal}

        if user.get('target_protein') is None or user.get('target_carbs') is None or user.get('target_fat') is None:
            tp, tc, tf = _compute_target_macros(dict(user))
            cur.execute("UPDATE users SET target_protein = %s, target_carbs = %s, target_fat = %s WHERE user_id = %s", (tp, tc, tf, user_id))
            conn.commit()
            user = {**user, 'target_protein': tp, 'target_carbs': tc, 'target_fat': tf}

        out = dict(user)
        out['target_calories'] = int(out['target_calories']) if out.get('target_calories') is not None else _compute_target_calories(out)
        tp, tc, tf = _compute_target_macros(out)
        out['target_protein'] = int(out['target_protein']) if out.get('target_protein') is not None else tp
        out['target_carbs'] = int(out['target_carbs']) if out.get('target_carbs') is not None else tc
        out['target_fat'] = int(out['target_fat']) if out.get('target_fat') is not None else tf
        out['current_streak'] = int(out['current_streak']) if out.get('current_streak') is not None else 0
        out['total_login_days'] = int(out['total_login_days']) if out.get('total_login_days') is not None else 0
        if out.get('last_login_date') and hasattr(out['last_login_date'], 'isoformat'):
            out['last_login_date'] = out['last_login_date'].isoformat() if out['last_login_date'] else None
        if out.get('birth_date') and hasattr(out['birth_date'], 'isoformat'):
            out['birth_date'] = out['birth_date'].isoformat()[:10] if out['birth_date'] else None
        if out.get('goal_start_date') and hasattr(out['goal_start_date'], 'isoformat'):
            out['goal_start_date'] = out['goal_start_date'].isoformat()[:10] if out['goal_start_date'] else None
        if out.get('goal_target_date') and hasattr(out['goal_target_date'], 'isoformat'):
            out['goal_target_date'] = out['goal_target_date'].isoformat()[:10] if out['goal_target_date'] else None
        return out
    finally:
        if conn:
            conn.close()


@router.delete("/users/{user_id}")
def delete_user(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        conn.commit()
        return {"message": "User deleted successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.get("/users/{user_id}/lifecycle_check")
def lifecycle_check(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=503, detail="DB unavailable")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        today = date.today()
        cur.execute("""
            SELECT birth_date, goal_start_date, goal_target_date,
                   current_weight_kg, target_weight_kg, target_calories,
                   last_tdee_recalc_date, created_at, activity_level,
                   gender, height_cm
            FROM users WHERE user_id = %s
        """, (user_id,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        cur.execute("SELECT MAX(recorded_date) AS last_date FROM weight_logs WHERE user_id = %s", (user_id,))
        wrow = cur.fetchone()
        last_weight_date = wrow["last_date"] if wrow else None
        if last_weight_date and hasattr(last_weight_date, 'date'):
            last_weight_date = last_weight_date.date()
        days_since_weight = (today - last_weight_date).days if last_weight_date else 9999
        weight_overdue = days_since_weight >= 14

        is_birthday = False
        tdee_needs_update = False
        if user["birth_date"]:
            bday = user["birth_date"]
            is_birthday = (bday.month == today.month and bday.day == today.day)
            birthday_this_year = date(today.year, bday.month, bday.day)
            last_recalc = user["last_tdee_recalc_date"]
            if birthday_this_year <= today:
                if last_recalc is None or last_recalc < birthday_this_year:
                    tdee_needs_update = True

        monthly_summary = False
        created = user.get("created_at")
        if created:
            days_since_join = (today - created.date()).days if hasattr(created, 'date') else 0
            monthly_summary = (days_since_join > 0 and days_since_join % 30 == 0)

        goal_days_left = None
        on_track = None
        if user["goal_target_date"] and user["goal_start_date"]:
            gtd = user["goal_target_date"]
            gsd = user["goal_start_date"]
            if hasattr(gtd, 'date'): gtd = gtd.date()
            if hasattr(gsd, 'date'): gsd = gsd.date()
            goal_days_left = (gtd - today).days
            total_days = (gtd - gsd).days
            days_elapsed = (today - gsd).days
            if total_days > 0 and user["current_weight_kg"] and user["target_weight_kg"]:
                start_w = float(user["current_weight_kg"])
                target_w = float(user["target_weight_kg"])
                expected_loss_pct = days_elapsed / total_days
                expected_weight = start_w + (target_w - start_w) * expected_loss_pct
                on_track = float(user["current_weight_kg"]) <= expected_weight + 0.5

        return {
            "user_id": user_id,
            "today": today.isoformat(),
            "weight_overdue": weight_overdue,
            "days_since_weight": days_since_weight if days_since_weight != 9999 else None,
            "is_birthday": is_birthday,
            "tdee_needs_update": tdee_needs_update,
            "monthly_summary": monthly_summary,
            "goal_days_left": goal_days_left,
            "on_track": on_track,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()


@router.post("/users/{user_id}/recalc_tdee")
def recalc_tdee(user_id: int, current_user: dict = Depends(get_current_user)):
    check_ownership(current_user, user_id)
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=503, detail="DB unavailable")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT gender, birth_date, height_cm, current_weight_kg,
                   target_weight_kg, activity_level, goal_target_date
            FROM users WHERE user_id = %s
        """, (user_id,))
        u = cur.fetchone()
        if not u:
            raise HTTPException(status_code=404, detail="User not found")
        if not all([u["gender"], u["birth_date"], u["height_cm"], u["current_weight_kg"]]):
            raise HTTPException(status_code=400, detail="Insufficient user data for TDEE")

        today = date.today()
        age = today.year - u["birth_date"].year - (
            (today.month, today.day) < (u["birth_date"].month, u["birth_date"].day))
        w = float(u["current_weight_kg"])
        h = float(u["height_cm"])
        if u["gender"] == "male":
            bmr = 10 * w + 6.25 * h - 5 * age + 5
        else:
            bmr = 10 * w + 6.25 * h - 5 * age - 161
        activity_multipliers = {
            "sedentary": 1.2, "lightly_active": 1.375,
            "moderately_active": 1.55, "very_active": 1.725, "extra_active": 1.9
        }
        multiplier = activity_multipliers.get(u["activity_level"] or "sedentary", 1.2)
        tdee = bmr * multiplier
        deficit = 0
        if u["target_weight_kg"] and u["goal_target_date"]:
            days_left = (u["goal_target_date"] - today).days
            if days_left > 0:
                kg_to_lose = w - float(u["target_weight_kg"])
                if kg_to_lose > 0:
                    deficit_per_day = (kg_to_lose * 7700) / days_left
                    deficit = min(deficit_per_day, 750)
        min_cal = 1500 if u["gender"] == "male" else 1200
        new_target = max(min_cal, round(tdee - deficit))
        cur.execute("""
            UPDATE users
            SET target_calories = %s, last_tdee_recalc_date = %s
            WHERE user_id = %s
            RETURNING target_calories
        """, (new_target, today, user_id))
        conn.commit()
        saved = cur.fetchone()
        return {
            "user_id": user_id,
            "age": age,
            "bmr": round(bmr),
            "tdee": round(tdee),
            "deficit": round(deficit),
            "new_target_calories": saved["target_calories"],
            "recalc_date": today.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

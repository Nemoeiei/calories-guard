from datetime import date, datetime, timedelta
from typing import List, Optional, Dict
from enum import Enum
import os
import shutil
from uuid import uuid4

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from passlib.context import CryptContext
from database import get_db_connection
from psycopg2.extras import RealDictCursor

app = FastAPI()

# --- Config & Helper ---
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

# ✅ 1. สร้างและ Mount โฟลเดอร์รูปภาพ
IMAGEDIR = "static/images"
if not os.path.exists(IMAGEDIR):
    os.makedirs(IMAGEDIR)

app.mount("/images", StaticFiles(directory=IMAGEDIR), name="images")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


# --- Enums (เหลือแค่ Goal กับ Activity ก็พอ) ---
class GoalType(str, Enum):
    lose_weight = 'lose_weight'
    maintain_weight = 'maintain_weight'
    gain_muscle = 'gain_muscle'

class ActivityLevel(str, Enum):
    sedentary = 'sedentary'
    lightly_active = 'lightly_active'
    moderately_active = 'moderately_active'
    very_active = 'very_active'

# --- Pydantic Models ---
class UserRegister(BaseModel):
    email: str
    password: str
    username: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserUpdate(BaseModel):
    username: str | None = None
    gender: str | None = None
    birth_date: date | None = None
    height_cm: float | None = None
    current_weight_kg: float | None = None
    goal_type: GoalType | None = None
    target_weight_kg: float | None = None
    target_calories: int | None = None
    activity_level: ActivityLevel | None = None
    goal_target_date: date | None = None
    unit_weight: str | None = None
    unit_height: str | None = None
    unit_energy: str | None = None
    unit_water: str | None = None

# ✅ Model สำหรับสร้างอาหาร (รองรับรูป)
class FoodCreate(BaseModel):
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float
    image_url: str | None = None 

class MealItem(BaseModel):
    food_id: int
    amount: float = 1.0
    food_name: str
    cal_per_unit: float
    protein_per_unit: float
    carbs_per_unit: float
    fat_per_unit: float

class DailyLogUpdate(BaseModel):
    date: date
    meal_type: str # ✅ รับค่า string อะไรก็ได้ (Infinite Meals)
    items: List[MealItem]

# ==========================================
# API Endpoints
# ==========================================

@app.get("/")
def read_root():
    return {"message": "API is running with Infinite Meals & Image Upload!"}

# --- API: Upload Image ---
@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    file_extension = file.filename.split(".")[-1]
    new_filename = f"food_{uuid4()}.{file_extension}"
    file_path = f"{IMAGEDIR}/{new_filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # ⚠️ ถ้าใช้ Emulator ให้ใช้ 10.0.2.2, ถ้าเครื่องจริงใช้ IP เครื่อง (เช่น 192.168.1.x)
    return {"url": f"http://10.0.2.2:8000/images/{new_filename}"}

# --- API 1: Foods List ---
@app.get("/foods")
def read_foods():
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Create Food (For Admin) ---
@app.post("/foods")
def create_food(food: FoodCreate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # ✅ บันทึก image_url ด้วย
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
        if conn: conn.close()

# --- API 2: Food Detail ---
@app.put("/foods/{food_id}")
def update_food(food_id: int, food: FoodCreate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # อัปเดตข้อมูลรวมถึงรูปภาพ
        cur.execute("""
            UPDATE foods 
            SET food_name = %s, 
                calories = %s, 
                protein = %s, 
                carbs = %s, 
                fat = %s, 
                image_url = %s
            WHERE food_id = %s
        """, (food.food_name, food.calories, food.protein, food.carbs, food.fat, food.image_url, food_id))
        
        conn.commit()
        return {"message": "Food updated successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 3: Register ---
@app.post("/register")
def register(user: UserRegister):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (user.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already exists")
        
        hashed_pw = get_password_hash(user.password)
        cur.execute("""
            INSERT INTO users (email, password_hash, username, role_id)
            VALUES (%s, %s, %s, 2)
            RETURNING user_id, email, username
        """, (user.email, hashed_pw, user.username))
        new_user = cur.fetchone()
        
        conn.commit()
        return {"message": "User created", "user": new_user}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 4: Login ---
@app.post("/login")
def login(user: UserLogin):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (user.email,))
        db_user = cur.fetchone()
        
        if not db_user or not verify_password(user.password, db_user['password_hash']):
            raise HTTPException(status_code=401, detail="Invalid email or password")
            
        return {
            "message": "Login successful",
            "user_id": db_user['user_id'],
            "username": db_user['username'],
            "email": db_user['email'],
            "role_id": db_user['role_id'] 
        }
    finally:
        if conn: conn.close()

# --- API 5: Update User ---
@app.put("/users/{user_id}")
def update_user(user_id: int, user_update: UserUpdate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        user_fields = []
        user_values = []
        if user_update.username: user_fields.append("username=%s"); user_values.append(user_update.username)
        if user_update.goal_type: user_fields.append("goal_type=%s"); user_values.append(user_update.goal_type)
        if user_update.target_weight_kg: user_fields.append("target_weight_kg=%s"); user_values.append(user_update.target_weight_kg)
        if user_update.target_calories: user_fields.append("target_calories=%s"); user_values.append(user_update.target_calories)
        if user_update.activity_level: user_fields.append("activity_level=%s"); user_values.append(user_update.activity_level)
        if user_update.gender: user_fields.append("gender=%s"); user_values.append(user_update.gender)
        if user_update.birth_date: user_fields.append("birth_date=%s"); user_values.append(user_update.birth_date)
        if user_update.height_cm: user_fields.append("height_cm=%s"); user_values.append(user_update.height_cm)
        if user_update.current_weight_kg: user_fields.append("current_weight_kg=%s"); user_values.append(user_update.current_weight_kg)
        if user_update.goal_target_date: user_fields.append("goal_target_date=%s"); user_values.append(user_update.goal_target_date)

        if user_fields:
            user_values.append(user_id)
            sql = f"UPDATE users SET {', '.join(user_fields)} WHERE user_id = %s"
            cur.execute(sql, tuple(user_values))

        # Weight Log
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
        if conn: conn.close()

# --- API 6: Get User Profile ---
@app.get("/users/{user_id}")
def get_user_profile(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    finally:
        if conn: conn.close()

# --- Map meal_1..4 (Flutter) -> breakfast/lunch/dinner/snack (cleangoal enum) ---
def _meal_type_to_enum(meal_type: str):
    m = {"meal_1": "breakfast", "meal_2": "lunch", "meal_3": "dinner", "meal_4": "snack"}
    return m.get(meal_type, "snack")

# --- API 7: Record Meal (cleangoal schema: meals + detail_items, daily_summaries แค่แคล) ---
@app.post("/meals/{user_id}")
def add_meal(user_id: int, log: DailyLogUpdate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        meal_type_db = _meal_type_to_enum(log.meal_type)
        total_cal = sum(item.cal_per_unit * item.amount for item in log.items)
        # วันที่บันทึก ใช้เป็น meal_time (เวลาเที่ยงของวันนั้น)
        meal_ts = datetime.combine(log.date, datetime.min.time().replace(hour=12, minute=0, second=0))

        # 1. Insert meal (cleangoal: meal_time, total_amount, meal_type enum)
        cur.execute("""
            INSERT INTO meals (user_id, meal_type, meal_time, total_amount)
            VALUES (%s, %s, %s, %s)
            RETURNING meal_id
        """, (user_id, meal_type_db, meal_ts, total_cal))
        meal_id = cur.fetchone()['meal_id']

        # 2. Insert detail_items (cleangoal ไม่มี meal_items; ไม่มี protein/carbs/fat ใน detail_items)
        for item in log.items:
            cur.execute("""
                INSERT INTO detail_items (meal_id, food_id, food_name, amount, cal_per_unit)
                VALUES (%s, %s, %s, %s, %s)
            """, (meal_id, item.food_id, item.food_name, item.amount, item.cal_per_unit))

        # 3. Upsert daily_summaries (cleangoal มีแค่ total_calories_intake, goal_calories, is_goal_met)
        cur.execute("""
            INSERT INTO daily_summaries (user_id, date_record, total_calories_intake)
            VALUES (%s, %s, %s)
            ON CONFLICT (user_id, date_record)
            DO UPDATE SET
                total_calories_intake = daily_summaries.total_calories_intake + EXCLUDED.total_calories_intake
        """, (user_id, log.date, total_cal))

        conn.commit()
        return {"message": "Meal recorded successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 8: Get Daily Summary (cleangoal: meals.meal_time, detail_items, โปรตีน/คาร์บ/ไขมันจาก foods) ---
@app.get("/daily_summary/{user_id}")
def get_daily_summary(user_id: int, date_record: date):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("SELECT target_calories FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        target_cal = user['target_calories'] if user else 2000

        cur.execute("""
            SELECT total_calories_intake FROM daily_summaries
            WHERE user_id = %s AND date_record = %s
        """, (user_id, date_record))
        row = cur.fetchone()
        total_cal = int(row['total_calories_intake']) if row and row['total_calories_intake'] else 0

        # โปรตีน/คาร์บ/ไขมัน จาก detail_items + foods (อัตราส่วนจากแคล)
        cur.execute("""
            SELECT COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.protein, 0) / NULLIF(f.calories, 0)), 0) AS total_protein,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.carbs, 0) / NULLIF(f.calories, 0)), 0) AS total_carbs,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.fat, 0) / NULLIF(f.calories, 0)), 0) AS total_fat
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            JOIN foods f ON f.food_id = di.food_id
            WHERE m.user_id = %s AND DATE(m.meal_time) = %s
        """, (user_id, date_record))
        macro = cur.fetchone()
        total_prot = float(macro['total_protein']) if macro else 0
        total_carb = float(macro['total_carbs']) if macro else 0
        total_fat = float(macro['total_fat']) if macro else 0

        summary = {
            "total_calories_intake": total_cal, "total_protein": total_prot,
            "total_carbs": total_carb, "total_fat": total_fat,
            "target_calories": target_cal,
        }

        cur.execute("""
            SELECT m.meal_type, STRING_AGG(di.food_name, ', ') AS menu_names
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            WHERE m.user_id = %s AND DATE(m.meal_time) = %s
            GROUP BY m.meal_type
        """, (user_id, date_record))
        menu_rows = cur.fetchall()
        summary['meals'] = {row['meal_type']: (row['menu_names'] or '') for row in menu_rows}

        return summary
    finally:
        if conn: conn.close()

# --- API 9: Delete User ---
@app.delete("/users/{user_id}")
def delete_user(user_id: int):
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
        if conn: conn.close()

# --- API 10: Calendar Logs ---
@app.get("/daily_logs/{user_id}/calendar")
def get_calendar_logs(user_id: int, month: int, year: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        sql = """
            SELECT date_record as date, total_calories_intake as calories 
            FROM daily_summaries
            WHERE user_id = %s 
              AND EXTRACT(MONTH FROM date_record) = %s
              AND EXTRACT(YEAR FROM date_record) = %s
        """
        cur.execute(sql, (user_id, month, year))
        logs = cur.fetchall()
        return logs
    finally:
        if conn: conn.close()


# --- API 10b: Weekly Logs (cleangoal: แคลจาก daily_summaries, โปรตีน/คาร์บ/ไขมันจาก detail_items+foods) ---
@app.get("/daily_logs/{user_id}/weekly")
def get_weekly_logs(user_id: int, week_start: Optional[str] = None):
    """คืนค่า 7 วัน (จ.–อา.): date, calories, protein, carbs, fat."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if week_start:
            try:
                monday = datetime.strptime(week_start, "%Y-%m-%d").date()
            except ValueError:
                monday = date.today()
                while monday.weekday() != 0:
                    monday -= timedelta(days=1)
        else:
            monday = date.today()
            while monday.weekday() != 0:
                monday -= timedelta(days=1)
        sunday = monday + timedelta(days=6)

        cur.execute("""
            SELECT date_record, total_calories_intake
            FROM daily_summaries
            WHERE user_id = %s AND date_record >= %s AND date_record <= %s
        """, (user_id, monday, sunday))
        cal_rows = {row["date_record"]: int(row["total_calories_intake"] or 0) for row in cur.fetchall()}

        cur.execute("""
            SELECT DATE(m.meal_time) AS d,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.protein, 0) / NULLIF(f.calories, 0)), 0) AS total_protein,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.carbs, 0) / NULLIF(f.calories, 0)), 0) AS total_carbs,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.fat, 0) / NULLIF(f.calories, 0)), 0) AS total_fat
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            JOIN foods f ON f.food_id = di.food_id
            WHERE m.user_id = %s AND DATE(m.meal_time) >= %s AND DATE(m.meal_time) <= %s
            GROUP BY DATE(m.meal_time)
        """, (user_id, monday, sunday))
        macro_rows = {row["d"]: row for row in cur.fetchall()}

        result = []
        for i in range(7):
            d = monday + timedelta(days=i)
            cal = cal_rows.get(d, 0)
            macro = macro_rows.get(d)
            result.append({
                "date": d.isoformat(),
                "calories": cal,
                "protein": float(macro["total_protein"]) if macro else 0,
                "carbs": float(macro["total_carbs"]) if macro else 0,
                "fat": float(macro["total_fat"]) if macro else 0,
            })
        return result
    finally:
        if conn: conn.close()


# --- API 10c: Day detail (cleangoal: meal_time, detail_items; meals.meal_type = breakfast/lunch/dinner/snack) ---
@app.get("/daily_logs/{user_id}")
def get_daily_log_by_date(user_id: int, date_query: date):
    """คืนค่าบันทึกวันเดียว: calories, protein, carbs, fat, meals (breakfast/lunch/dinner/snack)."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT total_calories_intake FROM daily_summaries
            WHERE user_id = %s AND date_record = %s
        """, (user_id, date_query))
        row = cur.fetchone()
        total_cal = int(row["total_calories_intake"]) if row and row["total_calories_intake"] else 0

        cur.execute("""
            SELECT COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.protein, 0) / NULLIF(f.calories, 0)), 0) AS total_protein,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.carbs, 0) / NULLIF(f.calories, 0)), 0) AS total_carbs,
                   COALESCE(SUM(di.amount * di.cal_per_unit * NULLIF(f.fat, 0) / NULLIF(f.calories, 0)), 0) AS total_fat
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            JOIN foods f ON f.food_id = di.food_id
            WHERE m.user_id = %s AND DATE(m.meal_time) = %s
        """, (user_id, date_query))
        macro = cur.fetchone()

        cur.execute("""
            SELECT m.meal_type, STRING_AGG(di.food_name, ', ') AS menu_names
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            WHERE m.user_id = %s AND DATE(m.meal_time) = %s
            GROUP BY m.meal_type
        """, (user_id, date_query))
        menu_rows = cur.fetchall()
        meals_map = {r["meal_type"]: (r["menu_names"] or "") for r in menu_rows}
        meals = {
            "breakfast": meals_map.get("breakfast", ""),
            "lunch": meals_map.get("lunch", ""),
            "dinner": meals_map.get("dinner", ""),
            "snack": meals_map.get("snack", ""),
        }
        return {
            "calories": total_cal,
            "protein": int(macro["total_protein"]) if macro else 0,
            "carbs": int(macro["total_carbs"]) if macro else 0,
            "fat": int(macro["total_fat"]) if macro else 0,
            "meals": meals,
        }
    finally:
        if conn: conn.close()


# --- API 11: Clear Meal (cleangoal: meals.meal_time, detail_items CASCADE ผ่าน FK) ---
@app.delete("/meals/clear/{user_id}")
def clear_meal_type(user_id: int, date_record: date, meal_type: str):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        meal_type_db = _meal_type_to_enum(meal_type)

        cur.execute("""
            DELETE FROM meals
            WHERE user_id = %s
              AND DATE(meal_time) = %s
              AND meal_type = %s
        """, (user_id, date_record, meal_type_db))

        cur.execute("""
            SELECT COALESCE(SUM(di.amount * di.cal_per_unit), 0) AS total_cal
            FROM meals m
            JOIN detail_items di ON di.meal_id = m.meal_id
            WHERE m.user_id = %s AND DATE(m.meal_time) = %s
        """, (user_id, date_record))
        row = cur.fetchone()
        new_cal = float(row['total_cal']) if row else 0

        cur.execute("""
            UPDATE daily_summaries
            SET total_calories_intake = %s
            WHERE user_id = %s AND date_record = %s
        """, (new_cal, user_id, date_record))
        if cur.rowcount == 0 and new_cal == 0:
            cur.execute("""
                DELETE FROM daily_summaries
                WHERE user_id = %s AND date_record = %s
            """, (user_id, date_record))

        conn.commit()
        return {"message": f"Cleared {meal_type} successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()
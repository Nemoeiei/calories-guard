from datetime import date, datetime
from typing import List, Optional, Dict
from enum import Enum
from fastapi import FastAPI, HTTPException
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

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


# --- Enums (ให้ตรงกับ DB) ---
class GoalType(str, Enum):
    lose_weight = 'lose_weight'
    maintain_weight = 'maintain_weight'
    gain_muscle = 'gain_muscle'

class ActivityLevel(str, Enum):
    sedentary = 'sedentary'
    lightly_active = 'lightly_active'
    moderately_active = 'moderately_active'
    very_active = 'very_active'

# ❌ ลบ MealType Enum ออกเพื่อให้รับค่าอะไรก็ได้ (meal_1, meal_2...)
# class MealType(str, Enum): ... 

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
    meal_type: str # ✅ เปลี่ยนเป็น str เพื่อรองรับ 'meal_1', 'meal_2' ได้ไม่จำกัด
    items: List[MealItem]

# ==========================================
# API Endpoints
# ==========================================

@app.get("/")
def read_root():
    return {"message": "API is running with Dynamic Meal Support!"}

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

# --- API 2: Food Detail ---
@app.get("/foods/{food_id}")
def read_food(food_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods WHERE food_id = %s", (food_id,))
        food = cur.fetchone()
        if food is None:
            raise HTTPException(status_code=404, detail="Food not found")
        return food
    finally:
        if conn: conn.close()

# --- API 3: Register ---
@app.post("/register")
def register(user: UserRegister):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # 1. Check Email
        cur.execute("SELECT * FROM users WHERE email = %s", (user.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already exists")
        
        # 2. Insert User
        hashed_pw = get_password_hash(user.password)
        cur.execute("""
            INSERT INTO users (email, password_hash, username, role_id)
            VALUES (%s, %s, %s, 2)
            RETURNING user_id, email, username
        """, (user.email, hashed_pw, user.username))
        new_user = cur.fetchone()
        
        # 3. Init User Stats
        cur.execute("""
            INSERT INTO user_stats (user_id, date_logged) VALUES (%s, CURRENT_DATE)
        """, (new_user['user_id'],))
        
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
        
        # 1. Update users table
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
        # Units
        if user_update.unit_weight: user_fields.append("unit_weight=%s"); user_values.append(user_update.unit_weight)
        if user_update.unit_height: user_fields.append("unit_height=%s"); user_values.append(user_update.unit_height)
        if user_update.unit_energy: user_fields.append("unit_energy=%s"); user_values.append(user_update.unit_energy)
        if user_update.unit_water: user_fields.append("unit_water=%s"); user_values.append(user_update.unit_water)

        if user_fields:
            user_values.append(user_id)
            sql = f"UPDATE users SET {', '.join(user_fields)} WHERE user_id = %s"
            cur.execute(sql, tuple(user_values))

        # 2. Update user_stats (ประวัติ)
        if user_update.current_weight_kg or user_update.height_cm:
            cur.execute("""
                INSERT INTO user_stats (user_id, date_logged, weight_kg, height_cm)
                VALUES (%s, CURRENT_DATE, %s, %s)
                ON CONFLICT (user_id, date_logged) 
                DO UPDATE SET weight_kg = EXCLUDED.weight_kg, height_cm = EXCLUDED.height_cm
            """, (user_id, user_update.current_weight_kg, user_update.height_cm))

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

# --- API 7: Record Meal (แบบใหม่ รองรับ Dynamic Meal Type) ---
@app.post("/meals/{user_id}")
def add_meal(user_id: int, log: DailyLogUpdate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. Create Meal
        # ใช้ created_at เป็นตัวเก็บเวลา
        cur.execute("""
            INSERT INTO meals (user_id, meal_type, created_at)
            VALUES (%s, %s, NOW())
            RETURNING meal_id
        """, (user_id, log.meal_type))
        meal_id = cur.fetchone()['meal_id']
        
        # 2. Insert Items & Calculate Total
        total_cal = 0
        total_prot = 0
        total_carb = 0
        total_fat = 0
        
        for item in log.items:
            cal = item.cal_per_unit * item.amount
            prot = item.protein_per_unit * item.amount
            carb = item.carbs_per_unit * item.amount
            fat = item.fat_per_unit * item.amount
            
            total_cal += cal
            total_prot += prot
            total_carb += carb
            total_fat += fat
            
            cur.execute("""
                INSERT INTO meal_items (meal_id, food_id, amount, food_name, 
                                        cal_per_unit, protein_per_unit, carbs_per_unit, fat_per_unit)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (meal_id, item.food_id, item.amount, item.food_name, 
                  item.cal_per_unit, item.protein_per_unit, item.carbs_per_unit, item.fat_per_unit))

        # 3. Update Daily Summary
        cur.execute("""
            INSERT INTO daily_summaries (user_id, date_record, total_calories_intake, total_protein, total_carbs, total_fat)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (user_id, date_record)
            DO UPDATE SET 
                total_calories_intake = daily_summaries.total_calories_intake + EXCLUDED.total_calories_intake,
                total_protein = daily_summaries.total_protein + EXCLUDED.total_protein,
                total_carbs = daily_summaries.total_carbs + EXCLUDED.total_carbs,
                total_fat = daily_summaries.total_fat + EXCLUDED.total_fat
        """, (user_id, log.date, total_cal, total_prot, total_carb, total_fat))
        
        conn.commit()
        return {"message": "Meal recorded successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 8: Get Daily Summary (แก้ไขให้คืนค่าเป็น Dynamic Map) ---
@app.get("/daily_summary/{user_id}")
def get_daily_summary(user_id: int, date_record: date):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. ดึงเป้าหมายแคลอรี่
        cur.execute("SELECT target_calories FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        target_cal = user['target_calories'] if user else 2000
        
        # 2. ดึงข้อมูลตัวเลขสรุป (Summary)
        cur.execute("""
            SELECT * FROM daily_summaries 
            WHERE user_id = %s AND date_record = %s
        """, (user_id, date_record))
        summary = cur.fetchone()
        
        if not summary:
            summary = {
                "total_calories_intake": 0, "total_protein": 0, 
                "total_carbs": 0, "total_fat": 0, 
                "target_calories": target_cal
            }
        else:
            summary['target_calories'] = target_cal

        # 🔥 3. [แก้ใหม่] ดึงรายชื่ออาหารและ Group ตาม meal_type
        # ใช้ created_at ในการกรองวัน เพราะตาราง meals ไม่มี meal_time
        cur.execute("""
            SELECT m.meal_type, STRING_AGG(mi.food_name, ', ') as menu_names
            FROM meals m
            JOIN meal_items mi ON m.meal_id = mi.meal_id
            WHERE m.user_id = %s AND DATE(m.created_at) = %s
            GROUP BY m.meal_type
        """, (user_id, date_record))
        
        menu_rows = cur.fetchall()
        
        # แปลงเป็น Dict เช่น: {'meal_1': 'ข้าวผัด', 'meal_2': 'ก๋วยเตี๋ยว'}
        meals_map = {row['meal_type']: row['menu_names'] for row in menu_rows}
        
        # ส่งก้อนนี้ไปให้ Frontend ใน key 'meals'
        summary['meals'] = meals_map 
        
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

# --- API 11: Clear Specific Meal Type (แก้ให้รับ str และใช้ created_at) ---
@app.delete("/meals/clear/{user_id}")
def clear_meal_type(user_id: int, date_record: date, meal_type: str): # ✅ รับ str
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        
        # 1. ลบข้อมูลในตาราง meals
        # ใช้ created_at ตามโครงสร้าง DB จริง
        cur.execute("""
            DELETE FROM meals 
            WHERE user_id = %s 
              AND DATE(created_at) = %s 
              AND meal_type = %s
        """, (user_id, date_record, meal_type))
        
        # 2. คำนวณ Daily Summary ใหม่ (Recalculate)
        cur.execute("""
            SELECT 
                COALESCE(SUM(mi.amount * mi.cal_per_unit), 0) as total_cal,
                COALESCE(SUM(mi.amount * mi.protein_per_unit), 0) as total_protein,
                COALESCE(SUM(mi.amount * mi.carbs_per_unit), 0) as total_carbs,
                COALESCE(SUM(mi.amount * mi.fat_per_unit), 0) as total_fat
            FROM meals m
            JOIN meal_items mi ON m.meal_id = mi.meal_id
            WHERE m.user_id = %s AND DATE(m.created_at) = %s
        """, (user_id, date_record))
        
        new_stats = cur.fetchone()
        
        # อัปเดตตารางสรุป
        cur.execute("""
            UPDATE daily_summaries
            SET total_calories_intake = %s,
                total_protein = %s,
                total_carbs = %s,
                total_fat = %s
            WHERE user_id = %s AND date_record = %s
        """, (new_stats[0], new_stats[1], new_stats[2], new_stats[3], user_id, date_record))

        conn.commit()
        return {"message": f"Cleared {meal_type} successfully"}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()
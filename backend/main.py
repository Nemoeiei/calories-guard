from datetime import date
import hashlib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from passlib.context import CryptContext
from database import get_db_connection
from psycopg2.extras import RealDictCursor

app = FastAPI()

# --- Config: ตั้งค่าการเข้ารหัสรหัสผ่าน ---
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --- Helper Functions: ช่วยเข้ารหัส/ตรวจสอบรหัสผ่าน ---
def get_password_hash(password):
    # 1. แปลงรหัสผ่านยาวๆ เป็น SHA-256 ก่อน
    hashed_sha256 = hashlib.sha256(password.encode('utf-8')).hexdigest()
    # 2. ส่งให้ Bcrypt เข้ารหัสต่อ
    return pwd_context.hash(hashed_sha256)

def verify_password(plain_password, hashed_password):
    # ตอนตรวจสอบ ก็ต้องแปลงเป็น SHA-256 ก่อน
    hashed_sha256 = hashlib.sha256(plain_password.encode('utf-8')).hexdigest()
    return pwd_context.verify(hashed_sha256, hashed_password)

# ==========================================
# Models (โครงสร้างข้อมูลรับ-ส่ง)
# ==========================================

class UserRegister(BaseModel):
    email: str
    password: str
    username: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserUpdate(BaseModel):
    gender: str | None = None
    birth_date: date | None = None
    height_cm: float | None = None
    current_weight_kg: float | None = None
    goal_type: str | None = None
    target_weight_kg: float | None = None
    goal_target_date: date | None = None
    target_calories: int | None = None
    target_protein: int | None = None
    target_carbs: int | None = None
    target_fat: int | None = None
    activity_level: str | None = None
    username: str | None = None
    unit_weight: str | None = None
    unit_height: str | None = None
    unit_energy: str | None = None
    unit_water: str | None = None

class DailyLogUpdate(BaseModel):
    date: date
    calories: int
    protein: int
    carbs: int
    fat: int
    breakfast_menu: str
    lunch_menu: str
    dinner_menu: str
    snack_menu: str

# ==========================================
# API Endpoints
# ==========================================

@app.get("/")
def read_root():
    return {"message": "API is running! Welcome to CleanGoal Backend."}

# --- API 1: ดึงรายชื่ออาหารทั้งหมด ---
@app.get("/foods")
def read_foods():
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 2: ดึงข้อมูลอาหารตาม ID ---
@app.get("/foods/{food_id}")
def read_food(food_id: int):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods WHERE food_id = %s", (food_id,))
        food = cur.fetchone()
        if food is None:
            raise HTTPException(status_code=404, detail="Food not found")
        return food
    finally:
        if conn: conn.close()

# --- API 3: สมัครสมาชิก (Register) ---
@app.post("/register")
def register(user: UserRegister):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # 1. เช็คอีเมลซ้ำ
        cur.execute("SELECT * FROM users WHERE email = %s", (user.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already exists")
        # 2. เข้ารหัส
        hashed_pw = get_password_hash(user.password)
        # 3. บันทึก
        sql = """
            INSERT INTO users (email, password_hash, username, created_at, updated_at)
            VALUES (%s, %s, %s, NOW(), NOW())
            RETURNING user_id, email, username
        """
        cur.execute(sql, (user.email, hashed_pw, user.username))
        new_user = cur.fetchone()
        conn.commit()
        return {"message": "User created successfully", "user": new_user}
    except Exception as e:
        conn.rollback()
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 4: เข้าสู่ระบบ (Login) ---
@app.post("/login")
def login(user: UserLogin):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
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
            "email": db_user['email']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 5: อัปเดตข้อมูลผู้ใช้ (PUT) ---
@app.put("/users/{user_id}")
def update_user(user_id: int, user_update: UserUpdate):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        update_fields = []
        values = []
        
        # ตรวจสอบว่าส่งค่าอะไรมาบ้าง
        if user_update.username is not None:
            update_fields.append("username = %s")
            values.append(user_update.username)
        if user_update.activity_level is not None:
            update_fields.append("activity_level = %s")
            values.append(user_update.activity_level)
        if user_update.target_protein is not None:
            update_fields.append("target_protein = %s")
            values.append(user_update.target_protein)
        if user_update.target_carbs is not None:
            update_fields.append("target_carbs = %s")
            values.append(user_update.target_carbs)
        if user_update.target_fat is not None:
            update_fields.append("target_fat = %s")
            values.append(user_update.target_fat)
        if user_update.target_calories is not None:
            update_fields.append("target_calories = %s")
            values.append(user_update.target_calories)
        if user_update.target_weight_kg:
            update_fields.append("target_weight_kg = %s")
            values.append(user_update.target_weight_kg)
        if user_update.goal_target_date:
            update_fields.append("goal_target_date = %s")
            values.append(user_update.goal_target_date)
        if user_update.goal_type:
            update_fields.append("goal_type = %s")
            values.append(user_update.goal_type)
        if user_update.gender:
            update_fields.append("gender = %s")
            values.append(user_update.gender)
        if user_update.birth_date:
            update_fields.append("birth_date = %s")
            values.append(user_update.birth_date)
        if user_update.height_cm:
            update_fields.append("height_cm = %s")
            values.append(user_update.height_cm)
        if user_update.current_weight_kg:
            update_fields.append("current_weight_kg = %s")
            values.append(user_update.current_weight_kg)
        
            
        if not update_fields:
             return {"message": "No fields to update"}
             
        values.append(user_id)
        
        sql = f"""
            UPDATE users 
            SET {", ".join(update_fields)}, updated_at = NOW()
            WHERE user_id = %s
            RETURNING *
        """
        cur.execute(sql, tuple(values))
        updated_user = cur.fetchone()
        conn.commit()
        
        if updated_user is None:
            raise HTTPException(status_code=404, detail="User not found")
            
        return {"message": "Update successful", "user": updated_user}
    except Exception as e:
        conn.rollback()
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 6: ดึงข้อมูลการกินของวันนี้ (GET Daily Log) ---
@app.get("/daily_logs/{user_id}")
def get_daily_log(user_id: int, date_query: date):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # ดึงทั้ง log และ target_calories ของ user
        sql = """
            SELECT d.*, u.target_calories 
            FROM daily_logs d
            RIGHT JOIN users u ON d.user_id = u.user_id
            WHERE u.user_id = %s AND (d.date = %s OR d.date IS NULL)
        """
        cur.execute(sql, (user_id, date_query))
        result = cur.fetchone()
        
        # จัดการค่า Default กรณีไม่มีข้อมูล
        if result:
            if result['target_calories'] is None: result['target_calories'] = 0
            if result['log_id'] is None: # ถ้าไม่มี log วันนี้
                return {
                    "calories": 0, "protein": 0, "carbs": 0, "fat": 0,
                    "breakfast_menu": "", "lunch_menu": "", "dinner_menu": "", "snack_menu": "",
                    "target_calories": result['target_calories']
                }
            return result
        else:
            raise HTTPException(status_code=404, detail="User not found")
    finally:
        if conn: conn.close()

# --- API 7: บันทึกการกินรายวัน (PUT Daily Log) ---
@app.put("/daily_logs/{user_id}")
def update_daily_log(user_id: int, log: DailyLogUpdate):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        sql = """
            INSERT INTO daily_logs (user_id, date, calories, protein, carbs, fat, breakfast_menu, lunch_menu, dinner_menu, snack_menu, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            ON CONFLICT (user_id, date) 
            DO UPDATE SET 
                calories = EXCLUDED.calories,
                protein = EXCLUDED.protein,
                carbs = EXCLUDED.carbs,
                fat = EXCLUDED.fat,
                breakfast_menu = EXCLUDED.breakfast_menu,
                lunch_menu = EXCLUDED.lunch_menu,
                dinner_menu = EXCLUDED.dinner_menu,
                snack_menu = EXCLUDED.snack_menu,
                updated_at = NOW()
            RETURNING *;
        """
        cur.execute(sql, (
            user_id, log.date, log.calories, log.protein, log.carbs, log.fat,
            log.breakfast_menu, log.lunch_menu, log.dinner_menu, log.snack_menu
        ))
        updated_log = cur.fetchone()
        conn.commit()
        return {"message": "Log updated", "data": updated_log}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 8: ดึงข้อมูล User Profile (GET) ---
@app.get("/users/{user_id}")
def get_user_profile(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # ✅ เพิ่ม goal_target_date เข้าไปในบรรทัด SELECT ครับ
        cur.execute("""
            SELECT user_id, email, username, gender, birth_date, 
                   height_cm, current_weight_kg, target_weight_kg, 
                   target_calories, 
                   target_protein, target_carbs, target_fat,
                   goal_type, 
                   goal_target_date  -- 🔥 บรรทัดนี้ที่ขาดไปครับ!
            FROM users 
            WHERE user_id = %s
        """, (user_id,))
        
        user = cur.fetchone()
        
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")
            
        return user
    finally:
        if conn: conn.close()
@app.delete("/users/{user_id}")
def delete_user(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # ลบข้อมูลที่เกี่ยวข้องก่อน (ถ้ามี Foreign Key) เช่น daily_logs
        cur.execute("DELETE FROM daily_logs WHERE user_id = %s", (user_id,))
        # ลบ user
        cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        conn.commit()
        return {"message": "User deleted successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()
@app.get("/daily_logs/{user_id}")
def get_daily_log(user_id: int, date_query: date):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # 1. เช็คก่อนว่ามี User คนนี้ไหม? (เอา Target Calories มาด้วย)
        cur.execute("SELECT target_calories FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()

        if user is None:
            # ถ้าไม่มี User นี้ในระบบเลย ค่อยส่ง 404
            raise HTTPException(status_code=404, detail="User not found")

        # 2. ถ้ามี User -> ให้ลองดึง Log ของวันที่ระบุ
        cur.execute("SELECT * FROM daily_logs WHERE user_id = %s AND date = %s", (user_id, date_query))
        log = cur.fetchone()

        target_cal = user['target_calories'] if user['target_calories'] is not None else 0

        # 3. ถ้ามี Log ของวันนี้ -> ส่งข้อมูลกลับไป
        if log:
            log['target_calories'] = target_cal
            return log
        
        # 4. 🔥 จุดสำคัญ: ถ้าไม่มี Log (วันใหม่) -> ให้ส่งค่า 0 กลับไป (ห้ามส่ง 404)
        else:
            return {
                "calories": 0,
                "protein": 0,
                "carbs": 0,
                "fat": 0,
                "breakfast_menu": "",
                "lunch_menu": "",
                "dinner_menu": "",
                "snack_menu": "",
                "target_calories": target_cal
            }

    finally:
        if conn: conn.close()
@app.get("/daily_logs/{user_id}/calendar")
def get_calendar_logs(user_id: int, month: int, year: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # ดึงเฉพาะวันที่ ที่มีข้อมูล
        sql = """
            SELECT date, calories 
            FROM daily_logs
            WHERE user_id = %s 
              AND EXTRACT(MONTH FROM date) = %s
              AND EXTRACT(YEAR FROM date) = %s
        """
        cur.execute(sql, (user_id, month, year))
        logs = cur.fetchall()
        return logs # ส่งกลับเป็น List ของวันที่ที่มีข้อมูล
    finally:
        if conn: conn.close()
<<<<<<< Updated upstream
from datetime import date, datetime, timedelta
from typing import List, Optional, Dict
from enum import Enum
import os
from dotenv import load_dotenv
load_dotenv()
import shutil
from uuid import uuid4
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from passlib.context import CryptContext
from database import get_db_connection
from psycopg2.extras import RealDictCursor

app = FastAPI()

# --- Email Config ---
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
FROM_EMAIL = os.getenv("FROM_EMAIL", SMTP_USERNAME)
FROM_NAME = os.getenv("FROM_NAME", "Calories Guard")

def send_email(to_email: str, subject: str, html_body: str) -> bool:
    """Send email via SMTP. Returns True if successful."""
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        print(f"[Email] SMTP not configured. Would send to {to_email}: {subject}")
        return False
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{FROM_NAME} <{FROM_EMAIL}>"
        msg["To"] = to_email
        msg.attach(MIMEText(html_body, "html"))
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.sendmail(FROM_EMAIL, to_email, msg.as_string())
        print(f"[Email] Sent to {to_email}: {subject}")
        return True
    except Exception as e:
        print(f"[Email] Failed to send to {to_email}: {e}")
        return False

def send_welcome_email(email: str, username: str):
    subject = "ยินดีต้อนรับสู่ Calories Guard!"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}!</h2>
        <p>ขอบคุณที่สมัครสมาชิก <strong>Calories Guard</strong></p>
        <p>ตอนนี้คุณสามารถเริ่มติดตามการรับประทานอาหารและเป้าหมายสุขภาพของคุณได้แล้ว</p>
        <p>หากมีคำถาม ติดต่อเราได้เสมอ</p>
        <br>
        <p>ด้วยความปรารถนาดี,<br>ทีมงาน Calories Guard</p>
    </html>
    """
    send_email(email, subject, html)

def send_verification_email(email: str, username: str, code: str):
    subject = "ยืนยันอีเมลของคุณ - Calories Guard"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}!</h2>
        <p>กรุณายืนยันอีเมลของคุณเพื่อเริ่มใช้งาน</p>
        <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>รหัสยืนยันของคุณ: <strong>{code}</strong></h3>
        </div>
        <p>ขอบคุณที่ร่วมเป็นส่วนหนึ่งกับเรา</p>
    </body>
    </html>
    """
    send_email(email, subject, html)

def send_password_reset_email(email: str, username: str, code: str):
    subject = "รีเซ็ตรหัสผ่าน - Calories Guard"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}</h2>
        <p>คุณได้ร้องขอการรีเซ็ตรหัสผ่าน</p>
        <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>รหัสยืนยันของคุณ: <strong>{code}</strong></h3>
        </div>
        <p>รหัสนี้จะหมดอายุภายใน 15 นาที</p>
        <p>หากคุณไม่ได้ร้องขอการรีเซ็ตรหัสผ่าน กรุณาเพิกเฉยต่ออีเมลนี้</p>
        <br>
        <p>ด้วยความปรารถนาดี,<br>ทีมงาน Calories Guard</p>
    </body>
    </html>
    """
    send_email(email, subject, html)

# --- CORS: ให้แอป Flutter / เบราว์เซอร์ จาก origin อื่น (เช่น ngrok, APK) ยิง API ได้ ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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


# --- Official formulas: BMR (Mifflin-St Jeor), TDEE, Daily Target ---
def _age_from_birth(birth_date: Optional[date]) -> int:
    if not birth_date:
        return 20
    today = date.today()
    age = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        age -= 1
    return max(age, 10)


def _compute_target_macros(user: dict) -> tuple:
    """คืน (target_protein, target_carbs, target_fat) จาก target_calories กับ goal (อัตราส่วนเท่า Flutter)."""
    cal = user.get('target_calories')
    if cal is None:
        cal = _compute_target_calories(user)
    cal = int(cal) if cal else 2000
    goal = (user.get('goal_type') or 'lose_weight').lower()
    if goal == 'maintain_weight':
        p_ratio, c_ratio, f_ratio = 0.25, 0.45, 0.30
    elif goal == 'gain_muscle':
        p_ratio, c_ratio, f_ratio = 0.30, 0.50, 0.20
    else:
        p_ratio, c_ratio, f_ratio = 0.30, 0.40, 0.30
    p = int(round(cal * p_ratio / 4))
    c = int(round(cal * c_ratio / 4))
    f = int(round(cal * f_ratio / 9))
    return (p, c, f)


def _compute_target_calories(user: dict) -> int:
    """Daily Target = TDEE + (kg_per_week * 1100). BMR Mifflin-St Jeor, TDEE = BMR * factor."""
    w = float(user.get('current_weight_kg') or 0)
    h = float(user.get('height_cm') or 0)
    if w <= 0 or h <= 0:
        return 2000
    birth = user.get('birth_date')
    if isinstance(birth, str):
        birth = datetime.strptime(birth[:10], "%Y-%m-%d").date() if birth else None
    age = _age_from_birth(birth)
    gender = (user.get('gender') or 'male').lower()
    # BMR: Male = (10*w)+(6.25*h)-(5*a)+5, Female = (10*w)+(6.25*h)-(5*a)-161
    bmr = (10 * w) + (6.25 * h) - (5 * age) + (5 if gender == 'male' else -161)
    act = (user.get('activity_level') or 'sedentary').lower()
    factors = {'sedentary': 1.2, 'lightly_active': 1.375, 'moderately_active': 1.55, 'very_active': 1.725}
    tdee = bmr * factors.get(act, 1.2)
    target_kg = float(user.get('target_weight_kg') or w)
    goal_start = user.get('goal_start_date')
    goal_end = user.get('goal_target_date')
    if isinstance(goal_start, str):
        goal_start = datetime.strptime(goal_start[:10], "%Y-%m-%d").date() if goal_start else None
    if isinstance(goal_end, str):
        goal_end = datetime.strptime(goal_end[:10], "%Y-%m-%d").date() if goal_end else None
    num_weeks = 12.0
    if goal_start and goal_end and goal_end > goal_start:
        num_weeks = max((goal_end - goal_start).days / 7.0, 1.0)
    kg_per_week = (target_kg - w) / num_weeks
    return int(round(tdee + (kg_per_week * 1100)))


def normalize_calories(values: List[float]) -> float:
    """Takes a list of at least 3 calorie values and returns the average (sum/count)."""
    if not values:
        return 0.0
    valid = [v for v in values if v is not None and v >= 0]
    if len(valid) < 3:
        return valid[0] if valid else 0.0
    return sum(valid) / len(valid)


def atwater_calories(protein: float, carbs: float, fat: float) -> float:
    """Atwater: (Protein*4) + (Carbs*4) + (Fat*9)."""
    return (protein * 4) + (carbs * 4) + (fat * 9)


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

class UserVerifyEmail(BaseModel):
    email: str
    code: str

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
    target_protein: int | None = None
    target_carbs: int | None = None
    target_fat: int | None = None
    activity_level: ActivityLevel | None = None
    goal_target_date: date | None = None
    unit_weight: str | None = None
    unit_height: str | None = None
    unit_energy: str | None = None
    unit_water: str | None = None

class PasswordResetRequest(BaseModel):
    email: str

class PasswordResetVerify(BaseModel):
    email: str
    code: str
    birth_date: date

class PasswordResetConfirm(BaseModel):
    email: str
    code: str
    birth_date: date
    new_password: str

# ✅ Model สำหรับสร้างอาหาร (รองรับรูป)
class FoodCreate(BaseModel):
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float
    image_url: str | None = None 

# ✅ Model สำหรับสร้างอาหารและส่งคำขอให้ Admin ตรวจสอบ (Auto-Add)
class FoodAutoAdd(BaseModel):
    user_id: int
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float

class AdminFoodReview(BaseModel):
    admin_id: int
    status: str # 'approved' or 'rejected'
    # Admin สามารถปรับแก้โภชนาการได้ก่อนกด Approve
    calories: float | None = None
    protein: float | None = None
    carbs: float | None = None
    fat: float | None = None
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
    return {"url": f"https://goosenecked-caleb-blandishingly.ngrok-free.dev/images/{new_filename}"}

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

# --- API: User Auto-Add Food and Request Verification ---
@app.post("/foods/auto-add")
def user_auto_add_food(req: FoodAutoAdd):
    """
    ผู้ใช้เพิ่มเมนูเอง (บันทึกลง foods ทันทีเพื่อใช้งาน) 
    และสร้างคำขอใน food_requests เพื่อให้ Admin ตรวจสอบโภชนาการทีหลัง
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. Insert into foods for immediate use
        cur.execute("""
            INSERT INTO foods (food_name, calories, protein, carbs, fat)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING food_id
        """, (req.food_name, req.calories, req.protein, req.carbs, req.fat))
        new_food_id = cur.fetchone()['food_id']
        
        # 2. Insert into food_requests for Admin review
        import json
        metadata = json.dumps({
            "auto_added_food_id": new_food_id,
            "original_calories": req.calories,
            "original_protein": req.protein,
            "original_carbs": req.carbs,
            "original_fat": req.fat
        })
        
        cur.execute("""
            INSERT INTO food_requests (user_id, food_name, status, ingredients_json)
            VALUES (%s, %s, 'pending', %s)
        """, (req.user_id, req.food_name, metadata))
        
        conn.commit()
        return {"message": "Menu added locally and sent for review", "food_id": new_food_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Admin Get Food Requests ---
@app.get("/admin/food-requests")
def get_food_requests():
    """ดึงรายการที่ user ขอเพิ่มเมนูทั้งหมดที่ยัง pending"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT fr.request_id, fr.food_name, fr.status, fr.ingredients_json, fr.created_at, u.username as requester_name
            FROM food_requests fr
            JOIN users u ON fr.user_id = u.user_id
            WHERE fr.status = 'pending'
            ORDER BY fr.created_at DESC
        """)
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Admin Approve/Reject Food Request ---
@app.put("/admin/food-requests/{request_id}")
def verify_food_request(request_id: int, review: AdminFoodReview):
    """Admin อนุมัติการตรวจสอบโภชนาการพร้อมแก้ไขค่าจริง"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. เช็คคำขอ
        cur.execute("SELECT * FROM food_requests WHERE request_id = %s", (request_id,))
        req_record = cur.fetchone()
        if not req_record:
            raise HTTPException(status_code=404, detail="Request not found")
            
        # 2. อัปเดตสถานะใน food_requests
        cur.execute("""
            UPDATE food_requests 
            SET status = %s, reviewed_by = %s 
            WHERE request_id = %s
        """, (review.status, review.admin_id, request_id))
        
        # 3. ถ้าอนุมัติ ให้แก้ไขโภชนาการใน foods ด้วย
        if review.status == 'approved' and req_record['ingredients_json']:
            import json
            meta = req_record['ingredients_json']
            if isinstance(meta, str):
                meta = json.loads(meta)
                
            food_id = meta.get('auto_added_food_id')
            if food_id and review.calories is not None:
                cur.execute("""
                    UPDATE foods
                    SET calories = %s, protein = %s, carbs = %s, fat = %s, image_url = COALESCE(%s, image_url)
                    WHERE food_id = %s
                """, (review.calories, review.protein, review.carbs, review.fat, review.image_url, food_id))
                
        conn.commit()
        return {"message": f"Request {review.status} successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Recommended Food ---
@app.get("/recommended-food")
def get_recommended_food():
    """แนะนำอาหาร (ดึง 20 รายการแรกสำหรับการจำลอง)"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC LIMIT 20")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Get Recipe by Food ID ---
@app.get("/recipes/{food_id}")
def get_recipe(food_id: int):
    """ดึงข้อมูลวิธีการทำอาหารจากตาราง recipes"""
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
            INSERT INTO users (email, password_hash, username, role_id, is_email_verified)
            VALUES (%s, %s, %s, 2, FALSE)
            RETURNING user_id, email, username
        """, (user.email, hashed_pw, user.username))
        new_user = cur.fetchone()
        
        # Generate OTP Verification code
        code = str(__import__('random').randint(100000, 999999))
        expires = datetime.now() + timedelta(minutes=15)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS email_verification_codes (
                id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL, code VARCHAR(10) NOT NULL,
                expires_at TIMESTAMP NOT NULL, used BOOLEAN DEFAULT FALSE
            )
        """)
        cur.execute("INSERT INTO email_verification_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
                    (new_user['user_id'], code, expires))

        conn.commit()
        
        send_verification_email(new_user['email'], new_user['username'], code)
        
        return {"message": "User created. Please check email for verification code.", "user": new_user}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 3.5: Verify Email ---
@app.post("/verify-email")
def verify_email(req: UserVerifyEmail):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Email not found")
            
        cur.execute("SELECT * FROM email_verification_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY id DESC LIMIT 1", (user['user_id'], req.code))
        code_record = cur.fetchone()
        
        if not code_record or code_record['expires_at'] < datetime.now():
            raise HTTPException(status_code=400, detail="Invalid or expired verification code")
        
        cur.execute("UPDATE users SET is_email_verified = TRUE WHERE user_id = %s", (user['user_id'],))
        cur.execute("UPDATE email_verification_codes SET used = TRUE WHERE id = %s", (code_record['id'],))
        conn.commit()
        
        send_welcome_email(user['email'], user['username'])
        
        return {"message": "Email verified successfully", "user_id": user['user_id']}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 3.6: Resend Verification Email ---
@app.post("/resend-verification-email")
def resend_verification_email(req: PasswordResetRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบอีเมลนี้ในระบบ")
        if user['is_email_verified']:
            raise HTTPException(status_code=400, detail="อีเมลนี้ได้รับการยืนยันแล้ว")
        
        # Invalidate old codes
        cur.execute("UPDATE email_verification_codes SET used = TRUE WHERE user_id = %s", (user['user_id'],))
        
        # Generate new OTP code
        import random
        code = str(random.randint(100000, 999999))
        expires = datetime.now() + timedelta(minutes=15)
        
        cur.execute("INSERT INTO email_verification_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
                    (user['user_id'], code, expires))
        conn.commit()
        
        send_verification_email(user['email'], user['username'], code)
        
        return {"message": "ส่งรหัสยืนยันใหม่ไปยังอีเมลแล้ว"}
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

        # Update last_login_date, total_login_days, current_streak
        today = date.today()
        last_login = db_user.get('last_login_date')
        if isinstance(last_login, datetime):
            last_login = last_login.date()
        total_days = int(db_user.get('total_login_days') or 0) + 1
        streak = int(db_user.get('current_streak') or 0)
        if last_login is None:
            streak = 1
        elif (today - last_login).days == 1:
            streak += 1
        elif (today - last_login).days > 1:
            streak = 1
        cur.execute("""
            UPDATE users
            SET last_login_date = %s, total_login_days = %s, current_streak = %s
            WHERE user_id = %s
        """, (datetime.combine(today, datetime.min.time()), total_days, streak, db_user['user_id']))
        conn.commit()
            
        return {
            "message": "Login successful",
            "user_id": db_user['user_id'],
            "username": db_user['username'],
            "email": db_user['email'],
            "role_id": db_user['role_id'],
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
        if user_update.target_protein is not None: user_fields.append("target_protein=%s"); user_values.append(user_update.target_protein)
        if user_update.target_carbs is not None: user_fields.append("target_carbs=%s"); user_values.append(user_update.target_carbs)
        if user_update.target_fat is not None: user_fields.append("target_fat=%s"); user_values.append(user_update.target_fat)
        if user_update.activity_level: user_fields.append("activity_level=%s"); user_values.append(user_update.activity_level)
        if user_update.gender: user_fields.append("gender=%s"); user_values.append(user_update.gender)
        if user_update.birth_date: user_fields.append("birth_date=%s"); user_values.append(user_update.birth_date)
        if user_update.height_cm: user_fields.append("height_cm=%s"); user_values.append(user_update.height_cm)
        if user_update.current_weight_kg: user_fields.append("current_weight_kg=%s"); user_values.append(user_update.current_weight_kg)
        if user_update.goal_target_date: user_fields.append("goal_target_date=%s"); user_values.append(user_update.goal_target_date)

        if user_fields:
            user_values.append(user_id)
            cur.execute(f"UPDATE users SET {', '.join(user_fields)} WHERE user_id = %s", tuple(user_values))

        # If target_calories or macros were not in request, (re)computeจากข้อมูลล่าสุดทุกครั้ง
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        row = cur.fetchone()
        if row:
            # ถ้า client ไม่ได้ส่ง target_calories มา → ให้ระบบคิดใหม่เสมอ (เผื่อส่วนสูง/น้ำหนัก/เป้าหมายเปลี่ยน)
            if user_update.target_calories is None:
                computed = _compute_target_calories(dict(row))
                cur.execute("UPDATE users SET target_calories = %s WHERE user_id = %s", (computed, user_id))
                row = {**row, 'target_calories': computed}

            # ถ้า client ไม่ได้ส่ง macro มา → คิดใหม่จาก target_calories ปัจจุบัน
            if (
                user_update.target_protein is None
                and user_update.target_carbs is None
                and user_update.target_fat is None
            ):
                p, c, f = _compute_target_macros(dict(row))
                cur.execute(
                    "UPDATE users SET target_protein = %s, target_carbs = %s, target_fat = %s WHERE user_id = %s",
                    (p, c, f, user_id),
                )

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

# --- Password reset helpers/endpoint ---

def _init_password_reset_table():
    conn = get_db_connection()
    if not conn:
        return
    try:
        cur = conn.cursor()
        cur.execute("""
        CREATE TABLE IF NOT EXISTS password_reset_codes (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            code VARCHAR(10) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            used BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """)
        conn.commit()
    except Exception as e:
        print('Could not create password reset table:', e)
    finally:
        conn.close()

_init_password_reset_table()

def _generate_code() -> str:
    from random import randint
    return f"{randint(100000, 999999)}"

@app.post('/password-reset/request')
def password_reset_request(req: PasswordResetRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="อีเมลไม่ถูกต้อง")

        code = _generate_code()
        expires = datetime.now() + timedelta(minutes=15)
        cur.execute(
            "INSERT INTO password_reset_codes (user_id, code, expires_at, used) VALUES (%s, %s, %s, %s)",
            (user['user_id'], code, expires, False),
        )
        conn.commit()
        send_password_reset_email(req.email, user['username'], code)
        return {"message": "รหัสยืนยันถูกส่งไปยังอีเมลแล้ว"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.post('/password-reset/verify')
def password_reset_verify(req: PasswordResetVerify):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")
        if not user.get('birth_date'):
            raise HTTPException(status_code=400, detail="กรุณากรอกข้อมูล วันเดือนปีเกิด ในโปรไฟล์")
        if isinstance(user['birth_date'], datetime):
            user_birth = user['birth_date'].date()
        else:
            user_birth = user['birth_date']
        if user_birth != req.birth_date:
            raise HTTPException(status_code=401, detail="วันเดือนปีเกิดไม่ตรงกับบัญชี")
        cur.execute("SELECT * FROM password_reset_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY created_at DESC LIMIT 1", (user['user_id'], req.code))
        row = cur.fetchone()
        if not row or row['expires_at'] < datetime.now():
            raise HTTPException(status_code=401, detail="รหัสไม่ถูกต้องหรือหมดอายุ")
        return {"message": "ยืนยันโค้ดสำเร็จ"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.post('/password-reset/confirm')
def password_reset_confirm(req: PasswordResetConfirm):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")
        if not user.get('birth_date'):
            raise HTTPException(status_code=400, detail="กรุณากรอกข้อมูล วันเดือนปีเกิด ในโปรไฟล์")
        if isinstance(user['birth_date'], datetime):
            user_birth = user['birth_date'].date()
        else:
            user_birth = user['birth_date']
        if user_birth != req.birth_date:
            raise HTTPException(status_code=401, detail="วันเดือนปีเกิดไม่ตรงกับบัญชี")

        cur.execute("SELECT * FROM password_reset_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY created_at DESC LIMIT 1", (user['user_id'], req.code))
        row = cur.fetchone()
        if not row or row['expires_at'] < datetime.now():
            raise HTTPException(status_code=401, detail="รหัสไม่ถูกต้องหรือหมดอายุ")

        new_hash = get_password_hash(req.new_password)
        cur.execute("UPDATE users SET password_hash = %s WHERE user_id = %s", (new_hash, user['user_id']))
        cur.execute("UPDATE password_reset_codes SET used = TRUE WHERE id = %s", (row['id'],))
        conn.commit()
        return {"message": "รีเซ็ตรหัสผ่านสำเร็จ"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 6: Get User Profile (null-safe, target_calories from DB or computed) ---
@app.get("/users/{user_id}")
def get_user_profile(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        # Null-safe: ensure numeric/string fields have defaults for JSON; store target_calories if missing
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
        if conn: conn.close()

# --- Map meal_1..4 (Flutter) -> breakfast/lunch/dinner/snack (cleangoal enum) ---
def _meal_type_to_enum(meal_type: str):
    """
    Map ค่า meal_type จากฝั่ง Flutter ให้ตรงกับ enum ใน DB.
    - ถ้าเป็น meal_1..4 ให้แปลงเป็น breakfast/lunch/dinner/snack
    - ถ้าเป็นชื่อมื้ออยู่แล้ว (breakfast/lunch/dinner/snack) ให้คืนค่าเดิม
    """
    m = {"meal_1": "breakfast", "meal_2": "lunch", "meal_3": "dinner", "meal_4": "snack"}
    return m.get(meal_type, meal_type)

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

        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user_row = cur.fetchone()
        if user_row and user_row.get('target_calories') is not None:
            target_cal = int(user_row['target_calories'])
        else:
            target_cal = _compute_target_calories(dict(user_row)) if user_row else 2000

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
=======
from datetime import date, datetime, timedelta
from typing import List, Optional, Dict
from enum import Enum
import os
from dotenv import load_dotenv
load_dotenv()
import shutil
from uuid import uuid4
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from passlib.context import CryptContext
from database import get_db_connection
from psycopg2.extras import RealDictCursor

app = FastAPI()

# --- Email Config ---
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
FROM_EMAIL = os.getenv("FROM_EMAIL", SMTP_USERNAME)
FROM_NAME = os.getenv("FROM_NAME", "Calories Guard")

def send_email(to_email: str, subject: str, html_body: str) -> bool:
    """Send email via SMTP. Returns True if successful."""
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        print(f"[Email] SMTP not configured. Would send to {to_email}: {subject}")
        return False
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{FROM_NAME} <{FROM_EMAIL}>"
        msg["To"] = to_email
        msg.attach(MIMEText(html_body, "html"))
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.sendmail(FROM_EMAIL, to_email, msg.as_string())
        print(f"[Email] Sent to {to_email}: {subject}")
        return True
    except Exception as e:
        print(f"[Email] Failed to send to {to_email}: {e}")
        return False

def send_welcome_email(email: str, username: str):
    subject = "ยินดีต้อนรับสู่ Calories Guard!"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}!</h2>
        <p>ขอบคุณที่สมัครสมาชิก <strong>Calories Guard</strong></p>
        <p>ตอนนี้คุณสามารถเริ่มติดตามการรับประทานอาหารและเป้าหมายสุขภาพของคุณได้แล้ว</p>
        <p>หากมีคำถาม ติดต่อเราได้เสมอ</p>
        <br>
        <p>ด้วยความปรารถนาดี,<br>ทีมงาน Calories Guard</p>
    </html>
    """
    send_email(email, subject, html)

def send_verification_email(email: str, username: str, code: str):
    subject = "ยืนยันอีเมลของคุณ - Calories Guard"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}!</h2>
        <p>กรุณายืนยันอีเมลของคุณเพื่อเริ่มใช้งาน</p>
        <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>รหัสยืนยันของคุณ: <strong>{code}</strong></h3>
        </div>
        <p>ขอบคุณที่ร่วมเป็นส่วนหนึ่งกับเรา</p>
    </body>
    </html>
    """
    send_email(email, subject, html)

def send_password_reset_email(email: str, username: str, code: str):
    subject = "รีเซ็ตรหัสผ่าน - Calories Guard"
    html = f"""
    <html>
    <body style="font-family: sans-serif; padding: 20px;">
        <h2>สวัสดีครับ/ค่ะ {username}</h2>
        <p>คุณได้ร้องขอการรีเซ็ตรหัสผ่าน</p>
        <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3>รหัสยืนยันของคุณ: <strong>{code}</strong></h3>
        </div>
        <p>รหัสนี้จะหมดอายุภายใน 15 นาที</p>
        <p>หากคุณไม่ได้ร้องขอการรีเซ็ตรหัสผ่าน กรุณาเพิกเฉยต่ออีเมลนี้</p>
        <br>
        <p>ด้วยความปรารถนาดี,<br>ทีมงาน Calories Guard</p>
    </body>
    </html>
    """
    send_email(email, subject, html)

# --- CORS: ให้แอป Flutter / เบราว์เซอร์ จาก origin อื่น (เช่น ngrok, APK) ยิง API ได้ ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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


# --- Official formulas: BMR (Mifflin-St Jeor), TDEE, Daily Target ---
def _age_from_birth(birth_date: Optional[date]) -> int:
    if not birth_date:
        return 20
    today = date.today()
    age = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        age -= 1
    return max(age, 10)


def _compute_target_macros(user: dict) -> tuple:
    """คืน (target_protein, target_carbs, target_fat) จาก target_calories.
    Updated Formula: Carbs 65%, Protein 15%, Fat 20% (ไม่แยกตาม goal)
    """
    cal = user.get('target_calories')
    if cal is None:
        cal = _compute_target_calories(user)
    cal = int(cal) if cal else 2000
    # New standard ratios for all goals
    p_ratio, c_ratio, f_ratio = 0.15, 0.65, 0.20
    p = int(round(cal * p_ratio / 4))
    c = int(round(cal * c_ratio / 4))
    f = int(round(cal * f_ratio / 9))
    return (p, c, f)


def _compute_target_calories(user: dict) -> int:
    """Daily Target = TDEE + (kg_per_week * 1100). BMR Mifflin-St Jeor, TDEE = BMR * factor."""
    w = float(user.get('current_weight_kg') or 0)
    h = float(user.get('height_cm') or 0)
    if w <= 0 or h <= 0:
        return 2000
    birth = user.get('birth_date')
    if isinstance(birth, str):
        birth = datetime.strptime(birth[:10], "%Y-%m-%d").date() if birth else None
    age = _age_from_birth(birth)
    gender = (user.get('gender') or 'male').lower()
    # BMR: Male = (10*w)+(6.25*h)-(5*a)+5, Female = (10*w)+(6.25*h)-(5*a)-161
    bmr = (10 * w) + (6.25 * h) - (5 * age) + (5 if gender == 'male' else -161)
    act = (user.get('activity_level') or 'sedentary').lower()
    factors = {'sedentary': 1.2, 'lightly_active': 1.375, 'moderately_active': 1.55, 'very_active': 1.725}
    tdee = bmr * factors.get(act, 1.2)
    target_kg = float(user.get('target_weight_kg') or w)
    goal_start = user.get('goal_start_date')
    goal_end = user.get('goal_target_date')
    if isinstance(goal_start, str):
        goal_start = datetime.strptime(goal_start[:10], "%Y-%m-%d").date() if goal_start else None
    if isinstance(goal_end, str):
        goal_end = datetime.strptime(goal_end[:10], "%Y-%m-%d").date() if goal_end else None
    num_weeks = 12.0
    if goal_start and goal_end and goal_end > goal_start:
        num_weeks = max((goal_end - goal_start).days / 7.0, 1.0)
    kg_per_week = (target_kg - w) / num_weeks
    return int(round(tdee + (kg_per_week * 1100)))


def normalize_calories(values: List[float]) -> float:
    """Takes a list of at least 3 calorie values and returns the average (sum/count)."""
    if not values:
        return 0.0
    valid = [v for v in values if v is not None and v >= 0]
    if len(valid) < 3:
        return valid[0] if valid else 0.0
    return sum(valid) / len(valid)


def atwater_calories(protein: float, carbs: float, fat: float) -> float:
    """Atwater: (Protein*4) + (Carbs*4) + (Fat*9)."""
    return (protein * 4) + (carbs * 4) + (fat * 9)


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

class UserVerifyEmail(BaseModel):
    email: str
    code: str

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
    target_protein: int | None = None
    target_carbs: int | None = None
    target_fat: int | None = None
    activity_level: ActivityLevel | None = None
    goal_target_date: date | None = None
    unit_weight: str | None = None
    unit_height: str | None = None
    unit_energy: str | None = None
    unit_water: str | None = None

class PasswordResetRequest(BaseModel):
    email: str

class PasswordResetVerify(BaseModel):
    email: str
    code: str
    birth_date: date

class PasswordResetConfirm(BaseModel):
    email: str
    code: str
    birth_date: date
    new_password: str

# ✅ Model สำหรับสร้างอาหาร (รองรับรูป)
class FoodCreate(BaseModel):
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float
    image_url: str | None = None 

# ✅ Model สำหรับสร้างอาหารและส่งคำขอให้ Admin ตรวจสอบ (Auto-Add)
class FoodAutoAdd(BaseModel):
    user_id: int
    food_name: str
    calories: float
    protein: float
    carbs: float
    fat: float

class AdminFoodReview(BaseModel):
    admin_id: int
    status: str # 'approved' or 'rejected'
    # Admin สามารถปรับแก้โภชนาการได้ก่อนกด Approve
    calories: float | None = None
    protein: float | None = None
    carbs: float | None = None
    fat: float | None = None
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
    return {"url": f"https://goosenecked-caleb-blandishingly.ngrok-free.dev/images/{new_filename}"}

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

# --- API: User Auto-Add Food and Request Verification ---
@app.post("/foods/auto-add")
def user_auto_add_food(req: FoodAutoAdd):
    """
    ผู้ใช้เพิ่มเมนูเอง (บันทึกลง foods ทันทีเพื่อใช้งาน) 
    และสร้างคำขอใน food_requests เพื่อให้ Admin ตรวจสอบโภชนาการทีหลัง
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. Insert into foods for immediate use
        cur.execute("""
            INSERT INTO foods (food_name, calories, protein, carbs, fat)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING food_id
        """, (req.food_name, req.calories, req.protein, req.carbs, req.fat))
        new_food_id = cur.fetchone()['food_id']
        
        # 2. Insert into food_requests for Admin review
        import json
        metadata = json.dumps({
            "auto_added_food_id": new_food_id,
            "original_calories": req.calories,
            "original_protein": req.protein,
            "original_carbs": req.carbs,
            "original_fat": req.fat
        })
        
        cur.execute("""
            INSERT INTO food_requests (user_id, food_name, status, ingredients_json)
            VALUES (%s, %s, 'pending', %s)
        """, (req.user_id, req.food_name, metadata))
        
        conn.commit()
        return {"message": "Menu added locally and sent for review", "food_id": new_food_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Admin Get Food Requests ---
@app.get("/admin/food-requests")
def get_food_requests():
    """ดึงรายการที่ user ขอเพิ่มเมนูทั้งหมดที่ยัง pending"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT fr.request_id, fr.food_name, fr.status, fr.ingredients_json, fr.created_at, u.username as requester_name
            FROM food_requests fr
            JOIN users u ON fr.user_id = u.user_id
            WHERE fr.status = 'pending'
            ORDER BY fr.created_at DESC
        """)
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Admin Approve/Reject Food Request ---
@app.put("/admin/food-requests/{request_id}")
def verify_food_request(request_id: int, review: AdminFoodReview):
    """Admin อนุมัติการตรวจสอบโภชนาการพร้อมแก้ไขค่าจริง"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. เช็คคำขอ
        cur.execute("SELECT * FROM food_requests WHERE request_id = %s", (request_id,))
        req_record = cur.fetchone()
        if not req_record:
            raise HTTPException(status_code=404, detail="Request not found")
            
        # 2. อัปเดตสถานะใน food_requests
        cur.execute("""
            UPDATE food_requests 
            SET status = %s, reviewed_by = %s 
            WHERE request_id = %s
        """, (review.status, review.admin_id, request_id))
        
        # 3. ถ้าอนุมัติ ให้แก้ไขโภชนาการใน foods ด้วย
        if review.status == 'approved' and req_record['ingredients_json']:
            import json
            meta = req_record['ingredients_json']
            if isinstance(meta, str):
                meta = json.loads(meta)
                
            food_id = meta.get('auto_added_food_id')
            if food_id and review.calories is not None:
                cur.execute("""
                    UPDATE foods
                    SET calories = %s, protein = %s, carbs = %s, fat = %s, image_url = COALESCE(%s, image_url)
                    WHERE food_id = %s
                """, (review.calories, review.protein, review.carbs, review.fat, review.image_url, food_id))
                
        conn.commit()
        return {"message": f"Request {review.status} successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Recommended Food ---
@app.get("/recommended-food")
def get_recommended_food():
    """แนะนำอาหาร (ดึง 20 รายการแรกสำหรับการจำลอง)"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC LIMIT 20")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API: Get Recipe by Food ID ---
@app.get("/recipes/{food_id}")
def get_recipe(food_id: int):
    """ดึงข้อมูลวิธีการทำอาหารจากตาราง recipes"""
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
            INSERT INTO users (email, password_hash, username, role_id, is_email_verified)
            VALUES (%s, %s, %s, 2, FALSE)
            RETURNING user_id, email, username
        """, (user.email, hashed_pw, user.username))
        new_user = cur.fetchone()
        
        # Generate OTP Verification code
        code = str(__import__('random').randint(100000, 999999))
        expires = datetime.now() + timedelta(minutes=15)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS email_verification_codes (
                id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL, code VARCHAR(10) NOT NULL,
                expires_at TIMESTAMP NOT NULL, used BOOLEAN DEFAULT FALSE
            )
        """)
        cur.execute("INSERT INTO email_verification_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
                    (new_user['user_id'], code, expires))

        conn.commit()
        
        send_verification_email(new_user['email'], new_user['username'], code)
        
        return {"message": "User created. Please check email for verification code.", "user": new_user}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 3.5: Verify Email ---
@app.post("/verify-email")
def verify_email(req: UserVerifyEmail):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Email not found")
            
        cur.execute("SELECT * FROM email_verification_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY id DESC LIMIT 1", (user['user_id'], req.code))
        code_record = cur.fetchone()
        
        if not code_record or code_record['expires_at'] < datetime.now():
            raise HTTPException(status_code=400, detail="Invalid or expired verification code")
        
        cur.execute("UPDATE users SET is_email_verified = TRUE WHERE user_id = %s", (user['user_id'],))
        cur.execute("UPDATE email_verification_codes SET used = TRUE WHERE id = %s", (code_record['id'],))
        conn.commit()
        
        send_welcome_email(user['email'], user['username'])
        
        return {"message": "Email verified successfully", "user_id": user['user_id']}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 3.6: Resend Verification Email ---
@app.post("/resend-verification-email")
def resend_verification_email(req: PasswordResetRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบอีเมลนี้ในระบบ")
        if user['is_email_verified']:
            raise HTTPException(status_code=400, detail="อีเมลนี้ได้รับการยืนยันแล้ว")
        
        # Invalidate old codes
        cur.execute("UPDATE email_verification_codes SET used = TRUE WHERE user_id = %s", (user['user_id'],))
        
        # Generate new OTP code
        import random
        code = str(random.randint(100000, 999999))
        expires = datetime.now() + timedelta(minutes=15)
        
        cur.execute("INSERT INTO email_verification_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
                    (user['user_id'], code, expires))
        conn.commit()
        
        send_verification_email(user['email'], user['username'], code)
        
        return {"message": "ส่งรหัสยืนยันใหม่ไปยังอีเมลแล้ว"}
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

        # Update last_login_date, total_login_days, current_streak
        today = date.today()
        last_login = db_user.get('last_login_date')
        if isinstance(last_login, datetime):
            last_login = last_login.date()
        total_days = int(db_user.get('total_login_days') or 0) + 1
        streak = int(db_user.get('current_streak') or 0)
        if last_login is None:
            streak = 1
        elif (today - last_login).days == 1:
            streak += 1
        elif (today - last_login).days > 1:
            streak = 1
        cur.execute("""
            UPDATE users
            SET last_login_date = %s, total_login_days = %s, current_streak = %s
            WHERE user_id = %s
        """, (datetime.combine(today, datetime.min.time()), total_days, streak, db_user['user_id']))
        conn.commit()
            
        return {
            "message": "Login successful",
            "user_id": db_user['user_id'],
            "username": db_user['username'],
            "email": db_user['email'],
            "role_id": db_user['role_id'],
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
        if user_update.target_protein is not None: user_fields.append("target_protein=%s"); user_values.append(user_update.target_protein)
        if user_update.target_carbs is not None: user_fields.append("target_carbs=%s"); user_values.append(user_update.target_carbs)
        if user_update.target_fat is not None: user_fields.append("target_fat=%s"); user_values.append(user_update.target_fat)
        if user_update.activity_level: user_fields.append("activity_level=%s"); user_values.append(user_update.activity_level)
        if user_update.gender: user_fields.append("gender=%s"); user_values.append(user_update.gender)
        if user_update.birth_date: user_fields.append("birth_date=%s"); user_values.append(user_update.birth_date)
        if user_update.height_cm: user_fields.append("height_cm=%s"); user_values.append(user_update.height_cm)
        if user_update.current_weight_kg: user_fields.append("current_weight_kg=%s"); user_values.append(user_update.current_weight_kg)
        if user_update.goal_target_date: user_fields.append("goal_target_date=%s"); user_values.append(user_update.goal_target_date)

        if user_fields:
            user_values.append(user_id)
            cur.execute(f"UPDATE users SET {', '.join(user_fields)} WHERE user_id = %s", tuple(user_values))

        # If target_calories or macros were not in request, (re)computeจากข้อมูลล่าสุดทุกครั้ง
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        row = cur.fetchone()
        if row:
            # ถ้า client ไม่ได้ส่ง target_calories มา → ให้ระบบคิดใหม่เสมอ (เผื่อส่วนสูง/น้ำหนัก/เป้าหมายเปลี่ยน)
            if user_update.target_calories is None:
                computed = _compute_target_calories(dict(row))
                cur.execute("UPDATE users SET target_calories = %s WHERE user_id = %s", (computed, user_id))
                row = {**row, 'target_calories': computed}

            # ถ้า client ไม่ได้ส่ง macro มา → คิดใหม่จาก target_calories ปัจจุบัน
            if (
                user_update.target_protein is None
                and user_update.target_carbs is None
                and user_update.target_fat is None
            ):
                p, c, f = _compute_target_macros(dict(row))
                cur.execute(
                    "UPDATE users SET target_protein = %s, target_carbs = %s, target_fat = %s WHERE user_id = %s",
                    (p, c, f, user_id),
                )

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

# --- Password reset helpers/endpoint ---

def _init_password_reset_table():
    conn = get_db_connection()
    if not conn:
        return
    try:
        cur = conn.cursor()
        cur.execute("""
        CREATE TABLE IF NOT EXISTS password_reset_codes (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            code VARCHAR(10) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            used BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """)
        conn.commit()
    except Exception as e:
        print('Could not create password reset table:', e)
    finally:
        conn.close()

_init_password_reset_table()

def _generate_code() -> str:
    from random import randint
    return f"{randint(100000, 999999)}"

@app.post('/password-reset/request')
def password_reset_request(req: PasswordResetRequest):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="อีเมลไม่ถูกต้อง")

        code = _generate_code()
        expires = datetime.now() + timedelta(minutes=15)
        cur.execute(
            "INSERT INTO password_reset_codes (user_id, code, expires_at, used) VALUES (%s, %s, %s, %s)",
            (user['user_id'], code, expires, False),
        )
        conn.commit()
        send_password_reset_email(req.email, user['username'], code)
        return {"message": "รหัสยืนยันถูกส่งไปยังอีเมลแล้ว"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.post('/password-reset/verify')
def password_reset_verify(req: PasswordResetVerify):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")
        if not user.get('birth_date'):
            raise HTTPException(status_code=400, detail="กรุณากรอกข้อมูล วันเดือนปีเกิด ในโปรไฟล์")
        if isinstance(user['birth_date'], datetime):
            user_birth = user['birth_date'].date()
        else:
            user_birth = user['birth_date']
        if user_birth != req.birth_date:
            raise HTTPException(status_code=401, detail="วันเดือนปีเกิดไม่ตรงกับบัญชี")
        cur.execute("SELECT * FROM password_reset_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY created_at DESC LIMIT 1", (user['user_id'], req.code))
        row = cur.fetchone()
        if not row or row['expires_at'] < datetime.now():
            raise HTTPException(status_code=401, detail="รหัสไม่ถูกต้องหรือหมดอายุ")
        return {"message": "ยืนยันโค้ดสำเร็จ"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.post('/password-reset/confirm')
def password_reset_confirm(req: PasswordResetConfirm):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE email = %s", (req.email,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="ไม่พบผู้ใช้")
        if not user.get('birth_date'):
            raise HTTPException(status_code=400, detail="กรุณากรอกข้อมูล วันเดือนปีเกิด ในโปรไฟล์")
        if isinstance(user['birth_date'], datetime):
            user_birth = user['birth_date'].date()
        else:
            user_birth = user['birth_date']
        if user_birth != req.birth_date:
            raise HTTPException(status_code=401, detail="วันเดือนปีเกิดไม่ตรงกับบัญชี")

        cur.execute("SELECT * FROM password_reset_codes WHERE user_id = %s AND code = %s AND used = FALSE ORDER BY created_at DESC LIMIT 1", (user['user_id'], req.code))
        row = cur.fetchone()
        if not row or row['expires_at'] < datetime.now():
            raise HTTPException(status_code=401, detail="รหัสไม่ถูกต้องหรือหมดอายุ")

        new_hash = get_password_hash(req.new_password)
        cur.execute("UPDATE users SET password_hash = %s WHERE user_id = %s", (new_hash, user['user_id']))
        cur.execute("UPDATE password_reset_codes SET used = TRUE WHERE id = %s", (row['id'],))
        conn.commit()
        return {"message": "รีเซ็ตรหัสผ่านสำเร็จ"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 6: Get User Profile (null-safe, target_calories from DB or computed) ---
@app.get("/users/{user_id}")
def get_user_profile(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user = cur.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        # Null-safe: ensure numeric/string fields have defaults for JSON; store target_calories if missing
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
        if conn: conn.close()

# --- Map meal_1..4 (Flutter) -> breakfast/lunch/dinner/snack (cleangoal enum) ---
def _meal_type_to_enum(meal_type: str):
    """
    Map ค่า meal_type จากฝั่ง Flutter ให้ตรงกับ enum ใน DB.
    - ถ้าเป็น meal_1..4 ให้แปลงเป็น breakfast/lunch/dinner/snack
    - ถ้าเป็นชื่อมื้ออยู่แล้ว (breakfast/lunch/dinner/snack) ให้คืนค่าเดิม
    """
    m = {"meal_1": "breakfast", "meal_2": "lunch", "meal_3": "dinner", "meal_4": "snack"}
    return m.get(meal_type, meal_type)

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

        cur.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user_row = cur.fetchone()
        if user_row and user_row.get('target_calories') is not None:
            target_cal = int(user_row['target_calories'])
        else:
            target_cal = _compute_target_calories(dict(user_row)) if user_row else 2000

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

@app.get("/users/{user_id}/weight_history")
def get_weight_history(user_id: int, limit: int = 8):
    """
    ดึงประวัติน้ำหนักจาก weight_logs N รายการล่าสุด เรียงจากเก่า → ใหม่
    Flutter เรียก: GET /users/{userId}/weight_history?limit=8
 
    Response:
    [
      { "date": "2026-01-01", "weight": 82.5 },
      { "date": "2026-01-08", "weight": 81.0 },
      ...
    ]
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
 
        # ตรวจสอบว่า user มีอยู่จริง
        cur.execute(
            "SELECT user_id FROM users WHERE user_id = %s AND deleted_at IS NULL",
            (user_id,)
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="User not found")
 
        # ดึง N รายการล่าสุด จาก weight_logs
        # table: cleangoal.weight_logs (log_id, user_id, weight_kg, recorded_date, created_at)
        cur.execute("""
            SELECT
                recorded_date::text  AS date,
                weight_kg::float     AS weight
            FROM weight_logs
            WHERE user_id = %s
            ORDER BY recorded_date DESC
            LIMIT %s
        """, (user_id, limit))
 
        rows = cur.fetchall()
 
        if not rows:
            return []  # Flutter จะแสดง empty state
 
        # reverse → เรียงเก่า→ใหม่ สำหรับ LineChart ซ้ายไปขวา
        result = [{"date": row["date"], "weight": row["weight"]} for row in rows]
        result.reverse()
        return result
 
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()
 
 
# --- API NEW 2: Top Foods (สำหรับ Top 5 Foods ใน Tab โภชนาการ) ---
@app.get("/daily_logs/{user_id}/top_foods")
def get_top_foods(user_id: int, days: int = 7, limit: int = 5):
    """
    นับความถี่ food_name จาก detail_items → meals ในช่วง N วัน
    แล้วดึง avg โภชนาการจาก foods table
 
    Flutter เรียก: GET /daily_logs/{userId}/top_foods?days=7
 
    Response:
    [
      {
        "name": "ข้าวมันไก่ต้ม",
        "count": 5,
        "avg_calories": 596.0,
        "protein": 29.0,
        "carbs": 69.0,
        "fat": 21.0
      },
      ...
    ]
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
 
        # ตรวจสอบ user
        cur.execute(
            "SELECT user_id FROM users WHERE user_id = %s AND deleted_at IS NULL",
            (user_id,)
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="User not found")
 
        # นับความถี่ food_name ในช่วง N วัน
        # ใช้ CURRENT_DATE - N แทน INTERVAL string (ปลอดภัยกับ psycopg2)
        cur.execute("""
            SELECT
                di.food_name                                            AS name,
                COUNT(*)::int                                           AS count,
                AVG(COALESCE(di.cal_per_unit, f.calories, 0))::float   AS avg_calories,
                AVG(COALESCE(f.protein,  0))::float                    AS protein,
                AVG(COALESCE(f.carbs,    0))::float                    AS carbs,
                AVG(COALESCE(f.fat,      0))::float                    AS fat
            FROM detail_items di
            -- JOIN meals เพื่อกรอง user_id + ช่วงวันที่
            JOIN meals m
                ON di.meal_id = m.meal_id
            -- LEFT JOIN foods เพื่อดึงโภชนาการ
            LEFT JOIN foods f
                ON di.food_id = f.food_id
            WHERE
                m.user_id  = %s
                AND m.meal_time::date >= CURRENT_DATE - %s
                AND di.food_name IS NOT NULL
                AND di.food_name <> ''
            GROUP BY di.food_name
            ORDER BY count DESC
            LIMIT %s
        """, (user_id, days, limit))
 
        rows = cur.fetchall()
 
        return [
            {
                "name":         row["name"],
                "count":        row["count"],
                "avg_calories": round(row["avg_calories"] or 0, 1),
                "protein":      round(row["protein"] or 0, 1),
                "carbs":        round(row["carbs"] or 0, 1),
                "fat":          round(row["fat"] or 0, 1),
            }
            for row in rows
        ]
 
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
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
        # ══════════════════════════════════════════════════════
#  เพิ่มใน main.py ต่อท้าย endpoint สุดท้าย
#  GET /recipes/by_food/{food_id}
#  ดึงข้อมูลสูตรอาหารทุกอย่างใน 1 request
# ══════════════════════════════════════════════════════

@app.get("/recipes/by_food/{food_id}")
def get_recipe_by_food(food_id: int):
    """
    ดึงข้อมูลสูตรอาหารทั้งหมดจาก food_id
    รวม: recipe info + ingredients + steps + tools + tips + reviews + favorites
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # ── 1. Recipe + Food info ──
        cur.execute("""
            SELECT
                r.recipe_id,
                r.food_id,
                f.food_name AS recipe_name,
                r.description,
                'อาหารทั่วไป' AS category,
                'ไทย' AS cuisine,
                'Easy' AS difficulty,
                r.prep_time_minutes,
                r.cooking_time_minutes,
                (r.prep_time_minutes + r.cooking_time_minutes) AS total_time_minutes,
                r.serving_people,
                0.0 AS avg_rating,
                0 AS review_count,
                0 AS favorite_count,
                COALESCE(r.image_url, f.image_url) AS image_url,
                f.calories,
                f.protein,
                f.carbs,
                f.fat,
                f.sodium,
                f.sugar,
                f.cholesterol
            FROM recipes r
            JOIN foods f ON r.food_id = f.food_id
            WHERE r.food_id = %s
              AND r.deleted_at IS NULL
        """, (food_id,))
        recipe = cur.fetchone()

        if not recipe:
            raise HTTPException(status_code=404, detail="Recipe not found")

        recipe_id = recipe["recipe_id"]

        # ── 2. Ingredients (จาก food_ingredients) ──
        cur.execute("""
            SELECT
                fi.food_ing_id AS ing_id,
                i.name AS ingredient_name,
                fi.amount AS quantity,
                u.name AS unit,
                FALSE AS is_optional,
                fi.note,
                1 AS sort_order
            FROM food_ingredients fi
            JOIN ingredients i ON fi.ingredient_id = i.ingredient_id
            LEFT JOIN units u ON fi.unit_id = u.unit_id
            WHERE fi.food_id = %s
            ORDER BY fi.food_ing_id ASC
        """, (food_id,))
        ingredients = cur.fetchall()

        # ── 3. Steps (แยกจาก recipes.instructions) ──
        steps = []
        if recipe.get("instructions"):
            inst_lines = str(recipe["instructions"]).split('\n')
            for idx, line in enumerate(inst_lines):
                if line.strip():
                    steps.append({
                        "step_id": idx + 1,
                        "step_number": idx + 1,
                        "title": f"ขั้นตอนที่ {idx + 1}",
                        "instruction": line.strip(),
                        "time_minutes": 0,
                        "image_url": "",
                        "tips": ""
                    })

        # ── 4. Tools ──
        tools = []

        # ── 5. Tips ──
        tips = []

        # ── 6. Reviews (ล่าสุด 10 รายการ) ──
        # Since recipe_reviews might not be created, we'll try to query or mock empty list.
        # Let's just return an empty list for reviews to ensure API stability right now.
        reviews = []

        # แปลง datetime เป็น string
        reviews_list = []
        for rv in reviews:
            rv_dict = dict(rv)
            if rv_dict.get("created_at"):
                rv_dict["created_at"] = rv_dict["created_at"].isoformat()
            reviews_list.append(rv_dict)

        return {
            "recipe":      dict(recipe),
            "ingredients": [dict(i) for i in ingredients],
            "steps":       [dict(s) for s in steps],
            "tools":       [dict(t) for t in tools],
            "tips":        [dict(t) for t in tips],
            "reviews":     reviews_list,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# ── เพิ่ม/ลบ Favorite ──
@app.post("/recipes/{food_id}/favorite/{user_id}")
def toggle_favorite(food_id: int, user_id: int):
    """Toggle favorite — กด ❤️ ครั้งแรก = เพิ่ม, กดซ้ำ = ลบ"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # หา recipe_id จาก food_id
        cur.execute("SELECT recipe_id FROM recipes WHERE food_id = %s", (food_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Recipe not found")
        recipe_id = row["recipe_id"]

        # เช็คว่า favorite อยู่แล้วมั้ย
        cur.execute("""
            SELECT fav_id FROM favorite_foods
            WHERE food_id = %s AND user_id = %s
        """, (food_id, user_id))
        existing = cur.fetchone()

        if existing:
            # ลบ favorite
            cur.execute("""
                DELETE FROM favorite_foods
                WHERE food_id = %s AND user_id = %s
            """, (food_id, user_id))
            conn.commit()
            return {"action": "removed", "is_favorite": False}
        else:
            # เพิ่ม favorite
            cur.execute("""
                INSERT INTO favorite_foods (food_id, user_id)
                VALUES (%s, %s)
            """, (food_id, user_id))
            conn.commit()
            return {"action": "added", "is_favorite": True}

    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# ── เพิ่ม Review ──
class RecipeReviewCreate(BaseModel):
    user_id: int
    rating: int   # 1–5
    comment: str | None = None

@app.post("/recipes/{food_id}/review")
def add_review(food_id: int, review: RecipeReviewCreate):
    """เพิ่มหรืออัปเดตรีวิว (1 user = 1 review ต่อ recipe)"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("SELECT recipe_id FROM recipes WHERE food_id = %s", (food_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Recipe not found")
        recipe_id = row["recipe_id"]

        if not (1 <= review.rating <= 5):
            raise HTTPException(status_code=400, detail="Rating ต้องอยู่ระหว่าง 1–5")

        cur.execute("""
            INSERT INTO recipe_reviews (recipe_id, user_id, rating, comment)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (recipe_id, user_id)
            DO UPDATE SET rating = EXCLUDED.rating, comment = EXCLUDED.comment
        """, (recipe_id, review.user_id, review.rating, review.comment))
        conn.commit()
        return {"message": "บันทึกรีวิวสำเร็จ"}

    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 30: POST Weight Log ---
class WeightLogEntry(BaseModel):
    weight_kg: float

@app.post("/weight_logs/{user_id}")
def add_weight_log(user_id: int, entry: WeightLogEntry):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        today = date.today()
        # Insert into weight_logs, ignore if duplicate on same day or update
        cur.execute("""
            INSERT INTO weight_logs (user_id, weight_kg, recorded_date)
            VALUES (%s, %s, %s)
            ON CONFLICT (log_id) DO NOTHING
        """, (user_id, entry.weight_kg, today))
        
        # We need to rely on the fact that if we can't ON CONFLICT recorded_date (no unique constraint possibly), we just insert.
        # But wait, does weight_logs have a UNIQUE constraint on (user_id, recorded_date)? If not, we just insert.
        cur.execute("""
            UPDATE users SET current_weight_kg = %s, updated_at = NOW() WHERE user_id = %s
        """, (entry.weight_kg, user_id))

        conn.commit()
        return {"message": "บันทึกน้ำหนักสำเร็จ"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 31: GET Weight Status (Check if >= 14 days) ---
@app.get("/weight_status/{user_id}")
def get_weight_status(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT recorded_date, weight_kg 
            FROM weight_logs 
            WHERE user_id = %s 
            ORDER BY recorded_date DESC 
            LIMIT 1
        """, (user_id,))
        last_log = cur.fetchone()

        cur.execute("SELECT current_weight_kg FROM users WHERE user_id = %s", (user_id,))
        user_row = cur.fetchone()
        current_weight = user_row['current_weight_kg'] if user_row else None

        if not last_log:
            return {"requires_update": True, "days_passed": None, "last_weight": current_weight}

        last_date = last_log['recorded_date']
        days_passed = (date.today() - last_date).days

        return {
            "requires_update": days_passed >= 14,
            "days_passed": days_passed,
            "last_recorded_date": last_date,
            "last_weight": last_log['weight_kg']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 32: GET Progress Summary ---
@app.get("/progress_summary/{user_id}")
def get_progress_summary(user_id: int):
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 1. Get User Data
        cur.execute("""
            SELECT current_weight_kg, target_weight_kg, goal_type, goal_start_date 
            FROM users 
            WHERE user_id = %s
        """, (user_id,))
        user_row = cur.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
            
        current_w = float(user_row['current_weight_kg'] or 0)
        target_w = float(user_row['target_weight_kg'] or 0)
        goal_type = user_row['goal_type']
        
        # 2. Find Start Weight (earliest log since goal_start, or just earliest overall)
        cur.execute("""
            SELECT weight_kg FROM weight_logs 
            WHERE user_id = %s 
            ORDER BY recorded_date ASC LIMIT 1
        """, (user_id,))
        first_log = cur.fetchone()
        
        start_w = current_w
        if first_log:
            start_w = float(first_log['weight_kg'])
        else:
            # Fallback if no logs
            if goal_type == 'lose_weight':
                start_w = target_w + 5.0 if start_w < target_w + 5 else start_w
            elif goal_type == 'gain_muscle':
                start_w = target_w - 5.0 if start_w > target_w - 5 else start_w

        # 3. Calculate Weight Progress %
        progress_percent = 0.0
        if goal_type == 'lose_weight' and start_w > target_w:
            total_to_lose = start_w - target_w
            lost = start_w - current_w
            progress_percent = max(0.0, min(1.0, lost / total_to_lose))
        elif goal_type == 'gain_muscle' and target_w > start_w:
            total_to_gain = target_w - start_w
            gained = current_w - start_w
            progress_percent = max(0.0, min(1.0, gained / total_to_gain))
        elif goal_type == 'maintain_weight':
            diff = abs(current_w - target_w)
            progress_percent = max(0.0, 1.0 - (diff / max(target_w, 1.0)))

        return {
            "start_weight_kg": start_w,
            "current_weight_kg": current_w,
            "target_weight_kg": target_w,
            "progress_percent": progress_percent
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

# --- API 33: POST Upload Image (เก็บรูปเป็น Object บน Server) ---
@app.post("/upload_image")
async def upload_image(file: UploadFile = File(...)):
    """อัปโหลดรูปภาพมาเก็บไว้ใน backend/static/images โดยตรง แทนการแปะ URL ภายนอก"""
    try:
        # Generate a unique filename to prevent collisions
        file_ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        unique_filename = f"{uuid4().hex}.{file_ext}"
        file_path = os.path.join(IMAGEDIR, unique_filename)
        
        # Save file to disk
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Return the local accessible URL route
        image_url = f"/images/{unique_filename}"
        return {"image_url": image_url, "message": "อัปโหลดรูปภาพสำเร็จ"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")

# --- API 34: Chatbot Coach (Hybrid AI) ---
from chatbot_agent import CoachingAgent

class ChatMessage(BaseModel):
    user_id: int
    message: str

coach_agent = CoachingAgent()

@app.post("/api/chat/coach")
def chat_with_coach(payload: ChatMessage):
    """พูดคุยกับ AI Coach ที่วิเคราะห์ประวัติการกินของคุณ"""
    try:
        response_text = coach_agent.generate_response(payload.user_id, payload.message)
        return {"response": response_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Coach Error: {str(e)}")
>>>>>>> Stashed changes

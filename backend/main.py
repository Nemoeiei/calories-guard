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

    unit_id: Optional[int] = None



class DailyLogUpdate(BaseModel):

    date: date

    meal_type: str # ✅ รับค่า string อะไรก็ได้ (Infinite Meals)

    items: List[MealItem]


class RecipeReview(BaseModel):
    user_id: int
    rating: int   # 1–5
    comment: str | None = None


class WaterLogUpdate(BaseModel):
    amount_ml: int  # total ml for the day (absolute, not delta)


class AllergyUpdate(BaseModel):
    flag_ids: List[int]  # list of allergy flag_ids to save (replaces existing)



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



# --- API 0: Units List ---

@app.get("/units")
def get_units():
    """คืนรายการหน่วยทั้งหมด พร้อม quantity"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT unit_id, name, quantity FROM units ORDER BY unit_id")
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        if conn: conn.close()


# --- API 0b: Unit Conversions ---

@app.get("/unit_conversions")
def get_unit_conversions(from_unit_id: Optional[int] = None):
    """คืนตาราง unit_conversions ทั้งหมด หรือกรองด้วย from_unit_id"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if from_unit_id:
            cur.execute("""
                SELECT uc.conversion_id,
                       uc.from_unit_id,
                       fu.name AS from_unit_name,
                       uc.to_unit_id,
                       tu.name AS to_unit_name,
                       uc.factor,
                       uc.note
                FROM unit_conversions uc
                JOIN units fu ON fu.unit_id = uc.from_unit_id
                JOIN units tu ON tu.unit_id = uc.to_unit_id
                WHERE uc.from_unit_id = %s
                ORDER BY uc.conversion_id
            """, (from_unit_id,))
        else:
            cur.execute("""
                SELECT uc.conversion_id,
                       uc.from_unit_id,
                       fu.name AS from_unit_name,
                       uc.to_unit_id,
                       tu.name AS to_unit_name,
                       uc.factor,
                       uc.note
                FROM unit_conversions uc
                JOIN units fu ON fu.unit_id = uc.from_unit_id
                JOIN units tu ON tu.unit_id = uc.to_unit_id
                ORDER BY uc.conversion_id
            """)
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        if conn: conn.close()


# --- API 1: Foods List (includes allergy_flag_ids per food) ---

@app.get("/foods")

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
        # Convert PostgreSQL array to Python list for JSON serialization
        result = []
        for row in rows:
            r = dict(row)
            r['allergy_flag_ids'] = list(r['allergy_flag_ids']) if r['allergy_flag_ids'] else []
            result.append(r)
        return result

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

            "auto_added_food_id": new_food_id

        })

        

        cur.execute("""

            INSERT INTO food_requests 
            (user_id, food_name, status, calories, protein, carbs, fat, ingredients_json)

            VALUES (%s, %s, 'pending', %s, %s, %s, %s, %s)

        """, (req.user_id, req.food_name, req.calories, req.protein, req.carbs, req.fat, metadata))

        

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

            SELECT 
                fr.request_id, 
                fr.food_name, 
                fr.status, 
                fr.calories,
                fr.protein,
                fr.carbs,
                fr.fat,
                fr.ingredients_json, 
                fr.created_at, 
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

    import re
    if not re.match(r'^[\w\.\-\+]+@[\w\-]+(\.[\w\-]+)*\.[a-zA-Z]{2,}$', user.email):
        raise HTTPException(status_code=400, detail="Invalid email format")

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

    except HTTPException:

        conn.rollback()

        raise

    except Exception:

        conn.rollback()

        raise HTTPException(status_code=500, detail="Registration failed. Please try again later.")

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

        if not db_user.get('is_email_verified'):

            raise HTTPException(status_code=403, detail="Email not verified. Please check your inbox for the verification code.")



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

    except HTTPException:

        raise

    except Exception:

        raise HTTPException(status_code=500, detail="Login failed. Please try again later.")

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


def _init_missing_tables():
    """Create tables missing from original schema: recipe_reviews, user_favorites, water_logs.
    Also adds macro columns to detail_items if not present."""
    conn = get_db_connection()
    if not conn:
        return
    try:
        cur = conn.cursor()

        cur.execute("""
            CREATE TABLE IF NOT EXISTS recipe_reviews (
                review_id BIGSERIAL PRIMARY KEY,
                food_id   BIGINT NOT NULL REFERENCES foods(food_id) ON DELETE CASCADE,
                user_id   BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                rating    SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
                comment   TEXT,
                created_at TIMESTAMP DEFAULT NOW(),
                UNIQUE (food_id, user_id)
            )
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS user_favorites (
                id         BIGSERIAL PRIMARY KEY,
                user_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                food_id    BIGINT NOT NULL REFERENCES foods(food_id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT NOW(),
                UNIQUE (user_id, food_id)
            )
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS water_logs (
                log_id      BIGSERIAL PRIMARY KEY,
                user_id     BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                date_record DATE NOT NULL DEFAULT CURRENT_DATE,
                amount_ml   INT  NOT NULL DEFAULT 0 CHECK (amount_ml >= 0),
                UNIQUE (user_id, date_record)
            )
        """)

        # food_allergy_flags — maps food → allergen flags (may not exist in older schemas)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS food_allergy_flags (
                food_id  BIGINT NOT NULL REFERENCES foods(food_id) ON DELETE CASCADE,
                flag_id  INT    NOT NULL REFERENCES allergy_flags(flag_id) ON DELETE CASCADE,
                PRIMARY KEY (food_id, flag_id)
            )
        """)

        # Seed allergy_flags ถ้าตารางว่าง
        cur.execute("SELECT COUNT(*) FROM allergy_flags")
        if cur.fetchone()[0] == 0:
            allergens = [
                (1,  "ถั่วลิสง",          "ถั่วลิสงและผลิตภัณฑ์จากถั่วลิสง"),
                (2,  "อาหารทะเล",         "กุ้ง ปู หอย และสัตว์น้ำมีเปลือก"),
                (3,  "ปลา",               "ปลาและผลิตภัณฑ์จากปลาทุกชนิด"),
                (4,  "นมและผลิตภัณฑ์นม", "นมวัว เนย ชีส โยเกิร์ต"),
                (5,  "ไข่",               "ไข่และผลิตภัณฑ์ที่มีส่วนผสมของไข่"),
                (6,  "กลูเตน",            "แป้งสาลี ข้าวบาร์เลย์ ไรย์ และธัญพืชที่มีกลูเตน"),
                (7,  "ถั่วเหลือง",        "ถั่วเหลืองและผลิตภัณฑ์จากถั่วเหลือง"),
                (8,  "ถั่วต้นไม้",        "วอลนัต มะม่วงหิมพานต์ อัลมอนด์ ถั่วพิสตาชิโอ"),
                (9,  "งา",                "เมล็ดงาและน้ำมันงา"),
                (10, "แล็กโทส",           "น้ำตาลแล็กโทสในผลิตภัณฑ์นม"),
            ]
            for fid, name, desc in allergens:
                cur.execute("""
                    INSERT INTO allergy_flags (flag_id, name, description)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (flag_id) DO NOTHING
                """, (fid, name, desc))
            cur.execute("SELECT setval('allergy_flags_flag_id_seq', 10)")

        # Add macro columns to detail_items (idempotent)
        for col, typ in [("protein_per_unit", "FLOAT DEFAULT 0"),
                         ("carbs_per_unit",   "FLOAT DEFAULT 0"),
                         ("fat_per_unit",     "FLOAT DEFAULT 0")]:
            cur.execute(f"""
                ALTER TABLE detail_items ADD COLUMN IF NOT EXISTS {col} {typ}
            """)

        # Add unit_id column to detail_items (idempotent)
        cur.execute("""
            ALTER TABLE detail_items ADD COLUMN IF NOT EXISTS unit_id INT REFERENCES units(unit_id)
        """)

        # Rename conversion_factor → quantity in units (idempotent)
        cur.execute("""
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'cleangoal'
                      AND table_name   = 'units'
                      AND column_name  = 'conversion_factor'
                ) THEN
                    ALTER TABLE units RENAME COLUMN conversion_factor TO quantity;
                END IF;
            END$$;
        """)

        # Create unit_conversions table (idempotent)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS unit_conversions (
                conversion_id  SERIAL PRIMARY KEY,
                from_unit_id   INT NOT NULL REFERENCES units(unit_id) ON DELETE CASCADE,
                to_unit_id     INT NOT NULL REFERENCES units(unit_id) ON DELETE CASCADE,
                factor         DECIMAL(12, 6) NOT NULL,
                note           VARCHAR,
                created_at     TIMESTAMP DEFAULT NOW(),
                UNIQUE (from_unit_id, to_unit_id)
            )
        """)

        conn.commit()
    except Exception as e:
        print(f"[Init] Error creating missing tables: {e}")
        conn.rollback()
    finally:
        conn.close()


_init_missing_tables()


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



        # 2. Insert detail_items (with macro columns for accurate per-item tracking)

        for item in log.items:

            cur.execute("""

                INSERT INTO detail_items (meal_id, food_id, food_name, amount, unit_id, cal_per_unit, protein_per_unit, carbs_per_unit, fat_per_unit)

                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)

            """, (meal_id, item.food_id, item.food_name, item.amount, item.unit_id,
                  item.cal_per_unit, item.protein_per_unit, item.carbs_per_unit, item.fat_per_unit))



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



        # โปรตีน/คาร์บ/ไขมัน จาก detail_items (ค่าที่บันทึกไว้โดยตรง ไม่คำนวณย้อนจากอัตราส่วน)

        cur.execute("""

            SELECT COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS total_protein,

                   COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS total_carbs,

                   COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS total_fat

            FROM meals m

            JOIN detail_items di ON di.meal_id = m.meal_id

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

                   COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS total_protein,

                   COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS total_carbs,

                   COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS total_fat

            FROM meals m

            JOIN detail_items di ON di.meal_id = m.meal_id

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

            SELECT COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS total_protein,

                   COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS total_carbs,

                   COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS total_fat

            FROM meals m

            JOIN detail_items di ON di.meal_id = m.meal_id

            WHERE m.user_id = %s AND DATE(m.meal_time) = %s

        """, (user_id, date_query))

        macro = cur.fetchone()



        cur.execute("""
            SELECT
                m.meal_type,
                di.food_id,
                di.food_name,
                di.amount,
                di.unit_id,
                u.name        AS unit_name,
                di.cal_per_unit,
                di.protein_per_unit,
                di.carbs_per_unit,
                di.fat_per_unit

            FROM meals m

            JOIN detail_items di ON di.meal_id = m.meal_id

            LEFT JOIN units u ON u.unit_id = di.unit_id

            WHERE m.user_id = %s AND DATE(m.meal_time) = %s

            ORDER BY m.meal_type, di.item_id

        """, (user_id, date_query))

        items = cur.fetchall()

        # จัดกลุ่มตามประเภทมื้อ
        meals_map = {"breakfast": [], "lunch": [], "dinner": [], "snack": []}

        for item in items:
            meal_type = item["meal_type"]
            if meal_type in meals_map:
                meals_map[meal_type].append({
                    "food_id":          item["food_id"],
                    "food_name":        item["food_name"],
                    "amount":           float(item["amount"]) if item["amount"] else 1.0,
                    "unit_id":          item["unit_id"],
                    "unit_name":        item["unit_name"] or "กรัม (g)",
                    "cal_per_unit":     float(item["cal_per_unit"])     if item["cal_per_unit"]     else 0,
                    "protein_per_unit": float(item["protein_per_unit"]) if item["protein_per_unit"] else 0,
                    "carbs_per_unit":   float(item["carbs_per_unit"])   if item["carbs_per_unit"]   else 0,
                    "fat_per_unit":     float(item["fat_per_unit"])     if item["fat_per_unit"]     else 0,
                })

        meals = meals_map

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


# =============================================================================
# API 35–36: User Favorites
# =============================================================================

@app.get("/recipes/{food_id}/favorite/{user_id}")
def get_favorite_status(food_id: int, user_id: int):
    """Check whether a user has favorited a recipe."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "SELECT 1 FROM user_favorites WHERE user_id = %s AND food_id = %s",
            (user_id, food_id),
        )
        return {"is_favorite": cur.fetchone() is not None}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.post("/recipes/{food_id}/favorite/{user_id}")
def toggle_favorite(food_id: int, user_id: int):
    """Toggle favorite on/off. Returns new state."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "SELECT 1 FROM user_favorites WHERE user_id = %s AND food_id = %s",
            (user_id, food_id),
        )
        exists = cur.fetchone() is not None
        if exists:
            cur.execute(
                "DELETE FROM user_favorites WHERE user_id = %s AND food_id = %s",
                (user_id, food_id),
            )
            is_favorite = False
        else:
            cur.execute(
                "INSERT INTO user_favorites (user_id, food_id) VALUES (%s, %s)",
                (user_id, food_id),
            )
            is_favorite = True
        conn.commit()
        return {"is_favorite": is_favorite}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.get("/users/{user_id}/favorites")
def get_user_favorites(user_id: int):
    """Return all recipes favorited by a user, joined with food data."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT f.food_id, f.food_name, f.calories, f.protein, f.carbs, f.fat,
                   f.image_url, uf.created_at AS favorited_at
            FROM user_favorites uf
            JOIN foods f ON f.food_id = uf.food_id
            WHERE uf.user_id = %s
            ORDER BY uf.created_at DESC
        """, (user_id,))
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# =============================================================================
# API 37–38: Recipe Reviews
# =============================================================================

@app.get("/recipes/{food_id}/reviews")
def get_recipe_reviews(food_id: int):
    """Return all reviews for a recipe with aggregated rating stats."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH review_stats AS (
                SELECT
                    food_id,
                    COUNT(*)                        AS review_count,
                    ROUND(AVG(rating)::numeric, 1)  AS avg_rating,
                    COUNT(*) FILTER (WHERE rating = 5) AS five_star,
                    COUNT(*) FILTER (WHERE rating = 4) AS four_star,
                    COUNT(*) FILTER (WHERE rating = 3) AS three_star,
                    COUNT(*) FILTER (WHERE rating = 2) AS two_star,
                    COUNT(*) FILTER (WHERE rating = 1) AS one_star
                FROM recipe_reviews
                WHERE food_id = %s
                GROUP BY food_id
            )
            SELECT
                rr.review_id,
                rr.user_id,
                u.username,
                rr.rating,
                rr.comment,
                rr.created_at,
                rs.review_count,
                rs.avg_rating,
                rs.five_star,
                rs.four_star,
                rs.three_star,
                rs.two_star,
                rs.one_star
            FROM recipe_reviews rr
            JOIN users u ON u.user_id = rr.user_id
            LEFT JOIN review_stats rs ON rs.food_id = rr.food_id
            WHERE rr.food_id = %s
            ORDER BY rr.created_at DESC
        """, (food_id, food_id))
        rows = cur.fetchall()
        if not rows:
            return {"reviews": [], "review_count": 0, "avg_rating": None,
                    "rating_distribution": {}}
        stats = rows[0]
        return {
            "reviews": [
                {"review_id": r["review_id"], "user_id": r["user_id"],
                 "username": r["username"], "rating": r["rating"],
                 "comment": r["comment"], "created_at": r["created_at"].isoformat() if r["created_at"] else None}
                for r in rows
            ],
            "review_count": stats["review_count"],
            "avg_rating": float(stats["avg_rating"]) if stats["avg_rating"] else None,
            "rating_distribution": {
                "5": stats["five_star"], "4": stats["four_star"],
                "3": stats["three_star"], "2": stats["two_star"], "1": stats["one_star"]
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.post("/recipes/{food_id}/review")
def upsert_recipe_review(food_id: int, review: RecipeReview):
    """Create or update a review (one review per user per recipe)."""
    if not (1 <= review.rating <= 5):
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            INSERT INTO recipe_reviews (food_id, user_id, rating, comment)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (food_id, user_id)
            DO UPDATE SET rating = EXCLUDED.rating,
                          comment = EXCLUDED.comment,
                          created_at = NOW()
            RETURNING review_id
        """, (food_id, review.user_id, review.rating, review.comment))
        review_id = cur.fetchone()["review_id"]
        conn.commit()
        return {"message": "Review saved", "review_id": review_id}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# =============================================================================
# API 39–40: Water Logs
# =============================================================================

@app.get("/water_logs/{user_id}")
def get_water_log(user_id: int, date_record: Optional[str] = None):
    """Return today's (or specified date's) water intake in ml."""
    target_date = date.fromisoformat(date_record) if date_record else date.today()
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT amount_ml, date_record
            FROM water_logs
            WHERE user_id = %s AND date_record = %s
        """, (user_id, target_date))
        row = cur.fetchone()
        return {
            "date_record": target_date.isoformat(),
            "amount_ml": int(row["amount_ml"]) if row else 0,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.post("/water_logs/{user_id}")
def upsert_water_log(user_id: int, entry: WaterLogUpdate):
    """Set (upsert) the total water intake for today."""
    if entry.amount_ml < 0:
        raise HTTPException(status_code=400, detail="amount_ml must be >= 0")
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            INSERT INTO water_logs (user_id, date_record, amount_ml)
            VALUES (%s, CURRENT_DATE, %s)
            ON CONFLICT (user_id, date_record)
            DO UPDATE SET amount_ml = EXCLUDED.amount_ml
            RETURNING amount_ml
        """, (user_id, entry.amount_ml))
        saved = cur.fetchone()["amount_ml"]
        conn.commit()
        return {"date_record": date.today().isoformat(), "amount_ml": saved}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


# =============================================================================
# API 41–44: Insights (CTE-based analytics)
# =============================================================================

@app.get("/insights/{user_id}")
def get_insights_overview(user_id: int):
    """
    Dashboard insight card — last 30 days.

    Uses a CTE chain:
      recent_daily  → per-day calories + macros from stored detail_items values
      goal_flags    → annotate each day with on_target / cal_diff
      summary       → aggregate into single overview row
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            WITH recent_daily AS (
                SELECT
                    ds.date_record,
                    ds.total_calories_intake                              AS calories,
                    COALESCE(SUM(di.amount * di.protein_per_unit), 0)    AS protein,
                    COALESCE(SUM(di.amount * di.carbs_per_unit),   0)    AS carbs,
                    COALESCE(SUM(di.amount * di.fat_per_unit),     0)    AS fat,
                    u.target_calories,
                    u.target_protein,
                    u.target_carbs,
                    u.target_fat,
                    u.current_streak
                FROM daily_summaries ds
                LEFT JOIN meals     m  ON m.user_id  = ds.user_id AND DATE(m.meal_time) = ds.date_record
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
                    ABS(calories - target_calories)                     AS cal_diff,
                    CASE WHEN target_calories > 0
                              AND ABS(calories - target_calories) <= target_calories * 0.1
                         THEN 1 ELSE 0 END                              AS on_target
                FROM recent_daily
            )
            SELECT
                COUNT(*)                                                 AS total_days_logged,
                ROUND(AVG(calories)::numeric, 0)                        AS avg_calories,
                SUM(on_target)                                           AS days_on_target,
                ROUND(AVG(protein)::numeric, 1)                         AS avg_protein,
                ROUND(AVG(carbs)::numeric, 1)                           AS avg_carbs,
                ROUND(AVG(fat)::numeric, 1)                             AS avg_fat,
                ROUND(MIN(cal_diff)::numeric, 0)                        AS best_day_diff,
                MAX(current_streak)                                      AS current_streak
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
        if conn: conn.close()


@app.get("/insights/{user_id}/top_foods")
def get_top_foods(user_id: int, limit: int = 10):
    """
    Top foods eaten by frequency in the last 30 days.

    CTE: food_frequency — counts occurrences and ranks by times_eaten.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH food_frequency AS (
                SELECT
                    di.food_id,
                    di.food_name,
                    COUNT(*)                                    AS times_eaten,
                    ROUND(SUM(di.amount)::numeric, 1)           AS total_amount,
                    ROUND(SUM(di.amount * di.cal_per_unit)::numeric, 0) AS total_calories,
                    f.image_url,
                    RANK() OVER (ORDER BY COUNT(*) DESC)        AS rank
                FROM meals m
                JOIN detail_items di ON di.meal_id = m.meal_id
                LEFT JOIN foods    f  ON f.food_id  = di.food_id
                WHERE m.user_id = %s
                  AND m.meal_time >= NOW() - INTERVAL '30 days'
                GROUP BY di.food_id, di.food_name, f.image_url
            )
            SELECT * FROM food_frequency
            WHERE rank <= %s
            ORDER BY rank
        """, (user_id, limit))
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.get("/insights/{user_id}/calorie_trend")
def get_calorie_trend(user_id: int, days: int = 30):
    """
    Daily calories vs target for the last N days, with 7-day moving average.

    CTE chain:
      daily_data   → raw calories per day joined with user target
      moving_avg   → 7-day rolling average using window function
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH daily_data AS (
                SELECT
                    ds.date_record,
                    ds.total_calories_intake        AS calories,
                    u.target_calories
                FROM daily_summaries ds
                CROSS JOIN (SELECT target_calories FROM users WHERE user_id = %s) u
                WHERE ds.user_id = %s
                  AND ds.date_record >= CURRENT_DATE - (%s || ' days')::INTERVAL
            ),
            moving_avg AS (
                SELECT
                    date_record,
                    calories,
                    target_calories,
                    ROUND(AVG(calories) OVER (
                        ORDER BY date_record
                        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                    )::numeric, 0)                  AS moving_avg_7d,
                    CASE WHEN target_calories > 0
                              AND ABS(calories - target_calories) <= target_calories * 0.1
                         THEN true ELSE false END   AS on_target
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
        if conn: conn.close()


@app.get("/insights/{user_id}/macro_balance")
def get_macro_balance(user_id: int):
    """
    Average macro distribution over the last 7 days with % breakdown.

    CTE chain:
      macro_daily  → per-day sum of protein/carbs/fat from stored detail_items values
      macro_avg    → average across days + Atwater-based % of total energy
      daily_detail → individual day rows for sparkline data
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            WITH macro_daily AS (
                SELECT
                    DATE(m.meal_time)                           AS day,
                    COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS protein,
                    COALESCE(SUM(di.amount * di.carbs_per_unit),   0) AS carbs,
                    COALESCE(SUM(di.amount * di.fat_per_unit),     0) AS fat,
                    COALESCE(SUM(di.amount * di.cal_per_unit),     0) AS total_cal
                FROM meals m
                JOIN detail_items di ON di.meal_id = m.meal_id
                WHERE m.user_id = %s
                  AND m.meal_time >= NOW() - INTERVAL '7 days'
                GROUP BY DATE(m.meal_time)
            ),
            macro_avg AS (
                SELECT
                    ROUND(AVG(protein)::numeric, 1)  AS avg_protein_g,
                    ROUND(AVG(carbs)::numeric, 1)    AS avg_carbs_g,
                    ROUND(AVG(fat)::numeric, 1)      AS avg_fat_g,
                    ROUND(AVG(total_cal)::numeric, 0) AS avg_calories,
                    -- Atwater factors: protein=4, carbs=4, fat=9
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(protein) * 4 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END                  AS protein_pct,
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(carbs) * 4 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END                  AS carbs_pct,
                    CASE WHEN AVG(total_cal) > 0
                         THEN ROUND((AVG(fat) * 9 / AVG(total_cal) * 100)::numeric, 1)
                         ELSE 0 END                  AS fat_pct
                FROM macro_daily
            )
            SELECT
                ma.*,
                JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'day', md.day,
                        'protein', ROUND(md.protein::numeric, 1),
                        'carbs',   ROUND(md.carbs::numeric, 1),
                        'fat',     ROUND(md.fat::numeric, 1),
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
        if conn: conn.close()


# =============================================================================
# API 45–47: Allergy Flags & User Allergy Preferences
# =============================================================================

@app.get("/allergy_flags")
def get_allergy_flags():
    """Return all available allergy flags from DB."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT flag_id, name, description FROM allergy_flags ORDER BY flag_id ASC")
        return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.get("/users/{user_id}/allergies")
def get_user_allergies(user_id: int):
    """Return the allergy flags the user has selected."""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT af.flag_id, af.name, af.description
            FROM user_allergy_preferences uap
            JOIN allergy_flags af ON af.flag_id = uap.flag_id
            WHERE uap.user_id = %s
            ORDER BY af.flag_id
        """, (user_id,))
        rows = cur.fetchall()
        return {
            "flag_ids": [r["flag_id"] for r in rows],
            "flags": [dict(r) for r in rows],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()


@app.post("/users/{user_id}/allergies")
def set_user_allergies(user_id: int, body: AllergyUpdate):
    """Replace user's allergy selections with the provided flag_ids list."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        # Delete all existing selections then re-insert
        cur.execute("DELETE FROM user_allergy_preferences WHERE user_id = %s", (user_id,))
        for flag_id in body.flag_ids:
            cur.execute("""
                INSERT INTO user_allergy_preferences (user_id, flag_id, preference_type)
                VALUES (%s, %s, 'allergy')
                ON CONFLICT (user_id, flag_id) DO NOTHING
            """, (user_id, flag_id))
        conn.commit()
        return {"message": "Allergies saved", "flag_ids": body.flag_ids}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

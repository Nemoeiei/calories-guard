import os
import random
from datetime import date, timedelta
from passlib.context import CryptContext
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv(r'd:\Senior_Project\calories-guard\.env')

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Connect to DB
conn = psycopg2.connect(
    host=os.environ.get('DB_HOST', 'localhost'),
    database=os.environ.get('DB_NAME', 'postgres'),
    user=os.environ.get('DB_USER', 'postgres'),
    password=os.environ.get('DB_PASSWORD', ''),
    port=os.environ.get('DB_PORT', '5432'),
    options="-c search_path=cleangoal,public"
)
cur = conn.cursor(cursor_factory=RealDictCursor)

try:
    print("🚀 เริ่มสร้างข้อมูลแอคเคาท์ Test Scenario: สมหญิง ดีใจ...")

    email = "somying@test.com"
    password = pwd_context.hash("somying123")
    today = date.today()
    start_date = today - timedelta(days=14)

    # 1. Create User สมหญิง ดีใจ
    # Target Calories calculations (BMR ~ 1460, TDEE ~ 1752, Deficit -> 1400 kcal)
    cur.execute("""
        INSERT INTO users (
            username, email, password_hash, gender, birth_date,
            height_cm, current_weight_kg, goal_type, target_weight_kg,
            target_calories, activity_level, goal_start_date, goal_target_date,
            target_protein, target_carbs, target_fat, is_email_verified
        )
        VALUES (
            'สมหญิง ดีใจ', %s, %s, 'female', '2004-01-01',
            165.0, 69.5, 'lose_weight', 67.0,
            1400, 'sedentary', %s, %s,
            70, 160, 45, TRUE
        )
        ON CONFLICT (email) DO UPDATE SET 
            current_weight_kg = 69.5,
            password_hash = %s
        RETURNING user_id;
    """, (email, password, start_date, today, password))
    user_id = cur.fetchone()['user_id']

    # Delete old records to rebuild scenario
    cur.execute("DELETE FROM weight_logs WHERE user_id = %s", (user_id,))
    cur.execute("DELETE FROM meals WHERE user_id = %s", (user_id,))
    cur.execute("DELETE FROM daily_summaries WHERE user_id = %s", (user_id,))

    # 2. Assign Weights (Day 1 = 70.0kg, Day 7 = 69.8kg, Day 14 = 69.5kg)
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 70.0, %s)", (user_id, start_date))
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 69.8, %s)", (user_id, start_date + timedelta(days=7)))
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 69.5, %s)", (user_id, today))

    # 3. Add 12 out of 14 days of tracked meals (Missing day 5 & day 10 according to evaluation)
    miss_days = {4, 9} # 0-indexed days 4 and 9 = day 5 and 10

    for i in range(15):
        if i in miss_days: continue

        current_day = start_date + timedelta(days=i)
        
        # 3 Meals a day
        b_cal = 400 + random.randint(-50, 50)
        l_cal = 500 + random.randint(-50, 50)
        d_cal = 500 + random.randint(-50, 50)
        total_day_cal = b_cal + l_cal + d_cal
        
        meals = [
            ('breakfast', b_cal, 'ข้าวต้มกุ้ง'),
            ('lunch', l_cal, 'ข้าวมันไก่ (รัน test)'),
            ('dinner', d_cal, 'สลัดปลาแซลมอน')
        ]
        
        for m_type, meal_cal, food_n in meals:
            # Insert Meal
            cur.execute("""
                INSERT INTO meals (user_id, meal_type, meal_time, total_amount)
                VALUES (%s, %s, %s, %s) RETURNING meal_id;
            """, (user_id, m_type, f"{current_day} 12:00:00", meal_cal))
            meal_id = cur.fetchone()['meal_id']
            
            # Insert Detail Item
            cur.execute("""
                INSERT INTO detail_items (meal_id, food_id, food_name, amount, cal_per_unit, protein_per_unit, carbs_per_unit, fat_per_unit)
                VALUES (%s, 2, %s, 1.0, %s, %s, %s, %s);
            """, (meal_id, food_n, meal_cal, meal_cal*0.08, meal_cal*0.12, meal_cal*0.03))
        
        # Record Daily Summary
        is_met = total_day_cal <= 1400
        cur.execute("""
            INSERT INTO daily_summaries (user_id, date_record, total_calories_intake, goal_calories, is_goal_met)
            VALUES (%s, %s, %s, %s, %s) ON CONFLICT (user_id, date_record) DO NOTHING;
        """, (user_id, current_day, total_day_cal, 1400, is_met))

    conn.commit()
    print("✅ ข้อมูล Scenario 'สมหญิง ดีใจ' พร้อมใช้งานแล้ว!")
    print("===========================================")
    print("👨‍💻 เข้าสู่ระบบด้วย:")
    print(f"📧 Email: somying@test.com")
    print("🔑 Password: somying123")
    print("===========================================")
    print("📌 ผลลัพธ์ในฐานข้อมูล (ตาม Evaluation):")
    print("- น้ำหนักเริ่มต้น: 70kg -> ปัจจุบัน: 69.5kg")
    print("- บันทึกอาหาร: 12/14 วัน (หยุดบันทึกไป 2 วัน จำลองลืมเก็บข้อมูล)")

except Exception as e:
    conn.rollback()
    print("❌ Error generating use case data:", e)
finally:
    cur.close()
    conn.close()

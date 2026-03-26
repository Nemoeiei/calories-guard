import os
import random
from datetime import date, timedelta
from passlib.context import CryptContext
import psycopg2
from dotenv import load_dotenv

load_dotenv(r'd:\Senior_Project\calories-guard\.env')

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Connect to DB
conn = psycopg2.connect(
    host=os.environ.get('DB_HOST', 'localhost'),
    database=os.environ.get('DB_NAME', 'postgres'),
    user=os.environ.get('DB_USER', 'postgres'),
    password=os.environ.get('DB_PASSWORD', ''),
    port=os.environ.get('DB_PORT', '5432')
)
cur = conn.cursor()

try:
    cur.execute("SET search_path TO cleangoal")
    print("🚀 Starting Use Case Seed for 1 Male (Muscle) and 1 Female (Lose Fat)...")

    # 1. Create Users
    male_email = "test_male@example.com"
    female_email = "test_female@example.com"
    password = pwd_context.hash("123456")
    today = date.today()
    start_date = today - timedelta(days=6) # 1 week ago

    # Male - Build Muscle (Start: 70kg, Target: 75kg)
    # TDEE for 25yrs, 175cm, 70kg (Sedentary) ~2000 kcal, Target ~ 2500 kcal
    cur.execute("""
        INSERT INTO users (username, email, password_hash, gender, birth_date, height_cm, current_weight_kg, goal_type, target_weight_kg, target_calories, activity_level, goal_start_date)
        VALUES ('John Doe', %s, %s, 'male', '1998-05-10', 175.0, 72.0, 'gain_muscle', 75.0, 2500, 'sedentary', %s)
        ON CONFLICT (email) DO UPDATE SET current_weight_kg = 72.0 RETURNING user_id;
    """, (male_email, password, start_date))
    male_id = cur.fetchone()[0]

    # Female - Lose Weight (Start: 65kg, Target: 55kg)
    # TDEE for 25yrs, 160cm, 65kg (Sedentary) ~ 1500 kcal, Target ~ 1000 kcal
    cur.execute("""
        INSERT INTO users (username, email, password_hash, gender, birth_date, height_cm, current_weight_kg, goal_type, target_weight_kg, target_calories, activity_level, goal_start_date)
        VALUES ('Jane Smith', %s, %s, 'female', '1998-08-20', 160.0, 63.0, 'lose_weight', 55.0, 1100, 'sedentary', %s)
        ON CONFLICT (email) DO UPDATE SET current_weight_kg = 63.0 RETURNING user_id;
    """, (female_email, password, start_date))
    female_id = cur.fetchone()[0]

    # 2. Assign Start Weight (Day 1 - 70kg and 65kg)
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 70.0, %s) ON CONFLICT DO NOTHING", (male_id, start_date))
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 65.0, %s) ON CONFLICT DO NOTHING", (female_id, start_date))

    # Current Weight (Day 7 - 72kg and 63kg) -> Progress updated!
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 72.0, %s) ON CONFLICT DO NOTHING", (male_id, today))
    cur.execute("INSERT INTO weight_logs (user_id, weight_kg, recorded_date) VALUES (%s, 63.0, %s) ON CONFLICT DO NOTHING", (female_id, today))

    # 3. Add 21 Meals (7 days * 3 meals)
    def add_meals_for_user(user_id, target_cal):
        for i in range(7):
            current_day = start_date + timedelta(days=i)
            # Break down target into 3 meals
            b_cal = target_cal * 0.3 # 30% Breakdown
            l_cal = target_cal * 0.4 # 40% Breakdown
            d_cal = target_cal * 0.3 # 30% Breakdown
            
            meals = [('breakfast', b_cal, 'ข้าวต้มหมู'), ('lunch', l_cal, 'ข้าวกะเพราไก่'), ('dinner', d_cal, 'สลัดผักอกไก่')]
            
            for m_type, meal_cal, food_n in meals:
                # Add randomness (+- 100 cal)
                final_cal = meal_cal + random.randint(-50, 50)
                
                # Insert Meal
                cur.execute("""
                    INSERT INTO meals (user_id, meal_type, meal_time, total_amount)
                    VALUES (%s, %s, %s, %s) RETURNING meal_id;
                """, (user_id, m_type, f"{current_day} 12:00:00", final_cal))
                meal_id = cur.fetchone()[0]
                
                # Insert Detail Item
                cur.execute("""
                    INSERT INTO detail_items (meal_id, food_id, food_name, amount, cal_per_unit)
                    VALUES (%s, 1, %s, 1.0, %s);
                """, (meal_id, food_n, final_cal))
            
            # Record Daily Summary
            total_day = target_cal + random.randint(-150, 150)
            is_met = abs(total_day - target_cal) < 100
            cur.execute("""
                INSERT INTO daily_summaries (user_id, date_record, total_calories_intake, goal_calories, is_goal_met)
                VALUES (%s, %s, %s, %s, %s) ON CONFLICT (user_id, date_record) DO NOTHING;
            """, (user_id, current_day, total_day, target_cal, is_met))

    # Delete old meals for these test users so we don't duplicate
    cur.execute("DELETE FROM meals WHERE user_id IN (%s, %s)", (male_id, female_id))
    cur.execute("DELETE FROM daily_summaries WHERE user_id IN (%s, %s)", (male_id, female_id))

    add_meals_for_user(male_id, 2500)
    add_meals_for_user(female_id, 1100)

    conn.commit()
    print("✅ Use Case Data Generation Complete!")
    print(f"👨 Male Account test -> Email: {male_email} | Password: 123456")
    print(f"👩 Female Account test -> Email: {female_email} | Password: 123456")

except Exception as e:
    conn.rollback()
    print("❌ Error generating use case data:", e)
finally:
    cur.close()
    conn.close()

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "dbname": os.getenv("DB_NAME", "cleangoal_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "options": "-c search_path=cleangoal,public",
}

def add_mock_data():
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        # Get all foods
        cur.execute("SELECT food_id, food_name FROM foods")
        foods = cur.fetchall()
        
        for food_id, food_name in foods:
            # Check if recipe exists
            cur.execute("SELECT recipe_id FROM recipes WHERE food_id = %s", (food_id,))
            if not cur.fetchone():
                cur.execute("""
                    INSERT INTO recipes (food_id, prep_time_minutes, cooking_time_minutes, instructions, description)
                    VALUES (%s, %s, %s, %s, %s)
                """, (
                    food_id,
                    15,
                    20,
                    f"1. เตรียมส่วนผสมสำหรับ {food_name}\n2. นำไปประกอบอาหารจนสุก\n3. จัดใส่จานพร้อมเสิร์ฟ รับประทานให้อร่อย!",
                    f"สูตรอาหารง่ายๆ สำหรับ {food_name} ทำได้เองที่บ้าน"
                ))
                print(f"Mocked recipe for_id {food_id}: {food_name}")
            else:
               print(f"Recipe already exists for {food_id}: {food_name}")
            
        conn.commit()
    except Exception as e:
        print(f"Error: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    add_mock_data()

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def add_mock_data():
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            database=os.getenv('DB_NAME', 'cleangoal_db'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD'),
            port=os.getenv('DB_PORT', '5432'),
            options="-c search_path=cleangoal,public"
        )
        cur = conn.cursor()

        # Check if mock food exists
        cur.execute("SELECT food_id FROM foods WHERE food_name = 'สลัดแซลมอนอะโวคาโด (Mockup)'")
        row = cur.fetchone()
        if row:
            food_id = row[0]
            print(f"Mock food already exists with ID: {food_id}")
        else:
            # Insert mock food
            cur.execute("""
                INSERT INTO foods (food_name, calories, protein, carbs, fat, image_url)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING food_id
            """, (
                "สลัดแซลมอนอะโวคาโด (Mockup)",
                350,
                25,
                15,
                20,
                "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop"
            ))
            food_id = cur.fetchone()[0]
            print(f"Inserted mock food with ID: {food_id}")

            # Insert mock recipe
            cur.execute("""
                INSERT INTO recipes (food_id, prep_time_minutes, cooking_time_minutes, instructions)
                VALUES (%s, %s, %s, %s)
            """, (
                food_id,
                10,
                15,
                "1. นำปลาแซลมอนมาโรยเกลือและพริกไทยเล็กน้อย\\n2. ย่างปลาแซลมอนในกระทะด้วยไฟกลางจนสุก\\n3. หั่นอะโวคาโด มะเขือเทศ และผักสลัด\\n4. ผสมน้ำสลัดน้ำมันงา 1 ช้อนโต๊ะ\\n5. จัดใส่จานพร้อมเสิร์ฟ"
            ))
            print("Inserted mock recipe")
            
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

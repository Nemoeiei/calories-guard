import psycopg2
from psycopg2.extras import RealDictCursor
import json
import os

# Connect to the database (adjust DB credentials if necessary)
# Usually main.py uses something like this:
import os
from database import get_db_connection

try:
    conn = get_db_connection()
    if conn is None:
        raise Exception("Cannot connect to Database")
    cur = conn.cursor()

    # 1. Insert Units
    cur.execute("INSERT INTO units (unit_id, name, conversion_factor) VALUES (1, 'กรัม (g)', 1.0) ON CONFLICT (unit_id) DO UPDATE SET name=EXCLUDED.name;")
    cur.execute("INSERT INTO units (unit_id, name, conversion_factor) VALUES (2, 'ฟอง', 50.0) ON CONFLICT (unit_id) DO UPDATE SET name=EXCLUDED.name;")
    cur.execute("INSERT INTO units (unit_id, name, conversion_factor) VALUES (3, 'ช้อนโต๊ะ', 15.0) ON CONFLICT (unit_id) DO UPDATE SET name=EXCLUDED.name;")
    
    # Reset Sequence for units
    cur.execute("SELECT setval('units_unit_id_seq', (SELECT MAX(unit_id) FROM units));")

    # 2. Insert Ingredients
    ingredients_data = [
        (101, 'ไข่ไก่', 'โปรตีน', 2, 72.00),
        (102, 'อกไก่ (ดิบ)', 'โปรตีน', 1, 1.65),
        (103, 'น้ำมันถั่วเหลือง', 'ไขมัน', 3, 120.00)
    ]
    for i in ingredients_data:
        cur.execute("""
            INSERT INTO ingredients (ingredient_id, name, category, default_unit_id, calories_per_unit)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (name) DO UPDATE SET calories_per_unit=EXCLUDED.calories_per_unit, default_unit_id=EXCLUDED.default_unit_id
        """, i)

    cur.execute("SELECT setval('ingredients_ingredient_id_seq', (SELECT MAX(ingredient_id) FROM ingredients));")

    # 3. Create mock Foods & Recipes before linking food_ingredients
    # We will insert Food: 'ไข่ดาว' and 'อกไก่ผัดไข่'
    mock_foods = [
        (901, 'ไข่ดาว', 'recipe_dish', 450.0, 'https://picsum.photos/400/300?1'),
        (902, 'อกไก่ผัดไข่', 'recipe_dish', 500.0, 'https://picsum.photos/400/300?2')
    ]
    for f in mock_foods:
        cur.execute("""
            INSERT INTO foods (food_id, food_name, food_type, calories, image_url)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (food_id) DO NOTHING
        """, f)

    cur.execute("SELECT setval('foods_food_id_seq', (SELECT MAX(food_id) FROM foods));")

    # Mock Recipes attached to Foods
    mock_recipes = [
        (901, 901, 'ไข่ดาวกรอบนอกนุ่มใน', '1. ตั้งน้ำมันให้ร้อน\n2. ตอกไข่ลงไปทอดให้กรอบ', 5, 5, 1.0),
        (902, 902, 'อกไก่ผัดไข่นุ่มชุ่มฉ่ำ', '1. ผัดไก่จนสุก\n2. ใส่ไข่ลงไปผัดให้เข้ากัน', 10, 10, 2.0)
    ]
    for r in mock_recipes:
        # Check if exists
        cur.execute("SELECT recipe_id FROM recipes WHERE food_id = %s", (r[1],))
        if not cur.fetchone():
            cur.execute("""
                INSERT INTO recipes (recipe_id, food_id, description, instructions, prep_time_minutes, cooking_time_minutes, serving_people)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, r)

    # 4. Insert Food_Ingredients
    food_ingredients_data = [
        # ไข่ดาว (901)
        (5001, 901, 101, 1.0, 2, 50.0, 'ไข่ไก่เบอร์ 2'),
        (5002, 901, 103, 1.0, 3, 15.0, 'สำหรับทอด'),
        # อกไก่ผัดไข่ (902)
        (5003, 902, 102, 150.0, 1, 150.0, 'หั่นเต๋า'),
        (5004, 902, 101, 2.0, 2, 100.0, 'ตีให้เข้ากัน'),
        (5005, 902, 103, 0.5, 3, 7.5, 'สำหรับผัด')
    ]

    for fi in food_ingredients_data:
        # Check if exists (by id or content) to avoid duplicates if run multiple times
        cur.execute("SELECT food_ing_id FROM food_ingredients WHERE food_ing_id = %s", (fi[0],))
        if not cur.fetchone():
            cur.execute("""
                INSERT INTO food_ingredients (food_ing_id, food_id, ingredient_id, amount, unit_id, calculated_grams, note)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, fi)

    cur.execute("SELECT setval('food_ingredients_food_ing_id_seq', (SELECT MAX(food_ing_id) FROM food_ingredients));")

    conn.commit()
    print("Mock data inserted successfully!")

except Exception as e:
    print("Error:", e)
finally:
    if 'conn' in locals() and conn:
        conn.close()

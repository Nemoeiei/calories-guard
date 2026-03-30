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

    # 0. สร้างตาราง unit_conversions ถ้ายังไม่มี
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

    # Rename conversion_factor → quantity (idempotent)
    cur.execute("""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name  = 'units'
                  AND column_name = 'conversion_factor'
            ) THEN
                ALTER TABLE units RENAME COLUMN conversion_factor TO quantity;
            END IF;
        END$$;
    """)
    conn.commit()

    # 1. Insert Units (quantity = 1 ทุกตัว — ค่าแปลงจริงอยู่ใน unit_conversions)
    units_data = [
        (1,  'กรัม (g)'),
        (2,  'ฟอง'),
        (3,  'ช้อนโต๊ะ'),
        (4,  'ทัพพี'),
        (5,  'จาน'),
        (6,  'ออนซ์ (oz)'),
        (7,  'ลิตร (L)'),
        (8,  'ช้อนชา (tsp)'),
        (9,  'มิลลิลิตร (ml)'),
        (10, 'แก้ว'),
        (11, 'ถ้วย'),
        (12, 'ชิ้น'),
        (13, 'ลูก / หัว'),
        (14, 'กิโลกรัม (kg)'),
        (15, 'ห่อ'),
    ]
    for uid, name in units_data:
        cur.execute(
            "INSERT INTO units (unit_id, name, quantity) VALUES (%s, %s, 1) "
            "ON CONFLICT (unit_id) DO UPDATE SET name=EXCLUDED.name, quantity=1;",
            (uid, name)
        )

    # Reset Sequence for units
    cur.execute("SELECT setval('units_unit_id_seq', (SELECT MAX(unit_id) FROM units));")

    # 1b. Insert unit_conversions (from_unit → กรัม)
    # (from_unit_id, to_unit_id=1[กรัม], factor, note)
    conversions_to_gram = [
        (1,  1,    1.0,       'กรัม → กรัม'),
        (2,  1,   50.0,       'ฟอง → กรัม (ไข่เบอร์กลาง)'),
        (3,  1,   15.0,       'ช้อนโต๊ะ → กรัม'),
        (4,  1,  100.0,       'ทัพพี → กรัม'),
        (5,  1,  300.0,       'จาน → กรัม'),
        (6,  1,   28.3495,    'ออนซ์ → กรัม (1 oz = 28.3495 g)'),
        (7,  1, 1000.0,       'ลิตร → กรัม (น้ำ 1 L ≈ 1000 g)'),
        (8,  1,    5.0,       'ช้อนชา → กรัม'),
        (9,  1,    1.0,       'มิลลิลิตร → กรัม (น้ำ 1 ml ≈ 1 g)'),
        (10, 1,  240.0,       'แก้ว → กรัม'),
        (11, 1,  240.0,       'ถ้วย → กรัม'),
        (12, 1,   30.0,       'ชิ้น → กรัม (ค่าเฉลี่ย)'),
        (13, 1,  100.0,       'ลูก/หัว → กรัม (ค่าเฉลี่ย)'),
        (14, 1, 1000.0,       'กิโลกรัม → กรัม'),
        (15, 1,  150.0,       'ห่อ → กรัม (ค่าเฉลี่ย)'),
    ]
    # แถวเพิ่มเติม: แปลงระหว่างหน่วยมาตรฐาน (kg, g, oz, L)
    extra_conversions = [
        (14, 1,    1000.0,    'kg → g'),
        (1,  14,      0.001,  'g → kg'),
        (6,  1,      28.3495, 'oz → g'),
        (1,  6,       0.035274,'g → oz'),
        (7,  9,    1000.0,    'L → ml'),
        (9,  7,       0.001,  'ml → L'),
    ]
    for from_id, to_id, factor, note in conversions_to_gram + extra_conversions:
        cur.execute(
            "INSERT INTO unit_conversions (from_unit_id, to_unit_id, factor, note) "
            "VALUES (%s, %s, %s, %s) "
            "ON CONFLICT (from_unit_id, to_unit_id) DO UPDATE "
            "SET factor=EXCLUDED.factor, note=EXCLUDED.note;",
            (from_id, to_id, factor, note)
        )

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

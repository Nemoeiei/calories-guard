"""
run_migrations.py
รัน migration SQL files ทั้งหมดบน local PostgreSQL ตามลำดับ
"""

import os
import sys
import glob
import psycopg2
from dotenv import load_dotenv

# โหลด .env จาก root หรือ backend
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "dbname":   os.getenv("DB_NAME", "cleangoal_db"),
    "user":     os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
    "port":     os.getenv("DB_PORT", "5432"),
    "options":  "-c search_path=cleangoal,public",
}

MIGRATIONS_DIR = os.path.join(os.path.dirname(__file__), "migrations")

# ไฟล์ที่ต้องการรัน (เรียงลำดับ)
TARGET_MIGRATIONS = [
    "v8_add_macros_water_to_daily_summaries.sql",
    "v9_create_water_logs.sql",
    "v10_create_exercise_logs.sql",
    "v11_add_performance_indexes.sql",
    "v12_add_consent_and_detail_macros.sql",
]

def run_migrations():
    print("=" * 60)
    print("🚀 Calories Guard — Local DB Migration Runner")
    print("=" * 60)
    print(f"📦 DB: {DB_CONFIG['user']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}")
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = False
        cur = conn.cursor()
        print("✅ เชื่อมต่อฐานข้อมูลสำเร็จ\n")
    except Exception as e:
        print(f"❌ เชื่อมต่อ DB ไม่ได้: {e}")
        sys.exit(1)

    success = 0
    failed  = 0

    for filename in TARGET_MIGRATIONS:
        filepath = os.path.join(MIGRATIONS_DIR, filename)
        if not os.path.exists(filepath):
            print(f"⚠️  ไม่พบไฟล์: {filename} — ข้าม")
            continue

        print(f"📄 กำลังรัน: {filename}")
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                sql = f.read()

            cur.execute(sql)
            conn.commit()
            print(f"   ✅ สำเร็จ\n")
            success += 1

        except Exception as e:
            conn.rollback()
            print(f"   ❌ ERROR: {e}\n")
            failed += 1
            # ถามว่าจะรันต่อไหม
            answer = input("   ต้องการรัน migration ถัดไปต่อหรือไม่? (y/n): ").strip().lower()
            if answer != "y":
                break

    cur.close()
    conn.close()

    print("=" * 60)
    print(f"📊 สรุป: สำเร็จ {success} | ล้มเหลว {failed}")
    print("=" * 60)

if __name__ == "__main__":
    run_migrations()

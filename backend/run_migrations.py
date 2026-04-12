"""
run_migrations.py
รัน migration SQL files บน local หรือ Supabase PostgreSQL ตามลำดับ
รองรับ schema_migrations table เพื่อ track ว่า migration ไหนรันแล้ว
"""

import os
import sys
import psycopg2
from dotenv import load_dotenv

# โหลด .env จาก root หรือ backend
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

DB_MODE = os.getenv("DB_MODE", "local").lower()

def _build_config():
    if DB_MODE == "supabase":
        return {
            "host":     os.getenv("SUPABASE_HOST"),
            "database": os.getenv("SUPABASE_NAME", "postgres"),
            "user":     os.getenv("SUPABASE_USER", "postgres"),
            "password": os.getenv("SUPABASE_PASSWORD"),
            "port":     os.getenv("SUPABASE_PORT", "5432"),
            "options":  "-c search_path=cleangoal,public",
            "sslmode":  "require",
        }
    else:
        return {
            "host":     os.getenv("DB_HOST", "localhost"),
            "database": os.getenv("DB_NAME", "cleangoal_db"),
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
    "v13_create_temp_and_verified_food.sql",
    "add_target_macros_to_users.sql",
]


def ensure_schema_migrations(cur):
    """สร้า��ตาราง schema_migrations ถ้ายังไม่มี"""
    cur.execute("""
        CREATE TABLE IF NOT EXISTS cleangoal.schema_migrations (
            name        VARCHAR(255) PRIMARY KEY,
            applied_at  TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """)


def get_applied_migrations(cur):
    """ดึงรายชื่อ migration ที่รันไปแ��้ว"""
    cur.execute("SELECT name FROM cleangoal.schema_migrations")
    return {row[0] for row in cur.fetchall()}


def run_migrations():
    mode_label = "Supabase" if DB_MODE == "supabase" else "Local"
    config = _build_config()

    print("=" * 60)
    print(f"Calories Guard — DB Migration Runner ({mode_label})")
    print("=" * 60)
    print(f"DB: {config.get('user')}@{config.get('host')}:{config.get('port')}/{config.get('database')}")
    print()

    try:
        conn = psycopg2.connect(**config)
        conn.autocommit = False
        cur = conn.cursor()
        print("Connected to database\n")
    except Exception as e:
        print(f"ERROR: Cannot connect to DB: {e}")
        sys.exit(1)

    try:
        # สร้างตาราง tracking
        ensure_schema_migrations(cur)
        conn.commit()

        applied = get_applied_migrations(cur)
        print(f"Already applied: {len(applied)} migration(s)\n")

        success = 0
        skipped = 0
        failed = 0

        for filename in TARGET_MIGRATIONS:
            if filename in applied:
                print(f"  SKIP: {filename} (already applied)")
                skipped += 1
                continue

            filepath = os.path.join(MIGRATIONS_DIR, filename)
            if not os.path.exists(filepath):
                print(f"  WARN: {filename} not found, skipping")
                continue

            print(f"  RUN:  {filename}")
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    sql = f.read()

                cur.execute(sql)
                cur.execute(
                    "INSERT INTO cleangoal.schema_migrations (name) VALUES (%s)",
                    (filename,)
                )
                conn.commit()
                print(f"        OK")
                success += 1

            except Exception as e:
                conn.rollback()
                print(f"        FAILED: {e}")
                failed += 1
                answer = input("        Continue with next migration? (y/n): ").strip().lower()
                if answer != "y":
                    break

        print()
        print("=" * 60)
        print(f"Summary: {success} applied | {skipped} skipped | {failed} failed")
        print("=" * 60)

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    run_migrations()

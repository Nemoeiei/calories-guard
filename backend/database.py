import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# โหลดค่าจาก .env (ค้นหาจาก root folder ก่อน แล้วค่อย backend/)
_root_env = os.path.join(os.path.dirname(__file__), '..', '.env')
_local_env = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path=_root_env)
load_dotenv(dotenv_path=_local_env)

DB_MODE = os.getenv("DB_MODE", "local").lower()  # "local" หรือ "supabase"

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

def get_db_connection():
    config = _build_config()
    try:
        conn = psycopg2.connect(**config)
        return conn
    except Exception as e:
        mode_label = "Supabase" if DB_MODE == "supabase" else "Local"
        print(f"[DB] ❌ เชื่อมต่อ {mode_label} DB ไม่ได้: {e}")
        return None

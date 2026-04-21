import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# โหลดค่าจาก .env
_root_env = os.path.join(os.path.dirname(__file__), '..', '.env')
_local_env = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path=_root_env)
load_dotenv(dotenv_path=_local_env)

def get_db_connection():
    """Return PostgreSQL connection using DATABASE_URL"""
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        print("[DB] ❌ DATABASE_URL environment variable not set")
        return None
    
    try:
        conn = psycopg2.connect(database_url)
        # Set search path to cleangoal schema
        with conn.cursor() as cur:
            cur.execute("SET search_path TO cleangoal, public")
        conn.commit()
        print("[DB] ✅ Connected to database successfully")
        return conn
    except Exception as e:
        print(f"[DB] ❌ Connection failed: {e}")
        return None
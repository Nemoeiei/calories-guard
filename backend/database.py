import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """Return PostgreSQL connection using DATABASE_URL or DIRECT_DATABASE_URL."""
    database_url = os.getenv("DIRECT_DATABASE_URL") or os.getenv("DATABASE_URL")
    
    if not database_url:
        print("[DB] ❌ DATABASE_URL or DIRECT_DATABASE_URL not set")
        return None
    
    try:
        conn = psycopg2.connect(database_url)
        with conn.cursor() as cur:
            cur.execute("SET search_path TO cleangoal, public")
        conn.commit()
        print("[DB] ✅ Connected to database successfully")
        return conn
    except Exception as e:
        print(f"[DB] ❌ Connection failed: {e}")
        return None

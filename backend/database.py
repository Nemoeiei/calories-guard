import os
from supabase import create_client
from dotenv import load_dotenv

# โหลดค่าจาก .env
_root_env = os.path.join(os.path.dirname(__file__), '..', '.env')
_local_env = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path=_root_env)
load_dotenv(dotenv_path=_local_env)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise Exception("Missing SUPABASE_URL or SUPABASE_KEY environment variables")

# สร้าง Supabase client
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def get_supabase():
    """Return Supabase client instance"""
    return supabase

# เก็บไว้เพื่อ compatibility กับโค้ดเก่าที่เรียก get_db_connection()
def get_db_connection():
    """Deprecated: Use get_supabase() instead"""
    print("[DB] Warning: get_db_connection() is deprecated. Use get_supabase() instead.")
    return None
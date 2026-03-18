import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# โหลดค่าจากไฟล์ .env
load_dotenv()

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST'),
            database=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            port=os.getenv('DB_PORT'),
            options="-c search_path=cleangoal,public"
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None
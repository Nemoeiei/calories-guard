
import os
import sys

# Add backend directory to python path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from dotenv import load_dotenv
env_path = os.path.join(os.getcwd(), 'backend', '.env')
load_dotenv(env_path)

from backend.app.core.database import SessionLocal, engine
from backend.app.models.models import User, Base
from sqlalchemy import text

def test_connection():
    print("Testing Database Connection...")
    try:
        # Test basic connection
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            print(f"Connection Successful! Result: {result.scalar()}")
            
        # Test ORM Session
        db = SessionLocal()
        print("Session Created Successfully")
        
        # Check if tables exist (basic check)
        from sqlalchemy import inspect
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"Tables found: {tables}")
        
        required_tables = ['users', 'foods', 'meals', 'daily_summaries']
        missing = [t for t in required_tables if t not in tables]
        
        if missing:
            print(f"WARNING: Missing tables: {missing}")
        else:
            print("All core tables present.")
            
        db.close()
        return True
    except Exception as e:
        print(f"CONNECTION FAILED: {e}")
        return False

if __name__ == "__main__":
    test_connection()

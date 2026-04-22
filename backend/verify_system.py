import os
import sys
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from chatbot_agent import CoachingAgent
from ai_models.multi_agent_system import NutritionMultiAgent
from database import get_db_connection

def test_database():
    print("--- Testing Database Connection ---")
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT user_id, username FROM users LIMIT 1")
        user = cur.fetchone()
        conn.close()
        if user:
            print(f"✅ DB connected. Found user: {user[1]} (ID: {user[0]})")
            return user[0]
        else:
            print("⚠️ DB connected but no users found. Please create a dummy user.")
            return None
    except Exception as e:
        print(f"❌ DB connection failed: {e}")
        return None

def test_chatbot_agent(user_id):
    print("\n--- Testing CoachingAgent (chatbot_agent.py) ---")
    agent = CoachingAgent()
    
    questions = [
        "สวัสดี โค้ชแคลเซียม แนะนำเมนูไก่ลดน้ำหนักหน่อย", # In scope
        "สอนเขียน Python สำหรับทำเว็บหน่อยครับ", # Out of scope
        "เพิ่มอาหารใหม่ที่ไม่มีในแอปทำยังไงครับ"  # In scope - app feature Help
    ]
    
    for q in questions:
        print(f"\nUser: {q}")
        response = agent.generate_response(user_id, q)
        print(f"AI: {response}")

def test_multi_agent_system(user_id):
    print("\n--- Testing NutritionMultiAgent (multi_agent_system.py) ---")
    agent = NutritionMultiAgent()
    
    questions = [
        "พี่โค้ช วันนี้กินข้าวผัดกะเพราไป 1 จาน อ้วนไหม", # In scope
        "ช่วยแต่งนิยายแนวแฟนตาซีให้หน่อย 1 ตอน", # Out of scope
        "สอนเปิดบันทึกน้ำหนักในแอปนี้หน่อย" # In scope - app feature
    ]
    
    for q in questions:
        print(f"\nUser: {q}")
        response = agent.run(user_id, q)
        print(f"AI: {response}")

if __name__ == "__main__":
    test_user_id = test_database()
    if test_user_id:
        test_chatbot_agent(test_user_id)
        test_multi_agent_system(test_user_id)
    else:
        print("Cannot test AI agents without a valid user_id in the database.")

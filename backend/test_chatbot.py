import os
import sys
from pprint import pprint

# Ensure we can import from backend
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.chatbot_agent import CoachingAgent

def main():
    print("Initializing Coaching Agent...")
    try:
        agent = CoachingAgent()
        
        # We assume user_id 1 is a valid mock user for testing
        test_user_id = 1
        print(f"\\n--- Fetching Context for User {test_user_id} ---")
        context = agent.fetch_user_context(test_user_id)
        if not context:
            print(f"User {test_user_id} not found in DB. Please create mock data first.")
            return
            
        print("Profile:", context['profile'])
        print(f"Weight Logs Count: {len(context['weight_logs'])}")
        print(f"Recent Foods Count: {len(context['recent_foods'])}")
        
        print("\\n--- Testing Response Generation ---")
        user_message = "ตอนนี้น้ำหนัก 70 ควรลดให้น้อยกว่านี้ไหม มีเมนูอะไรแนะนำบ้าง?"
        print(f"User Message: {user_message}")
        
        response = agent.generate_response(test_user_id, user_message)
        print("\\n[AI Coach Response]:")
        print(response)
        
    except Exception as e:
        print(f"Error during test: {str(e)}")

if __name__ == "__main__":
    main()

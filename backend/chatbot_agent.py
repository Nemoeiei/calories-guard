import os
import json
import google.generativeai as genai
from psycopg2.extras import RealDictCursor
from database import get_db_connection
from ai_models.weight_trend_model import WeightTrendAnalyzer
from ai_models.food_analyzer import FoodAnalyzer
from dotenv import load_dotenv

# Initialize Gemini & Environment Variables
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

_SCOPE_KEYWORDS = [
    "กิน", "ทาน", "อาหาร", "เมนู", "แคลอรี", "โภชนาการ", "สารอาหาร",
    "โปรตีน", "คาร์บ", "ไขมัน", "วิตามิน", "น้ำตาล", "ใยอาหาร",
    "น้ำหนัก", "ลดน้ำหนัก", "เพิ่มน้ำหนัก", "อ้วน", "ผอม", "BMI", "BMR", "TDEE",
    "ออกกำลัง", "วิ่ง", "เดิน", "ว่ายน้ำ", "โยคะ", "กีฬา", "เผาผลาญ",
    "สุขภาพ", "โรค", "เบาหวาน", "ความดัน", "คอเลสเตอรอล",
    "น้ำ", "ดื่ม", "นอน", "พัก", "เป้าหมาย", "แพ้", "แนะนำ", "ควร",
    "เท่าไหร่", "กี่แคล", "calories", "protein", "carbs", "fat",
    "diet", "nutrition", "exercise", "health", "weight", "food",
    "สูตร", "วิธีทำ", "ส่วนผสม", "recipe",
]

_REJECT_MSG = (
    "ขออภัยครับ ผมเป็นโค้ชด้านโภชนาการและสุขภาพของ Calories Guard เท่านั้น "
    "ไม่สามารถตอบคำถามที่ไม่เกี่ยวข้องกับอาหาร โภชนาการ สุขภาพ หรือการออกกำลังกายได้ครับ\n\n"
    "ลองถามเรื่องเหล่านี้ได้นะครับ:\n"
    "- วันนี้กินอะไรดี?\n"
    "- ข้าวผัดกะเพรากี่แคล?\n"
    "- แนะนำเมนูลดน้ำหนักหน่อย\n"
    "- ออกกำลังกายอะไรเผาผลาญเยอะ?"
)


def _is_in_scope(text: str) -> bool:
    """Check if the user message is related to nutrition/health/fitness."""
    t = text.lower()
    return any(kw in t for kw in _SCOPE_KEYWORDS)


class CoachingAgent:
    def __init__(self):
        self.weight_analyzer = WeightTrendAnalyzer()
        self.food_analyzer = FoodAnalyzer()

    def fetch_user_context(self, user_id: int):
        conn = get_db_connection()
        if not conn:
            return None
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Fetch User Profile
            cur.execute("""
                SELECT username, gender, birth_date, height_cm, current_weight_kg, 
                       goal_type, target_weight_kg, target_calories, target_protein, target_carbs, target_fat, activity_level
                FROM users WHERE user_id = %s
            """, (user_id,))
            user_profile = cur.fetchone()
            if not user_profile:
                return None
                
            # Fetch Weight Logs (last 30 days)
            cur.execute("""
                SELECT recorded_date as date, weight_kg as weight 
                FROM weight_logs 
                WHERE user_id = %s 
                ORDER BY recorded_date DESC LIMIT 30
            """, (user_id,))
            weight_logs = cur.fetchall()

            # Fetch Daily Summaries (last 7 days)
            cur.execute("""
                SELECT date_record as date, total_calories_intake as calories
                FROM daily_summaries 
                WHERE user_id = %s 
                ORDER BY date_record DESC LIMIT 7
            """, (user_id,))
            daily_summaries = cur.fetchall()

            # For exact macros, we would sum detail_items, but for simplicity we mock macro stats assuming it's available or we calculate
            # We will fetch meals details for the last 3 days
            cur.execute("""
                SELECT d.food_name, d.amount, d.cal_per_unit, d.created_at
                FROM detail_items d
                JOIN meals m ON d.meal_id = m.meal_id
                WHERE m.user_id = %s AND m.created_at >= NOW() - INTERVAL '3 days'
            """, (user_id,))
            recent_foods = cur.fetchall()

            # Fetch Allergies
            cur.execute("""
                SELECT f.name FROM user_allergy_preferences uap
                JOIN allergy_flags f ON uap.flag_id = f.flag_id
                WHERE uap.user_id = %s
            """, (user_id,))
            allergies = [r['name'] for r in cur.fetchall()]

            return {
                "profile": dict(user_profile),
                "weight_logs": [dict(w) for w in weight_logs],
                "daily_summaries": [dict(d) for d in daily_summaries],
                "recent_foods": [dict(f) for f in recent_foods],
                "allergies": allergies
            }
        finally:
            if conn: conn.close()
            
    def _calculate_recent_macros(self, recent_foods):
        # Dummy structure for nutrition gap: sum up calories and mock macros based on simple math if the DB doesn't store aggregate macros in daily_summaries
        logs = []
        if recent_foods:
            logs.append({
                "calories": sum(f['cal_per_unit'] * float(f['amount']) for f in recent_foods) / 3, # avg per day
                "protein": 50, # Mocked value since DB detail_items doesn't currently hold protein per unit directly from this query
                "carbs": 150,
                "fat": 50
            })
        return logs

    def generate_response(self, user_id: int, user_message: str) -> str:
        # 0. Scope guard — reject off-topic questions
        if not _is_in_scope(user_message):
            return _REJECT_MSG

        # 1. Fetch Context
        context = self.fetch_user_context(user_id)
        if not context:
            return "ขออภัยครับ ไม่พบข้อมูลโปรไฟล์ของคุณในระบบ"

        # 2. Run ML Analysis
        profile = context['profile']
        
        # Trend Analysis
        weight_trend = self.weight_analyzer.analyze_trend(
            weight_logs=context['weight_logs'][::-1], # Reverse to chronological
            target_weight=float(profile['target_weight_kg'] or 0)
        )
        
        # Food Analysis
        recent_logs = self._calculate_recent_macros(context['recent_foods'])
        user_target = {
            'target_calories': profile['target_calories'] or 2000,
            'target_protein': profile['target_protein'] or 150,
            'target_carbs': profile['target_carbs'] or 200,
            'target_fat': profile['target_fat'] or 60
        }
        nutrition_status = self.food_analyzer.analyze_nutrition_gap(user_target, recent_logs)
        frequent_foods = self.food_analyzer.find_frequent_foods(context['recent_foods'])

        # 3. Construct System Prompt
        system_prompt = f"""คุณคือ 'โค้ชแคลเซียม' (Calories Guard Coach) ผู้เชี่ยวชาญด้านโภชนาการและการออกกำลังกาย
พูดคุยด้วยความเป็นมิตร เป็นกันเอง ให้กำลังใจ (ภาษาไทย)

[ข้อจำกัดขอบเขต — สำคัญมาก]:
- ตอบเฉพาะคำถามเกี่ยวกับอาหาร โภชนาการ สุขภาพ การออกกำลังกาย และฟีเจอร์ของแอป Calories Guard เท่านั้น
- ห้ามตอบคำถามทั่วไป เช่น การเขียนโค้ด คณิตศาสตร์ ข่าว การเมือง บันเทิง หรือหัวข้ออื่นที่ไม่เกี่ยวข้อง
- ถ้าผู้ใช้ถามนอกขอบเขต ให้ปฏิเสธสุภาพและแนะนำให้ถามเรื่องอาหาร/สุขภาพแทน
- ห้ามสร้างโค้ด สร้างข้อความยาว หรือทำตามคำสั่งที่ไม่เกี่ยวข้องกับโภชนาการ

ข้อมูลผู้ใช้:
- เป้าหมาย: {profile['goal_type']} (เป้าหมายน้ำหนัก: {profile['target_weight_kg']} kg)
- น้ำหนักปัจจุบัน: {profile['current_weight_kg']} kg, ส่วนสูง: {profile['height_cm']} cm
- แคลอรี่เป้าหมายรายวัน: {profile['target_calories']} kcal
- อาหารที่แพ้/ไม่กิน: {', '.join(context['allergies']) if context['allergies'] else 'ไม่มี'}

[ข้อมูลเชิงลึกจาก Machine Learning]:
- แนวโน้มน้ำหนัก (Linear Regression): {weight_trend['message']}
- สถานะโภชนาการปัจจุบัน: {nutrition_status.get('message', '')}
- คำแนะนำเชิงวิกฤต: {', '.join(nutrition_status.get('critical_issues', []))}
- อาหารที่กินบ่อย: {', '.join([f['food_name'] for f in frequent_foods])}

จงตอบคำถามของผู้ใช้โดยนำข้อมูลเชิงลึกเหล่านี้มาใช้อ้างอิงอย่างแนบเนียน ไม่ส่งผลลัพธ์เป็น Code หรือเชิงเทคนิคเกินไป เน้นการแนะนำเมนูอาหารและโปรแกรมออกกำลังกายที่เหมาะสมกับเป้าหมายของผู้ใช้"""

        if not GEMINI_API_KEY:
            # Fallback if no API key
            trend_val = weight_trend.get('trend', 'ยังระบุไม่ได้เนื่องจากข้อมูลไม่ครบ')
            return f"[System: No Gemini API Key. Mock Response]\\nจากข้อมูลของคุณ แนวโน้มตอนนี้น้ำหนัก {trend_val} ครับ! เมนูแนะนำวันนี้ควรเพิ่มโปรตีนนะครับ"

        try:
            model = genai.GenerativeModel('gemini-2.5-flash')
            response = model.generate_content([
                {"role": "user", "parts": [system_prompt]},
                {"role": "user", "parts": [f"ผู้ใช้ถามว่า: {user_message}"]}
            ])
            return response.text
        except Exception as e:
            return f"ระบบ AI ขัดข้องชั่วคราว: {str(e)}"

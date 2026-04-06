import pandas as pd

class FoodAnalyzer:
    def __init__(self):
        pass

    def analyze_nutrition_gap(self, user_target: dict, recent_logs: list) -> dict:
        """
        วิเคราะห์สารอาหารที่ขาดไปเทียบกับเป้าหมายรายวัน ตลอดสัปดาห์ที่ผ่านมา
        :param user_target: dict { 'target_calories': 2000, 'target_protein': 150, 'target_carbs': 200, 'target_fat': 60 }
        :param recent_logs: list of dicts (จากตาราง daily_summaries หรือ meals) 
               { 'date': '2023-10-01', 'calories': 1800, 'protein': 100, 'carbs': 220, 'fat': 50 }
        :return: ข้อมูลสรุปส่วนต่างสารอาหาร
        """
        if not recent_logs:
            return {
                "status": "no_data",
                "message": "ไม่พบประวัติการรับประทานอาหารในช่วงนี้นะครับ แจ้งให้เริ่มบันทึกมื้อแรกได้เลย!"
            }

        df = pd.DataFrame(recent_logs)
        
        # Calculate averages
        avg_cal = df['calories'].mean()
        avg_pro = df['protein'].mean()
        avg_carb = df['carbs'].mean()
        avg_fat = df['fat'].mean()

        gap_cal = user_target['target_calories'] - avg_cal
        gap_pro = user_target['target_protein'] - avg_pro
        gap_carb = user_target['target_carbs'] - avg_carb
        gap_fat = user_target['target_fat'] - avg_fat

        target_cal = max(user_target['target_calories'], 1)
        target_pro = max(user_target['target_protein'], 1)

        recommendations = []
        if (gap_pro / target_pro) > 0.15: 
            recommendations.append(f"โปรตีน (ขาดเฉลี่ยกว่า {round((gap_pro/target_pro)*100)}% ของเป้าหมาย)")
        if (gap_cal / target_cal) < -0.10:
            surplus_pct = round((abs(gap_cal) / target_cal) * 100)
            recommendations.append(f"ทานเกินแคลอรีเป้าหมาย (เกินกว่า {surplus_pct}%)")
        if (gap_cal / target_cal) > 0.20:
            deficit_pct = round((gap_cal / target_cal) * 100)
            recommendations.append(f"ทานน้อยเกินไป (ขาดแคลอรีไปกว่า {deficit_pct}%)")

        return {
            "status": "analyzed",
            "average_intake": {
                "calories": round(avg_cal, 2),
                "protein": round(avg_pro, 2),
                "carbs": round(avg_carb, 2),
                "fat": round(avg_fat, 2)
            },
            "gaps": {
                "calories": round(gap_cal, 2),
                "protein": round(gap_pro, 2),
                "carbs": round(gap_carb, 2),
                "fat": round(gap_fat, 2)
            },
            "critical_issues": recommendations,
            "message": "มีการบริโภคโปรตีนน้อยกว่าเป้าหมายเป็นประจำ" if gap_pro > 20 else "โภชนาการอยู่ในเกณฑ์ที่ดีครับ"
        }
        
    def find_frequent_foods(self, detail_items: list, top_n: int = 5) -> list:
        """
        ค้นหาอาหารที่ผู้ใช้ทานบ่อยที่สุด
        """
        if not detail_items:
            return []
            
        df = pd.DataFrame(detail_items)
        freq = df['food_name'].value_counts().head(top_n).reset_index()
        freq.columns = ['food_name', 'count']
        return freq.to_dict('records')

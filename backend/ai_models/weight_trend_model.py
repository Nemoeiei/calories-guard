import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from datetime import datetime, date

class WeightTrendAnalyzer:
    def __init__(self):
        self.model = LinearRegression()

    def analyze_trend(self, weight_logs: list, target_weight: float) -> dict:
        """
        วิเคราะห์แนวโน้มน้ำหนักจาก Logs ย้อนหลังด้วย Linear Regression
        :param weight_logs: list ของ dict { 'date': '2023-10-01', 'weight': 70.5 }
        :param target_weight: น้ำหนักเป้าหมายของผู้ใช้
        :return: dict หรือข้อความอธิบายทิศทาง
        """
        if not weight_logs or len(weight_logs) < 3:
            return {
                "status": "insufficient_data",
                "message": "ข้อมูลน้ำหนักย้อนหลังไม่เพียงพอ (ต้องการอย่างน้อย 3 วัน) เพื่อพยากรณ์ได้อย่างแม่นยำ"
            }

        # แปลงข้อมูลเป็น DataFrame
        df = pd.DataFrame(weight_logs)
        df['date'] = pd.to_datetime(df['date'])
        df = df.sort_values('date')

        # เริ่มต้นวันที่ 0
        min_date = df['date'].min()
        df['days_passed'] = (df['date'] - min_date).dt.days
        
        X = df[['days_passed']]
        y = df['weight']

        # Train model
        self.model.fit(X, y)
        
        slope = self.model.coef_[0]
        intercept = self.model.intercept_
        current_weight = df['weight'].iloc[-1]
        
        # ถ้าน้ำหนักไม่เปลี่ยนแปลงเลย
        if abs(slope) < 0.001:
            return {
                "status": "stagnant",
                "trend": "คงที่",
                "slope": round(float(slope), 4),
                "message": "น้ำหนักของคุณค่อนข้างคงที่ในช่วงที่ผ่านมา"
            }

        days_to_target = -1
        if (target_weight < current_weight and slope < 0) or (target_weight > current_weight and slope > 0):
            # ไปถูกทางแล้ว คำนวณวันที่จะถึงเป้า
            # target = slope * x + intercept -> x = (target - intercept) / slope
            target_day_index = (target_weight - intercept) / slope
            days_to_target = max(0, int(target_day_index - df['days_passed'].iloc[-1]))
            
            return {
                "status": "on_track",
                "trend": "ลดลง" if slope < 0 else "เพิ่มขึ้น",
                "days_estimated": days_to_target,
                "slope": round(float(slope), 4),
                "message": f"คุณอยู่ในทิศทางที่ถูกต้อง! คาดว่าจะถึงเป้าหมายในอีกประมาณ {days_to_target} วัน"
            }
        else:
            # ไปผิดทาง
            return {
                "status": "off_track",
                "trend": "พุ่งขึ้น" if slope > 0 else "ลดลงอย่างต่อเนื่อง",
                "slope": round(float(slope), 4),
                "message": "ทิศทางน้ำหนักของคุณกำลังสวนทางกับเป้าหมายที่ตั้งไว้! อาจจะต้องปรับเปลี่ยนพฤติกรรมการกินใหม่นะครับ"
            }

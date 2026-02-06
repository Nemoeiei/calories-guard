# ... (schemas เดิม) ...

# === FOOD LOGGING SCHEMAS ===

# รายการอาหารย่อยที่จะบันทึก (เช่น ข้าวมันไก่ 1 จาน)
class MealItemCreate(BaseModel):
    food_id: int
    amount: float = 1.0
    unit_id: Optional[int] = None # ถ้ามีระบบหน่วย
    note: Optional[str] = None

# ฟอร์มหลักสำหรับบันทึกมื้ออาหาร (รับ list ของอาหาร)
class MealCreate(BaseModel):
    meal_type: str  # breakfast, lunch, dinner, snack
    meal_time: Optional[datetime] = None # ถ้าไม่ส่งมา ให้ใช้เวลาปัจจุบัน
    items: List[MealItemCreate]

# ฟอร์มสำหรับแสดงผลกลับ (Response)
class MealItemResponse(BaseModel):
    food_name: str
    amount: float
    cal_per_unit: float
    total_calories: float # คำนวณให้ frontend เลย (amount * cal)

class MealLogResponse(BaseModel):
    meal_id: int
    meal_type: str
    meal_time: datetime
    total_calories: float
    items: List[MealItemResponse]

    class Config:
        from_attributes = True
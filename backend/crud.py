# ... (imports เดิม) ...

def create_meal_log(db: Session, meal_data: schemas.MealCreate, user_id: int):
    # 1. สร้างหัวมื้ออาหาร (Header)
    db_meal = models.Meal(
        user_id=user_id,
        meal_type=meal_data.meal_type,
        meal_time=meal_data.meal_time or datetime.now()
    )
    db.add(db_meal)
    db.commit()
    db.refresh(db_meal) # ได้ meal_id มาใช้งานต่อ

    total_calories_log = 0

    # 2. วนลูปสร้างรายการอาหารย่อย (Items)
    for item in meal_data.items:
        # 2.1 ดึงข้อมูลต้นฉบับจาก Food Master
        food_master = db.query(models.Food).filter(models.Food.food_id == item.food_id).first()
        if not food_master:
            continue # ถ้าไม่เจออาหาร ให้ข้ามไป (หรือจะ raise Error ก็ได้)

        # 2.2 บันทึกข้อมูลแบบ Snapshot (Copy ค่า ณ ตอนนั้นมาเก็บ)
        db_item = models.MealItem(
            meal_id=db_meal.meal_id,
            food_id=item.food_id,
            amount=item.amount,
            unit_id=item.unit_id,
            # Snapshot Data 👇
            food_name=food_master.food_name,
            cal_per_unit=food_master.calories,
            protein_per_unit=food_master.protein,
            carbs_per_unit=food_master.carbs,
            fat_per_unit=food_master.fat,
            note=item.note
        )
        db.add(db_item)
        
        # บวกเลขแคลอรี่รวมของมื้อนี้ไว้ส่งกลับ
        if food_master.calories:
            total_calories_log += (food_master.calories * item.amount)

    db.commit()
    
    # 3. (Optional) Update Daily Summary ตรงนี้ได้เลย หรือจะรอทำแยกก็ได้
    # update_daily_summary(db, user_id, db_meal.meal_time.date()) 

    return db_meal
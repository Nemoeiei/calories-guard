from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import schemas, database, crud, models, oauth2

router = APIRouter(
    prefix="/meals",
    tags=["Meals & Food Logging"]
)

# API: บันทึกมื้ออาหาร (Log Food)
@router.post("/log", status_code=status.HTTP_201_CREATED) # response_model อาจจะซับซ้อน ใส่ไว้ทีหลังได้
def log_meal(
    meal: schemas.MealCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(oauth2.get_current_user)
):
    # ส่ง user_id จาก token ไปให้ CRUD
    return crud.create_meal_log(db=db, meal_data=meal, user_id=current_user.user_id)

# API: ดึงประวัติการกินของ "วันนี้" (แถมให้)
@router.get("/today")
def get_today_meals(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(oauth2.get_current_user)
):
    # Logic ง่ายๆ ดึงจาก Table meals
    from datetime import date
    today = date.today()
    
    meals = db.query(models.Meal).filter(
        models.Meal.user_id == current_user.user_id,
        func.date(models.Meal.meal_time) == today
    ).all()
    return meals
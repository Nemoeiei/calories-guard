"""
Meal Logging Routes
Handles meal creation, updates, and daily tracking
"""
from fastapi import APIRouter, HTTPException, status, Depends
from datetime import date
from sqlalchemy.orm import Session
from app.schemas.meal_schemas import (
    MealCreate, MealResponse, MealItemCreate, DailySummaryResponse,
    WeightLogCreate, WeightLogResponse
)
from app.crud.meal_crud import MealCRUD
from app.security.dependencies import get_current_user
from app.core.database import get_db

router = APIRouter(prefix="/meals", tags=["Meals"])

@router.post("/log", response_model=MealResponse)
async def log_meal(
    meal_data: MealCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Log a meal with food items
    Requires authentication
    """
    try:
        # Create meal
        meal = MealCRUD.create_meal(
            db=db,
            user_id=user_id,
            meal_type=meal_data.meal_type.value,
            meal_time=meal_data.meal_time
        )
        
        if not meal:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create meal"
            )
        
        # Add meal items
        for item in meal_data.items:
            MealCRUD.add_meal_item(
                db=db,
                meal_id=meal.meal_id,
                food_id=item.food_id,
                amount=item.amount,
                unit_id=item.unit_id,
                note=item.note
            )
        
        # Update daily summary
        MealCRUD.update_daily_summary(db, user_id, date.today())
        
        # Refresh meal to get items and populated fields
        db.refresh(meal)
        
        # Compute totals (Pydantic model expects these if modeled, or we add them)
        # Note: In ORM, 'items' is a relationship.
        
        # Helper to compute totals (could be a method on Meal model)
        total_calories = sum(i.cal_per_unit * i.amount for i in meal.items)
        total_protein = sum(i.protein_per_unit * i.amount for i in meal.items)
        total_carbs = sum(i.carbs_per_unit * i.amount for i in meal.items)
        total_fat = sum(i.fat_per_unit * i.amount for i in meal.items)
        
        # We can construct the response or let Pydantic handle it if properties exist.
        # Since standard Pydantic from ORM won't compute these unless we add properties to the model or intermediate dict.
        # I'll create a response object.
        
        response_data = MealResponse.model_validate(meal)
        response_data.total_calories = total_calories # These are not stuck on the ORM object automatically unless hybrid_property
        response_data.total_protein = total_protein
        response_data.total_carbs = total_carbs
        response_data.total_fat = total_fat
        
        return response_data
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/by-date", response_model=list[MealResponse])
async def get_meals_by_date(
    date_str: date,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all meals for a specific date
    Requires authentication
    """
    try:
        meals = MealCRUD.get_user_meals_by_date(db, user_id, date_str)
        
        response_list = []
        for meal in meals:
            # Manual computation for response
            resp = MealResponse.model_validate(meal)
            resp.total_calories = sum(i.cal_per_unit * i.amount for i in meal.items)
            resp.total_protein = sum(i.protein_per_unit * i.amount for i in meal.items)
            resp.total_carbs = sum(i.carbs_per_unit * i.amount for i in meal.items)
            resp.total_fat = sum(i.fat_per_unit * i.amount for i in meal.items)
            response_list.append(resp)
            
        return response_list
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{meal_id}", response_model=MealResponse)
async def get_meal(meal_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Get meal details by ID
    Requires authentication
    """
    try:
        meal = MealCRUD.get_meal_by_id(db, meal_id)
        
        if not meal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found"
            )
        
        # Verify ownership
        if meal.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view this meal"
            )
        
        resp = MealResponse.model_validate(meal)
        resp.total_calories = sum(i.cal_per_unit * i.amount for i in meal.items)
        resp.total_protein = sum(i.protein_per_unit * i.amount for i in meal.items)
        resp.total_carbs = sum(i.carbs_per_unit * i.amount for i in meal.items)
        resp.total_fat = sum(i.fat_per_unit * i.amount for i in meal.items)
        
        return resp
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{meal_id}")
async def delete_meal(meal_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Delete meal entry
    Requires authentication
    """
    try:
        meal = MealCRUD.get_meal_by_id(db, meal_id)
        
        if not meal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found"
            )
        
        if meal.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this meal"
            )
        
        MealCRUD.delete_meal(db, meal_id)
        MealCRUD.update_daily_summary(db, user_id, date.today())
        
        return {"message": "Meal deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/summary/{date_str}", response_model=DailySummaryResponse)
async def get_daily_summary(
    date_str: date,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get daily summary for a specific date
    Requires authentication
    """
    try:
        summary = MealCRUD.get_daily_summary(db, user_id, date_str)
        return summary
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/weight", response_model=WeightLogResponse)
async def log_weight(
    weight_data: WeightLogCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Log weight measurement
    Requires authentication
    """
    try:
        weight_log = MealCRUD.log_weight(
            db=db,
            user_id=user_id,
            weight_kg=weight_data.weight_kg,
            recorded_date=weight_data.recorded_date
        )
        
        if not weight_log:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to log weight"
            )
        
        return weight_log
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/weight/history/{limit}")
async def get_weight_history(
    limit: int = 30,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get weight history
    Requires authentication
    """
    try:
        history = MealCRUD.get_weight_history(db, user_id, limit)
        return history
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

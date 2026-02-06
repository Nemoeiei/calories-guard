"""
Pydantic Schemas for Meals and Food Logging
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from enum import Enum

class MealType(str, Enum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"
    snack = "snack"

# ==================== MEAL ITEM SCHEMAS ====================
class MealItemCreate(BaseModel):
    """Create meal item schema"""
    food_id: int
    amount: float = Field(default=1.0, gt=0)
    unit_id: Optional[int] = None
    note: Optional[str] = None

class MealItemResponse(BaseModel):
    """Meal item response schema"""
    item_id: int
    food_id: int
    food_name: Optional[str] = None
    amount: Optional[float] = 0.0
    unit_id: Optional[int] = None
    cal_per_unit: Optional[float] = 0.0
    protein_per_unit: Optional[float] = 0.0
    carbs_per_unit: Optional[float] = 0.0
    fat_per_unit: Optional[float] = 0.0
    note: Optional[str] = None
    
    # We might need to compute totals in the application or DB view
    
    class Config:
        from_attributes = True

# ==================== MEAL SCHEMAS ====================
class MealCreate(BaseModel):
    """Create meal schema"""
    meal_type: MealType
    meal_time: Optional[datetime] = None
    items: List[MealItemCreate]

class MealUpdate(BaseModel):
    """Update meal schema"""
    meal_type: Optional[MealType] = None
    meal_time: Optional[datetime] = None
    items: Optional[List[MealItemCreate]] = None

class MealResponse(BaseModel):
    """Meal response schema"""
    meal_id: int
    user_id: int
    meal_type: Optional[MealType] = None
    meal_time: Optional[datetime] = None
    total_amount: Optional[float] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    items: List[MealItemResponse] = []
    
    class Config:
        from_attributes = True

# ==================== DAILY SUMMARY SCHEMAS ====================
class DailySummaryResponse(BaseModel):
    """Daily summary response schema"""
    summary_id: int
    user_id: int
    date_record: Optional[date]
    water_intake_glasses: Optional[int] = 0
    total_calories_intake: Optional[float] = 0.0
    total_protein: Optional[float] = 0.0
    total_carbs: Optional[float] = 0.0
    total_fat: Optional[float] = 0.0
    goal_calories: Optional[int] = None
    is_goal_met: Optional[bool] = False
    
    class Config:
        from_attributes = True

class DailySummaryUpdate(BaseModel):
    """Update daily summary"""
    water_intake_glasses: Optional[int] = None
    goal_calories: Optional[int] = None

# ==================== WEIGHT LOG SCHEMAS ====================
class WeightLogCreate(BaseModel):
    """Create weight log schema"""
    weight_kg: float = Field(..., gt=0, le=500)
    recorded_date: Optional[date] = None

class WeightLogResponse(BaseModel):
    """Weight log response schema"""
    log_id: int
    user_id: int
    weight_kg: Optional[float]
    recorded_date: Optional[date]
    
    class Config:
        from_attributes = True

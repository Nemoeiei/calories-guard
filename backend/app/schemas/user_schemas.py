"""
Pydantic Schemas for Users and Authentication
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date, datetime
from enum import Enum

# ==================== ENUMS ====================
class GoalType(str, Enum):
    lose_weight = "lose_weight"
    maintain_weight = "maintain_weight"
    gain_muscle = "gain_muscle"

class ActivityLevel(str, Enum):
    sedentary = "sedentary"
    lightly_active = "lightly_active"
    moderately_active = "moderately_active"
    very_active = "very_active"

class GenderType(str, Enum):
    male = "male"
    female = "female"

# ==================== AUTH SCHEMAS ====================
class UserRegister(BaseModel):
    """User registration schema"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    username: str = Field(..., min_length=3, max_length=100)

class UserLogin(BaseModel):
    """User login schema"""
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    """JWT token response"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    user_id: int

class TokenRefresh(BaseModel):
    """Refresh token request"""
    refresh_token: str

# ==================== USER PROFILE SCHEMAS ====================
class UserProfileUpdate(BaseModel):
    """User profile update schema"""
    username: Optional[str] = Field(None, max_length=100)
    gender: Optional[GenderType] = None
    birth_date: Optional[date] = None
    height_cm: Optional[float] = Field(None, gt=0, le=300)
    current_weight_kg: Optional[float] = Field(None, gt=0, le=500)
    goal_type: Optional[GoalType] = None
    target_weight_kg: Optional[float] = Field(None, gt=0, le=500)
    target_calories: Optional[int] = Field(None, gt=0, le=10000)
    activity_level: Optional[ActivityLevel] = None
    goal_target_date: Optional[date] = None
    avatar_url: Optional[str] = None

class UserResponse(BaseModel):
    """User response schema"""
    user_id: int
    email: str
    username: Optional[str] = None # Added Optional as it might be null in DB
    gender: Optional[GenderType] = None
    birth_date: Optional[date] = None
    height_cm: Optional[float] = None
    current_weight_kg: Optional[float] = None
    goal_type: Optional[GoalType] = None
    target_weight_kg: Optional[float] = None
    target_calories: Optional[int] = None
    activity_level: Optional[ActivityLevel] = None
    goal_start_date: Optional[date] = None
    goal_target_date: Optional[date] = None
    current_streak: Optional[int] = 0
    avatar_url: Optional[str] = None
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class UserStatsResponse(BaseModel):
    """User statistics response"""
    stat_id: int
    user_id: int
    date_logged: Optional[date]
    weight_kg: Optional[float]
    height_cm: Optional[float]
    activity_level: Optional[ActivityLevel] = None
    bmi: Optional[float]
    bmr: Optional[float]
    tdee: Optional[float]
    created_at: Optional[datetime]
    
    class Config:
        from_attributes = True

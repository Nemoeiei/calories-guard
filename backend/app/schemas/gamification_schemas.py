"""
Pydantic Schemas for Gamification
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class CriteriaType(str, Enum):
    streak = "streak"
    meals_logged = "meals_logged"
    goal_met_days = "goal_met_days"
    weight_loss = "weight_loss"
    custom = "custom"

# ==================== ACHIEVEMENT SCHEMAS ====================
class AchievementCreate(BaseModel):
    """Create achievement schema"""
    name: str = Field(..., max_length=100)
    description: Optional[str] = Field(None, max_length=255)
    icon_url: Optional[str] = None
    criteria_type: CriteriaType
    criteria_value: int = Field(..., gt=0)

class AchievementUpdate(BaseModel):
    """Update achievement schema"""
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=255)
    icon_url: Optional[str] = None
    criteria_type: Optional[CriteriaType] = None
    criteria_value: Optional[int] = Field(None, gt=0)

class AchievementResponse(BaseModel):
    """Achievement response schema"""
    achievement_id: int
    name: str
    description: Optional[str]
    icon_url: Optional[str]
    criteria_type: str
    criteria_value: int
    
    class Config:
        from_attributes = True

# ==================== USER ACHIEVEMENT SCHEMAS ====================
class UserAchievementCreate(BaseModel):
    """Award achievement to user"""
    user_id: int
    achievement_id: int

class UserAchievementResponse(BaseModel):
    """User achievement response"""
    id: int
    user_id: int
    achievement_id: int
    achievement_name: str
    achievement_icon_url: Optional[str]
    earned_at: datetime
    
    class Config:
        from_attributes = True

# ==================== GAMIFICATION STATS ====================
class GamificationStatsResponse(BaseModel):
    """Gamification statistics response"""
    user_id: int
    current_streak: int
    total_achievements: int
    last_login_date: Optional[datetime]
    total_login_days: int
    achievements: list[AchievementResponse]
    
    class Config:
        from_attributes = True

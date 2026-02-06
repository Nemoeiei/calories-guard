"""
Pydantic Schemas for Content Management
"""
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional
from datetime import datetime
from enum import Enum

class ContentType(str, Enum):
    article = "article"
    video = "video"

class DifficultyLevel(str, Enum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"

# ==================== HEALTH CONTENT SCHEMAS ====================
class HealthContentCreate(BaseModel):
    """Create health content schema"""
    title: str = Field(..., max_length=255)
    type: ContentType
    thumbnail_url: Optional[str] = None
    resource_url: Optional[str] = None
    description: Optional[str] = None
    category_tag: Optional[str] = None
    difficulty_level: Optional[DifficultyLevel] = None
    is_published: bool = True

class HealthContentUpdate(BaseModel):
    """Update health content schema"""
    title: Optional[str] = Field(None, max_length=255)
    type: Optional[ContentType] = None
    thumbnail_url: Optional[str] = None
    resource_url: Optional[str] = None
    description: Optional[str] = None
    category_tag: Optional[str] = None
    difficulty_level: Optional[DifficultyLevel] = None
    is_published: Optional[bool] = None

class HealthContentResponse(BaseModel):
    """Health content response schema"""
    content_id: int
    title: str
    type: str
    thumbnail_url: Optional[str]
    resource_url: Optional[str]
    description: Optional[str]
    category_tag: Optional[str]
    difficulty_level: Optional[str]
    is_published: bool
    created_at: datetime
    view_count: int  # Computed
    saved_count: int  # Computed
    
    class Config:
        from_attributes = True

# ==================== USER SAVED CONTENT ====================
class UserSavedContentCreate(BaseModel):
    """Save content schema"""
    content_id: int

class UserSavedContentResponse(BaseModel):
    """User saved content response"""
    id: int
    user_id: int
    content_id: int
    content_title: str
    content_type: str
    thumbnail_url: Optional[str]
    saved_at: datetime
    
    class Config:
        from_attributes = True

# ==================== CONTENT VIEW LOG ====================
class ContentViewLogResponse(BaseModel):
    """Content view log response"""
    log_id: int
    user_id: int
    content_id: int
    content_title: str
    viewed_at: datetime
    
    class Config:
        from_attributes = True

# ==================== CONTENT RECOMMENDATION ====================
class ContentRecommendationResponse(BaseModel):
    """Content recommendation response"""
    content_id: int
    title: str
    type: str
    description: Optional[str]
    thumbnail_url: Optional[str]
    category_tag: Optional[str]
    difficulty_level: Optional[str]
    reason: str  # Why this content is recommended
    
    class Config:
        from_attributes = True

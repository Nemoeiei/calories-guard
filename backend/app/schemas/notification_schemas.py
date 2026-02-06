"""
Pydantic Schemas for Notifications
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class NotificationType(str, Enum):
    system_alert = "system_alert"
    achievement = "achievement"
    content_update = "content_update"

# ==================== NOTIFICATION SCHEMAS ====================
class NotificationCreate(BaseModel):
    """Create notification schema"""
    user_id: int
    title: str = Field(..., max_length=255)
    message: Optional[str] = None
    type: NotificationType
    action_url: Optional[str] = None
    reference_id: Optional[int] = None

class NotificationUpdate(BaseModel):
    """Update notification schema"""
    is_read: Optional[bool] = None

class NotificationResponse(BaseModel):
    """Notification response schema"""
    notification_id: int
    user_id: int
    title: str
    message: Optional[str]
    type: str
    action_url: Optional[str]
    reference_id: Optional[int]
    is_read: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ==================== ANNOUNCEMENT SCHEMAS ====================
class SystemAnnouncementCreate(BaseModel):
    """Create system announcement schema"""
    title: str = Field(..., max_length=255)
    message: Optional[str] = None
    image_url: Optional[str] = None
    target_role: Optional[str] = None
    is_active: bool = True

class SystemAnnouncementUpdate(BaseModel):
    """Update announcement schema"""
    title: Optional[str] = Field(None, max_length=255)
    message: Optional[str] = None
    image_url: Optional[str] = None
    target_role: Optional[str] = None
    is_active: Optional[bool] = None

class SystemAnnouncementResponse(BaseModel):
    """System announcement response"""
    announcement_id: int
    title: str
    message: Optional[str]
    image_url: Optional[str]
    target_role: Optional[str]
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

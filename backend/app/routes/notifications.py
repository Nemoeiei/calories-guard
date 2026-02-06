"""
Notification Routes
Manages user notifications and announcements
"""
from fastapi import APIRouter, HTTPException, status, Depends, Query
from app.schemas.notification_schemas import (
    NotificationResponse, NotificationUpdate, SystemAnnouncementResponse
)
from app.crud.notification_crud import NotificationCRUD, AnnouncementCRUD
from app.security.dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("/", response_model=list[NotificationResponse])
async def get_notifications(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    unread_only: bool = Query(False),
    user_id: int = Depends(get_current_user)
):
    """
    Get user notifications
    Requires authentication
    
    - **skip**: Number of records to skip
    - **limit**: Number of records to return
    - **unread_only**: Filter only unread notifications
    """
    try:
        notifications = NotificationCRUD.get_user_notifications(
            user_id=user_id,
            skip=skip,
            limit=limit,
            unread_only=unread_only
        )
        return notifications
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/unread-count")
async def get_unread_count(user_id: int = Depends(get_current_user)):
    """
    Get count of unread notifications
    Requires authentication
    """
    try:
        count = NotificationCRUD.get_unread_count(user_id)
        return {"unread_count": count}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/{notification_id}/read", response_model=dict)
async def mark_as_read(
    notification_id: int,
    user_id: int = Depends(get_current_user)
):
    """
    Mark notification as read
    Requires authentication
    """
    try:
        NotificationCRUD.mark_as_read(notification_id)
        return {"message": "Marked as read"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/read-all")
async def mark_all_as_read(user_id: int = Depends(get_current_user)):
    """
    Mark all notifications as read
    Requires authentication
    """
    try:
        NotificationCRUD.mark_all_as_read(user_id)
        return {"message": "All notifications marked as read"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: int,
    user_id: int = Depends(get_current_user)
):
    """
    Delete notification
    Requires authentication
    """
    try:
        NotificationCRUD.delete_notification(notification_id)
        return {"message": "Notification deleted"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/announcements", response_model=list[SystemAnnouncementResponse])
async def get_announcements():
    """
    Get active system announcements
    """
    try:
        announcements = AnnouncementCRUD.get_active_announcements()
        return announcements
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/announcements/{announcement_id}/read")
async def mark_announcement_read(
    announcement_id: int,
    user_id: int = Depends(get_current_user)
):
    """
    Mark announcement as read by user
    Requires authentication
    """
    try:
        AnnouncementCRUD.mark_announcement_as_read(user_id, announcement_id)
        return {"message": "Announcement marked as read"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

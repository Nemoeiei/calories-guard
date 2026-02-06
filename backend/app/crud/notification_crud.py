"""CRUD operations for Notifications and Announcements"""
from typing import Optional, List
from app.core.database import get_db

class NotificationCRUD:
    """CRUD operations for Notifications"""
    
    db = get_db()
    
    @staticmethod
    def create_notification(user_id: int, title: str, message: str = None,
                           notification_type: str = "system_alert", 
                           action_url: str = None, reference_id: int = None) -> Optional[dict]:
        """Create notification"""
        try:
            return NotificationCRUD.db.execute_insert_returning(
                """
                INSERT INTO notifications 
                (user_id, title, message, type, action_url, reference_id)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING notification_id, user_id, title, message, type, 
                          action_url, reference_id, is_read, created_at, updated_at
                """,
                (user_id, title, message, notification_type, action_url, reference_id)
            )
        except Exception as e:
            raise Exception(f"Error creating notification: {e}")
    
    @staticmethod
    def get_user_notifications(user_id: int, skip: int = 0, limit: int = 50, 
                              unread_only: bool = False) -> List[dict]:
        """Get user notifications"""
        try:
            query = """
                SELECT notification_id, user_id, title, message, type, action_url,
                       reference_id, is_read, created_at, updated_at
                FROM notifications
                WHERE user_id = %s
            """
            params = [user_id]
            
            if unread_only:
                query += " AND is_read = FALSE"
            
            query += " ORDER BY created_at DESC LIMIT %s OFFSET %s"
            params.extend([limit, skip])
            
            return NotificationCRUD.db.execute_query(query, tuple(params))
        except Exception as e:
            raise Exception(f"Error fetching notifications: {e}")
    
    @staticmethod
    def mark_as_read(notification_id: int) -> bool:
        """Mark notification as read"""
        try:
            NotificationCRUD.db.execute_update(
                """
                UPDATE notifications
                SET is_read = TRUE, updated_at = NOW()
                WHERE notification_id = %s
                """,
                (notification_id,)
            )
            return True
        except Exception as e:
            raise Exception(f"Error marking notification as read: {e}")
    
    @staticmethod
    def mark_all_as_read(user_id: int) -> bool:
        """Mark all user notifications as read"""
        try:
            NotificationCRUD.db.execute_update(
                """
                UPDATE notifications
                SET is_read = TRUE, updated_at = NOW()
                WHERE user_id = %s AND is_read = FALSE
                """,
                (user_id,)
            )
            return True
        except Exception as e:
            raise Exception(f"Error marking all notifications as read: {e}")
    
    @staticmethod
    def delete_notification(notification_id: int) -> bool:
        """Delete notification"""
        try:
            NotificationCRUD.db.execute_update(
                "DELETE FROM notifications WHERE notification_id = %s",
                (notification_id,)
            )
            return True
        except Exception as e:
            raise Exception(f"Error deleting notification: {e}")
    
    @staticmethod
    def get_unread_count(user_id: int) -> int:
        """Get unread notification count"""
        try:
            result = NotificationCRUD.db.execute_single(
                """
                SELECT COUNT(*) as count FROM notifications
                WHERE user_id = %s AND is_read = FALSE
                """,
                (user_id,)
            )
            return result['count'] if result else 0
        except Exception as e:
            raise Exception(f"Error counting unread: {e}")

class AnnouncementCRUD:
    """CRUD operations for System Announcements"""
    
    db = get_db()
    
    @staticmethod
    def create_announcement(title: str, message: str = None, image_url: str = None,
                           target_role: str = None, is_active: bool = True) -> Optional[dict]:
        """Create system announcement"""
        try:
            return AnnouncementCRUD.db.execute_insert_returning(
                """
                INSERT INTO system_announcements 
                (title, message, image_url, target_role, is_active)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING announcement_id, title, message, image_url, 
                          target_role, is_active, created_at
                """,
                (title, message, image_url, target_role, is_active)
            )
        except Exception as e:
            raise Exception(f"Error creating announcement: {e}")
    
    @staticmethod
    def get_active_announcements() -> List[dict]:
        """Get all active announcements"""
        try:
            return AnnouncementCRUD.db.execute_query(
                """
                SELECT announcement_id, title, message, image_url, target_role, 
                       is_active, created_at
                FROM system_announcements
                WHERE is_active = TRUE
                ORDER BY created_at DESC
                """
            )
        except Exception as e:
            raise Exception(f"Error fetching announcements: {e}")
    
    @staticmethod
    def mark_announcement_as_read(user_id: int, announcement_id: int) -> bool:
        """Mark announcement as read by user"""
        try:
            # Check if already read
            existing = AnnouncementCRUD.db.execute_single(
                """
                SELECT * FROM user_read_announcements
                WHERE user_id = %s AND announcement_id = %s
                """,
                (user_id, announcement_id)
            )
            
            if not existing:
                AnnouncementCRUD.db.execute_update(
                    """
                    INSERT INTO user_read_announcements (user_id, announcement_id)
                    VALUES (%s, %s)
                    """,
                    (user_id, announcement_id)
                )
            
            return True
        except Exception as e:
            raise Exception(f"Error marking announcement as read: {e}")

"""CRUD operations for Content Management"""
from typing import Optional, List
from app.core.database import get_db

class ContentCRUD:
    """CRUD operations for Health Content"""
    
    db = get_db()
    
    @staticmethod
    def create_content(title: str, content_type: str, thumbnail_url: str = None,
                      resource_url: str = None, description: str = None,
                      category_tag: str = None, difficulty_level: str = None,
                      is_published: bool = True) -> Optional[dict]:
        """Create health content"""
        try:
            return ContentCRUD.db.execute_insert_returning(
                """
                INSERT INTO health_contents 
                (title, type, thumbnail_url, resource_url, description, 
                 category_tag, difficulty_level, is_published)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING content_id, title, type, thumbnail_url, resource_url,
                          description, category_tag, difficulty_level, is_published,
                          created_at
                """,
                (title, content_type, thumbnail_url, resource_url, description,
                 category_tag, difficulty_level, is_published)
            )
        except Exception as e:
            raise Exception(f"Error creating content: {e}")
    
    @staticmethod
    def get_content_by_id(content_id: int) -> Optional[dict]:
        """Get content by ID"""
        try:
            content = ContentCRUD.db.execute_single(
                """
                SELECT content_id, title, type, thumbnail_url, resource_url,
                       description, category_tag, difficulty_level, is_published,
                       created_at
                FROM health_contents
                WHERE content_id = %s AND is_published = TRUE
                """,
                (content_id,)
            )
            
            if content:
                # Log view
                ContentCRUD.db.execute_update(
                    """
                    INSERT INTO content_view_logs (content_id, viewed_at)
                    VALUES (%s, NOW())
                    """,
                    (content_id,)
                )
                
                # Get view count
                view_count = ContentCRUD.db.execute_single(
                    """
                    SELECT COUNT(*) as count FROM content_view_logs
                    WHERE content_id = %s
                    """,
                    (content_id,)
                )
                content['view_count'] = view_count['count'] if view_count else 0
            
            return content
        except Exception as e:
            raise Exception(f"Error fetching content: {e}")
    
    @staticmethod
    def get_all_published_content(skip: int = 0, limit: int = 20) -> List[dict]:
        """Get all published content"""
        try:
            contents = ContentCRUD.db.execute_query(
                """
                SELECT content_id, title, type, thumbnail_url, resource_url,
                       description, category_tag, difficulty_level, created_at
                FROM health_contents
                WHERE is_published = TRUE
                ORDER BY created_at DESC
                LIMIT %s OFFSET %s
                """,
                (limit, skip)
            )
            
            for content in contents:
                view_count = ContentCRUD.db.execute_single(
                    """
                    SELECT COUNT(*) as count FROM content_view_logs
                    WHERE content_id = %s
                    """,
                    (content['content_id'],)
                )
                content['view_count'] = view_count['count'] if view_count else 0
            
            return contents
        except Exception as e:
            raise Exception(f"Error fetching published content: {e}")
    
    @staticmethod
    def search_content(query: str, limit: int = 20) -> List[dict]:
        """Search content by title or description"""
        try:
            contents = ContentCRUD.db.execute_query(
                """
                SELECT content_id, title, type, thumbnail_url, resource_url,
                       description, category_tag, difficulty_level, created_at
                FROM health_contents
                WHERE (title ILIKE %s OR description ILIKE %s) AND is_published = TRUE
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (f"%{query}%", f"%{query}%", limit)
            )
            
            for content in contents:
                view_count = ContentCRUD.db.execute_single(
                    """
                    SELECT COUNT(*) as count FROM content_view_logs
                    WHERE content_id = %s
                    """,
                    (content['content_id'],)
                )
                content['view_count'] = view_count['count'] if view_count else 0
            
            return contents
        except Exception as e:
            raise Exception(f"Error searching content: {e}")
    
    @staticmethod
    def get_content_by_category(category_tag: str, skip: int = 0, limit: int = 20) -> List[dict]:
        """Get content by category"""
        try:
            contents = ContentCRUD.db.execute_query(
                """
                SELECT content_id, title, type, thumbnail_url, resource_url,
                       description, category_tag, difficulty_level, created_at
                FROM health_contents
                WHERE category_tag = %s AND is_published = TRUE
                ORDER BY created_at DESC
                LIMIT %s OFFSET %s
                """,
                (category_tag, limit, skip)
            )
            
            for content in contents:
                view_count = ContentCRUD.db.execute_single(
                    """
                    SELECT COUNT(*) as count FROM content_view_logs
                    WHERE content_id = %s
                    """,
                    (content['content_id'],)
                )
                content['view_count'] = view_count['count'] if view_count else 0
            
            return contents
        except Exception as e:
            raise Exception(f"Error fetching content by category: {e}")
    
    @staticmethod
    def update_content(content_id: int, **kwargs) -> Optional[dict]:
        """Update content"""
        try:
            fields = []
            params = []
            
            allowed_fields = ['title', 'type', 'thumbnail_url', 'resource_url',
                             'description', 'category_tag', 'difficulty_level', 'is_published']
            
            for field, value in kwargs.items():
                if field in allowed_fields and value is not None:
                    fields.append(f"{field} = %s")
                    params.append(value)
            
            if not fields:
                return ContentCRUD.get_content_by_id(content_id)
            
            params.append(content_id)
            
            query = f"""
                UPDATE health_contents
                SET {', '.join(fields)}
                WHERE content_id = %s
                RETURNING content_id, title, type, thumbnail_url, resource_url,
                          description, category_tag, difficulty_level, is_published,
                          created_at
            """
            
            return ContentCRUD.db.execute_insert_returning(query, tuple(params))
        except Exception as e:
            raise Exception(f"Error updating content: {e}")
    
    @staticmethod
    def save_content(user_id: int, content_id: int) -> Optional[dict]:
        """Save content for user"""
        try:
            # Check if already saved
            existing = ContentCRUD.db.execute_single(
                """
                SELECT id FROM user_saved_contents
                WHERE user_id = %s AND content_id = %s
                """,
                (user_id, content_id)
            )
            
            if existing:
                return {"message": "Already saved"}
            
            return ContentCRUD.db.execute_insert_returning(
                """
                INSERT INTO user_saved_contents (user_id, content_id)
                VALUES (%s, %s)
                RETURNING id, user_id, content_id, saved_at
                """,
                (user_id, content_id)
            )
        except Exception as e:
            raise Exception(f"Error saving content: {e}")
    
    @staticmethod
    def unsave_content(user_id: int, content_id: int) -> bool:
        """Unsave content for user"""
        try:
            ContentCRUD.db.execute_update(
                """
                DELETE FROM user_saved_contents
                WHERE user_id = %s AND content_id = %s
                """,
                (user_id, content_id)
            )
            return True
        except Exception as e:
            raise Exception(f"Error unsaving content: {e}")
    
    @staticmethod
    def get_user_saved_content(user_id: int, skip: int = 0, limit: int = 20) -> List[dict]:
        """Get user's saved content"""
        try:
            return ContentCRUD.db.execute_query(
                """
                SELECT hc.content_id, hc.title, hc.type, hc.thumbnail_url,
                       hc.description, hc.category_tag, hc.difficulty_level,
                       usc.saved_at
                FROM user_saved_contents usc
                JOIN health_contents hc ON usc.content_id = hc.content_id
                WHERE usc.user_id = %s AND hc.is_published = TRUE
                ORDER BY usc.saved_at DESC
                LIMIT %s OFFSET %s
                """,
                (user_id, limit, skip)
            )
        except Exception as e:
            raise Exception(f"Error fetching saved content: {e}")
    
    @staticmethod
    def log_content_view(user_id: int, content_id: int) -> bool:
        """Log content view"""
        try:
            ContentCRUD.db.execute_update(
                """
                INSERT INTO content_view_logs (user_id, content_id, viewed_at)
                VALUES (%s, %s, NOW())
                """,
                (user_id, content_id)
            )
            return True
        except Exception as e:
            raise Exception(f"Error logging content view: {e}")
    
    @staticmethod
    def get_popular_content(limit: int = 10) -> List[dict]:
        """Get most viewed content"""
        try:
            return ContentCRUD.db.execute_query(
                """
                SELECT hc.content_id, hc.title, hc.type, hc.thumbnail_url,
                       hc.description, hc.category_tag, hc.difficulty_level,
                       COUNT(cvl.log_id) as view_count
                FROM health_contents hc
                LEFT JOIN content_view_logs cvl ON hc.content_id = cvl.content_id
                WHERE hc.is_published = TRUE
                GROUP BY hc.content_id
                ORDER BY view_count DESC
                LIMIT %s
                """,
                (limit,)
            )
        except Exception as e:
            raise Exception(f"Error fetching popular content: {e}")

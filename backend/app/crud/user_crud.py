"""CRUD operations for Users"""
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.models import User, UserStat, Role, DailySummary
from app.security.security import security_manager
from app.schemas.user_schemas import UserProfileUpdate

class UserCRUD:
    """CRUD operations for User management"""
    
    @staticmethod
    def create_user(db: Session, email: str, password: str, username: str) -> User:
        """Create new user account"""
        try:
            hashed_password = security_manager.get_password_hash(password)
            
            # Create User
            db_user = User(
                email=email,
                password_hash=hashed_password,
                username=username,
                role_id=2 # Default role
            )
            db.add(db_user)
            db.flush() # To get user_id
            
            # Initialize Stats
            db_stats = UserStat(user_id=db_user.user_id, date_logged=func.current_date())
            db.add(db_stats)
            
            db.commit()
            db.refresh(db_user)
            return db_user
            
        except Exception as e:
            db.rollback()
            raise Exception(f"Error creating user: {e}")
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email, User.deleted_at.is_(None)).first()
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.user_id == user_id, User.deleted_at.is_(None)).first()
    
    @staticmethod
    def update_user_profile(db: Session, user_id: int, updates: UserProfileUpdate) -> Optional[User]:
        """Update user profile"""
        try:
            user = UserCRUD.get_user_by_id(db, user_id)
            if not user:
                return None
            
            update_data = updates.model_dump(exclude_unset=True)
            
            # Enums need to be handled if Pydantic doesn't map them directly to DB Enum objects?
            # SQLAlchemy handles Python Enums correctly if defined in model.
            
            for key, value in update_data.items():
                setattr(user, key, value)
            
            db.commit()
            db.refresh(user)
            return user
        except Exception as e:
            db.rollback()
            raise Exception(f"Error updating user profile: {e}")
    
    @staticmethod
    def get_user_stats(db: Session, user_id: int) -> Optional[UserStat]:
        """Get user statistics for today"""
        return db.query(UserStat).filter(
            UserStat.user_id == user_id, 
            UserStat.date_logged == func.current_date()
        ).first()
    
    @staticmethod
    def update_user_stats(db: Session, user_id: int, weight_kg: float = None, 
                         height_cm: float = None, bmi: float = None,
                         bmr: float = None, tdee: float = None) -> UserStat:
        """Update user stats for today"""
        try:
            stats = UserCRUD.get_user_stats(db, user_id)
            
            if not stats:
                stats = UserStat(user_id=user_id, date_logged=func.current_date())
                db.add(stats)
            
            if weight_kg is not None: stats.weight_kg = weight_kg
            if height_cm is not None: stats.height_cm = height_cm
            if bmi is not None: stats.bmi = bmi
            if bmr is not None: stats.bmr = bmr
            if tdee is not None: stats.tdee = tdee
            
            db.commit()
            db.refresh(stats)
            return stats
        except Exception as e:
            db.rollback()
            raise Exception(f"Error updating user stats: {e}")
    
    @staticmethod
    def increment_streak(db: Session, user_id: int) -> bool:
        """Increment user streak"""
        try:
            user = UserCRUD.get_user_by_id(db, user_id)
            if user:
                user.current_streak = (user.current_streak or 0) + 1
                user.last_login_date = func.current_date()
                user.total_login_days = (user.total_login_days or 0) + 1
                db.commit()
                return True
            return False
        except Exception as e:
            db.rollback()
            raise Exception(f"Error incrementing streak: {e}")

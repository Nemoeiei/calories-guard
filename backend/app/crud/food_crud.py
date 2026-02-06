"""CRUD operations for Foods"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.models import Food, FavoriteFood, UserAllergyPreference, AllergyFlag

class FoodCRUD:
    """CRUD operations for Food management"""
    
    @staticmethod
    def create_food(db: Session, food_name: str, food_type: str, calories: float = None,
                   protein: float = None, carbs: float = None, fat: float = None,
                   serving_quantity: float = 100, serving_unit: str = "g",
                   created_by_user_id: int = None, image_url: str = None) -> Food:
        """Create new food"""
        try:
            food = Food(
                food_name=food_name,
                food_type=food_type,
                calories=calories,
                protein=protein,
                carbs=carbs,
                fat=fat,
                serving_quantity=serving_quantity,
                serving_unit=serving_unit,
                created_by_user_id=created_by_user_id,
                image_url=image_url
            )
            db.add(food)
            db.commit()
            db.refresh(food)
            return food
        except Exception as e:
            db.rollback()
            raise Exception(f"Error creating food: {e}")
    
    @staticmethod
    def get_food_by_id(db: Session, food_id: int) -> Optional[Food]:
        """Get food by ID"""
        return db.query(Food).filter(Food.food_id == food_id, Food.deleted_at.is_(None)).first()
    
    @staticmethod
    def get_all_foods(db: Session, skip: int = 0, limit: int = 100) -> List[Food]:
        """Get all foods"""
        return db.query(Food).filter(Food.deleted_at.is_(None))\
                 .order_by(Food.food_name.asc())\
                 .offset(skip).limit(limit).all()
    
    @staticmethod
    def search_foods(db: Session, query: str, limit: int = 20) -> List[Food]:
        """Search foods by name"""
        search = f"%{query}%"
        return db.query(Food).filter(
            (Food.food_name.ilike(search)) | (Food.food_type.ilike(search)),
            Food.deleted_at.is_(None)
        ).order_by(Food.food_name.asc()).limit(limit).all()
    
    @staticmethod
    def update_food(db: Session, food_id: int, **kwargs) -> Optional[Food]:
        """Update food"""
        try:
            food = FoodCRUD.get_food_by_id(db, food_id)
            if not food:
                return None
            
            allowed_fields = ['food_name', 'food_type', 'calories', 'protein', 
                             'carbs', 'fat', 'sodium', 'sugar', 'cholesterol',
                             'serving_quantity', 'serving_unit', 'image_url']
            
            for field, value in kwargs.items():
                if field in allowed_fields and value is not None:
                    setattr(food, field, value)
            
            db.commit()
            db.refresh(food)
            return food
        except Exception as e:
            db.rollback()
            raise Exception(f"Error updating food: {e}")
    
    @staticmethod
    def delete_food(db: Session, food_id: int) -> bool:
        """Soft delete food"""
        try:
            food = FoodCRUD.get_food_by_id(db, food_id)
            if food:
                food.deleted_at = func.now()
                db.commit()
                return True
            return False
        except Exception as e:
            db.rollback()
            raise Exception(f"Error deleting food: {e}")
    
    @staticmethod
    def add_to_favorites(db: Session, user_id: int, food_id: int) -> Optional[FavoriteFood]:
        """Add food to favorites"""
        try:
            # Check if already favorited
            existing = db.query(FavoriteFood).filter(
                FavoriteFood.user_id == user_id, 
                FavoriteFood.food_id == food_id
            ).first()
            
            if existing:
                # Return existing but maybe raise or special return?
                # The original returned {"message": ...} dict, which is inconsistent with returning Model object.
                # I should handle this in Route or return None/Existing.
                # Let's return the existing object, Route handles logic.
                return existing 
            
            fav = FavoriteFood(user_id=user_id, food_id=food_id)
            db.add(fav)
            db.commit()
            db.refresh(fav)
            return fav
        except Exception as e:
            db.rollback()
            raise Exception(f"Error adding to favorites: {e}")
    
    @staticmethod
    def remove_from_favorites(db: Session, user_id: int, food_id: int) -> bool:
        """Remove food from favorites"""
        try:
            fav = db.query(FavoriteFood).filter(
                FavoriteFood.user_id == user_id, 
                FavoriteFood.food_id == food_id
            ).first()
            if fav:
                db.delete(fav)
                db.commit()
                return True
            return False
        except Exception as e:
            db.rollback()
            raise Exception(f"Error removing from favorites: {e}")
    
    @staticmethod
    def get_user_favorites(db: Session, user_id: int) -> List[Food]:
        """Get user's favorite foods"""
        # Join FavoriteFood -> Food
        return db.query(Food).join(FavoriteFood, Food.food_id == FavoriteFood.food_id)\
                 .filter(FavoriteFood.user_id == user_id, Food.deleted_at.is_(None))\
                 .order_by(Food.food_name.asc()).all()
    
    @staticmethod
    def add_allergy_preference(db: Session, user_id: int, flag_id: int, preference_type: str) -> UserAllergyPreference:
        """Add allergy or preference flag"""
        try:
            # Upsert logic
            pref = db.query(UserAllergyPreference).filter(
                UserAllergyPreference.user_id == user_id,
                UserAllergyPreference.flag_id == flag_id
            ).first()
            
            if pref:
                pref.preference_type = preference_type
            else:
                pref = UserAllergyPreference(
                    user_id=user_id,
                    flag_id=flag_id,
                    preference_type=preference_type
                )
                db.add(pref)
            
            db.commit()
            db.refresh(pref)
            return pref
        except Exception as e:
            db.rollback()
            raise Exception(f"Error adding allergy preference: {e}")
    
    @staticmethod
    def get_user_allergy_preferences(db: Session, user_id: int) -> List[UserAllergyPreference]:
        """Get user's allergy and preference flags"""
        return db.query(UserAllergyPreference).filter(UserAllergyPreference.user_id == user_id).all()
    
    @staticmethod
    def get_all_allergy_flags(db: Session) -> List[AllergyFlag]:
        """Get all available allergy flags"""
        return db.query(AllergyFlag).order_by(AllergyFlag.name.asc()).all()

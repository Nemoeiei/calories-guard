"""CRUD operations for Meals and Food Logging"""
from typing import Optional, List
from datetime import date, datetime
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from app.models.models import Meal, DetailItem, Food, DailySummary, User, WeightLog

class MealCRUD:
    """CRUD operations for Meal management"""
    
    @staticmethod
    def create_meal(db: Session, user_id: int, meal_type: str, meal_time: str = None) -> Meal:
        """Create new meal entry"""
        try:
            meal = Meal(
                user_id=user_id,
                meal_type=meal_type,
                meal_time=meal_time if meal_time else func.now()
            )
            db.add(meal)
            db.commit()
            db.refresh(meal)
            return meal
        except Exception as e:
            db.rollback()
            raise Exception(f"Error creating meal: {e}")
    
    @staticmethod
    def add_meal_item(db: Session, meal_id: int, food_id: int, amount: float, 
                     unit_id: int = None, note: str = None) -> DetailItem:
        """Add item to meal"""
        try:
            # Get food details
            food = db.query(Food).filter(Food.food_id == food_id).first()
            if not food:
                raise Exception("Food not found")
            
            # Use food nutrition as snapshot
            item = DetailItem(
                meal_id=meal_id,
                food_id=food_id,
                amount=amount,
                unit_id=unit_id,
                food_name=food.food_name,
                cal_per_unit=food.calories or 0,
                protein_per_unit=food.protein or 0,
                carbs_per_unit=food.carbs or 0,
                fat_per_unit=food.fat or 0,
                note=note
            )
            
            db.add(item)
            db.commit()
            db.refresh(item)
            return item
        except Exception as e:
            db.rollback()
            raise Exception(f"Error adding meal item: {e}")
    
    @staticmethod
    def get_meal_by_id(db: Session, meal_id: int) -> Optional[Meal]:
        """Get meal with all items"""
        return db.query(Meal).filter(Meal.meal_id == meal_id).first()
    
    @staticmethod
    def get_user_meals_by_date(db: Session, user_id: int, date_str: date) -> List[Meal]:
        """Get all meals for user on specific date"""
        return db.query(Meal).filter(
            Meal.user_id == user_id, 
            cast(Meal.meal_time, Date) == date_str
        ).order_by(Meal.meal_time.asc()).all()
    
    @staticmethod
    def delete_meal(db: Session, meal_id: int) -> bool:
        """Delete meal"""
        try:
            meal = db.query(Meal).filter(Meal.meal_id == meal_id).first()
            if meal:
                db.delete(meal)
                db.commit()
                return True
            return False
        except Exception as e:
            db.rollback()
            raise Exception(f"Error deleting meal: {e}")
            
    @staticmethod
    def get_daily_summary(db: Session, user_id: int, date_str: date) -> DailySummary:
        """Get daily summary for user, create if not exists"""
        try:
            summary = db.query(DailySummary).filter(
                DailySummary.user_id == user_id,
                DailySummary.date_record == date_str
            ).first()
            
            if not summary:
                # Create empty summary
                # Need to fetch target calories from user
                user = db.query(User).filter(User.user_id == user_id).first()
                target_cal = user.target_calories if user and user.target_calories else 2000
                
                summary = DailySummary(
                    user_id=user_id,
                    date_record=date_str,
                    goal_calories=target_cal
                )
                db.add(summary)
                db.commit()
                db.refresh(summary)
                
            return summary
        except Exception as e:
            if not summary: # Ensure session rollback if failed inside
                db.rollback()
            raise Exception(f"Error fetching daily summary: {e}")
    
    @staticmethod
    def update_daily_summary(db: Session, user_id: int, date_str: date) -> DailySummary:
        """Recalculate and update daily summary"""
        try:
            # 1. Calculate totals from meals
            # Join Meal -> DetailItem
            # Filter by user and date
            
            totals = db.query(
                func.sum(DetailItem.cal_per_unit * DetailItem.amount).label("total_calories"),
                func.sum(DetailItem.protein_per_unit * DetailItem.amount).label("total_protein"),
                func.sum(DetailItem.carbs_per_unit * DetailItem.amount).label("total_carbs"),
                func.sum(DetailItem.fat_per_unit * DetailItem.amount).label("total_fat")
            ).join(Meal, DetailItem.meal_id == Meal.meal_id)\
             .filter(Meal.user_id == user_id, cast(Meal.meal_time, Date) == date_str)\
             .first()
             
            total_cal = totals.total_calories or 0
            total_prot = totals.total_protein or 0
            total_carb = totals.total_carbs or 0
            total_fat = totals.total_fat or 0
            
            # 2. Get Summary or Create
            summary = MealCRUD.get_daily_summary(db, user_id, date_str)
            
            # 3. Update
            summary.total_calories_intake = total_cal
            summary.total_protein = total_prot
            summary.total_carbs = total_carb
            summary.total_fat = total_fat
            
            # Update goal met status
            summary.is_goal_met = (summary.total_calories_intake <= (summary.goal_calories or 2000))
            
            db.commit()
            db.refresh(summary)
            return summary
            
        except Exception as e:
            db.rollback()
            raise Exception(f"Error updating daily summary: {e}")
            
    @staticmethod
    def log_weight(db: Session, user_id: int, weight_kg: float, recorded_date: date = None) -> WeightLog:
        """Log weight"""
        try:
            log = WeightLog(
                user_id=user_id,
                weight_kg=weight_kg,
                recorded_date=recorded_date if recorded_date else date.today()
            )
            db.add(log)
            db.commit()
            db.refresh(log)
            return log
        except Exception as e:
            db.rollback()
            raise Exception(f"Error logging weight: {e}")

    @staticmethod
    def get_weight_history(db: Session, user_id: int, limit: int = 30) -> List[WeightLog]:
        return db.query(WeightLog).filter(WeightLog.user_id == user_id)\
                 .order_by(WeightLog.recorded_date.desc()).limit(limit).all()

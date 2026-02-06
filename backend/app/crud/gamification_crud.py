"""CRUD operations for Gamification"""
from typing import Optional, List
from app.core.database import get_db

class AchievementCRUD:
    """CRUD operations for Achievements and Gamification"""
    
    db = get_db()
    
    @staticmethod
    def create_achievement(name: str, description: str = None, icon_url: str = None,
                          criteria_type: str = "custom", criteria_value: int = 1) -> Optional[dict]:
        """Create new achievement"""
        try:
            return AchievementCRUD.db.execute_insert_returning(
                """
                INSERT INTO achievements 
                (name, description, icon_url, criteria_type, criteria_value)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING achievement_id, name, description, icon_url, 
                          criteria_type, criteria_value
                """,
                (name, description, icon_url, criteria_type, criteria_value)
            )
        except Exception as e:
            raise Exception(f"Error creating achievement: {e}")
    
    @staticmethod
    def get_all_achievements() -> List[dict]:
        """Get all achievements"""
        try:
            return AchievementCRUD.db.execute_query(
                """
                SELECT achievement_id, name, description, icon_url, 
                       criteria_type, criteria_value
                FROM achievements
                ORDER BY achievement_id ASC
                """
            )
        except Exception as e:
            raise Exception(f"Error fetching achievements: {e}")
    
    @staticmethod
    def award_achievement(user_id: int, achievement_id: int) -> Optional[dict]:
        """Award achievement to user"""
        try:
            # Check if already earned
            existing = AchievementCRUD.db.execute_single(
                """
                SELECT * FROM user_achievements
                WHERE user_id = %s AND achievement_id = %s
                """,
                (user_id, achievement_id)
            )
            
            if existing:
                return {"message": "Already earned this achievement"}
            
            return AchievementCRUD.db.execute_insert_returning(
                """
                INSERT INTO user_achievements (user_id, achievement_id)
                VALUES (%s, %s)
                RETURNING id, user_id, achievement_id, earned_at
                """,
                (user_id, achievement_id)
            )
        except Exception as e:
            raise Exception(f"Error awarding achievement: {e}")
    
    @staticmethod
    def get_user_achievements(user_id: int) -> List[dict]:
        """Get user's earned achievements"""
        try:
            return AchievementCRUD.db.execute_query(
                """
                SELECT ua.id, ua.user_id, ua.achievement_id, a.name, a.description,
                       a.icon_url, a.criteria_type, a.criteria_value, ua.earned_at
                FROM user_achievements ua
                JOIN achievements a ON ua.achievement_id = a.achievement_id
                WHERE ua.user_id = %s
                ORDER BY ua.earned_at DESC
                """,
                (user_id,)
            )
        except Exception as e:
            raise Exception(f"Error fetching user achievements: {e}")
    
    @staticmethod
    def check_and_award_streak_achievements(user_id: int, current_streak: int) -> List[dict]:
        """Check and award streak-based achievements"""
        awarded = []
        try:
            # Get all streak achievements
            streak_achievements = AchievementCRUD.db.execute_query(
                """
                SELECT achievement_id, name, criteria_value
                FROM achievements
                WHERE criteria_type = 'streak'
                ORDER BY criteria_value ASC
                """
            )
            
            for achievement in streak_achievements:
                if current_streak >= achievement['criteria_value']:
                    result = AchievementCRUD.award_achievement(
                        user_id, 
                        achievement['achievement_id']
                    )
                    if isinstance(result, dict) and 'id' in result:
                        awarded.append(result)
            
            return awarded
        except Exception as e:
            raise Exception(f"Error checking streak achievements: {e}")
    
    @staticmethod
    def check_and_award_meals_logged_achievements(user_id: int) -> List[dict]:
        """Check and award meals logged achievements"""
        awarded = []
        try:
            # Count meals logged
            result = AchievementCRUD.db.execute_single(
                """
                SELECT COUNT(*) as meal_count FROM meals
                WHERE user_id = %s
                """,
                (user_id,)
            )
            
            meal_count = result['meal_count'] if result else 0
            
            # Get all meals_logged achievements
            meal_achievements = AchievementCRUD.db.execute_query(
                """
                SELECT achievement_id, name, criteria_value
                FROM achievements
                WHERE criteria_type = 'meals_logged'
                ORDER BY criteria_value ASC
                """
            )
            
            for achievement in meal_achievements:
                if meal_count >= achievement['criteria_value']:
                    achievement_result = AchievementCRUD.award_achievement(
                        user_id,
                        achievement['achievement_id']
                    )
                    if isinstance(achievement_result, dict) and 'id' in achievement_result:
                        awarded.append(achievement_result)
            
            return awarded
        except Exception as e:
            raise Exception(f"Error checking meals logged achievements: {e}")
    
    @staticmethod
    def check_and_award_goal_met_achievements(user_id: int) -> List[dict]:
        """Check and award goal met achievements"""
        awarded = []
        try:
            # Count days goal was met
            result = AchievementCRUD.db.execute_single(
                """
                SELECT COUNT(*) as goal_met_days FROM daily_summaries
                WHERE user_id = %s AND is_goal_met = TRUE
                """,
                (user_id,)
            )
            
            goal_met_days = result['goal_met_days'] if result else 0
            
            # Get all goal_met_days achievements
            goal_achievements = AchievementCRUD.db.execute_query(
                """
                SELECT achievement_id, name, criteria_value
                FROM achievements
                WHERE criteria_type = 'goal_met_days'
                ORDER BY criteria_value ASC
                """
            )
            
            for achievement in goal_achievements:
                if goal_met_days >= achievement['criteria_value']:
                    achievement_result = AchievementCRUD.award_achievement(
                        user_id,
                        achievement['achievement_id']
                    )
                    if isinstance(achievement_result, dict) and 'id' in achievement_result:
                        awarded.append(achievement_result)
            
            return awarded
        except Exception as e:
            raise Exception(f"Error checking goal met achievements: {e}")
    
    @staticmethod
    def get_gamification_stats(user_id: int) -> Optional[dict]:
        """Get user's gamification statistics"""
        try:
            user = AchievementCRUD.db.execute_single(
                """
                SELECT current_streak, total_login_days, last_login_date
                FROM users
                WHERE user_id = %s
                """,
                (user_id,)
            )
            
            if not user:
                return None
            
            achievements = AchievementCRUD.get_user_achievements(user_id)
            
            return {
                "user_id": user_id,
                "current_streak": user['current_streak'],
                "total_login_days": user['total_login_days'],
                "last_login_date": user['last_login_date'],
                "total_achievements": len(achievements),
                "achievements": achievements
            }
        except Exception as e:
            raise Exception(f"Error fetching gamification stats: {e}")

"""
Gamification Routes
Manages achievements and gamification features
"""
from fastapi import APIRouter, HTTPException, status, Depends
from app.schemas.gamification_schemas import (
    AchievementResponse, UserAchievementResponse, GamificationStatsResponse
)
from app.crud.gamification_crud import AchievementCRUD
from app.security.dependencies import get_current_user

router = APIRouter(prefix="/gamification", tags=["Gamification"])

@router.get("/achievements", response_model=list[AchievementResponse])
async def get_all_achievements():
    """
    Get all available achievements
    """
    try:
        achievements = AchievementCRUD.get_all_achievements()
        return achievements
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/my-achievements", response_model=list[UserAchievementResponse])
async def get_user_achievements(user_id: int = Depends(get_current_user)):
    """
    Get user's earned achievements
    Requires authentication
    """
    try:
        achievements = AchievementCRUD.get_user_achievements(user_id)
        return achievements
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/stats", response_model=GamificationStatsResponse)
async def get_gamification_stats(user_id: int = Depends(get_current_user)):
    """
    Get user's gamification statistics
    Requires authentication
    
    Returns:
    - current_streak: Current consecutive login/goal streak
    - total_achievements: Number of earned achievements
    - total_login_days: Total days logged in
    - achievements: List of earned achievements
    """
    try:
        stats = AchievementCRUD.get_gamification_stats(user_id)
        
        if not stats:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return stats
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/check-achievements")
async def check_achievements(user_id: int = Depends(get_current_user)):
    """
    Check for and award new achievements
    Requires authentication
    
    This endpoint evaluates:
    - Streak achievements
    - Meals logged achievements
    - Goal met days achievements
    """
    try:
        awarded = []
        
        # Check streak achievements
        streak_awarded = AchievementCRUD.check_and_award_streak_achievements(user_id)
        awarded.extend(streak_awarded if isinstance(streak_awarded, list) else [])
        
        # Check meals logged achievements
        meals_awarded = AchievementCRUD.check_and_award_meals_logged_achievements(user_id)
        awarded.extend(meals_awarded if isinstance(meals_awarded, list) else [])
        
        # Check goal met achievements
        goal_awarded = AchievementCRUD.check_and_award_goal_met_achievements(user_id)
        awarded.extend(goal_awarded if isinstance(goal_awarded, list) else [])
        
        return {
            "message": "Achievements checked",
            "newly_awarded": len(awarded),
            "awards": awarded
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

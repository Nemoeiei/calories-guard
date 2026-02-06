"""
User Profile Routes
Manages user profile updates and statistics
"""
from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from app.schemas.user_schemas import UserProfileUpdate, UserResponse, UserStatsResponse
from app.crud.user_crud import UserCRUD
from app.security.dependencies import get_current_user
from app.core.database import get_db

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/profile", response_model=UserResponse)
async def get_profile(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Get current user profile
    Requires authentication
    """
    try:
        user = UserCRUD.get_user_by_id(db, user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return user
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/profile", response_model=UserResponse)
async def update_profile(
    profile_update: UserProfileUpdate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user profile information
    Requires authentication
    """
    try:
        updated_user = UserCRUD.update_user_profile(db, user_id, profile_update)
        
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update profile"
            )
        
        return updated_user
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/stats", response_model=UserStatsResponse)
async def get_stats(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Get user statistics for today
    Requires authentication
    """
    try:
        stats = UserCRUD.get_user_stats(db, user_id)
        
        if not stats:
            # If no stats found for today, maybe we should return defaults or last logged? 
            # For now, following logic of 404 if not found strictly today, or creation logic?
            # To be user friendly, we could create it if missing, but GET shouldn't change state.
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No stats found for today"
            )
        
        return stats
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/stats", response_model=UserStatsResponse)
async def update_stats(
    weight_kg: float = None,
    height_cm: float = None,
    bmi: float = None,
    bmr: float = None,
    tdee: float = None,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user statistics
    Requires authentication
    """
    try:
        stats = UserCRUD.update_user_stats(
            db=db,
            user_id=user_id,
            weight_kg=weight_kg,
            height_cm=height_cm,
            bmi=bmi,
            bmr=bmr,
            tdee=tdee
        )
        
        if not stats:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update stats"
            )
        
        return stats
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

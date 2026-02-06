"""
Authentication Routes
Handles user registration, login, and token management
"""
from fastapi import APIRouter, HTTPException, status, Depends
from datetime import timedelta
from sqlalchemy.orm import Session
from app.schemas.user_schemas import (
    UserRegister, UserLogin, TokenResponse, TokenRefresh, UserResponse
)
from app.crud.user_crud import UserCRUD
from app.security.security import security_manager
from app.core.config import settings
from app.core.database import get_db
# Use Depends(get_current_user) for /me if needed, but logic is inline currently.
from app.security.dependencies import get_current_user 

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Register new user account
    
    - **email**: User email (must be unique)
    - **password**: Password (min 8 characters)
    - **username**: Username for display
    """
    try:
        # Check if email already exists
        existing_user = UserCRUD.get_user_by_email(db, user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Create new user
        new_user = UserCRUD.create_user(
            db=db,
            email=user_data.email,
            password=user_data.password,
            username=user_data.username
        )
        
        if not new_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user"
            )
        
        # Create tokens
        access_token_expires = timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
        access_token = security_manager.create_access_token(
            data={"sub": str(new_user.user_id)},
            expires_delta=access_token_expires
        )
        
        refresh_token = security_manager.create_refresh_token(
            data={"sub": str(new_user.user_id)}
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=new_user.user_id
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """
    Login user and get authentication tokens
    
    - **email**: User email
    - **password**: User password
    """
    try:
        user = UserCRUD.get_user_by_email(db, credentials.email)
        
        # Verify user exists and password
        if not user or not security_manager.verify_password(credentials.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Update last login
        UserCRUD.increment_streak(db, user.user_id)
        
        # Create tokens
        access_token_expires = timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
        access_token = security_manager.create_access_token(
            data={"sub": str(user.user_id)},
            expires_delta=access_token_expires
        )
        
        refresh_token = security_manager.create_refresh_token(
            data={"sub": str(user.user_id)}
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=user.user_id
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(token_data: TokenRefresh):
    """
    Refresh access token using refresh token
    
    - **refresh_token**: Valid refresh token
    """
    try:
        payload = security_manager.verify_token(token_data.refresh_token)
        
        if payload is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Not a refresh token"
            )
        
        user_id = payload.get("sub")
        
        # Create new access token
        access_token_expires = timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
        new_access_token = security_manager.create_access_token(
            data={"sub": user_id},
            expires_delta=access_token_expires
        )
        
        return TokenResponse(
            access_token=new_access_token,
            user_id=int(user_id) if user_id.isdigit() else user_id # Handle if sub is str
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    user_id: int = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """
    Get current authenticated user profile
    Requires valid JWT token in Authorization header
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

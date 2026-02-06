"""
Dependency Injections
Provides FastAPI dependencies for authentication and authorization
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.security.security import security_manager
from app.core.database import get_db
from app.models.models import User, Role

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user from JWT token"""
    token = credentials.credentials
    
    payload = security_manager.verify_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id: int = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return int(user_id) if str(user_id).isdigit() else user_id

async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[int]:
    """Get current user if authenticated, otherwise None"""
    if credentials is None:
        return None
    
    token = credentials.credentials
    payload = security_manager.verify_token(token)
    if payload is None:
        return None
    
    user_id = payload.get("sub")
    return int(user_id) if str(user_id).isdigit() else user_id

async def verify_admin_role(
    user_id: int = Depends(get_current_user), 
    db: Session = Depends(get_db)
) -> int:
    """Verify user has admin role"""
    try:
        user = db.query(User).filter(User.user_id == user_id).first()
        
        if not user or not user.role or user.role.role_name != 'admin':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions"
            )
        
        return user_id
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

"""
Content Management Routes
Manages health content and user interactions
"""
from fastapi import APIRouter, HTTPException, status, Depends, Query
from app.schemas.content_schemas import (
    HealthContentResponse, UserSavedContentResponse, ContentViewLogResponse
)
from app.crud.content_crud import ContentCRUD
from app.security.dependencies import get_current_user_optional, get_current_user

router = APIRouter(prefix="/content", tags=["Content"])

@router.get("/", response_model=list[HealthContentResponse])
async def get_published_content(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get published health content
    
    - **skip**: Number of records to skip
    - **limit**: Number of records to return
    """
    try:
        content = ContentCRUD.get_all_published_content(skip, limit)
        return content
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/search", response_model=list[HealthContentResponse])
async def search_content(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Search health content by title or description
    
    - **q**: Search query
    - **limit**: Maximum results
    """
    try:
        content = ContentCRUD.search_content(q, limit)
        return content
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/category/{category}", response_model=list[HealthContentResponse])
async def get_by_category(
    category: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get content by category
    
    - **category**: Category tag (e.g., nutrition, exercise, health)
    - **skip**: Number of records to skip
    - **limit**: Number of records to return
    """
    try:
        content = ContentCRUD.get_content_by_category(category, skip, limit)
        return content
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/popular", response_model=list[HealthContentResponse])
async def get_popular_content(limit: int = Query(10, ge=1, le=100)):
    """
    Get most viewed content
    
    - **limit**: Number of results
    """
    try:
        content = ContentCRUD.get_popular_content(limit)
        return content
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{content_id}", response_model=HealthContentResponse)
async def get_content_detail(
    content_id: int,
    user_id: int = Depends(get_current_user_optional)
):
    """
    Get content details
    Optionally requires authentication to log view
    
    - **content_id**: Content ID
    """
    try:
        content = ContentCRUD.get_content_by_id(content_id)
        
        if not content:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Content not found"
            )
        
        # Log view if user is authenticated
        if user_id:
            ContentCRUD.log_content_view(user_id, content_id)
        
        return content
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/save/{content_id}")
async def save_content(content_id: int, user_id: int = Depends(get_current_user)):
    """
    Save content to user's collection
    Requires authentication
    """
    try:
        result = ContentCRUD.save_content(user_id, content_id)
        
        if isinstance(result, dict) and 'message' in result:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=result['message']
            )
        
        return {"message": "Content saved"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/save/{content_id}")
async def unsave_content(content_id: int, user_id: int = Depends(get_current_user)):
    """
    Remove content from user's saved collection
    Requires authentication
    """
    try:
        ContentCRUD.unsave_content(user_id, content_id)
        return {"message": "Content removed from saved"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/saved", response_model=list[UserSavedContentResponse])
async def get_saved_content(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    user_id: int = Depends(get_current_user)
):
    """
    Get user's saved content
    Requires authentication
    
    - **skip**: Number of records to skip
    - **limit**: Number of records to return
    """
    try:
        saved = ContentCRUD.get_user_saved_content(user_id, skip, limit)
        return saved
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/view/{content_id}")
async def log_view(content_id: int, user_id: int = Depends(get_current_user)):
    """
    Manually log content view
    Requires authentication
    """
    try:
        ContentCRUD.log_content_view(user_id, content_id)
        return {"message": "View logged"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

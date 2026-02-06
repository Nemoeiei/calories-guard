"""
Food Database Routes
Manages food items and user food preferences
"""
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlalchemy.orm import Session
from app.schemas.food_schemas import (
    FoodCreate, FoodUpdate, FoodResponse, FavoriteFoodResponse,
    AllergyFlagResponse, UserAllergyPreferenceCreate, UserAllergyPreferenceResponse
)
from app.crud.food_crud import FoodCRUD
from app.security.dependencies import get_current_user
from app.core.database import get_db

router = APIRouter(prefix="/foods", tags=["Foods"])

@router.get("/", response_model=list[FoodResponse])
async def list_foods(
    skip: int = Query(0, ge=0), 
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """
    Get list of all foods
    """
    try:
        foods = FoodCRUD.get_all_foods(db, skip, limit)
        return foods
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/search", response_model=list[FoodResponse])
async def search_foods(
    q: str = Query(..., min_length=1), 
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """
    Search foods by name or type
    """
    try:
        foods = FoodCRUD.search_foods(db, q, limit)
        return foods
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{food_id}", response_model=FoodResponse)
async def get_food(food_id: int, db: Session = Depends(get_db)):
    """
    Get food details by ID
    """
    try:
        food = FoodCRUD.get_food_by_id(db, food_id)
        
        if not food:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food not found"
            )
        
        return food
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/", response_model=FoodResponse)
async def create_food(
    food_data: FoodCreate, 
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create custom food entry
    Requires authentication
    """
    try:
        food = FoodCRUD.create_food(
            db=db,
            food_name=food_data.food_name,
            food_type=food_data.food_type.value,
            calories=food_data.calories,
            protein=food_data.protein,
            carbs=food_data.carbs,
            fat=food_data.fat,
            serving_quantity=food_data.serving_quantity,
            serving_unit=food_data.serving_unit,
            created_by_user_id=user_id,
            image_url=food_data.image_url
        )
        
        if not food:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create food"
            )
        
        return food
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/{food_id}", response_model=FoodResponse)
async def update_food(
    food_id: int,
    food_data: FoodUpdate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update food details
    Requires authentication
    Only food creator can update
    """
    try:
        # Verify ownership
        food = FoodCRUD.get_food_by_id(db, food_id)
        if not food:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food not found"
            )
        
        if food.created_by_user_id and food.created_by_user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this food"
            )
        
        updated_food = FoodCRUD.update_food(
            db=db,
            food_id=food_id,
            food_name=food_data.food_name,
            food_type=food_data.food_type.value if food_data.food_type else None,
            calories=food_data.calories,
            protein=food_data.protein,
            carbs=food_data.carbs,
            fat=food_data.fat,
            serving_quantity=food_data.serving_quantity,
            serving_unit=food_data.serving_unit,
            image_url=food_data.image_url
        )
        
        return updated_food
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{food_id}")
async def delete_food(
    food_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete food entry
    Requires authentication
    Only food creator can delete
    """
    try:
        food = FoodCRUD.get_food_by_id(db, food_id)
        if not food:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food not found"
            )
        
        if food.created_by_user_id and food.created_by_user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this food"
            )
        
        FoodCRUD.delete_food(db, food_id)
        
        return {"message": "Food deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/favorites/{food_id}", response_model=FavoriteFoodResponse)
async def add_to_favorites(
    food_id: int, 
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add food to user favorites
    """
    try:
        # Check if food exists first
        food = FoodCRUD.get_food_by_id(db, food_id)
        if not food:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food not found"
            )

        favorite = FoodCRUD.add_to_favorites(db, user_id, food_id)
        
        # If favorite is newly created or fetched, it's a FavoriteFood object.
        # Check if we should block duplicates in route or CRUD?
        # CRUD returns existing if found.
        # We can just return it. The user might want idempotency.
        
        return favorite
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/favorites/{food_id}")
async def remove_from_favorites(
    food_id: int, 
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Remove food from favorites
    """
    try:
        FoodCRUD.remove_from_favorites(db, user_id, food_id)
        return {"message": "Removed from favorites"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/favorites/list", response_model=list[FoodResponse])
async def get_favorites(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's favorite foods
    Returns list of Food objects
    """
    try:
        favorites = FoodCRUD.get_user_favorites(db, user_id)
        return favorites
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/allergies/flags", response_model=list[AllergyFlagResponse])
async def get_allergy_flags(db: Session = Depends(get_db)):
    """
    Get all available allergy flags
    """
    try:
        flags = FoodCRUD.get_all_allergy_flags(db)
        return flags
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/allergies/preference", response_model=UserAllergyPreferenceResponse)
async def add_allergy_preference(
    preference: UserAllergyPreferenceCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add allergy or food preference
    """
    try:
        result = FoodCRUD.add_allergy_preference(
            db=db,
            user_id=user_id,
            flag_id=preference.flag_id,
            preference_type=preference.preference_type
        )
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add preference"
            )
        
        # In ORM, result is UserAllergyPreference object.
        # We need to populate flag_name for response if the schema expects it.
        # UserAllergyPreference has relationship 'flag' (assuming modeled).
        # Let's check model...
        # If I didn't add relationship in model, I should trigger lazy load or separate query if needed.
        # My model had:
        # flag = relationship("AllergyFlag")
        # So I can access result.flag.name
        
        response_data = UserAllergyPreferenceResponse.model_validate(result)
        if result.flag:
             response_data.flag_name = result.flag.name
        
        return response_data
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/allergies/preferences", response_model=list[UserAllergyPreferenceResponse])
async def get_allergy_preferences(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's allergy and preference flags
    """
    try:
        preferences = FoodCRUD.get_user_allergy_preferences(db, user_id)
        
        # Populate flag names
        response_list = []
        for p in preferences:
            resp = UserAllergyPreferenceResponse.model_validate(p)
            if p.flag:
                resp.flag_name = p.flag.name
            response_list.append(resp)
            
        return response_list
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

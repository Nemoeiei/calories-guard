"""
Pydantic Schemas for Foods
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class FoodType(str, Enum):
    raw_ingredient = "raw_ingredient"
    recipe_dish = "recipe_dish"

# ==================== FOOD SCHEMAS ====================
class FoodCreate(BaseModel):
    """Create food schema"""
    food_name: str = Field(..., max_length=255)
    food_type: FoodType = FoodType.raw_ingredient
    calories: Optional[float] = Field(None, ge=0)
    protein: Optional[float] = Field(None, ge=0)
    carbs: Optional[float] = Field(None, ge=0)
    fat: Optional[float] = Field(None, ge=0)
    sodium: Optional[float] = Field(None, ge=0)
    sugar: Optional[float] = Field(None, ge=0)
    cholesterol: Optional[float] = Field(None, ge=0)
    serving_quantity: float = Field(default=100, gt=0)
    serving_unit: str = Field(default="g")
    image_url: Optional[str] = None

class FoodUpdate(BaseModel):
    """Update food schema"""
    food_name: Optional[str] = Field(None, max_length=255)
    food_type: Optional[FoodType] = None
    calories: Optional[float] = Field(None, ge=0)
    protein: Optional[float] = Field(None, ge=0)
    carbs: Optional[float] = Field(None, ge=0)
    fat: Optional[float] = Field(None, ge=0)
    sodium: Optional[float] = Field(None, ge=0)
    sugar: Optional[float] = Field(None, ge=0)
    cholesterol: Optional[float] = Field(None, ge=0)
    serving_quantity: Optional[float] = Field(None, gt=0)
    serving_unit: Optional[str] = None
    image_url: Optional[str] = None

class FoodResponse(BaseModel):
    """Food response schema"""
    food_id: int
    food_name: str
    food_type: str
    calories: Optional[float]
    protein: Optional[float]
    carbs: Optional[float]
    fat: Optional[float]
    sodium: Optional[float]
    sugar: Optional[float]
    cholesterol: Optional[float]
    serving_quantity: float
    serving_unit: str
    image_url: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ==================== FAVORITE FOODS ====================
class FavoriteFoodCreate(BaseModel):
    """Add favorite food schema"""
    food_id: int

class FavoriteFoodResponse(BaseModel):
    """Favorite food response"""
    favorite_id: int
    user_id: int
    food_id: int
    food_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# ==================== ALLERGY FLAGS ====================
class AllergyFlagCreate(BaseModel):
    """Create allergy flag schema"""
    name: str = Field(..., max_length=100)
    description: Optional[str] = None

class AllergyFlagResponse(BaseModel):
    """Allergy flag response"""
    flag_id: int
    name: str
    description: Optional[str]
    
    class Config:
        from_attributes = True

# ==================== USER ALLERGY PREFERENCES ====================
class UserAllergyPreferenceCreate(BaseModel):
    """Create user allergy preference"""
    flag_id: int
    preference_type: str = Field(..., pattern="^(LIKE|DISLIKE|ALLERGY)$")

class UserAllergyPreferenceResponse(BaseModel):
    """User allergy preference response"""
    user_id: int
    flag_id: int
    flag_name: str
    preference_type: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# ==================== RECIPE SCHEMAS ====================
class RecipeIngredientCreate(BaseModel):
    """Recipe ingredient schema"""
    ingredient_food_id: int
    amount: float = Field(..., gt=0)
    unit_id: Optional[int] = None
    note: Optional[str] = None

class RecipeCreate(BaseModel):
    """Create recipe schema"""
    food_id: int
    description: Optional[str] = Field(None, max_length=255)
    instructions: Optional[str] = None
    prep_time_minutes: int = Field(default=0, ge=0)
    cooking_time_minutes: int = Field(default=0, ge=0)
    serving_people: float = Field(default=1.0, gt=0)
    source_reference: Optional[str] = None
    ingredients: List[RecipeIngredientCreate] = []

class RecipeIngredientResponse(BaseModel):
    """Recipe ingredient response"""
    id: int
    ingredient_food_id: int
    ingredient_name: str
    amount: float
    unit_id: Optional[int]
    unit_name: Optional[str]
    calculated_grams: Optional[float]
    note: Optional[str]
    
    class Config:
        from_attributes = True

class RecipeResponse(BaseModel):
    """Recipe response"""
    recipe_id: int
    food_id: int
    description: Optional[str]
    instructions: Optional[str]
    prep_time_minutes: int
    cooking_time_minutes: int
    serving_people: float
    source_reference: Optional[str]
    total_time_minutes: int  # Computed
    ingredients: List[RecipeIngredientResponse]
    created_at: datetime
    
    class Config:
        from_attributes = True

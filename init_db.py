
import os
import sys

# Add backend directory to python path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from backend.core.database import engine
from backend.app.models.models import Base
# Import all models to ensure they are registered with Base metadata
from backend.app.models.models import (
    Role, User, UserStat, AllergyFlag, UserAllergyPreference,
    Food, FavoriteFood, FoodAllergyFlag, Beverage, Snack, Recipe,
    Meal, DetailItem, DailySummary, Unit, UserMealPlan, WeightLog
)

def init_db():
    print("Creating database tables...")
    try:
        # Create all tables defined in models
        Base.metadata.create_all(bind=engine)
        print("Tables created successfully!")
    except Exception as e:
        print(f"Error creating tables: {e}")

if __name__ == "__main__":
    init_db()

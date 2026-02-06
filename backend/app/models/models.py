from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, Date, DateTime, Text, BigInteger, DECIMAL, Enum, PrimaryKeyConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum
from datetime import datetime

# --- Enums (Same as before) ---
class GoalType(str, enum.Enum):
    lose_weight = 'lose_weight'
    maintain_weight = 'maintain_weight'
    gain_muscle = 'gain_muscle'

class ActivityLevel(str, enum.Enum):
    sedentary = 'sedentary'
    lightly_active = 'lightly_active'
    moderately_active = 'moderately_active'
    very_active = 'very_active'

class ContentType(str, enum.Enum):
    article = 'article'
    video = 'video'

class FoodType(str, enum.Enum):
    raw_ingredient = 'raw_ingredient'
    recipe_dish = 'recipe_dish'

class GenderType(str, enum.Enum):
    male = 'male'
    female = 'female'

class MealType(str, enum.Enum):
    breakfast = 'breakfast'
    lunch = 'lunch'
    dinner = 'dinner'
    snack = 'snack'

class NotificationType(str, enum.Enum):
    system_alert = 'system_alert'
    achievement = 'achievement'
    content_update = 'content_update'
    system_announcement = 'system_announcement'

# --- Models ---

class Role(Base):
    __tablename__ = "roles"
    role_id = Column(Integer, primary_key=True, index=True)
    role_name = Column(String, unique=True, nullable=False)

    users = relationship("User", back_populates="role")

class User(Base):
    __tablename__ = "users"
    user_id = Column(BigInteger, primary_key=True, index=True)
    username = Column(String)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    gender = Column(Enum(GenderType))
    birth_date = Column(Date)
    height_cm = Column(DECIMAL(5, 2))
    current_weight_kg = Column(DECIMAL(5, 2))
    goal_type = Column(Enum(GoalType))
    target_weight_kg = Column(DECIMAL(5, 2))
    target_calories = Column(Integer)
    activity_level = Column(Enum(ActivityLevel))
    goal_start_date = Column(Date, default=func.now())
    goal_target_date = Column(Date)
    last_kpi_check_date = Column(Date, default=func.now())
    current_streak = Column(Integer, default=0)
    last_login_date = Column(Date)
    total_login_days = Column(Integer, default=0)
    avatar_url = Column(String)
    role_id = Column(Integer, ForeignKey("roles.role_id"), default=2)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True))

    role = relationship("Role", back_populates="users")
    stats = relationship("UserStat", back_populates="user", cascade="all, delete-orphan")
    meals = relationship("Meal", back_populates="user", cascade="all, delete-orphan")
    daily_summaries = relationship("DailySummary", back_populates="user", cascade="all, delete-orphan")
    allergy_preferences = relationship("UserAllergyPreference", back_populates="user", cascade="all, delete-orphan")
    favorite_foods = relationship("FavoriteFood", back_populates="user", cascade="all, delete-orphan")
    weight_logs = relationship("WeightLog", back_populates="user", cascade="all, delete-orphan")
    
class UserStat(Base):
    __tablename__ = "user_stats"
    stat_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"))
    date_logged = Column(Date, default=func.current_date())
    weight_kg = Column(DECIMAL(5, 2))
    height_cm = Column(DECIMAL(5, 2))
    activity_level = Column(Enum(ActivityLevel))
    bmi = Column(DECIMAL(4, 2))
    bmr = Column(DECIMAL(6, 2))
    tdee = Column(DECIMAL(6, 2))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="stats")

class AllergyFlag(Base):
    __tablename__ = "allergy_flags"
    flag_id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String)

class UserAllergyPreference(Base):
    __tablename__ = "user_allergy_preferences"
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)
    flag_id = Column(Integer, ForeignKey("allergy_flags.flag_id", ondelete="CASCADE"), primary_key=True)
    preference_type = Column(String) # LIKE, DISLIKE, ALLERGY
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="allergy_preferences")
    flag = relationship("AllergyFlag")

class Food(Base):
    __tablename__ = "foods"
    food_id = Column(BigInteger, primary_key=True, index=True)
    food_name = Column(String, nullable=False)
    food_type = Column(Enum(FoodType), default=FoodType.raw_ingredient)
    calories = Column(DECIMAL(6, 2))
    protein = Column(DECIMAL(6, 2))
    carbs = Column(DECIMAL(6, 2))
    fat = Column(DECIMAL(6, 2))
    sodium = Column(DECIMAL(6, 2))
    sugar = Column(DECIMAL(6, 2))
    cholesterol = Column(DECIMAL(6, 2))
    serving_quantity = Column(DECIMAL(6, 2), default=100)
    serving_unit = Column(String, default="g")
    image_url = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    deleted_at = Column(DateTime(timezone=True))

    beverage_details = relationship("Beverage", uselist=False, back_populates="food")
    snack_details = relationship("Snack", uselist=False, back_populates="food")
    recipe_details = relationship("Recipe", uselist=False, back_populates="food")

class FavoriteFood(Base):
    __tablename__ = "favorite_foods"
    favorite_id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"))
    food_id = Column(BigInteger, ForeignKey("foods.food_id", ondelete="CASCADE"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorite_foods")
    food = relationship("Food")

class FoodAllergyFlag(Base):
    __tablename__ = "food_allergy_flags"
    food_id = Column(BigInteger, ForeignKey("foods.food_id", ondelete="CASCADE"), primary_key=True)
    flag_id = Column(Integer, ForeignKey("allergy_flags.flag_id", ondelete="CASCADE"), primary_key=True)

class Beverage(Base):
    __tablename__ = "beverages"
    beverage_id = Column(BigInteger, primary_key=True, index=True)
    food_id = Column(BigInteger, ForeignKey("foods.food_id"), unique=True)
    volume_ml = Column(DECIMAL(6, 2))
    is_alcoholic = Column(Boolean, default=False)
    caffeine_mg = Column(DECIMAL(6, 2), default=0)
    sugar_level_label = Column(String)
    container_type = Column(String)
    
    food = relationship("Food", back_populates="beverage_details")

class Snack(Base):
    __tablename__ = "snacks"
    snack_id = Column(BigInteger, primary_key=True, index=True)
    food_id = Column(BigInteger, ForeignKey("foods.food_id"), unique=True)
    is_sweet = Column(Boolean, default=True)
    packaging_type = Column(String)
    trans_fat = Column(DECIMAL(6, 2))

    food = relationship("Food", back_populates="snack_details")

class Recipe(Base):
    __tablename__ = "recipes"
    recipe_id = Column(BigInteger, primary_key=True, index=True)
    food_id = Column(BigInteger, ForeignKey("foods.food_id"), unique=True)
    description = Column(String)
    instructions = Column(Text)
    prep_time_minutes = Column(Integer, default=0)
    cooking_time_minutes = Column(Integer, default=0)
    serving_people = Column(DECIMAL(3, 1), default=1)
    source_reference = Column(String)
    calculation_note = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    deleted_at = Column(DateTime(timezone=True))

    food = relationship("Food", back_populates="recipe_details")

class Meal(Base):
    __tablename__ = "meals"
    meal_id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"))
    meal_type = Column(Enum(MealType))
    meal_time = Column(DateTime(timezone=True), server_default=func.now())
    total_amount = Column(DECIMAL)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    items = relationship("DetailItem", back_populates="meal", cascade="all, delete-orphan")
    user = relationship("User", back_populates="meals")

class DetailItem(Base):
    __tablename__ = "detail_items"
    item_id = Column(BigInteger, primary_key=True, index=True)
    meal_id = Column(BigInteger, ForeignKey("meals.meal_id", ondelete="CASCADE"))
    plan_id = Column(BigInteger, ForeignKey("user_meal_plans.plan_id", ondelete="CASCADE"), nullable=True)
    summary_id = Column(BigInteger, ForeignKey("daily_summaries.summary_id", ondelete="CASCADE"), nullable=True)
    food_id = Column(BigInteger, ForeignKey("foods.food_id"))
    food_name = Column(String)
    day_number = Column(Integer)
    amount = Column(DECIMAL(8, 2), default=1)
    unit_id = Column(Integer, ForeignKey("units.unit_id"))
    cal_per_unit = Column(DECIMAL(10, 2))
    protein_per_unit = Column(DECIMAL(10, 2))
    carbs_per_unit = Column(DECIMAL(10, 2))
    fat_per_unit = Column(DECIMAL(10, 2))
    note = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    meal = relationship("Meal", back_populates="items")
    food = relationship("Food")

class DailySummary(Base):
    __tablename__ = "daily_summaries"
    summary_id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"))
    date_record = Column(Date, default=func.current_date())
    water_intake_glasses = Column(Integer, default=0)
    total_calories_intake = Column(DECIMAL(10, 2), default=0)
    total_protein = Column(DECIMAL(10, 2), default=0)
    total_carbs = Column(DECIMAL(10, 2), default=0)
    total_fat = Column(DECIMAL(10, 2), default=0)
    goal_calories = Column(Integer)
    is_goal_met = Column(Boolean, default=False)

    user = relationship("User", back_populates="daily_summaries")

class Unit(Base):
    __tablename__ = "units"
    unit_id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    conversion_factor = Column(DECIMAL(10, 4))

class UserMealPlan(Base):
    __tablename__ = "user_meal_plans"
    plan_id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="SET NULL"))
    name = Column(String, nullable=False)
    description = Column(Text)
    source_type = Column(String, default='SYSTEM')
    goal_tag = Column(String)
    duration_days = Column(Integer)
    is_premium = Column(Boolean, default=False)
    status = Column(String, default='ACTIVE')
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class WeightLog(Base):
    __tablename__ = "weight_logs"
    log_id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"))
    weight_kg = Column(DECIMAL(5, 2))
    recorded_date = Column(Date, default=func.current_date())
    
    user = relationship("User", back_populates="weight_logs")

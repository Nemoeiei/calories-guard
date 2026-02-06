"""
Common utility functions and helpers
"""
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Optional

def calculate_bmi(weight_kg: float, height_cm: float) -> Optional[float]:
    """Calculate Body Mass Index"""
    if height_cm <= 0 or weight_kg <= 0:
        return None
    height_m = height_cm / 100
    return round(weight_kg / (height_m ** 2), 2)

def calculate_bmr_harris_benedict(gender: str, weight_kg: float, 
                                   height_cm: float, age: int) -> Optional[float]:
    """
    Calculate Basal Metabolic Rate using Harris-Benedict equation
    BMR = calories/day at rest
    """
    if gender == "male":
        bmr = 88.362 + (13.397 * weight_kg) + (4.799 * height_cm) - (5.677 * age)
    elif gender == "female":
        bmr = 447.593 + (9.247 * weight_kg) + (3.098 * height_cm) - (4.330 * age)
    else:
        return None
    
    return round(bmr, 2)

def calculate_tdee(bmr: float, activity_level: str) -> Optional[float]:
    """
    Calculate Total Daily Energy Expenditure
    Multiplies BMR by activity factor
    """
    activity_factors = {
        "sedentary": 1.2,           # Little or no exercise
        "lightly_active": 1.375,    # Exercise 1-3 days/week
        "moderately_active": 1.55,  # Exercise 3-5 days/week
        "very_active": 1.725,       # Exercise 6-7 days/week
        "extremely_active": 1.9     # Physical job or training twice a day
    }
    
    factor = activity_factors.get(activity_level, 1.55)
    return round(bmr * factor, 2)

def get_age_from_birth_date(birth_date: date) -> int:
    """Calculate age from birth date"""
    today = date.today()
    return today.year - birth_date.year - (
        (today.month, today.day) < (birth_date.month, birth_date.day)
    )

def calculate_weight_change(current_weight: float, previous_weight: float) -> float:
    """Calculate weight change between two measurements"""
    return round(current_weight - previous_weight, 2)

def calculate_calorie_deficit(tdee: float, target_calories: int) -> int:
    """Calculate calorie deficit from TDEE and target"""
    deficit = target_calories - tdee
    return round(deficit)

def get_macronutrient_percentages(protein: float, carbs: float, fat: float) -> dict:
    """
    Calculate macronutrient distribution percentages
    Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    """
    protein_cal = protein * 4
    carbs_cal = carbs * 4
    fat_cal = fat * 9
    
    total_cal = protein_cal + carbs_cal + fat_cal
    
    if total_cal == 0:
        return {"protein": 0, "carbs": 0, "fat": 0}
    
    return {
        "protein": round((protein_cal / total_cal) * 100, 1),
        "carbs": round((carbs_cal / total_cal) * 100, 1),
        "fat": round((fat_cal / total_cal) * 100, 1)
    }

def format_datetime_readable(dt: datetime) -> str:
    """Format datetime for display"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")

def is_goal_met(actual_calories: float, target_calories: int, tolerance_percent: float = 5) -> bool:
    """
    Check if daily calorie goal is met
    Allows for tolerance percentage (default 5%)
    """
    if target_calories == 0:
        return False
    
    tolerance = (target_calories * tolerance_percent) / 100
    lower_bound = target_calories - tolerance
    upper_bound = target_calories + tolerance
    
    return lower_bound <= actual_calories <= upper_bound

def get_date_range(start_date: date, end_date: date) -> list[date]:
    """Get list of dates between start and end date (inclusive)"""
    dates = []
    current_date = start_date
    
    while current_date <= end_date:
        dates.append(current_date)
        current_date += timedelta(days=1)
    
    return dates

def get_week_dates(target_date: date = None) -> tuple[date, date]:
    """Get start and end dates of week for given date"""
    if target_date is None:
        target_date = date.today()
    
    # Monday = 0, Sunday = 6
    day_of_week = target_date.weekday()
    start_date = target_date - timedelta(days=day_of_week)
    end_date = start_date + timedelta(days=6)
    
    return start_date, end_date

def get_month_dates(target_date: date = None) -> tuple[date, date]:
    """Get start and end dates of month for given date"""
    if target_date is None:
        target_date = date.today()
    
    # First day of month
    start_date = target_date.replace(day=1)
    
    # Last day of month
    if target_date.month == 12:
        end_date = target_date.replace(year=target_date.year + 1, month=1, day=1) - timedelta(days=1)
    else:
        end_date = target_date.replace(month=target_date.month + 1, day=1) - timedelta(days=1)
    
    return start_date, end_date

def validate_email_format(email: str) -> bool:
    """Basic email format validation"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def truncate_string(text: str, max_length: int, suffix: str = "...") -> str:
    """Truncate string to max length with suffix"""
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix

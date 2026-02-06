"""
Recommendation Routes
"""
from fastapi import APIRouter, Depends
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])

# Schema for Recommendation Response
class RecommendationItem(BaseModel):
    name: str
    cal: str
    image: str
    category: Optional[str] = "general"

@router.get("/foods", response_model=List[RecommendationItem])
async def get_food_recommendations():
    """
    Get recommended food menu
    """
    # Mock data matches original Frontend content
    return [
        {
            "name": "เมนู หมูพันเห็ดเข็มทองคลีน",
            "cal": "120–150 kcal",
            "image": "assets/images/food/หมูพันเห็ดเข็มของคลีน.png",
            "category": "clean"
        },
        {
            "name": "เมนู ผักหมูลวกจิ้มคลีน",
            "cal": "180–220 กิโลแคลอรี่",
            "image": "assets/images/food/ลาบวุ้นเส้นคลีน.png", # Image name from frontend seemed mismatch, keeping as is
            "category": "clean"
        },
        {
            "name": "เมนู ลาบวุ้นเส้นคลีน",
            "cal": "230–280 kcal",
            "image": "assets/images/food/ผักหมูลวกจิ้มคลีน.png",
            "category": "clean"
        },
        {
            "name": "เมนู กระเพราหมูสับไข่ดาว",
            "cal": "550–650 kcal",
            "image": "assets/images/food/กระเพราหมูสับไข่ดาว.png",
            "category": "general"
        }
    ]

@router.get("/drinks", response_model=List[RecommendationItem])
async def get_drink_recommendations():
    """
    Get recommended drink menu
    """
    return [
        {
            "name": "เมนู นํ้ามะม่วงสมูทตี้",
            "cal": "180–250 kcal",
            "image": "assets/images/food/นํ้ามะม่วงสมูทตี้.png",
            "category": "fruit"
        },
        {
            "name": "เมนู นํ้าสตอเบอรี่สมูทตี้",
            "cal": "140–200 kcal",
            "image": "assets/images/food/นํ้าสตอเบอรี่สมูทตี้.png",
            "category": "fruit"
        },
        {
            "name": "เมนู มัจฉะลาเต้",
            "cal": "180–250 kcal",
            "image": "assets/images/food/มัจฉะลาเต้.png",
            "category": "tea"
        },
        {
            "name": "เมนู มัจฉะลาเต้สตอเบอรี่",
            "cal": "220–300 kcal",
            "image": "assets/images/food/มัจฉะลาเต้สตอเบอรี่.png",
            "category": "tea"
        }
    ]

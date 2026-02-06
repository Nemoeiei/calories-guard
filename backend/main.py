"""
Calories Guard API
Main application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

# Import Routers
from app.routes import auth, users, foods, meals, recommendations

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS Middleware
# Allow all origins for development, specific origins for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Update this in production to specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(foods.router)
app.include_router(meals.router)
app.include_router(recommendations.router)

# Root Endpoint
@app.get("/")
def read_root():
    return {"message": "Calories Guard API is running with SQLAlchemy ORM!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
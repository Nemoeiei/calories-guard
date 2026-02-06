# Calories Guard - Project Structure Overview

## 1. Architecture Overview
This project is a **Full-Stack Application** consisting of:
- **Frontend**: Mobile Application built with **Flutter**.
- **Backend**: REST API built with **Python (FastAPI)**.
- **Database**: **PostgreSQL** (managed via SQLAlchemy ORM).

---

## 2. Backend Structure (`backend/`)
The backend is organized using the **MVC (Model-View-Controller)** pattern adapted for FastAPI.

### Key Directories & Files:
- **`app/main.py`**: The entry point of the API. It initializes FastAPI and includes all routers.
- **`app/models/models.py`**: **(The Database Layer)** Defines SQL tables using SQLAlchemy classes (e.g., `User`, `Food`, `Meal`). Changing these classes updates the database structure.
- **`app/schemas/`**: **(The Validation Layer)** Pydantic models used for request/response validation (e.g., `UserCreate`, `MealResponse`).
- **`app/crud/`**: **(The Logic Layer)** Contains functions to Create, Read, Update, Delete data in the DB.
- **`app/routes/`**: **(The Controller Layer)** Defines API endpoints (URLs) like `/auth/login`, `/meals/log`.
- **`app/core/`**: Configuration (Settings, Database Connection).

### Current Features (Backend):
1.  **Authentication**: Register, Login, JWT Token generation (`routes/auth.py`).
2.  **User Profile**: specific user data, update weight/goals (`routes/users.py`).
3.  **Food Database**: Search and retrieve food info (`routes/foods.py`).
4.  **Meal Tracking**: Log meals, calculate daily nutrition (`routes/meals.py`).
5.  **Recommendations**: API for food/drink suggestions (`routes/recommendations.py`).

### Database Connection:
- logic in `app/core/database.py`.
- Uses `.env` file to store credentials (`DATABASE_URL`).
- `verify_db.py` is a script to test the connection.

---

## 3. Frontend Structure (`flutter_application_1/`)
The frontend follows a **Feature-based** or **Layered** architecture using **Riverpod** for state management.

### Key Directories:
- **`lib/main.dart`**: Entry point. Sets up Theme and Routes.
- **`lib/screens/`**: UI Pages.
    - `login_register/`: Auth screens.
    - `record/`: Food logging screen.
    - `recommend_food/`: Recommendation screen.
    - `app_home_screen.dart`: Main dashboard.
- **`lib/services/`**: logic to talk to Backend.
    - `auth_service.dart`: Login/Register API.
    - `meal_service.dart`: Log meals, get summary.
    - `food_service.dart`: Search foods.
    - `recommendation_service.dart`: Get suggestions.
- **`lib/providers/`**: Global State (User data, Navigation index) using Riverpod.

### How it connects to Backend:
The Frontend uses `http` package in `services/` to send REST requests (GET, POST, PUT, DELETE) to the Backend URL (defined in `AppConstants`). It sends the **JWT Token** in the Header for secure access.

---

## 4. Testing & Reliability
- **Unit Tests**: (To be added) Will test individual functions in `crud/` and `services/`.
- **Error Handling**: 
    - **Backend**: Uses `HTTPException` to return 400/404/401 errors.
    - **Frontend**: specific `try-catch` blocks in Services/Screens to catch network errors and show Snackbars.

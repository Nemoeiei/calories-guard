# Calories Guard Backend API

A comprehensive health and nutrition tracking backend built with FastAPI, featuring meal logging, gamification, user management, and content delivery.

## 🏗️ Project Structure

```
backend/
├── app/
│   ├── core/              # Core configuration and database
│   │   ├── config.py      # Environment settings
│   │   └── database.py    # Supabase PostgreSQL connection
│   ├── models/            # Data models (SQLAlchemy models if needed)
│   ├── schemas/           # Pydantic schemas for validation
│   │   ├── user_schemas.py
│   │   ├── meal_schemas.py
│   │   ├── food_schemas.py
│   │   ├── notification_schemas.py
│   │   ├── gamification_schemas.py
│   │   └── content_schemas.py
│   ├── crud/              # Database operations
│   │   ├── user_crud.py
│   │   ├── meal_crud.py
│   │   ├── food_crud.py
│   │   ├── notification_crud.py
│   │   ├── gamification_crud.py
│   │   └── content_crud.py
│   ├── routes/            # API endpoints (organized by feature)
│   │   ├── auth.py        # Authentication endpoints
│   │   ├── users.py       # User profile endpoints
│   │   ├── meals.py       # Meal logging endpoints
│   │   ├── foods.py       # Food database endpoints
│   │   ├── notifications.py # Notifications endpoints
│   │   ├── gamification.py  # Gamification endpoints
│   │   └── content.py     # Content management endpoints
│   ├── security/          # Authentication and authorization
│   │   ├── security.py    # JWT and password management
│   │   └── dependencies.py # FastAPI dependencies
│   └── utils/             # Utility functions
├── main_new.py            # Application entry point
├── requirements.txt       # Python dependencies
├── .env.example          # Environment variables template
└── README.md             # This file
```

## 🚀 Installation & Setup

### 1. Prerequisites

- Python 3.9+
- Supabase account with PostgreSQL database
- pip package manager

### 2. Clone & Navigate

```bash
cd calories-guard/backend
```

### 3. Create Virtual Environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

### 5. Configure Environment

Copy `.env.example` to `.env` and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env` with your database credentials:
```
DB_HOST=your-supabase-host.supabase.co
DB_USER=postgres
DB_PASSWORD=your-password
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key
SECRET_KEY=your-secret-key-change-this-in-production
```

### 6. Initialize Database

Run the SQL schema from `databaseV2.sql` in your Supabase database console:
- Go to SQL Editor in Supabase
- Create new query
- Copy contents of `databaseV2.sql`
- Execute

### 7. Run Application

```bash
# Development with hot reload
uvicorn main_new:app --reload --host 0.0.0.0 --port 8000

# Production
uvicorn main_new:app --host 0.0.0.0 --port 8000
```

Visit `http://localhost:8000` to see the API documentation at `/docs`

## 📚 API Documentation

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123",
  "username": "john_doe"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user_id": 1
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer {access_token}
```

### User Profile

#### Get Profile
```http
GET /api/users/profile
Authorization: Bearer {access_token}
```

#### Update Profile
```http
PUT /api/users/profile
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "username": "john_doe",
  "gender": "male",
  "birth_date": "1990-01-15",
  "height_cm": 180,
  "current_weight_kg": 75,
  "goal_type": "lose_weight",
  "target_weight_kg": 70,
  "target_calories": 2000,
  "activity_level": "moderately_active"
}
```

#### Get User Stats
```http
GET /api/users/stats
Authorization: Bearer {access_token}
```

#### Update User Stats
```http
POST /api/users/stats
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "weight_kg": 74.5,
  "bmi": 23.0,
  "bmr": 1700,
  "tdee": 2400
}
```

### Meal Logging

#### Log Meal
```http
POST /api/meals/log
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "meal_type": "breakfast",
  "items": [
    {
      "food_id": 1,
      "amount": 100,
      "note": "1 bowl"
    },
    {
      "food_id": 5,
      "amount": 200,
      "note": "1 glass"
    }
  ]
}
```

#### Get Meals by Date
```http
GET /api/meals/by-date?date_str=2024-01-26
Authorization: Bearer {access_token}
```

#### Get Meal Details
```http
GET /api/meals/{meal_id}
Authorization: Bearer {access_token}
```

#### Delete Meal
```http
DELETE /api/meals/{meal_id}
Authorization: Bearer {access_token}
```

#### Get Daily Summary
```http
GET /api/meals/summary/2024-01-26
Authorization: Bearer {access_token}
```

#### Log Weight
```http
POST /api/meals/weight
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "weight_kg": 74.5
}
```

#### Get Weight History
```http
GET /api/meals/weight/history/30
Authorization: Bearer {access_token}
```

### Food Database

#### Get All Foods
```http
GET /api/foods/?skip=0&limit=100
```

#### Search Foods
```http
GET /api/foods/search?q=chicken&limit=20
```

#### Get Food Details
```http
GET /api/foods/{food_id}
```

#### Create Custom Food
```http
POST /api/foods/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "food_name": "Custom Meal",
  "food_type": "recipe_dish",
  "calories": 500,
  "protein": 30,
  "carbs": 50,
  "fat": 15,
  "serving_quantity": 1,
  "serving_unit": "serving"
}
```

#### Add to Favorites
```http
POST /api/foods/favorites/{food_id}
Authorization: Bearer {access_token}
```

#### Get Favorites
```http
GET /api/foods/favorites/list
Authorization: Bearer {access_token}
```

#### Get Allergy Flags
```http
GET /api/foods/allergies/flags
```

#### Add Allergy Preference
```http
POST /api/foods/allergies/preference
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "flag_id": 1,
  "preference_type": "ALLERGY"
}
```

### Notifications

#### Get Notifications
```http
GET /api/notifications/?skip=0&limit=50&unread_only=false
Authorization: Bearer {access_token}
```

#### Get Unread Count
```http
GET /api/notifications/unread-count
Authorization: Bearer {access_token}
```

#### Mark as Read
```http
PUT /api/notifications/{notification_id}/read
Authorization: Bearer {access_token}
```

#### Mark All as Read
```http
PUT /api/notifications/read-all
Authorization: Bearer {access_token}
```

#### Get Announcements
```http
GET /api/notifications/announcements
```

### Gamification

#### Get All Achievements
```http
GET /api/gamification/achievements
```

#### Get User Achievements
```http
GET /api/gamification/my-achievements
Authorization: Bearer {access_token}
```

#### Get Gamification Stats
```http
GET /api/gamification/stats
Authorization: Bearer {access_token}

Response:
{
  "user_id": 1,
  "current_streak": 5,
  "total_login_days": 20,
  "total_achievements": 8,
  "achievements": [...]
}
```

#### Check Achievements
```http
POST /api/gamification/check-achievements
Authorization: Bearer {access_token}
```

### Content Management

#### Get Published Content
```http
GET /api/content/?skip=0&limit=20
```

#### Search Content
```http
GET /api/content/search?q=nutrition&limit=20
```

#### Get Content by Category
```http
GET /api/content/category/nutrition?skip=0&limit=20
```

#### Get Popular Content
```http
GET /api/content/popular?limit=10
```

#### Get Content Details
```http
GET /api/content/{content_id}
Authorization: Bearer {access_token} (optional)
```

#### Save Content
```http
POST /api/content/save/{content_id}
Authorization: Bearer {access_token}
```

#### Get Saved Content
```http
GET /api/content/saved?skip=0&limit=20
Authorization: Bearer {access_token}
```

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: SHA256 + Bcrypt dual hashing
- **Role-Based Access Control**: Admin and User roles
- **Input Validation**: Pydantic schema validation
- **CORS Protection**: Configurable cross-origin policies
- **Dependency Injection**: FastAPI security dependencies

## 🎮 Features Implemented

### 1. ✅ Registration & Login
- User registration with email verification support
- Secure login with JWT tokens
- Token refresh mechanism
- Password hashing with bcrypt

### 2. ✅ Meal Recording
- Log meals with food items
- Track nutritional information
- Daily summaries
- Weight logging and history

### 3. ✅ Role Management
- Admin and User roles
- Role-based access control
- User profile management

### 4. ✅ Notifications
- System notifications
- Achievement notifications
- User announcements
- Read/unread status tracking

### 5. ✅ Food Allergies
- Allergy flag management
- User allergy preferences
- Allergy type categorization (LIKE, DISLIKE, ALLERGY)

### 6. ✅ Gamification
- Achievement system
- User streaks
- Login day tracking
- Multiple achievement criteria (streak, meals logged, goal met days)

### 7. ✅ Content Management
- Health articles and videos
- Content categorization
- View tracking
- User saved content
- Popular content ranking

## 📊 Database Schema

The application uses a comprehensive PostgreSQL schema with:
- 19 main tables
- 7 ENUM types
- Automatic timestamp management
- Cascading delete protection
- UNIQUE constraints for data integrity

See `databaseV2.sql` for complete schema definition.

## 🔄 Workflow Example

1. **User Registration**
   - POST `/api/auth/register` → Get tokens
   
2. **Setup Profile**
   - PUT `/api/users/profile` → Update personal info

3. **Track Meals**
   - POST `/api/meals/log` → Log breakfast
   - POST `/api/meals/log` → Log lunch
   - POST `/api/meals/log` → Log dinner
   - GET `/api/meals/summary/today` → View daily stats

4. **Monitor Progress**
   - POST `/api/meals/weight` → Log weight
   - GET `/api/meals/weight/history/30` → View 30-day history

5. **Engage with Gamification**
   - GET `/api/gamification/stats` → View achievements
   - POST `/api/gamification/check-achievements` → Earn new achievements

6. **Access Content**
   - GET `/api/content/` → Browse content
   - POST `/api/content/save/{id}` → Save for later

## 📝 Configuration

Key configuration file: `app/core/config.py`

Environment variables:
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_KEY`: Supabase anonymous key
- `DB_*`: Database connection details
- `SECRET_KEY`: JWT signing key
- `DEBUG`: Development mode toggle

## 🛠️ Development

### Running Tests (when implemented)
```bash
pytest
```

### Code Formatting
```bash
black app/
```

### Linting
```bash
flake8 app/
```

## 📦 Deployment

### Docker Support (Future)
```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main_new:app", "--host", "0.0.0.0"]
```

### Deployment to Production
1. Set `DEBUG=False` in `.env`
2. Use strong `SECRET_KEY`
3. Configure proper CORS origins
4. Use HTTPS
5. Set up database backups
6. Monitor logs and performance

## 🤝 Contributing

1. Follow PEP 8 style guide
2. Use type hints
3. Add docstrings
4. Test new features
5. Update documentation

## 📄 License

This project is part of Calories Guard health tracking application.

## 🆘 Troubleshooting

### "PostgreSQL connection error"
- Verify Supabase credentials in `.env`
- Check database is running
- Ensure IP whitelist includes your machine

### "JWT validation failed"
- Verify `SECRET_KEY` is set
- Check token hasn't expired
- Ensure proper Authorization header format: `Bearer {token}`

### "CORS error"
- Check `ALLOWED_ORIGINS` in `.env`
- Ensure Flutter app origin is added

## 📞 Support

For issues or questions, contact the development team.

---

**Last Updated**: January 2024
**Version**: 1.0.0
**Status**: Production Ready

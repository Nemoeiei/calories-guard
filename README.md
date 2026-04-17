# Calories Guard

Personalized calorie tracking + AI nutrition coach for Thai users.

**Stack:** Flutter (mobile) · FastAPI (backend) · PostgreSQL / Supabase (DB + Auth + Storage) · Gemini 2.5 Flash (AI coach) · React + Vite (admin web).

---

## Repository layout

```
.
├─ backend/                       FastAPI service (Python 3.11)
│  ├─ main.py                     Thin entry: CORS, rate limiter, static files, init
│  ├─ app/
│  │  ├─ core/                    Config, security, shared dependencies
│  │  ├─ models/schemas.py        Pydantic request/response models
│  │  ├─ routers/                 12 domain routers (health, auth, users, foods, ...)
│  │  └─ services/                Business logic (nutrition calcs, email)
│  ├─ auth/dependencies.py        Supabase JWT verification
│  ├─ ai_models/                  Coach + 3-agent nutrition pipeline (Gemini)
│  ├─ migrations/                 SQL migrations v1..v13 + macros
│  ├─ tests/                      pytest suite
│  └─ Dockerfile
├─ flutter_application_1/         Flutter app (Android focus)
├─ admin-web/                     React + Vite admin dashboard
├─ docker-compose.yml             Local dev stack: backend + postgres
├─ docs/
│  ├─ DEPLOYMENT.md               Railway + Supabase deploy guide
│  └─ DEVELOPMENT.md              Local dev setup, running tests
└─ .github/workflows/ci.yml       GitHub Actions (ruff + pytest + flutter)
```

---

## Quick start (local dev)

### Prerequisites
- Python 3.11, Flutter 3.x, Node 18+ (for admin-web)
- Docker (optional, for the local Postgres)
- Supabase project (for Auth/Storage) — free tier works
- Gemini API key (optional — coach falls back to canned responses)

### 1. Clone + env
```bash
git clone https://github.com/Nemoeiei/calories-guard.git
cd calories-guard
cp backend/.env.example backend/.env   # fill in your secrets
```

Required env vars in `backend/.env`:
- `DB_MODE=local|supabase`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173`
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_JWT_SECRET`
- `GEMINI_API_KEY` (optional)
- `SMTP_*` (optional — only needed for email features)

### 2. Backend
```bash
# Option A: docker compose (recommended)
docker compose up --build

# Option B: manual
cd backend
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```
API at <http://localhost:8000> · docs at <http://localhost:8000/docs>.

### 3. Flutter
```bash
cd flutter_application_1
cp lib/config/secrets.example.dart lib/config/secrets.dart   # fill in Supabase URL/anon key
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### 4. Admin web (optional)
```bash
cd admin-web
cp .env.example .env   # set VITE_API_BASE_URL=http://localhost:8000
npm install
npm run dev
```

---

## Running tests

### Backend
```bash
cd backend
pip install -r requirements-dev.txt
pytest -q
```

### Flutter
```bash
cd flutter_application_1
flutter analyze
flutter test
```

---

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for Railway + Supabase setup.

### Build release APK
```bash
cd flutter_application_1
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.calories-guard.example.com
```

---

## Key design notes

- **Auth is Supabase-only.** All protected endpoints require `Authorization: Bearer <jwt>`; the token is verified with `SUPABASE_JWT_SECRET` in `backend/auth/dependencies.py`.
- **AI scope guard.** Both `chatbot_agent.py` and `ai_models/multi_agent_system.py` enforce keyword + system-prompt scope — the coach refuses off-topic questions (code, math, news, etc.).
- **Auto-add food.** When the AI is asked about an unknown food, it estimates nutrition with Gemini and inserts into `temp_food` for admin review. Admins promote entries into the canonical `foods` table via `POST /admin/temp-foods/{id}/approve`.
- **Rate limits.** `/register`, `/login`, `/upload-image/`, `/api/chat/*` are rate-limited with `slowapi`.
- **AI timeout.** Chat endpoints enforce a 30 s wall-clock timeout + 2 000-char input cap.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ModuleNotFoundError: slowapi` | run `pip install -r requirements.txt` |
| APK can't reach API | release build missing `android.permission.INTERNET`, or `API_BASE_URL` baked in as `http://10.0.2.2` |
| Chat returns `AI ตอบช้าเกินไป` | Gemini timeout — check API key / network |
| Admin endpoints return 401 | admin-web not sending `Authorization` header yet (see follow-ups) |

---

## License / academic use

Senior Project — Calories Guard. Not licensed for redistribution.

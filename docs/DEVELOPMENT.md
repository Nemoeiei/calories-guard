# Development Guide — Calories Guard

Local setup for backend (FastAPI), Flutter app, and admin-web.

---

## Prerequisites

- **Python 3.11** (match Railway/CI)
- **Flutter 3.x** (Android SDK + an emulator or device)
- **Node 18+** (for `admin-web/`)
- **Docker Desktop** (optional — easiest Postgres)
- A **Supabase project** (free tier works) — provides Auth, Storage, optional Postgres
- A **Gemini API key** from Google AI Studio (optional — coach falls back to canned answers)

---

## 1. Clone + env files

```bash
git clone https://github.com/Nemoeiei/calories-guard.git
cd calories-guard

cp backend/.env.example backend/.env
cp flutter_application_1/lib/config/secrets.example.dart flutter_application_1/lib/config/secrets.dart
cp admin-web/.env.example admin-web/.env
```

Fill in `backend/.env` (see the keys listed in [DEPLOYMENT.md](DEPLOYMENT.md) section 2).
For local dev you can use `DB_MODE=local` + the Postgres container.

---

## 2. Run the backend

### Option A — docker compose (recommended)
```bash
docker compose up --build
```
This brings up Postgres 16 + FastAPI on `:8000`.

### Option B — manual
```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt   # pytest, ruff, httpx

uvicorn main:app --reload
```

Open <http://localhost:8000/docs> for the interactive OpenAPI spec.

### First-time DB setup
If running against a fresh local Postgres:
```bash
cd backend
python run_migrations.py            # runs init_database.sql + migrations/*
```
Set `DB_MODE=supabase` in `.env` to target Supabase instead.

---

## 3. Run the Flutter app

```bash
cd flutter_application_1
flutter pub get

# Android emulator: loopback to host machine is 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical device on same Wi-Fi
flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:8000
```

`secrets.dart` must contain your Supabase project URL + anon key (used by
`supabase_flutter` to initialise auth).

---

## 4. Run admin-web

```bash
cd admin-web
npm install
npm run dev       # http://localhost:5173
```

`VITE_API_BASE_URL` in `.env` controls where the dashboard calls.

> Known follow-up: `src/api/client.ts` does not yet attach the admin JWT
> (`Authorization: Bearer ...`). Admin endpoints return 401 until that is wired.

---

## 5. Tests

### Backend
```bash
cd backend
pip install -r requirements-dev.txt
pytest -q
ruff check .
```
Tests live in `backend/tests/` and use FastAPI `dependency_overrides` to mock
auth + DB — no network or real DB needed.

### Flutter
```bash
cd flutter_application_1
flutter analyze
flutter test
```
Widget tests are in `flutter_application_1/test/`.

CI (`.github/workflows/ci.yml`) runs both suites on every push/PR.

---

## 6. Project layout cheatsheet

```
backend/
  main.py               thin entrypoint — wires CORS, limiter, routers
  app/
    core/               config (pydantic-settings), security, shared deps
    models/schemas.py   Pydantic request/response models
    routers/            12 domain routers — add new endpoints here
    services/           business logic (nutrition, email)
  auth/dependencies.py  Supabase JWT verification
  ai_models/            Gemini multi-agent pipeline
  migrations/           SQL migrations v1..v13
  tests/                pytest suite
flutter_application_1/
  lib/
    config/             env + Supabase secrets
    screens/            UI — one folder per flow
    services/           HTTP + auth
    widgets/            shared UI
  test/                 widget tests
admin-web/              React + Vite dashboard
```

---

## 7. Common gotchas

| Problem | Fix |
|---|---|
| `ModuleNotFoundError: slowapi` | `pip install -r backend/requirements.txt` |
| Tests fail with `ModuleNotFoundError: psycopg2` | install `requirements.txt` **and** `requirements-dev.txt` |
| Android emulator can't reach backend | use `10.0.2.2` (not `localhost`) for `API_BASE_URL` |
| iOS simulator can't reach backend | use `127.0.0.1` or your LAN IP |
| Auth endpoints return 401 in Postman | copy the JWT from Supabase dashboard → `Authorization: Bearer <jwt>` |
| `flutter build apk` fails on signing | generate a release keystore and wire `android/key.properties` — the checked-in debug keystore is **not** suitable for release |
| CORS error from admin-web | add the admin-web origin (e.g. `http://localhost:5173`) to `ALLOWED_ORIGINS` in `backend/.env` |

---

## 8. Adding a new endpoint

1. Add a Pydantic model in `backend/app/models/schemas.py`.
2. Add a handler in the relevant `backend/app/routers/<domain>.py` (or create
   a new router and register it in `backend/main.py`).
3. Protect it with `Depends(get_current_user)` or `Depends(get_current_admin)`
   from `backend/auth/dependencies.py`.
4. Add a test in `backend/tests/` — `conftest.py` exposes `app_client`
   (authenticated) and `unauth_client` fixtures.
5. If the endpoint writes data, also add a SQL migration under
   `backend/migrations/` and bump `run_migrations.py`.

---

## 9. Useful commands

```bash
# Fresh DB
docker compose down -v && docker compose up --build

# Only run backend tests touching auth
pytest backend/tests/test_auth_guard.py -v

# Lint & autofix
ruff check backend/ --fix

# Flutter hot-reload (already default with `flutter run`)
# press `r` in the terminal; `R` for full restart
```

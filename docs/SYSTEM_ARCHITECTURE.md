# System Architecture — Calories Guard

_Snapshot: 2026-04-19, branch `claude/jolly-wu` (post-v14)._
_Target deployment: Railway (backend container) + Supabase (Postgres/Auth/Storage) + Firebase App Distribution (APK)._

---

## 1. High-level Component Diagram

```mermaid
flowchart TB
    %% ===================== CLIENTS =====================
    subgraph Clients["Clients"]
      direction TB
      MobileApp["Flutter mobile app<br/><i>com.caloriesguard.app</i><br/>Android / iOS"]
      AdminWeb["Admin web (Vite + React)<br/><i>admin-web/</i>"]
    end

    %% ===================== EDGE / HOSTING =============
    subgraph Edge["Edge / Hosting"]
      direction TB
      Railway["Railway service<br/>(Docker container, /health probe)"]
    end

    %% ===================== BACKEND =====================
    subgraph Backend["FastAPI backend (backend/app)"]
      direction TB
      Main["main.py<br/>create_app() factory"]
      CORS["CORS middleware<br/>(ALLOWED_ORIGINS env)"]
      AuthDep["app/core/security.py<br/>Supabase JWT verify"]
      subgraph Routers["app/routers/*"]
        direction TB
        R_auth["auth.py"]
        R_users["users.py"]
        R_foods["foods.py"]
        R_meals["meals.py"]
        R_admin["admin.py"]
        R_water["water.py"]
        R_weight["weight.py"]
        R_health["health.py"]
        R_insights["insights.py"]
        R_chat["chat.py"]
        R_notif["notifications.py"]
        R_social["social.py"]
      end
      subgraph Services["app/services/*"]
        direction TB
        S_nutrition["nutrition_service.py<br/>TDEE · macros"]
        S_email["email_service.py<br/>SMTP"]
      end
      ChatAgent["chatbot_agent.py<br/>+ ai_models/ multi-agent"]
      Storage["supabase_storage.py<br/>(signed URLs)"]
    end

    %% ===================== SUPABASE ====================
    subgraph Supabase["Supabase (zawlghlnzgftlxcoipuf)"]
      direction TB
      SBAuth["Auth<br/>(email + OAuth providers)"]
      SBDB["Postgres 17 · schema<br/><b>cleangoal</b><br/>35 tables, 8 enums<br/>RLS on user-owned tables"]
      SBStorage["Storage bucket<br/><b>food-images</b>"]
      SBPooler["Connection pooler<br/>(pgbouncer 6543)"]
    end

    %% ===================== EXTERNAL ====================
    subgraph External["External services"]
      direction TB
      Gemini["Google Gemini API<br/>(food macros + AI coach)"]
      Sentry["Sentry<br/>(errors + traces)"]
      Uptime["UptimeRobot<br/>GET /health"]
      SMTP["SMTP provider<br/>(verification emails)"]
      FAD["Firebase App Distribution<br/>(APK delivery)"]
    end

    %% ===================== CI/CD =======================
    subgraph CICD["CI / CD"]
      direction TB
      GH["GitHub Actions<br/>.github/workflows/ci.yml<br/>(ruff · pytest · flutter analyze/test)"]
      RailwayDeploy["Railway auto-deploy<br/>(on merge to main)"]
    end

    %% ===================== FLOWS =======================
    MobileApp -- "HTTPS + Bearer JWT" --> Railway
    AdminWeb  -- "HTTPS + Bearer JWT" --> Railway
    Railway --> Main --> CORS --> AuthDep --> Routers
    Routers --> Services
    R_chat --> ChatAgent
    R_foods --> ChatAgent
    ChatAgent -- "Gemini 1.5/2.x" --> Gemini
    Routers -- "psycopg2 + pooler" --> SBPooler --> SBDB
    R_foods --> Storage
    Storage --> SBStorage
    MobileApp -- "auth (email/OTP, Google OAuth)" --> SBAuth
    AdminWeb  -- "auth" --> SBAuth
    SBAuth -- "signed JWT (HS256)" --> AuthDep
    S_email --> SMTP
    Main -- "sentry_sdk[fastapi]" --> Sentry
    MobileApp -- "sentry_flutter" --> Sentry
    Uptime -- "every 5m" --> Railway
    GH --> RailwayDeploy --> Railway
    FAD --> MobileApp
```

_Rationale for the layout: clients at the top, edge/ingress next, backend responsibilities expanded in the centre, persistence + side-effects on the right, dev pipeline at the bottom. This matches the layering that the codebase actually enforces (routers → services → DB / external API)._

---

## 2. Request lifecycle — a typical meal log

```mermaid
sequenceDiagram
    autonumber
    participant U as User (Flutter)
    participant API as FastAPI /meals
    participant AUTH as Supabase Auth
    participant DB as Supabase Postgres
    participant G as Gemini
    participant TRG as DB trigger<br/>trg_sync_water_to_daily

    U->>AUTH: POST /auth/v1/token (email+password)
    AUTH-->>U: access_token (JWT, exp≈1h)
    U->>API: POST /meals {meal_type, items[]}<br/>Authorization: Bearer <jwt>
    API->>API: verify JWT (HS256 · SUPABASE_JWT_SECRET)
    API->>DB: INSERT meals (user_id, meal_time, meal_type)
    API->>DB: INSERT detail_items (meal_id, food_id|food_name, macros)
    DB-->>API: summary totals (trigger recomputes daily_summaries)
    API-->>U: 201 {meal_id, totals}

    Note over U,API: Later, user adds water
    U->>API: POST /water/log {glasses}
    API->>DB: INSERT water_logs
    DB->>TRG: AFTER INSERT
    TRG->>DB: UPSERT daily_summaries.water_glasses

    Note over U,G: Unknown food flow
    U->>API: POST /foods/auto-add {name}
    API->>G: chat.completions(prompt: estimate macros)
    G-->>API: {calories, protein, carbs, fat}
    API->>DB: INSERT temp_food (awaiting admin)
    API-->>U: 202 {tf_id, status: pending}
```

---

## 3. Infrastructure view (deployment)

```mermaid
flowchart LR
    subgraph Dev["Dev workstation"]
      VSCode["VS Code + Flutter SDK"]
      Git["git push"]
    end

    Git -->|PR / merge main| GH[GitHub repo]
    GH -->|webhook| Actions["GitHub Actions<br/>ruff · pytest · flutter test"]
    Actions -->|pass| GHMain[(main branch)]
    GHMain -->|deploy hook| RW[Railway]

    subgraph RW["Railway — backend"]
      direction TB
      Dockerfile["backend/Dockerfile<br/>python:3.11-slim"]
      Gunicorn["gunicorn + uvicorn workers"]
      ENV["Env: DB_MODE=supabase<br/>SUPABASE_* · GEMINI_API_KEY<br/>ALLOWED_ORIGINS · SENTRY_DSN"]
    end

    subgraph SB["Supabase project zawlghlnzgftlxcoipuf"]
      direction TB
      SBPG["Postgres 17<br/>schema: cleangoal<br/>+ pgbouncer 6543"]
      SBA["Auth (GoTrue)"]
      SBS["Storage · bucket food-images"]
    end

    RW -- 443 HTTPS --> SBPG
    RW -- REST --> SBA
    RW -- REST --> SBS

    RW --> Gemini[(Google Gemini API)]
    RW --> Sentry[(Sentry)]
    RW --> SMTP[(SMTP relay)]

    subgraph MobileDist["Mobile distribution"]
      direction TB
      APK["flutter build apk<br/>--dart-define=API_BASE_URL"]
      FAD["Firebase App Distribution"]
    end
    GHMain -->|manual build| APK --> FAD --> Testers((Beta testers))

    subgraph AdminDist["Admin web"]
      direction TB
      Vercel["Vercel / Netlify<br/>admin-web/dist"]
    end
    GHMain --> Vercel

    Testers -->|HTTPS| RW
    Admin((Admin user)) --> Vercel --> RW
```

---

## 4. Flutter app — layered structure

```mermaid
flowchart TB
    subgraph UI["UI layer (lib/screens/*)"]
      direction TB
      LoginS["auth/login_screen"]
      RecordS["record/record_food_screen"]
      ProgressS["profile/.../progress_screen"]
      AdminS["admin/*"]
    end

    subgraph State["State/helpers"]
      AuthCtx["providers/auth_provider"]
      NotifHelp["services/notification_helper"]
      LifeCycle["services/lifecycle_service"]
    end

    subgraph Net["Network / data"]
      APIClient["services/api_client.dart<br/>dio + interceptors<br/>(Authorization · timeout · 401→logout)"]
      AuthSvc["services/auth_service.dart<br/>Supabase Flutter SDK"]
      HealthSvc["services/health_service.dart"]
    end

    subgraph Platform["Platform"]
      SecureStore["flutter_secure_storage<br/>(refresh token)"]
      Firebase["firebase_core<br/>(App Distribution only)"]
      SentryFl["sentry_flutter"]
    end

    UI --> State --> Net
    Net --> APIClient --> Backend[(FastAPI /api)]
    Net --> AuthSvc --> Supabase[(Supabase Auth)]
    AuthSvc --> SecureStore
    UI --> Platform
    Platform --> SentryFl
```

---

## 5. Environments / config matrix

| Concern | Local dev | Staging (Railway) | Production (Railway) |
|---|---|---|---|
| `DB_MODE` | `local` (psycopg → localhost) | `supabase` | `supabase` |
| `SUPABASE_URL` | dev branch URL | staging Supabase project | prod Supabase project |
| `ALLOWED_ORIGINS` | `http://localhost:5173` | staging admin domain | prod admin domain |
| `GEMINI_API_KEY` | dev key (rate-limited) | staging key | prod key |
| `SENTRY_DSN` | empty (sentry disabled) | staging DSN | prod DSN |
| `APP_ENV` | `dev` | `staging` | `production` |
| `--dart-define=API_BASE_URL` | `http://10.0.2.2:8000` (emulator) | staging Railway URL | prod Railway URL |

---

## 6. Security posture (current)

- **Transport**: Railway fronts TLS 1.2+; backend sees `X-Forwarded-Proto: https`.
- **AuthN**: Supabase issues JWT (HS256 · `SUPABASE_JWT_SECRET`). Backend verifies signature + `exp`, maps `sub` → `cleangoal.users.user_id`.
- **AuthZ**: Route-level dependency `get_current_user()` / `get_current_admin()` (role_id == 1). RLS on user-owned tables acts as a second line — anon/authenticated keys cannot read those tables directly.
- **Rate limiting**: `slowapi` — `/login` 5/15min/IP, `/chat/*` 10/hour/user, `/upload-image` 10/min/user.
- **Upload validation**: 5 MB cap, mime whitelist (`image/jpeg|png|webp`).
- **Secrets**: Never in repo — Railway env vars + `flutter_secure_storage` on device. `.env.example` only documents keys.
- **Monitoring**: Sentry captures exceptions in both backend and Flutter client; UptimeRobot pings `/health`.

---

## 7. Data flow summary

| Source | Sink | Transport | Notes |
|---|---|---|---|
| Flutter app | FastAPI | HTTPS REST + Bearer JWT | Central `api_client.dart` handles 401→logout |
| FastAPI | Supabase Postgres | psycopg2 over pgbouncer (6543) | Pooled, SSL required |
| FastAPI | Gemini | HTTPS REST | 30s timeout + 1 retry |
| FastAPI | Supabase Storage | REST (service role) | Signed URLs returned to client |
| Flutter | Supabase Auth | HTTPS (GoTrue) | Email/OTP, Google OAuth |
| Backend / Flutter | Sentry | HTTPS | Errors + 10% traces |
| UptimeRobot | Railway | HTTPS `GET /health` | 5-minute interval |

---

## 8. Related docs

- `docs/ER_DIAGRAM.md` — full 35-table schema
- `docs/DATA_DICTIONARY.md` — table-by-table column descriptions
- `docs/DB_V14_NORMALIZE_PROPOSAL.md` — v14 rationale + rollback
- `docs/DEPLOYMENT.md` — step-by-step Railway + Supabase setup
- `docs/DEVELOPMENT.md` — local dev onboarding

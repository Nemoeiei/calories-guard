# Orchestration - Calories Guard

วันที่จัดทำ: 2026-04-24
ระบบ: Calories Guard
ขอบเขต: Mobile, Admin Web, Backend, Supabase, AI Provider, Storage, Observability และ CI/CD

เอกสารนี้อธิบายการประสานงานของระบบตั้งแต่ผู้ใช้กดใช้งานในแอป ไปจนถึง backend ตรวจสิทธิ์ เรียก service เขียนฐานข้อมูล เรียก AI provider และส่งผลกลับไปยัง client

## 1. ภาพรวม Orchestration

```mermaid
flowchart TB
    Mobile[Flutter Mobile App]
    Admin[React Admin Web]
    API[FastAPI Backend on Railway]
    Auth[Supabase Auth]
    DB[(Supabase Postgres<br/>schema cleangoal)]
    Storage[Supabase Storage<br/>food-images]
    AI[LLM Provider<br/>Ollama / Local / Legacy Hosted]
    Sentry[Sentry APM/Error]
    CI[GitHub Actions]
    Railway[Railway Deploy]

    Mobile -->|Supabase SDK login/OAuth| Auth
    Admin -->|Supabase SDK login| Auth
    Auth -->|JWT access token| Mobile
    Auth -->|JWT access token| Admin

    Mobile -->|HTTPS REST + Bearer JWT| API
    Admin -->|HTTPS REST + Bearer JWT| API

    API -->|verify JWT| Auth
    API -->|psycopg2 + search_path cleangoal| DB
    API -->|signed upload/read| Storage
    API -->|AI prompt| AI
    API -->|errors/traces| Sentry
    Mobile -->|client errors| Sentry

    CI -->|test/build/deploy workflow| Railway
    Railway --> API
```

แนวคิดหลักคือ backend เป็น orchestration hub ของ business logic ส่วน Supabase รับผิดชอบ identity, transactional data และ file storage ส่วน AI provider ถูกซ่อนหลัง `llm_provider.py` เพื่อให้ใช้ Ollama เป็นหลัก และยังสลับไป local transformers หรือ legacy hosted provider ได้โดยไม่ต้องแก้ router หลัก

## 2. Request Orchestration มาตรฐาน

```mermaid
sequenceDiagram
    autonumber
    participant Client as Mobile/Admin Client
    participant API as FastAPI Backend
    participant AuthDep as Auth Dependency
    participant Router as Router Layer
    participant Service as Service/Helper Layer
    participant DB as Supabase Postgres
    participant Obs as Sentry/Logger

    Client->>API: HTTPS request + Bearer JWT
    API->>API: CORS + X-Api-Version middleware
    API->>AuthDep: Decode Supabase JWT
    AuthDep-->>API: current_user / current_admin
    API->>Router: Route handler
    Router->>Service: validate/compute/prepare data
    Service->>DB: SQL query in schema cleangoal
    DB-->>Service: rows / affected row count
    Service-->>Router: domain result
    Router-->>Client: JSON response
    API-->>Obs: transaction/error tags
```

| ขั้น | Component | หน้าที่ |
|---|---|---|
| 1 | Client | ส่ง request ผ่าน HTTPS พร้อม Bearer token |
| 2 | FastAPI | จัดการ CORS, API version header, route matching และ exception handling |
| 3 | Auth dependency | ตรวจ Supabase JWT ด้วย `SUPABASE_JWT_SECRET` |
| 4 | Router | รับ payload, validate schema, คุม transaction และเรียก service |
| 5 | Database | ใช้ `DATABASE_URL`, `psycopg2`, `SET search_path TO cleangoal, public` |
| 6 | Observability | ส่ง trace/error ไป Sentry ใน flow สำคัญ |

## 3. Authentication Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant App as Flutter/Admin
    participant SB as Supabase Auth
    participant API as FastAPI
    participant DB as cleangoal.users

    U->>App: Login/Register
    App->>SB: signIn/signUp/OAuth
    SB-->>App: access_token + refresh_token
    App->>API: Request with Authorization: Bearer token
    API->>API: Decode JWT, read app_metadata.user_id/role_id
    API->>DB: Query/update user-owned data
    DB-->>API: user data
    API-->>App: JSON response
```

| ส่วน | รับผิดชอบ |
|---|---|
| Supabase Auth | login, register, OAuth, session และ token lifecycle |
| Flutter/Admin Web | เก็บ session และแนบ token ตอนเรียก backend |
| FastAPI auth dependency | verify token และแยก user/admin |
| `cleangoal.users` | เก็บ profile, role และ health target ของผู้ใช้ |

## 4. Meal Logging Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter Record Screen
    participant API as POST /meals/{user_id}
    participant Auth as get_current_user
    participant DB as Supabase Postgres
    participant Trg as DB Trigger
    participant Notif as notifications

    App->>API: meal_type + date + items[]
    API->>Auth: verify ownership
    Auth-->>API: OK
    API->>DB: INSERT meals
    API->>DB: INSERT detail_items per item
    DB->>Trg: sync daily summary trigger / aggregate logic
    Trg->>DB: UPSERT daily_summaries
    API->>DB: read daily total vs target
    API->>Notif: insert warning/tip if over or near target
    API-->>App: Meal recorded successfully
```

| Table | บทบาท |
|---|---|
| `meals` | header ของมื้ออาหารหนึ่งมื้อ |
| `detail_items` | รายการอาหารแต่ละตัวในมื้อ |
| `foods` | catalogue โภชนาการอ้างอิง |
| `units` | หน่วยของ amount ผ่าน `detail_items.unit_id` |
| `daily_summaries` | aggregate ต่อวันสำหรับ progress |
| `notifications` | แจ้งเตือนเมื่อใกล้หรือเกินเป้าหมาย |

## 5. AI Meal Estimate Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter AI Meal Sheet
    participant API as POST /api/meals/estimate
    participant Guard as AI_ENABLED + Rate Limit
    participant Extract as Food Extraction
    participant DB as foods/temp_food
    participant LLM as LLM Provider

    App->>API: Thai free text
    API->>Guard: check AI_ENABLED + slowapi
    Guard-->>API: allowed
    API->>Extract: sanitize + extract food mentions
    Extract->>DB: match known foods dictionary
    alt Known food
        DB-->>API: nutrition from foods
    else Unknown food
        API->>LLM: estimate macro/calorie
        LLM-->>API: structured estimate
        API->>DB: INSERT temp_food for admin review
    end
    API-->>App: items, total macro, allergy warnings
```

| Mechanism | รายละเอียด |
|---|---|
| `AI_ENABLED` | kill-switch ปิด AI endpoint ผ่าน env |
| Timeout | 30 วินาทีผ่าน thread pool wrapper |
| Rate limit | `/api/meals/estimate` จำกัด 30/hour |
| Temp food review | อาหารที่ AI ประเมินแต่ยังไม่ verified ถูกส่งเข้า `temp_food` |
| Admin approval | admin ตรวจแล้ว promote เข้า `foods` |

## 6. 3-Agent Chat Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant User as User
    participant API as /api/chat/multi
    participant Scope as Scope Guard
    participant A1 as DataOrchestrator
    participant A2 as NutritionAnalysis
    participant A3 as ResponseComposer
    participant DB as Supabase Postgres
    participant LLM as Ollama/Local/Legacy Hosted

    User->>API: message + user_id + optional lat/lng
    API->>Scope: reject off-topic questions
    Scope-->>API: in-scope
    API->>A1: fetch user context
    A1->>DB: profile, meals, logs, goals
    DB-->>A1: user_context
    opt location provided
        A1->>A1: fetch nearby restaurants
    end
    API->>A2: analyze message + context
    A2->>DB: match foods / infer nutrition
    A2-->>API: structured analysis
    API->>A3: compose final answer
    A3->>LLM: generate natural Thai response
    LLM-->>A3: final text
    API-->>User: response
```

| Agent | หน้าที่ | Output |
|---|---|---|
| DataOrchestratorAgent | ดึงข้อมูลผู้ใช้และบริบทสุขภาพจาก DB | `user_context` |
| NutritionAnalysisAgent | วิเคราะห์อาหาร กิจกรรม goal และ allergy | `analysis` |
| ResponseComposerAgent | เรียบเรียงคำตอบภาษาไทยให้อ่านง่าย | `final_response` |

## 7. Recipe Lazy-Fill Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant App as Recipe Detail Screen
    participant API as GET /recipes/{food_id}
    participant DB as recipes/foods
    participant LLM as LLM Provider

    App->>API: open recipe by food_id
    API->>DB: SELECT recipes JOIN foods WHERE food_id
    alt Recipe exists
        DB-->>API: cached recipe row
        API-->>App: shaped recipe response
    else Missing recipe
        API->>DB: SELECT food metadata
        API->>LLM: generate Thai recipe JSON
        LLM-->>API: description, steps, ingredients, tools, tips
        API->>DB: INSERT recipes with JSONB cache
        API-->>App: generated recipe response
    end
```

| Table | บทบาท |
|---|---|
| `foods` | อาหารที่ผู้ใช้กดดูสูตร |
| `recipes` | recipe header และ JSONB AI cache |
| `recipe_reviews` | รีวิวต่อ `recipe_id` |
| `recipe_ingredients/steps/tools/tips` | recipe detail แบบ normalized สำหรับข้อมูล seed/edit |

## 8. Admin Food Approval Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant User as Mobile User
    participant API as /foods/auto-add
    participant DB as temp_food/verified_food
    participant Admin as Admin Web
    participant AdminAPI as /admin/temp-foods
    participant Foods as foods

    User->>API: suggest unknown food
    API->>DB: INSERT temp_food
    DB->>DB: trigger creates verified_food baseline
    Admin->>AdminAPI: list pending temp foods
    AdminAPI->>DB: SELECT v_admin_temp_food_review
    DB-->>AdminAPI: pending list
    Admin->>AdminAPI: approve with corrected macros/category
    AdminAPI->>DB: UPDATE temp_food + verified_food
    AdminAPI->>Foods: INSERT foods
    AdminAPI-->>Admin: approved food_id
```

## 9. Deployment Orchestration

```mermaid
sequenceDiagram
    autonumber
    participant Dev as Developer
    participant GH as GitHub
    participant CI as GitHub Actions
    participant RW as Railway
    participant SB as Supabase
    participant Probe as Synthetic Probe

    Dev->>GH: push / pull request
    GH->>CI: run ci.yml
    CI->>CI: backend pytest and configured checks
    alt main branch
        GH->>RW: deploy backend container
        RW->>RW: build Dockerfile + start gunicorn/uvicorn
        RW->>SB: connect using DATABASE_URL
        Probe->>RW: synthetic login/meal/summary cron
    end
```

| Workflow | หน้าที่ |
|---|---|
| `.github/workflows/ci.yml` | ตรวจคุณภาพ code/test ตอน push/PR |
| `.github/workflows/deploy.yml` | deploy staging/prod ตาม branch/manual dispatch |
| `.github/workflows/synthetic.yml` | probe E2E ทุก 10 นาทีตาม configuration |

## 10. Failure Handling

| Failure | Detection | Handling |
|---|---|---|
| JWT หมดอายุหรือไม่ถูกต้อง | auth dependency | return 401, client logout/refresh |
| user เข้าถึงข้อมูลคนอื่น | `check_ownership` | return 403 |
| AI provider ช้า | timeout 30s | return 504 |
| AI ถูกปิด | `AI_ENABLED=false` | return 503 |
| DB constraint fail | PostgreSQL FK/unique/check | transaction rollback |
| orphan legacy data | v17/v18 migration checks | archive table ก่อน enforce FK |
| deploy fail | Railway/GitHub Actions | healthcheck/synthetic fail |

## 11. Summary

Calories Guard ใช้ backend เป็น orchestration hub:

1. Client authenticate กับ Supabase Auth
2. Client ส่ง token ให้ FastAPI
3. FastAPI ตรวจสิทธิ์และ ownership
4. Router เรียก service, DB, AI หรือ storage ตามงาน
5. Supabase Postgres enforce relationship, RLS และ trigger
6. Sentry, GitHub Actions และ synthetic probe ตรวจ runtime/deployment


# Calories Guard — Status (ณ 2026-04-24)

> สรุปสิ่งที่ทำแล้ว + ที่เหลือต้องทำ สำหรับส่งงานให้ AI/คนอื่นสานต่อ
> แหล่งความจริง: `origin/main` ที่ HEAD = `1ec2d765`
> คู่กับไฟล์: [WORK_HISTORY.md](WORK_HISTORY.md) (log รายเซสชัน) · [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) (task-by-task specs) · [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)

---

## 1. System Overview (สั้น)

3 ชั้น — มือถือ (Flutter) + admin web (React) + backend (FastAPI บน Railway) + Supabase (Auth/Postgres/Storage) + LLM (Ollama/local/legacy hosted swap ผ่าน `LLM_PROVIDER` env)

- Mobile: `flutter_application_1/` — Riverpod + supabase_flutter
- Backend: `backend/main.py` + `backend/app/routers/*` (โมดูล) · Gunicorn + Uvicorn 2 workers · Docker บน Railway
- Admin web: `admin-web/` — Vite + React + Tailwind · Cloudflare Pages
- DB: Supabase Postgres schema `cleangoal` (migrations v8–v19) + RLS + food-images bucket
- AI: `backend/ai_models/llm_provider.py` (unified) + `chatbot_agent.py` (3-agent pipeline)
- Ops: GitHub Actions (ci / deploy / synthetic-every-10-min), Sentry APM, Railway cron cleanup

ดูไดอะแกรมเต็มที่ [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)

---

## 2. สิ่งที่ทำเสร็จแล้ว (Done)

### P0 — Release blockers
- [x] Android bundle id = `com.caloriesguard.app` (commit `a6cb7222`)
- [x] Supabase Auth migration — Firebase ออก, Supabase JWT เข้า (commit `4106a30f`)
- [x] Supabase `cleangoal` schema clean + RLS baseline (v15, v15_c)
- [x] Storage bucket policies — `food-images` tightened (v15_d)
- [x] Android release keystore runbook ([docs/RELEASE_KEYSTORE.md](RELEASE_KEYSTORE.md))
- [x] `search_path` pin บน function ทั้งหมด (v15)

### Backend / API
- [x] Backend split จาก 4200-line monolith → modular routers (12 routers) — commit `ca2f7c9d`
- [x] pydantic-settings config + Sentry integration + exception handlers
- [x] API versioning + `X-Api-Version` header + client mismatch detection (commit `dda11a95`)
- [x] AI kill-switch `AI_ENABLED=false` (commit `79d80cb6`)
- [x] PDPA data export + soft-delete endpoints (commit `468ba67c`)
- [x] LLM provider abstraction — Ollama / local / legacy hosted swap (commit `ed09f7ca`)
- [x] Recipe endpoint — LLM lazy-fill + JSONB cache (commit `f743a951`) **[ดู §4: schema duplication]**
- [x] Rate limiting — slowapi 10/hr chat, 30/hr meal estimate
- [x] `DATABASE_URL` + pool; psycopg2 + `search_path = cleangoal, public`

### Mobile (Flutter)
- [x] แทน `catch (_)` เงียบๆ ด้วย `ErrorReporter` ทั้งแอป (commit `b780e811`)
- [x] Email availability check + case-insensitive lookup (commit `84fde30b`)
- [x] Forgot-password + register email ผ่าน Supabase Auth (commit `a0bfd79f`)
- [x] Progress screen — weekly calorie goal card ชัดขึ้น (commit `733cce94`)
- [x] Add-food flows — จากทุก meal slot + search + quick-add (commit `157cc7b3`)
- [x] Password rules เป็น red text inline บน register (commit `e6f64e2f`)
- [x] Samsung Health — code เสร็จ (commit `c4328486`) **[ยังไม่เทสต์เครื่องจริง]**
- [x] Tap-to-recipe flow — กดเมนูแล้วเปิดหน้าสูตร (commit `f743a951`)

### Admin Web
- [x] Admin-web wiring — Railway backend + Cloudflare Pages (commit `5b737411`)
- [x] Admin food-approval workflow (`temp_food` → `verified_food`)

### Data / Seed / i18n
- [x] CSV-driven Thai food importer (commit `49db83c1`)
- [x] Thai / English l10n สำหรับ public + hot-path screens (commit `dfce599a`)
- [x] DeepSeek LoRA fine-tune notebook — app-scoped (commit `1ec2d765`)
- [x] Supabase 3NF cleanup + dish taxonomy — `dish_categories -> dishes -> foods`, FK cleanup, orphan archives (v18/v19, 2026-04-24)

### Ops / Deploy / Observability
- [x] Deploy pipeline — staging auto / prod manual + smoke test + Slack (commit `3c3aa50a`)
- [x] Synthetic E2E probe (login→meal→summary) + 10-min cron (commit `32e2ad05`)
- [x] k6 load tests — foods search, meal loop, chat (commit `d7e7c286`)
- [x] Sentry SLO transaction tagging (commit `1b310d42`)
- [x] Privacy Policy + Terms of Service draft (commit `2f27be02`)
- [x] Railway `$PORT` deploy fix (commit `37d55627` — วันนี้)

### Tests
- [x] Backend pytest — 60 passed / 1 skipped (ทุก router) (commits `836d7210`, `b1426806`)

---

## 3. สิ่งที่ยังไม่ได้ทำ (Todo)

### P0 — ยังติดก่อน closed beta
- [ ] **Samsung Health real-device verify** — code เสร็จแล้ว (commit `c4328486`) แต่ยังไม่รันบน Android จริง
  - ต้องเช็ก: FlutterFragmentActivity, Health Connect permissions dialog, intent filter, package visibility
  - ถ้าฟังก์ชันพัง ต้องไล่ log `com.google.android.apps.healthdata` และ `com.sec.android.app.shealth`
- [ ] **Rotate Supabase DB password** — password เคยถูก paste ใน chat แล้ว ต้อง rotate ก่อนใช้ staging/prod จริง
- [x] **Recipe schema decision** — เลือก Approach B: JSONB columns ใน `recipes` + LLM cache
  - `GET /recipes/{food_id}` เหลือ owner เดียวที่ `backend/app/routers/foods.py`
  - เพิ่ม regression test `backend/tests/test_recipe_routes.py` กัน route ซ้ำกลับมา
  - หมายเหตุ: `recipe_reviews` ยังอยู่เพราะเป็น social/review feature แยกจาก recipe detail payload

### P1 — ก่อน Production
- [x] **Production pre-deploy test plan** — ร่าง checklist ครบชุดแล้ว
  - scope ที่ต้องครอบคลุม: smoke (health, auth, meal CRUD, chat), load (k6 มีแล้ว แต่ยังไม่ได้รันจริง), security (RLS, rate limit), i18n (th/en), network error path, offline behavior, version mismatch
  - artifact: [PRE_DEPLOY_TESTS.md](PRE_DEPLOY_TESTS.md) พร้อมช่อง result/note สำหรับ release candidate
- [x] **Apply recipe/3NF migrations บน Supabase**
  - ไฟล์: [backend/migrations/v16_a_recipes_ai_fields.sql](../backend/migrations/v16_a_recipes_ai_fields.sql) — JSONB recipe AI cache
  - ไฟล์: [backend/migrations/v17_recipe_consistency.sql](../backend/migrations/v17_recipe_consistency.sql) — normalize `recipe_reviews` ให้ใช้ `recipe_id`
  - ไฟล์: [backend/migrations/v18_dishes_3nf_integrity.sql](../backend/migrations/v18_dishes_3nf_integrity.sql) — normalize `dish_categories/dishes`, `foods.serving_unit_id`, recipe/unit FKs
  - ไฟล์: [backend/migrations/v19_detail_items_unit_fk.sql](../backend/migrations/v19_detail_items_unit_fk.sql) — FK `detail_items.unit_id -> units.unit_id`
  - Applied live on Supabase 2026-04-24; archived 20 orphan seed reviews, 100 orphan recipe relation rows, and 19 invalid unit conversion rows
- [ ] **Staging environment** — provision Supabase staging project + Railway staging service แยกจาก prod (PRODUCTION_READINESS #10)
- [ ] **Load test บน staging จริง** — k6 scripts พร้อมแล้ว ([backend/scripts/loadtest/](../backend/scripts/loadtest/)) ต้องรันแล้วอ่าน p95/p99 (PRODUCTION_READINESS #13)
- [ ] **Sentry SLO dashboard** — สร้าง dashboard + alerts บน Sentry UI (code tagging เสร็จแล้ว, UI ยังไม่ได้ทำ) (PRODUCTION_READINESS #14)

### P2 — Polish / Ops
- [ ] **Expand Thai food database** — seed ปัจจุบันยังเล็ก, `temp_food` ยังต้องพึ่ง admin review (PRODUCTION_READINESS #12)
- [ ] **Publish Privacy Policy + ToS** — draft อยู่ใน repo แล้ว แต่ยังไม่ได้ upload ไปที่ public URL + ยังไม่ได้ใส่ link ในแอป (PRODUCTION_READINESS #18)
- [ ] **Cross-platform verification** — ทดสอบ iOS build (ปัจจุบันเทสต์แต่ Android)
- [ ] **Deeper monitoring** — uptime pings, DB connection pool metrics, LLM provider error rate (PRODUCTION_READINESS #19)

### Follow-ups ที่เจอใน session
- [ ] Notebook `deepseek_finetune.ipynb` ยังไม่ได้ train จริง — ต้องมี GPU/Colab Pro run ก่อนดูว่า alignment % ขึ้นจริงไหม
- [ ] Health Connect อาจไม่มีบน Samsung บางรุ่น — fallback path ใน `HealthService.healthConnectStatus()` ต้องเทสต์
- [ ] Railway redeploy หลัง commit `37d55627` — ต้องเปิด dashboard เช็กว่า `/health` เขียวจริง
- [ ] Final ER diagram/data dictionary should use [SUPABASE_3NF_AUDIT_2026_04_24.md](SUPABASE_3NF_AUDIT_2026_04_24.md) and [SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md](SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md) as the live post-v19 baseline

---

## 4. Known Issues / Tech Debt

- **`LLM_PROVIDER=ollama`** — ใช้ Ollama server แยกจาก backend; ต้องให้ backend reach `OLLAMA_BASE_URL` ได้
- **ไม่มี background queue** (Celery/RQ) — AI calls sync + timeout; ถ้า Ollama ช้า/down, user เห็น error ตรงๆ
- **ไม่มี Redis cache** — `recipes` JSONB คือ cache เดียว; `/foods`, `/users/me`, `/meals/*` ไม่มี layer cache
- **Recipe favorite naming** — endpoint `/recipes/{food_id}/favorite` ยังใช้ `user_favorites(food_id)` ตาม mobile API เดิม; `recipe_favorites` ถูก mark เป็น legacy ใน v17
- **Legacy env vars** `DB_HOST`/`DB_PORT`/`DB_NAME` ใน config ยังอยู่แต่ไม่ใช้ (เก็บไว้ backward compat) — ลบทิ้งเมื่อมั่นใจ
- **Forgot-password in-app OTP** — ตอนนี้เป็น no-op placeholder; Supabase ส่ง reset link ทางเมล UI ยังต้อง rework (WORK_HISTORY note)
- **iOS build** ยังไม่ได้ verify หลัง bundle id rename — ต้องเปิด Xcode ทดสอบ

---

## 5. Env vars ที่ต้องตั้งก่อน deploy

### Backend (Railway)
```
DATABASE_URL=<supabase postgres URL>
SUPABASE_URL=<https://xxx.supabase.co>
SUPABASE_ANON_KEY=<anon>
SUPABASE_JWT_SECRET=<HS256 secret>
SUPABASE_SERVICE_ROLE_KEY=<service role>  # สำหรับ storage uploads
LLM_PROVIDER=ollama                        # ollama | local | deepseek | gemini
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=deepseek-r1:1.5b
AI_ENABLED=true                            # kill-switch
SENTRY_DSN=<dsn>                           # optional
SENTRY_TRACES_SAMPLE_RATE=0.1              # default
APP_ENV=production                         # or staging / development
PDPA_RETENTION_DAYS=30                     # default
ALLOWED_ORIGINS=https://admin.caloriesguard.com,...
SMTP_SERVER=smtp.gmail.com                 # optional (password reset fallback)
SMTP_USERNAME / SMTP_PASSWORD / FROM_EMAIL / FROM_NAME
```

### Flutter build flags
```
--dart-define=API_BASE_URL=https://api.caloriesguard.com
--dart-define=SUPABASE_URL=https://xxx.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon>
```

### Admin web (Cloudflare Pages env)
```
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
VITE_API_BASE_URL=...
```

---

## 6. Handoff note สำหรับ AI/คนที่จะรับต่อ

แนะนำให้อ่านตามลำดับ:
1. [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) — เข้าใจภาพรวม
2. [ไฟล์นี้](STATUS.md) §2 + §3 — รู้ว่าอะไรเสร็จ/เหลือ
3. [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) — ถ้างานที่จะทำอยู่ใน 20 task นั้น ให้ทำตาม spec (Goal/Why/Files/Steps/Verification)
4. [WORK_HISTORY.md](WORK_HISTORY.md) — ดู context รายเซสชัน ถ้ามีเรื่อง conflict/decision

**Branch convention**: ทำงานบน `claude/<task-slug>` → PR เข้า `main`
**Smoke test ก่อน merge**: `cd backend && pytest` + `cd flutter_application_1 && flutter analyze`
**Deploy**: push `main` = auto staging / `workflow_dispatch + confirm=yes` = prod

งานแรกที่แนะนำให้หยิบ (P0): **rotate Supabase DB password** แล้ว **รัน Samsung Health บนเครื่องจริง** — สองอันนี้ยัง block closed beta launch

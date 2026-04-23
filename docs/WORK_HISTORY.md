# Work History — Calories Guard

บันทึกงานที่ทำในแต่ละ session เพื่อ trace กลับได้ว่าแก้อะไร ทำเมื่อไหร่ ผลเป็นไงบ้าง
รูปแบบ: ใหม่สุดอยู่บน / แต่ละ entry ใส่ วันที่ + task + สถานะ + คอมมิต/ไฟล์ที่แตะ

---

## 2026-04-24 — Session: Consolidate worktrees + feature backlog planning

### Context
- ก่อนหน้านี้มี 5 worktrees (claude/jolly-wu, agitated-ride, funny-agnesi, suspicious-kepler, sweet-chatterjee)
- main local ตามหลัง origin/main 30 commits (ทีมทำงานขนานกันไป)
- User set up Ollama + Docker + Cloudflare Tunnel บน PC บ้าน (ยังไม่ commit)
- User ต้องการ consolidate งานทั้งหมดเข้า main + push origin
- User เปิด backlog 7 งาน (admin-web wiring, duplicate check, email sending, add food flow, progress UI, DeepSeek swap, cross-platform)

### Plan (approved)
- Step 0: Tag backup points
- Step 1: .gitignore credentials + build artifacts
- Step 2: Commit docker infra to local main
- Step 3: Fast-forward pull origin/main
- Step 4: Merge claude/jolly-wu (expect conflicts in main.py, chatbot_agent.py, auth_service.dart)
- Step 5: Push origin/main
- Step 6+: Feature backlog

### Progress log
- [x] Step 0 — Tagged `backup/main-pre-merge-2026-04-24`, `backup/jolly-wu-pre-merge-2026-04-24`, `backup/origin-main-pre-merge-2026-04-24`
- [x] Step 1 — `.gitignore` chore commit `4cc2d00f` (Cloudflare creds, docker clone, keystore, scratch scripts)
- [x] Step 2 — Docker infra left untracked (whole `docker/` gitignored since it's an external clone of kesor/ollama-proxy)
- [x] Step 3 — Rebased gitignore commit onto origin/main (pulled 30 teammate commits)
- [x] Step 4 — Merged `claude/jolly-wu` — 30 conflicts resolved (commit `3501977f`)
- [x] Step 4b — Smoke test: backend pytest 60 passed/1 skipped; flutter analyze 0 errors (commit `1b7e0a67`)
- [x] Step 5 — Pushed to `origin/main` → HEAD `1b7e0a67`
- [ ] Step 6 — Audit Nemo's 15 post-`a601063c` commits for fixes missing from modular routers
- [ ] Task #2 — Duplicate email verify
- [ ] Task #3 — Email sending fix
- [ ] Task #5 — Progress UI
- [ ] Task #1 — Admin-web wiring
- [ ] Task #4 — Add-food flows
- [ ] Task #6 — DeepSeek swap
- [ ] Task #7 — Cross-platform

### Commits added this session
- `4cc2d00f` chore(gitignore): exclude Cloudflare Tunnel credentials, docker/ clone, release keystore, scratch scripts
- `a347b4ad` chore: reconcile local mods with origin/main (baseUrl prod default + google-services classpath)
- `3501977f` merge: claude/jolly-wu into main — production-readiness consolidation
- `1b7e0a67` fix(flutter): post-merge smoke-test fixes (intl ^0.20.2, plugin registrants, forgot_password signature)

### Conflicts encountered
Total: 30 conflicts on `git merge claude/jolly-wu`.

| Category | Count | Resolution |
|---|---|---|
| Build artifacts (flutter ephemeral, .dart_tool, ios Pods) | 17 | `git rm` — accept jolly-wu's deletion (already gitignored) |
| Core files jolly-wu rewrote wholesale | 6 | `git checkout --theirs` — backend/main.py (167 lines), Dockerfile, MainActivity.kt, build.gradle.kts, main.dart, auth_service.dart |
| Manual union-merge | 5 | pubspec.yaml (dep union), AndroidManifest.xml (Supabase OAuth deep link + union), requirements.txt, .env.example, login_screen.dart (kept jolly-wu's `_syncSocialBackend`), constants.dart (kept upstream supabaseUrl/anonKey/googleWebClientId + added kExpectedApiVersion + privacy/terms URLs), android/build.gradle.kts |
| Smoke-test drift | 2 | `forgot_password_screen.dart` adapted to Supabase `requestPasswordReset(email)` single-param signature; intl ^0.20.2 to satisfy flutter_localizations pin |

### Notes
- `login_screen.dart` — removed dead Facebook handler, kept only Google via Supabase OAuth (`signInWithOAuth(OAuthProvider.google, redirectTo: 'com.caloriesguard.app://login-callback')`)
- `AndroidManifest.xml` — added `com.linusu.flutter_web_auth_2.CallbackActivity` for Supabase OAuth deep link; both sides had already removed Facebook SDK metadata independently
- `docker/` gitignored overmatching: initial rule `CaloriesGuard/` accidentally hit kotlin package `kotlin/com/caloriesguard/` on case-insensitive Windows FS → fixed to `/CaloriesGuard/` (root-anchored)
- forgot-password in-app OTP is now a no-op placeholder; Supabase emails a reset link — Task #3 will rework the UI

---

## 2026-04-20 → 2026-04-23 — Session: Production readiness (claude/jolly-wu)

### Scope
งาน 20 ข้อจาก `docs/PRODUCTION_READINESS.md` เพื่อเตรียม closed beta

### Commits (30 commits, บน branch `claude/jolly-wu`)
- `f1b0bae7` fix: production blockers — keystore, upload validation, iOS perms, DB migrations
- `4106a30f` feat(auth): migrate Firebase Auth → Supabase Auth + protect all endpoints
- `ca2f7c9d` refactor(backend): split 4200-line monolith into modular router package
- `0d28a991` feat(ai): restrict chatbot scope + auto-add unknown foods to temp_food
- `a601063c` Merge origin/main: port admin food-approval workflow into modular routers
- `ece40e6e` chore: untrack build caches and flutter ephemeral files
- `76d18b17` feat: phase 1.6 tests + phase 3 deployment & hardening
- `018060ea` feat: admin-web auth + pythainlp food extraction + meal-estimate endpoint
- `bcd48ae9` feat: AI meal estimate UI + Thai food seed + Sentry/RLS hardening
- `cc96af55` feat(db): v14 normalize phase A+B — meal_type, FKs, CHECK/UNIQUE
- `001a1ebe` feat(db): v14 normalize phase C+D+E+F + ER/system diagrams
- `ea8df17d` docs: add PRODUCTION_READINESS.md with 20 actionable tasks
- `ed0c1566` chore(db): v15 security hardening — drop public leftovers + pin search_path
- `a6cb7222` chore(android): rename bundle id to com.caloriesguard.app
- `5564e291` chore(db): v15_c RLS policies baseline
- `e020fe67` chore(storage): v15_d tighten food-images bucket policies
- `b780e811` refactor(flutter): replace silent catch(_) with ErrorReporter
- `4ce4e441` docs: add Android release keystore runbook
- `79d80cb6` feat(ai): AI_ENABLED kill-switch on chat + meal-estimate
- `dda11a95` feat(api): API_VERSION + X-Api-Version header + client mismatch
- `468ba67c` feat(pdpa): data export + soft-delete endpoints
- `836d7210` test: expand backend test coverage — PDPA, meals, admin, AI kill-switch
- `b1426806` test: E2E meal roundtrip + integration suite scaffold
- `3c3aa50a` ci: deploy workflow (staging auto, prod manual) + staging runbook
- `49db83c1` feat(seed): CSV-driven Thai food importer with sanity validation
- `1b310d42` feat(observability): tag auth/meal/chat transactions for Sentry SLOs
- `dfce599a` feat(l10n): hot-path Thai/English catalogue for beta
- `2f27be02` docs(legal): draft Privacy Policy + Terms for closed beta
- `32e2ad05` feat(ops): synthetic E2E probe + 10-min cron workflow
- `d7e7c286` test(load): k6 scripts for foods search, meal loop, chat

### Artifacts created
- `backend/app/` — modular router package (auth, users, meals, foods, admin, chat, health_tracking, insights, notifications, misc)
- `backend/app/core/` — config (pydantic-settings), security (Supabase JWT), observability (Sentry), exceptions, database pool, logging
- `backend/tests/` — pytest suite ครบทุก router
- `backend/scripts/synthetic_check.py` + `.github/workflows/synthetic.yml`
- `backend/scripts/loadtest/{foods,meals,chat}.js` + README.md
- `backend/scripts/seed_thai_foods.py` — CSV importer
- `docs/{DEPLOYMENT,STAGING,MONITORING,RELEASE_KEYSTORE,SYNTHETIC_CHECK,L10N,PRODUCTION_READINESS}.md`
- `docs/DEPLOYMENT_CHECKLIST.md` (2026-04-24)
- `docs/privacy-policy.md`, `docs/terms-of-service.md`
- `flutter_application_1/lib/l10n/app_localizations.dart` — hand-rolled th/en
- Migrations `v14_*.sql`, `v15_*.sql` (normalize + RLS + storage)
- `experiments/llm_eval/questions_sample.csv` + `deepseek_r1_eval.ipynb`

### Known issues at end of session
- `claude/jolly-wu` ยังไม่ merge เข้า main → พร้อม merge 2026-04-24
- origin/main มี 30 commits ของทีมที่ยังไม่ได้ pull → conflict risk
- Deployment blocker: Nemoeiei ต้องยอม install Railway GitHub App

---

## Template สำหรับ session ใหม่

```markdown
## YYYY-MM-DD — Session: <title>

### Context
สถานการณ์ตอนเริ่ม session อะไร

### Plan
1. ...
2. ...

### Progress log
- [x] ขั้นที่ 1 — ผล: ...
- [ ] ขั้นที่ 2 — ติด: ...

### Commits
- `sha` short-desc

### Files touched
- path/to/file.py — reason

### Follow-ups
- สิ่งที่ต้องทำต่อ session หน้า
```

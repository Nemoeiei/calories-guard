# Calories Guard — Master Test Plan

> Purpose: แผนทดสอบหลักก่อน deploy / release สำหรับระบบ Calories Guard ทั้ง backend, Flutter user app, admin web, Supabase และ AI provider.
>
> Scope current architecture:
> - User app: Flutter Android + Flutter Web/PWA
> - Admin app: React/Vite `admin-web`
> - Backend: FastAPI
> - Database/Auth/Storage: Supabase schema `cleangoal`
> - AI: local/self-hosted Ollama DeepSeek model by default via `LLM_PROVIDER=ollama`; hosted providers are legacy fallback modes

## Release Gates

| Gate | When | Owner | Required before production |
|---|---|---|---|
| Commit Gate | Every commit / PR | Developer | Yes |
| Staging Gate | Before staging deploy | Developer + QA | Yes |
| Release Gate | Before production deploy | Release owner | Yes |
| Post-Deploy Gate | Immediately after deploy | Release owner | Yes |
| Periodic Assurance | Weekly / monthly | Maintainer | Before public launch |

## Minimum Commands

Run these before marking a release candidate as ready:

```powershell
pytest backend\tests
cd admin-web; npm run build
cd ..\flutter_application_1; flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Optional but recommended:

```powershell
pip-audit
npm audit --prefix admin-web
gitleaks detect --source .
```

## Test Type Coverage

| Test Type | What It Means For Calories Guard | Current / Required Coverage |
|---|---|---|
| Unit Tests | Pure functions and local logic | Nutrition formulas, Thai food extraction, LLM JSON parser, region enum, Flutter model parsing |
| Integration Tests | Multiple modules with DB/API | Meal logging, daily summary trigger, AI unknown food to `temp_food`, admin approve, regional name approve |
| Contract Tests | API shape stays stable for frontend | `/foods`, `/foods/search`, `/api/meals/estimate`, `/admin/temp-foods`, `/admin/regional-name-submissions` |
| E2E Tests | Browser/app UI to backend to DB | Flutter web user flow, admin web approval flow |
| Smoke Tests | Fast post-deploy checks | `/health`, login, search `ข้าวปุ้น`, AI estimate, admin queue |
| Regression Tests | Known bugs never return | Legacy food columns gone, v22 dropped tables, regional search, AI kill switch |
| Sanity Tests | Environment is basically correct | env present, DB connects, migrations applied, no frontend secret leakage |
| Functional Tests | Feature behavior | Auth, meals, foods, recipes, AI, region setting, admin review |
| Acceptance Tests | Business owner acceptance | User can log meals, AI can queue unknown food, admin can approve, local names display |
| UI / Visual Regression | Screens do not visually break | Flutter web, admin dashboard, regional page, food cards, settings |
| API Tests | Endpoint behavior and auth | 2xx/4xx/5xx, schema, auth guard, rate limit |
| Database Migration Tests | Migration works on fresh and existing DB | v20-v24, archive tables, triggers, schema_migrations |
| Data Integrity / Drift Tests | DB still matches expected schema | no orphan rows, no duplicate primary regional names, FK coverage |
| Performance Tests | Normal latency | foods/search/meal/admin p95 targets |
| Load Tests | Expected concurrent traffic | food search, meal loop, admin list, limited AI traffic |
| Stress Tests | Beyond capacity | DB pool saturation, burst admin approvals, AI rate limit |
| Soak / Endurance Tests | Long-running stability | 2-8 hour staging run, memory/connection leaks |
| Spike Tests | Sudden traffic jump | 0 to high VU in short time, no data corruption |
| Scalability Tests | Growth readiness | horizontal backend, Supabase pool, CDN static apps |
| Security Tests | SAST/DAST and auth checks | bandit/semgrep/ZAP, IDOR, CORS, RLS |
| Penetration Tests (basic) | Manual abuse attempts | admin bypass, SQLi, XSS in food names, upload abuse |
| Secrets Scan | No secrets committed | `.env`, docs, notebooks, static bundles |
| Dependency Vulnerability Scan | Known CVEs | `pip-audit`, `npm audit`, Flutter dependency review |
| License Compliance | Legal use of dependencies/model/assets | npm/pip/pub, Ollama model license, icons/assets/fonts |
| Configuration Validation | Env and deploy config correct | backend env, admin `VITE_API_BASE_URL`, Flutter `--dart-define` |
| Backup & Recovery Tests | Backup can be restored | `pg_dump`, restore to local/staging, verify data |
| Disaster Recovery Tests | Recover from major failure | restore DB, rollback deploy, disable AI |
| Chaos Engineering | Controlled failure injection | Ollama down, DB timeout, bad env on staging |
| Compatibility Tests | Devices/browsers/OS | Chrome, Edge, Safari iOS, Android emulator/device |
| Accessibility Tests | Users can navigate/read | keyboard, contrast, labels, text scaling |
| Localization Tests | Thai/English and regional Thai | language fallback, Thai date/number, local food names |
| Installation / Upgrade Tests | New and upgraded clients | fresh install, web cache, old token, old client version |
| Rollback Tests | Return to previous safe version | backend/admin/web rollback, DB restore plan |
| Canary Validation | Small release before full rollout | test admin/user first, then open wider |
| A/B Readiness | Experiment framework prepared | future feature flags for AI/local names |
| Feature Flag Verification | Flags safely enable/disable features | `AI_ENABLED`, regional names, recipe generation |
| Rate Limiting Tests | Abuse is throttled | chat 10/hr, meal estimate 30/hr, upload/admin |
| Idempotency Tests | Retries are safe | AI queue no duplicate, approve no duplicate, migrations rerun |
| Race / Concurrency Tests | Simultaneous writes are safe | double approve, duplicate regional submissions, meal retry |
| Idle / Timeout Tests | Expired sessions and slow services | token expiry, Ollama timeout, network timeout |
| Logging / Monitoring | Events visible | Sentry, logs, AI latency, admin actions |
| Alert Trigger Tests | Alerts actually fire | 5xx, DB errors, AI failures |
| Audit Trail Tests | Admin/user actions recorded | `verified_by`, `approved_by`, `reviewed_by`, timestamps |
| GDPR / PDPA Tests | Privacy requirements | export, delete, cross-user block, privacy docs |
| Third-Party Mock Tests | External services mocked in CI | Ollama, Supabase, Storage, email, Sentry |

## Production Critical Paths

| Path | Why Critical | Must Pass |
|---|---|---|
| Login and session | No app without auth | Yes |
| Food search and meal log | Core calorie tracking | Yes |
| Daily summary update | User trust in totals | Yes |
| AI unknown food submission | User can add foods missing from DB | Yes |
| Admin food approval | Converts unknown food into catalog | Yes |
| Regional name approval | Local Thai names become searchable/displayable | Yes |
| PDPA export/delete | Legal/privacy requirement | Yes |
| AI kill switch | Cost/outage control | Yes |

## Environment Checklist

| Area | Required Values |
|---|---|
| Backend DB | `DIRECT_DATABASE_URL` or `DATABASE_URL` |
| Supabase | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET` |
| AI | `AI_ENABLED=true`, `LLM_PROVIDER=ollama`, `OLLAMA_BASE_URL`, `OLLAMA_MODEL`, `OLLAMA_TIMEOUT` |
| CORS | `ALLOWED_ORIGINS=https://admin...,https://app...` |
| Admin Web | `VITE_API_BASE_URL=https://api...` |
| Flutter | `--dart-define=API_BASE_URL=https://api...`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` |

## Exit Criteria

A release is ready only when:

- All P0 tests pass.
- Any P1 failures have owner, workaround, and release approval.
- Supabase migrations are verified.
- Backup/restore plan exists for DB-impacting releases.
- Sentry/log monitoring is active.
- Rollback path is known.
- No frontend bundle contains backend secrets.

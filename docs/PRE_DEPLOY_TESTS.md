# Pre-Deploy Tests — Calories Guard

> Use this checklist for every closed-beta release candidate before promoting staging to production.
> Fill the Result column with `PASS`, `FAIL`, `SKIP`, or `N/A`, and link logs/screenshots in Notes.

## Release Info

| Field | Value |
|---|---|
| Date | |
| Commit SHA | |
| Tester | |
| Backend URL | |
| Supabase project | |
| Flutter build | |
| Admin web URL | |
| LLM provider | Ollama / local / legacy hosted |

## 1. Automated Gates

| Check | Command / Source | Result | Notes |
|---|---|---|---|
| Backend unit tests | `cd backend && python -m pytest -q` | | |
| Flutter static analysis | `cd flutter_application_1 && flutter analyze` | | |
| Flutter widget/unit tests | `cd flutter_application_1 && flutter test` | | |
| Admin web build | `cd admin-web && npm run build` | | |
| Deploy workflow staging job | GitHub Actions `Deploy -> staging` | | |
| Synthetic E2E probe | GitHub Actions `synthetic-every-10-min` or manual run | | |

## 2. Backend Smoke

| Check | Expected | Result | Notes |
|---|---|---|---|
| `GET /health` | 200, `status=ok`, `X-Api-Version` header present | | |
| `GET /foods` | 200, returns array, no 5xx in logs | | |
| `GET /recommended-food` | 200, returns up to 20 foods | | |
| Auth-required route without token | 401/403, never data leakage | | |
| Version header | All responses expose current API version | | |
| Sentry | No new unhandled backend errors during smoke | | |

## 3. Auth And Account

| Check | Expected | Result | Notes |
|---|---|---|---|
| Register with valid email | Supabase Auth user created, app profile created | | |
| Duplicate email register | Clear validation message, no duplicate profile | | |
| Login valid user | Enters app and loads profile data | | |
| Login wrong password | Clear failure, no crash | | |
| Forgot password | Supabase reset email sent or expected fallback behavior documented | | |
| Logout | Session cleared, protected screens inaccessible | | |
| PDPA export | Authenticated user can download own data | | |
| Soft delete | Account is marked deleted, login/data access blocked as designed | | |

## 4. Meal And Nutrition Flow

| Check | Expected | Result | Notes |
|---|---|---|---|
| Search existing Thai food | Relevant foods appear, macros visible | | |
| Search regional alias | Query such as `ข้าวปุ้น` returns canonical food with regional display name | | |
| Region preference display | User region changes food cards/recipe detail display names where regional primary exists | | |
| Add food to breakfast | Meal row created, daily summary updates | | |
| Add food to lunch/dinner/snack | Correct meal slot and totals | | |
| Quick-add unknown food | Creates `temp_food`/approval item, user sees confirmation | | |
| AI estimate unknown food | Unknown menu text is extracted, estimated, and queued in `temp_food` for admin review | | |
| Edit or delete meal item | Totals recalculate correctly | | |
| Progress screen weekly card | Goal and totals render without overflow | | |
| Network failure during meal save | User sees recoverable error, no duplicate writes | | |

## 5. AI Features

| Check | Expected | Result | Notes |
|---|---|---|---|
| `AI_ENABLED=false` | Chat and meal estimate return disabled response/status | | |
| LLM provider env | `LLM_PROVIDER=ollama`, `OLLAMA_BASE_URL`, `OLLAMA_MODEL`; no DeepSeek/Gemini key required | | |
| Chat in scope | Ollama DeepSeek model gives nutrition/health answer, no policy-breaking content | | |
| Chat out of scope | Politely refuses or redirects to app scope | | |
| Meal estimate existing food | Returns DB-backed calories/macros without creating duplicate temp food | | |
| Meal estimate regional alias | Recognizes approved regional aliases from `food_regional_names` | | |
| Meal estimate unknown food | Returns LLM estimate and creates/keeps one pending `temp_food` row | | |
| Recipe first load | `GET /recipes/{food_id}` generates/caches recipe if missing | | |
| Recipe second load | Uses cached DB row, no second LLM call expected | | |
| LLM provider error | User gets graceful 502/503 path, Sentry captures signal | | |

## 6. Admin Web

| Check | Expected | Result | Notes |
|---|---|---|---|
| Admin login | Admin-only pages accessible with admin account | | |
| Non-admin access | Blocked from admin APIs/pages | | |
| Food requests list | Pending `temp_food` items visible | | |
| Approve request | Creates/updates verified food and marks request reviewed | | |
| Reject request | Request status changes, no verified food created | | |
| Regional names list | Pending `food_regional_name_submissions` items visible | | |
| Approve regional name | Creates/updates `food_regional_names`, optional primary/popularity saved | | |
| Reject regional name | Submission changes to rejected and approved aliases remain unchanged | | |
| Admin web deep link | Refreshing `/regional-names`, `/foods`, `/users` does not 404 | | |
| Food edit | Food fields persist and appear in mobile/API | | |

## 7. Security

| Check | Expected | Result | Notes |
|---|---|---|---|
| Supabase security advisor | No ERROR-level public RLS findings | | |
| RLS self-owned tables | User A cannot read/write User B data via Supabase client | | |
| Service role key | Not present in Flutter/admin-web bundles or public logs | | |
| Hosted LLM API key | Not required for Ollama mode; no DeepSeek/Gemini key present in frontend bundles or public logs | | |
| CORS | Only configured origins allowed in staging/prod | | |
| Rate limit chat | More than 10/hr/IP is limited | | |
| Rate limit meal estimate | More than 30/hr/IP is limited | | |
| Storage bucket listing | Anonymous user cannot list all `food-images` objects | | |
| Upload validation | Oversized/invalid image rejected | | |

## 8. Localization And UX

| Check | Expected | Result | Notes |
|---|---|---|---|
| Thai locale main flow | Login, search, meal, progress strings are Thai | | |
| English locale main flow | Same screens render English strings | | |
| Long Thai text | Buttons/cards do not overflow on small Android screen | | |
| Version mismatch | Old client sees update prompt/path | | |
| Offline launch | App opens cached/safe state or clear offline error | | |
| Slow network | Loading/error states are visible and recoverable | | |

## 9. Mobile Device Matrix

| Device / OS | Build | Result | Notes |
|---|---|---|---|
| Android emulator, latest stable | | | |
| Physical Android, API 30+ | | | |
| Samsung device with Health Connect/Samsung Health | | | |
| Flutter web desktop Chrome | PWA loads, login, food search, meal estimate work | | |
| Flutter web iPhone Safari | PWA loads, Add to Home Screen flow documented | | |
| iOS simulator | Optional until Apple build pipeline exists | | |
| Physical iOS device | Optional via Flutter web/PWA until Apple Developer account exists | | |

## 10. Samsung Health Real-Device Checks

| Check | Expected | Result | Notes |
|---|---|---|---|
| App launches with `FlutterFragmentActivity` | No activity crash | | |
| Health Connect status | Correctly detects installed/unavailable/update-needed | | |
| Permission dialog | Steps/calories permissions requested and remembered | | |
| Package visibility | Health Connect and Samsung Health packages visible where needed | | |
| Sync steps | Recent step data imports or clear empty-state appears | | |
| Sync calories/activity | Calories/activity data imports or documented unsupported path | | |
| Fallback | Device without Health Connect shows safe fallback UI | | |
| Logs | No fatal errors from `com.google.android.apps.healthdata` or `com.sec.android.app.shealth` | | |

## 11. Load Test On Staging

Run only on staging. See `backend/scripts/loadtest/README.md`.

| Scenario | Command | Target | Result | Notes |
|---|---|---|---|---|
| Foods search | `k6 run backend/scripts/loadtest/foods.js` | p95 < 500 ms, errors < 1% | | |
| Meal loop | `k6 run backend/scripts/loadtest/meals.js` | p95 < 500 ms, no 5xx | | |
| Chat | `k6 run backend/scripts/loadtest/chat.js` | p95 target depends on LLM provider; rate limits respected | | |
| Railway metrics | Dashboard | No restarts, CPU/memory acceptable | | |
| Supabase metrics | Dashboard | Pool not saturated, no migration locks | | |

## 12. Go / No-Go

| Gate | Result | Notes |
|---|---|---|
| No P0 failures remain | | |
| Known P1 failures have owner and rollback plan | | |
| Staging DB migration verified | | |
| Sentry alerts/dashboard checked | | |
| Rollback target identified | | |
| Production deploy approved by | | |

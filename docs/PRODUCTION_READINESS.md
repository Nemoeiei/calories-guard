# Production Readiness Checklist — Calories Guard

> **Purpose**: executable task list for any engineer or AI agent to take the app from "working on my machine" to "safe for closed beta → production".
> **Audience**: a fresh agent without prior conversation context. Each task is self-contained: goal, why, exact files, steps, verification.
> **Last updated**: 2026-04-19 (post-v14 DB normalization).
> **Branch convention**: work on `claude/<task-slug>`, open PR to `main`.
> **Definition of done**: every box under **Verification** checked; PR green in CI; merged.

---

## How to use this file

1. Pick the lowest-numbered task that is not yet checked off under "Status".
2. Read **Goal → Why → Files → Steps → Verification** top to bottom.
3. Do the work on a topic branch. Commit early, commit often.
4. Update the **Status** box (`[ ]` → `[x]`) + append a line to **Change log** at the bottom of this file in the same PR.
5. Do NOT skip verification — if a step fails, add a note under the task and stop. Someone else picks it up.

Priority legend: **P0** = release blocker · **P1** = before beta · **P2** = polish/ops.

Dependency legend: if a task says "Depends on #N", finish N first.

---

# P0 — Release blockers

## 1. Rename Android bundle id to `com.caloriesguard.app`

**Status**: [ ]

**Goal**: Production app identifier must not be `com.example.*` (Play Store rejects it, and Firebase App Distribution treats `com.example.*` as a test artifact).

**Why**: irreversible once users install — changing it later forces every beta tester to uninstall/reinstall. Has to happen before the first signed APK is distributed.

**Files**:
- `flutter_application_1/android/app/build.gradle.kts` — `applicationId`
- `flutter_application_1/android/app/src/main/AndroidManifest.xml` — verify no hardcoded package refs
- `flutter_application_1/android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt` — move directory + fix package statement
- `flutter_application_1/android/app/google-services.json` — regenerate in Firebase console for the new package
- `flutter_application_1/ios/Runner.xcodeproj/project.pbxproj` — `PRODUCT_BUNDLE_IDENTIFIER` (set to `com.caloriesguard.app` for parity)
- `flutter_application_1/ios/Runner/Info.plist` — verify `CFBundleIdentifier`

**Steps**:
1. In `build.gradle.kts` change `applicationId = "com.example.flutter_application_1"` → `applicationId = "com.caloriesguard.app"`. Also set `namespace` to the same value.
2. Move the Kotlin source: `mv android/app/src/main/kotlin/com/example/flutter_application_1 android/app/src/main/kotlin/com/caloriesguard/app`. Update the `package` line at the top of `MainActivity.kt`.
3. Do the same for `debug/` and `profile/` flavors if they exist.
4. Regenerate `google-services.json` from Firebase console (add the new package, keep the old one for 1 release so debug installs keep working).
5. For iOS, open `Runner.xcodeproj` (or edit `project.pbxproj` via search/replace) and set `PRODUCT_BUNDLE_IDENTIFIER = com.caloriesguard.app;` for all three build configs (Debug/Release/Profile).
6. Run `cd flutter_application_1 && flutter clean && flutter pub get && flutter build apk --debug` to catch stale refs.

**Verification**:
- [ ] `flutter build apk --release --dart-define=API_BASE_URL=https://<staging>` succeeds.
- [ ] `aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep package` shows `name='com.caloriesguard.app'`.
- [ ] Fresh Android device install works; login → record meal → see saved data.

---

## 2. Clean up leaked tables in Supabase `public` schema

**Status**: [ ]

**Goal**: Every table exposed via Supabase PostgREST (`public` schema) must either be dropped or have RLS enabled with a policy.

**Why**: Supabase security advisor reports **ERROR**-level findings: `public.progress_snapshots`, `public.units`, `public.roles`, `public.users`, `public.foods`, `public.user_goals`, `public.user_activities`, `public.weight_logs`, `public.progress`, `public.health_contents`, `public.user_stats` have RLS disabled. Anyone with the anon key can `SELECT * FROM public.users` via REST. These appear to be leftovers from an earlier init before the project standardized on `cleangoal`.

**Files**:
- `backend/migrations/v15_a_drop_public_leftovers.sql` (new)

**Steps**:
1. For each table listed above, confirm it has **no dependencies** in `cleangoal` and no row the app needs:
   ```sql
   SELECT c.relname, n.nspname
   FROM pg_depend d
   JOIN pg_class c ON c.oid = d.refobjid
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE d.classid = 'pg_class'::regclass
     AND c.relname = '<table>' AND n.nspname = 'public';
   ```
2. If unused → `DROP TABLE public.<table> CASCADE;` in the migration.
3. If actually used (e.g. `public.units` might be seeded by a Supabase template), move it with `ALTER TABLE public.<t> SET SCHEMA cleangoal;` and update any code reference, then enable RLS.
4. Grep the codebase to be sure:
   ```
   rg "public\.(users|foods|units|roles|progress|weight_logs|health_contents|user_stats|user_goals|user_activities|progress_snapshots)"
   ```
   Expected result: zero hits in `backend/` and `flutter_application_1/`.
5. Apply via Supabase MCP `apply_migration` with name `v15_a_drop_public_leftovers`.

**Verification**:
- [ ] `mcp__supabase__get_advisors(type=security)` no longer lists any `rls_disabled_in_public` findings.
- [ ] Backend test suite still green (`pytest` in `backend/`).
- [ ] `SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type='BASE TABLE'` returns only Supabase system tables.

---

## 3. Write RLS policies for user-owned tables in `cleangoal`

**Status**: [ ] · **Depends on**: #2

**Goal**: Every user-owned table in `cleangoal` should have a policy so a stolen anon/authenticated key cannot read another user's rows.

**Why**: 17 tables in `cleangoal` have RLS enabled but **no policies** (security advisor `rls_enabled_no_policy`). PostgreSQL's default with RLS + no policy = "deny all to non-owner roles", which is safe _today_ because the backend uses the `postgres` role that bypasses RLS. But when we move to Supabase Auth (anon/authenticated roles per user), writes will silently fail. Policies close that gap and give us defense-in-depth.

**Files**:
- `backend/migrations/v15_b_rls_policies.sql` (new)

**Affected tables** (self-owned via `user_id`): `users`, `meals`, `detail_items`, `daily_summaries`, `water_logs`, `exercise_logs`, `weight_logs`, `notifications`, `temp_food`, `verified_food`, `food_requests`, `email_verification_codes`, `password_reset_codes`, `user_favorites`, `user_meal_plans`, `user_allergy_preferences`, `recipe_favorites`, `recipe_reviews`.

**Template** (per self-owned table):
```sql
CREATE POLICY "user_read_own" ON cleangoal.<t>
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'user_id')::bigint = user_id );

CREATE POLICY "user_write_own" ON cleangoal.<t>
  FOR ALL TO authenticated
  USING ( (auth.jwt() ->> 'user_id')::bigint = user_id )
  WITH CHECK ( (auth.jwt() ->> 'user_id')::bigint = user_id );
```

**Steps**:
1. Decide on the JWT claim that carries the DB `user_id`. In the current auth flow it's set in `backend/app/core/security.py`. Either:
   - Store `user_id` (int8) as a custom claim in the Supabase JWT at login (preferred), or
   - Resolve `auth.uid()` (UUID) → `cleangoal.users.user_id` via a `SECURITY DEFINER` helper function.
2. Write policies for each table. For `detail_items` (polymorphic), use a `USING` clause that joins to `meals` / `user_meal_plans` / `daily_summaries` to find the owner.
3. For `recipe_*` (no FK to user currently) — leave as-is for now or add "public read, authenticated write" policies.
4. Public read tables that should not be user-scoped: `foods`, `ingredients`, `units`, `allergy_flags`, `health_contents`, `recipes`, `recipe_*` public read. Add `CREATE POLICY "public_read" ON cleangoal.<t> FOR SELECT TO anon, authenticated USING (true);`.

**Verification**:
- [ ] `mcp__supabase__get_advisors(type=security)` no longer reports `rls_enabled_no_policy` on `cleangoal` tables.
- [ ] Backend regression: `pytest backend/tests -q` green.
- [ ] Manual test with anon key: `curl -H "apikey: <anon>" https://<ref>.supabase.co/rest/v1/users?select=*` returns `[]` (was the full user table before).

---

## 4. Pin `search_path` on all cleangoal functions

**Status**: [ ] · **Can run in parallel with #3**

**Goal**: No `SECURITY DEFINER` or trigger function should rely on the session's `search_path`.

**Why**: Supabase advisor `function_search_path_mutable` flags 7 functions. A malicious user who manages to create a function in `public` with the same name as a `cleangoal` object could hijack what the trigger calls. Pinning `search_path` eliminates that class of attack.

**Files**: `backend/migrations/v15_c_function_search_path.sql` (new)

**Affected functions**:
- `cleangoal.fn_sync_water_to_daily`
- `cleangoal.fn_sync_daily_summary`
- `cleangoal.fn_create_verified_food_on_temp_insert`
- `cleangoal.fn_temp_food_touch_updated_at`
- `cleangoal.fn_verified_food_touch_updated_at`
- `cleangoal.update_recipe_favorite_count`
- `cleangoal.update_recipe_rating`
- `public.handle_new_user`

**Steps**:
1. For each function, re-create (or `ALTER FUNCTION ... SET search_path = cleangoal, pg_catalog`).
   ```sql
   ALTER FUNCTION cleangoal.fn_sync_water_to_daily()
     SET search_path = cleangoal, pg_catalog;
   ```
2. Apply.

**Verification**:
- [ ] Advisor no longer reports `function_search_path_mutable`.
- [ ] Functional test: insert a water log and confirm `daily_summaries.water_glasses` still updates.

---

## 5. Create release keystore + signing config

**Status**: [ ]

**Goal**: Ship signed release APKs that can be distributed via Firebase App Distribution today and Play Store later.

**Why**: Current config falls back to the debug keystore for release builds. Debug-signed APKs are rejected by Firebase App Distribution and the Play Store, and every user must uninstall to receive a properly-signed build later.

**Files**:
- `~/calories-guard-release.jks` (created locally, backed up off-repo)
- `flutter_application_1/android/key.properties` (gitignored — already is)
- `flutter_application_1/android/app/build.gradle.kts` (verify signing block)
- `docs/DEPLOYMENT.md` §3 (already documents it — follow it)

**Steps**:
1. Generate the keystore:
   ```bash
   keytool -genkey -v \
     -keystore ~/calories-guard-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias calories-guard
   ```
   Use **strong, unique** passwords (store them in a password manager + back up the `.jks`).
2. Create `flutter_application_1/android/key.properties`:
   ```properties
   storePassword=<store_password>
   keyPassword=<key_password>
   keyAlias=calories-guard
   storeFile=/absolute/path/to/calories-guard-release.jks
   ```
3. Verify `android/app/build.gradle.kts` reads `key.properties` (it should already). If not, add the `signingConfigs { create("release") { ... } }` block per the `DEPLOYMENT.md` snippet.
4. Back up the `.jks` file to 2 places (password manager attachment + encrypted cloud folder). **Losing it = cannot publish updates.**

**Verification**:
- [ ] `flutter build apk --release` produces an APK signed with the new keystore:
  ```
  jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | grep "CN="
  ```
- [ ] Uploaded APK shows up in Firebase App Distribution and installs on a fresh device.
- [ ] `.jks` and `key.properties` are in `.gitignore` (`git check-ignore android/key.properties`).

---

# P1 — Before opening closed beta

## 6. Expand backend + Flutter test coverage

**Status**: [ ] · **Depends on**: — (can parallelize with #7)

**Goal**: Confidence that a PR doesn't break hot paths.

**Why**: Current: 6 backend test files, 2 Flutter test files. We routinely touch `routers/meals.py`, `routers/foods.py`, `routers/admin.py` without automated regression.

**Target coverage** (new test files, each pattern shown):

| Area | New file | Minimum cases |
|---|---|---|
| Auth 401/403 | `backend/tests/test_auth_routes.py` | register dup, login bad pw, /users/{other_id}→403 |
| Meals CRUD | `backend/tests/test_meals.py` | create → list → delete, daily totals recompute |
| Foods + temp_food | `backend/tests/test_foods.py` | search, quick-add → temp_food row, admin approve |
| Admin | `backend/tests/test_admin.py` | non-admin→403, approve temp_food flow |
| Water | `backend/tests/test_water.py` | log twice same day upserts, delete resets daily_summary |
| Weight | `backend/tests/test_weight.py` | log, update, history |
| Flutter login flow | `flutter_application_1/test/login_flow_test.dart` | form validation + happy path with mock Dio |
| Flutter record_food | `flutter_application_1/test/record_food_test.dart` | add item, totals update |

**Files**: see table; plus fixtures in `backend/tests/conftest.py` (exists) — extend with a `client_as(user_id=...)` helper.

**Steps**:
1. For each new backend test, use FastAPI's `TestClient` + a per-test Postgres fixture (or a mocked DB layer if tests are unit-scoped).
2. For Flutter, use `mocktail` or `mockito` to stub `Dio`. Run `flutter test` locally.
3. Add coverage report to CI: `pytest --cov=app --cov-report=xml`, and upload to Codecov (optional).

**Verification**:
- [ ] `pytest -q` → ≥ 25 tests pass (up from ~10).
- [ ] `flutter test` → ≥ 6 tests pass (up from 2).
- [ ] CI green on a PR touching a router — `git diff main -- backend/app/routers/meals.py` triggers meals tests.

---

## 7. Replace silent `catch (_) {}` in Flutter

**Status**: [ ]

**Goal**: No silent failure paths in the Flutter app — every caught error is either logged (Sentry) or shown to the user.

**Why**: 30 occurrences of `catch (_) {}` across `lib/`. A broken endpoint now manifests as a blank screen or stale data. Users think "the app is bad" instead of reporting a specific error.

**Files**: all under `flutter_application_1/lib/` — use:
```bash
rg --files-with-matches "catch \(_\)" flutter_application_1/lib/
```

**Steps**:
1. Create a helper `lib/utils/error_handler.dart`:
   ```dart
   void handleError(Object e, StackTrace st, {String? userMessage, BuildContext? ctx}) {
     Sentry.captureException(e, stackTrace: st);
     if (kDebugMode) debugPrint('Error: $e\n$st');
     if (ctx != null && userMessage != null) {
       ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(userMessage)));
     }
   }
   ```
2. Replace every `catch (_) {}` with either:
   - `catch (e, st) { handleError(e, st); }` (background tasks)
   - `catch (e, st) { handleError(e, st, userMessage: 'โหลดข้อมูลไม่สำเร็จ', ctx: context); }` (UI actions)
3. Where the intent _really is_ "ignore this error", replace with `catch (_) { /* intentional: <reason> */ }` — but be strict: fewer than 3 of these should remain.

**Verification**:
- [ ] `rg "catch \(_\)" flutter_application_1/lib/ | grep -v "intentional"` returns 0 hits.
- [ ] `flutter analyze` clean.
- [ ] Manual: disconnect wifi, open any screen → see a snackbar (not a blank page).

---

## 8. End-to-end integration test (at least one flow)

**Status**: [ ] · **Depends on**: #6

**Goal**: One automated black-box flow that exercises real HTTP → real DB.

**Why**: Unit tests mock the DB. Integration tests catch migration drift, wrong column names, missing env vars.

**Files**:
- `backend/tests/integration/test_e2e_meal.py` (new)
- `backend/tests/integration/conftest.py` (new — spins up a Postgres container via `testcontainers-python` or uses `DB_MODE=local`)
- `.github/workflows/ci.yml` — add an `integration` job that sets `DB_MODE=local`, runs init+migrations, runs these tests.

**Flow to cover**:
1. POST `/register` new user.
2. POST `/auth/login` → get JWT.
3. POST `/meals` with `meal_type=breakfast` + 2 detail items.
4. GET `/daily_summary?date=today` → asserts totals = sum of items.
5. DELETE `/meals/{id}` → daily_summary totals back to 0.

**Steps**:
1. Add a fixture that runs `backend/init_database.sql` + all `backend/migrations/*.sql` in order against a throwaway DB.
2. Write the test using `httpx.AsyncClient(app=app, base_url="http://test")`.
3. Run in CI as a second job so it doesn't gate unit tests but surfaces regressions.

**Verification**:
- [ ] `pytest backend/tests/integration -q` green locally.
- [ ] CI shows the new `integration` job passing.

---

## 9. Automated deploy pipeline (staging → prod)

**Status**: [ ] · **Depends on**: #10

**Goal**: Merging to `main` auto-deploys to staging; a manual "promote" step deploys to production.

**Why**: Right now Railway auto-deploys on push. No gate, no smoke test, no rollback story.

**Files**:
- `.github/workflows/deploy.yml` (new)
- `docs/DEPLOYMENT.md` — add "promotion" section

**Steps**:
1. Add GitHub Actions job `deploy-staging` that triggers on push to `main`:
   - Waits for `backend` + `flutter` jobs to succeed.
   - Calls Railway deploy webhook for the **staging** service (env `RAILWAY_STAGING_TOKEN`).
   - After deploy, runs `curl https://<staging>/health` 10× with backoff as a smoke test.
2. Add `deploy-prod` job triggered by a manual `workflow_dispatch` with input `confirm=yes`:
   - Deploys to prod Railway service.
   - Posts message to a Slack webhook (`PROD_DEPLOY_SLACK_URL`) with commit SHA.
3. Document rollback: `railway redeploy --environment production <previous-deployment-id>`.

**Verification**:
- [ ] Push a dummy commit → staging URL returns `{"status":"ok"}`.
- [ ] `gh workflow run deploy.yml -f confirm=yes` deploys prod + Slack ping fires.
- [ ] Rollback doc has concrete commands, not prose.

---

## 10. Provision staging Supabase + Railway environments

**Status**: [ ]

**Goal**: Dev/test data never touches production.

**Why**: All smoke tests and beta tester data currently go into the same Supabase project. One bad migration wipes real users.

**Steps**:
1. Create a second Supabase project `calories-guard-staging`. Apply `backend/init_database.sql` + all migrations in order.
2. Create a second Railway service `calories-guard-api-staging`. Copy env vars from prod but with staging Supabase credentials + `APP_ENV=staging`.
3. Add a staging variant for Flutter: `--dart-define=API_BASE_URL=https://staging-api.calories-guard.example.com`. Build a staging APK for internal testers.
4. Add a `[staging]` banner in the app when `APP_ENV != production` (read via `--dart-define`).

**Verification**:
- [ ] `curl https://<staging-api>/health` 200.
- [ ] Register a user on staging → does NOT appear in prod Supabase `users` table.
- [ ] Staging APK shows a visible "STAGING" banner.

---

## 11. Tighten Supabase Storage bucket policy

**Status**: [ ]

**Goal**: Bucket `food-images` should allow fetching by exact URL, **not** listing all objects.

**Why**: Advisor `public_bucket_allows_listing` flags that the current SELECT policy `USING (true)` plus `list=public` permits scraping every uploaded image.

**Files**: Supabase SQL editor (or migration via MCP).

**Steps**:
1. In Supabase Dashboard → Storage → `food-images` → Policies, delete the broad "Public read food-images" policy.
2. Add a narrower policy:
   ```sql
   CREATE POLICY "public_read_by_path" ON storage.objects
     FOR SELECT TO anon, authenticated
     USING (bucket_id = 'food-images');
   ```
   (This still allows `GET /storage/v1/object/food-images/<path>` but the default `storage.buckets.public = false` prevents listing.)
3. Set bucket `public = false` in Dashboard settings and verify images still load in the app (they should — the SDK uses signed/public URLs).

**Verification**:
- [ ] Advisor no longer flags `public_bucket_allows_listing`.
- [ ] `curl https://<ref>.supabase.co/storage/v1/bucket/food-images` (list) returns 403.
- [ ] `curl https://<ref>.supabase.co/storage/v1/object/food-images/<known-path>` still returns the image.

---

# P2 — Polish before wider launch

## 12. Expand Thai food database

**Status**: [ ]

**Goal**: ≥ 500 entries in `cleangoal.foods` with realistic macros.

**Files**:
- `backend/scripts/seed_thai_foods.py` (exists — extend)
- CSV source under `backend/scripts/data/thai_foods_v2.csv`

**Steps**:
1. Pull data from INMUCAL / FDA Thailand. Shape into `food_name, calories, protein, carbs, fat, serving_quantity, serving_unit`.
2. Run `python backend/scripts/seed_thai_foods.py --csv data/thai_foods_v2.csv`.
3. Spot-check 20 random rows — calories in 50-800 kcal range per serving.

**Verification**:
- [ ] `SELECT COUNT(*) FROM cleangoal.foods` ≥ 500.
- [ ] No duplicates: `SELECT food_name, COUNT(*) FROM cleangoal.foods GROUP BY food_name HAVING COUNT(*) > 1` returns 0.

---

## 13. Load test hot endpoints

**Status**: [ ] · **Depends on**: #10

**Goal**: Confirm p95 < 500 ms at 50 concurrent users on the top 3 endpoints.

**Files**: `backend/scripts/loadtest/` (new) — k6 or `hey` scripts.

**Scenarios**:
1. `GET /foods?q=...` (search, 50 concurrent, 2 min).
2. `POST /meals` + `GET /daily_summary` loop (mimics record-food screen).
3. `POST /chat/send` (AI path, rate-limited — run slower).

**Steps**:
1. Write k6 scripts. Store as `backend/scripts/loadtest/foods.js` etc.
2. Run against **staging** (not prod).
3. Record p50/p95/p99 in a short report committed at `docs/LOAD_TEST_2026_04.md`.

**Verification**:
- [ ] Report file exists with numbers.
- [ ] No Railway instance OOMs during the test.
- [ ] Gemini endpoint does not blow through daily quota.

---

## 14. SLO dashboard + critical-path transactions in Sentry

**Status**: [ ]

**Goal**: One page showing "% successful record_meal in last 24h", "AI chat p95 latency", "login success rate".

**Steps**:
1. In `backend/app/routers/meals.py` wrap the POST handler with `with sentry_sdk.start_transaction(op='meal.create', name='POST /meals'):`.
2. Same for `/auth/login`, `/chat/send`.
3. In Flutter, wrap `RecordFoodScreen._submit` and `ChatScreen._send` with `Sentry.startTransaction`.
4. In Sentry UI create a dashboard `Calories Guard — SLO` with 3 panels (failure rate, p95, throughput).

**Verification**:
- [ ] Record a meal on staging → appears as a transaction in Sentry.
- [ ] Dashboard URL pasted in `docs/MONITORING.md`.

---

## 15. AI feature kill switch

**Status**: [ ]

**Goal**: Disable AI endpoints via env var without redeploying.

**Files**:
- `backend/app/core/config.py` — add `AI_ENABLED: bool = True`.
- `backend/app/routers/chat.py` — 503 with friendly message if disabled.
- `backend/app/routers/foods.py::auto_add` — same.
- Flutter: surface the 503 as a banner "AI unavailable".

**Steps**:
1. Add the setting. Default True.
2. Guard each Gemini call: `if not settings.AI_ENABLED: raise HTTPException(503, "AI temporarily unavailable")`.
3. On Railway, setting `AI_ENABLED=false` now shuts down AI without a deploy.

**Verification**:
- [ ] Temporarily set `AI_ENABLED=false` on staging → `/chat/send` returns 503.
- [ ] App shows a non-crashing banner, rest of app continues to work.

---

## 16. PDPA / GDPR export + delete endpoints

**Status**: [ ]

**Goal**: Users can download their data + permanently delete their account.

**Why**: Thailand PDPA (พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล) gives users the right to access + delete. Play Store also requires an in-app "delete account" path.

**Files**:
- `backend/app/routers/users.py` — add `GET /users/me/export` and `DELETE /users/me`.
- Flutter: `lib/screens/profile/account_data_screen.dart` (new) — "ดาวน์โหลดข้อมูล" / "ลบบัญชี" buttons.

**Steps**:
1. Export: return a JSON bundle containing all rows from user-owned tables for `current_user.user_id`. Stream as `Content-Type: application/json; Content-Disposition: attachment`.
2. Delete: transaction that sets `users.deleted_at = now()` + cascades clean via existing FKs. Email the user a confirmation.
3. Document retention: after 30 days `deleted_at` rows are hard-deleted by a scheduled job (add to `backend/scripts/cleanup.py` + cron).
4. Add links to Privacy Policy (#18) explaining both rights.

**Verification**:
- [ ] `curl -H "Authorization: Bearer <jwt>" /users/me/export > mydata.json` — valid JSON with meals/water/etc.
- [ ] `DELETE /users/me` → subsequent `/users/me` returns 401 (soft-deleted).
- [ ] After 30 days a hard-delete job removes the row (simulate by running script manually).

---

## 17. Localization for public + hot-path screens (Thai / English)

**Status**: [ ]

**Goal**: A non-Thai user can register and record a meal in English.

**Files**:
- `flutter_application_1/pubspec.yaml` — add `flutter_localizations`.
- `flutter_application_1/lib/l10n/app_en.arb`, `app_th.arb` (new).
- `flutter_application_1/lib/main.dart` — wire up `localizationsDelegates`, `supportedLocales`.

**Scope** (hot paths only — not every screen):
- Login / register / onboarding.
- Record food screen.
- Home dashboard.
- Error messages from `api_client.dart`.

**Steps**:
1. Extract Thai strings from the above screens into `app_th.arb`. Add English equivalents in `app_en.arb`.
2. Replace hardcoded strings with `AppLocalizations.of(context)!.loginTitle`.
3. Run `flutter gen-l10n`.

**Verification**:
- [ ] Changing the device language to English shows English strings on targeted screens.
- [ ] `flutter analyze` clean.

---

## 18. Publish Privacy Policy + Terms of Service

**Status**: [ ] · **Depends on**: #16 (you can't publish a PDPA policy if delete-account doesn't exist yet)

**Goal**: Hosted `privacy.html` and `terms.html` URLs that the app links to and Play Store can reference.

**Files**:
- `docs/privacy-policy.md` (new)
- `docs/terms-of-service.md` (new)
- Host via GitHub Pages under `/docs` branch or a simple `admin-web/public/privacy.html`.
- Flutter: add footer link on login + settings screen.

**Must cover in Privacy Policy**:
- What data is collected (email, age, weight, food logs, location for restaurant map).
- Why (calorie tracking, AI coach).
- Third parties (Supabase US-East, Google Gemini, Firebase, Sentry).
- Retention (active + 30 days post-delete).
- User rights (access, delete, export) — point to #16 endpoints.
- Contact email.

**Verification**:
- [ ] Public URL returns 200 (e.g. https://calories-guard.pages.dev/privacy).
- [ ] App settings → "Privacy Policy" opens the URL.
- [ ] Play Store listing draft accepts the URL.

---

## 19. Deeper monitoring + synthetic checks

**Status**: [ ]

**Goal**: Detect regressions before a user reports them.

**Files**:
- `backend/scripts/synthetic_check.py` (new) — login + record meal round-trip.
- External: UptimeRobot / Checkly configuration.

**Steps**:
1. Write a script that every 10 minutes: logs in as a pre-seeded synthetic user, records a dummy meal, deletes it, hits `/health`.
2. Host it on Checkly (free tier) or a cron-scheduled GitHub Action that POSTs to Sentry on failure.
3. In Supabase Dashboard → Logs → set an alert for p95 query time > 1s.

**Verification**:
- [ ] Checkly/Cron check green on the dashboard.
- [ ] Deliberately break an endpoint → alert fires within 15 minutes.

---

## 20. API versioning + client compat check

**Status**: [ ]

**Goal**: A Flutter client running an old API shape gets a clear "please update" message, not silent failures.

**Files**:
- `backend/app/main.py` — add `API_VERSION = "2026.04"` constant, include in `/health` response and a custom `X-Api-Version` response header.
- Flutter: `lib/services/api_client.dart` — on every response, compare `X-Api-Version` vs a `kExpectedApiVersion` constant; if the major differs, set a global `isUpgradeRequired` flag that shows a modal.
- Add a `docs/CHANGELOG_API.md` with a running list.

**Steps**:
1. Bump `API_VERSION` whenever a breaking change ships (removed field, required new field, renamed endpoint).
2. Flutter's `kExpectedApiVersion` is bumped in the same PR that upgrades the client.
3. For non-breaking additions, leave the version alone.

**Verification**:
- [ ] `GET /health` returns `{"status":"ok","api_version":"2026.04"}`.
- [ ] Running an old APK against a bumped server shows the "update required" modal.

---

# Suggested execution order (2 week plan)

_Assuming one engineer full-time; adjust as needed._

| Days | Task IDs | Rationale |
|---|---|---|
| 1–2 | #1, #5, #4, #2 | Store-rejection blockers + obvious DB hardening. All small PRs. |
| 3–4 | #3, #11, #7 | Auth-facing hardening + remove silent failures. |
| 5–7 | #6, #8, #16 | Confidence + legal compliance in one sprint. |
| 8–10 | #10, #9, #14, #13 | Stand up staging, gate deploys, measure. |
| 11–14 | #17, #18, #15, #20, #19, #12 | Polish, beta-readiness, ops maturity. |

---

# Change log

- **2026-04-19**: File created after v14 DB normalization (commit `001a1ebe`). Initial 20 tasks drafted.

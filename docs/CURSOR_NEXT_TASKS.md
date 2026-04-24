# Cursor Next Tasks — Calories Guard

Date: 2026-04-24  
Working repo: `C:\calories-guard`  
Current focus: finish the remaining P0 closed-beta blocker, then production readiness.

## Current State

Latest local work already done in this repo:

- Recipe schema decision: use `recipes` JSONB cache fields for AI-generated recipe details.
- Added route regression test: `backend/tests/test_recipe_routes.py`.
- Added schema review: `docs/SUPABASE_CLEANGOAL_SCHEMA_REVIEW.md`.
- Added pre-deploy checklist: `docs/PRE_DEPLOY_TESTS.md`.
- Added v17 migration: `backend/migrations/v17_recipe_consistency.sql`.
- Added v18 migration: `backend/migrations/v18_dishes_3nf_integrity.sql`.
- Added v19 migration: `backend/migrations/v19_detail_items_unit_fk.sql`.
- Updated recipe review routes in `backend/app/routers/social.py` to accept public `food_id` paths but write/read `recipe_reviews.recipe_id`.
- Applied v16/v17/v18/v19 live on Supabase and added current 3NF audit: `docs/SUPABASE_3NF_AUDIT_2026_04_24.md`.
- Generated live column snapshot for data dictionary: `docs/SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md`.

Backend verification already passed:

```powershell
python -m pytest backend -q
# 64 passed, 1 skipped
```

Note: direct DB connection from this machine failed because `db.zawlghlnzgftlxcoipuf.supabase.co` resolves as IPv6-only/DNS-unavailable here. The Supabase session pooler works:

```text
postgres.zawlghlnzgftlxcoipuf @ aws-1-ap-southeast-1.pooler.supabase.com:5432
```

## Do Not Forget

The Supabase DB password was pasted into chat once. Rotate it in Supabase Dashboard before production/staging use.

## P0 — Closed Beta Blockers

### 1. Commit Current Repo Changes

In `C:\calories-guard`, commit the files from the latest work:

```powershell
git status --short

git add `
  backend/app/routers/social.py `
  backend/migrations/v17_recipe_consistency.sql `
  backend/migrations/v18_dishes_3nf_integrity.sql `
  backend/migrations/v19_detail_items_unit_fk.sql `
  backend/tests/test_recipe_social.py `
  docs/STATUS.md `
  docs/DATA_DICTIONARY.md `
  docs/SUPABASE_3NF_AUDIT_2026_04_24.md `
  docs/SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md `
  docs/SUPABASE_CLEANGOAL_SCHEMA_REVIEW.md `
  docs/WORK_HISTORY.md

git commit -m "feat(recipes): normalize recipe reviews by recipe id"
```

There may also be unrelated local artifacts. Do not commit unless intentionally needed:

```text
.claude/worktrees/suspicious-kepler
docker
.cursor/
flutter_application_1/build_error.txt
```

### 2. Apply Recipe/3NF Migrations On Supabase

Status: done on 2026-04-24.

Applied, in order:

1. `backend/migrations/v16_a_recipes_ai_fields.sql`
2. `backend/migrations/v17_recipe_consistency.sql`
3. `backend/migrations/v18_dishes_3nf_integrity.sql`
4. `backend/migrations/v19_detail_items_unit_fk.sql`

Verification used:

```sql
SELECT *
FROM cleangoal.schema_migrations
WHERE version IN ('v16_a_recipes_ai_fields', 'v17_recipe_consistency')
ORDER BY version;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'cleangoal'
  AND table_name = 'recipes'
  AND column_name IN ('ingredients_json', 'tools_json', 'tips_json', 'generated_by')
ORDER BY column_name;

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'cleangoal'
  AND table_name = 'recipe_reviews'
ORDER BY ordinal_position;

SELECT
  tc.constraint_name,
  tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'cleangoal'
  AND tc.table_name = 'recipe_reviews'
ORDER BY tc.constraint_name;
```

Expected:

- `recipes` has `ingredients_json`, `tools_json`, `tips_json`, `generated_by`.
- `recipe_reviews.recipe_id` exists and is `NOT NULL`.
- `recipe_reviews` has FK to `recipes(recipe_id)`.
- `recipe_reviews` has uniqueness for `(recipe_id, user_id)`, either as existing constraint or v17 index.

Live result:

- all three versions are present in `cleangoal.schema_migrations`
- `recipe_reviews` has no missing recipe/user references
- 20 orphan seed reviews were archived to `cleangoal.recipe_reviews_orphan_archive`
- `dish_categories` = 6, `dishes` = 103
- active foods without `dish_id` = 0
- foods with serving unit but missing `serving_unit_id` = 0
- non-PK, non-archive `_id` columns without FK = 0
- 100 orphan recipe relation rows were archived to `recipe_relation_orphan_archive`
- 19 invalid unit conversion rows were archived to `unit_conversion_orphan_archive`

### 3. Live API Smoke After Migrations

With backend pointed at the migrated Supabase DB:

```powershell
curl https://<backend-url>/health
curl https://<backend-url>/recipes/<known_food_id>
curl https://<backend-url>/recipes/<known_food_id>/reviews
```

Manual checks:

- First recipe load works even if recipe was missing before.
- Second recipe load returns cached DB data.
- Review list no longer errors from missing `food_id` column on `recipe_reviews`.
- Posting a review still works from Flutter recipe detail screen.

### 4. Samsung Health Real-Device Verify

Needs a real Android/Samsung device. Check:

- App launches with `FlutterFragmentActivity`.
- Health Connect status detects installed / unavailable / update-needed correctly.
- Permission dialog appears for steps/calories/activity.
- Package visibility works for:
  - `com.google.android.apps.healthdata`
  - `com.sec.android.app.shealth`
- Step sync imports recent step data or shows safe empty state.
- Calories/activity sync imports or shows documented unsupported path.
- Device without Health Connect shows fallback UI, not crash.

Useful logs:

```powershell
adb logcat | Select-String "healthdata|shealth|HealthConnect|CaloriesGuard"
```

Update `docs/STATUS.md` after the real-device result.

## P1 — Before Production

### 5. Create Real Staging Environment

Follow `docs/STAGING.md`.

Create:

- Supabase staging project
- Railway staging service
- separate staging env vars
- staging Flutter build using staging API/Supabase

Verify:

- staging users do not appear in prod DB
- `/health` passes on staging URL
- GitHub Actions staging deploy works

### 6. Run Load Test On Staging

Use `backend/scripts/loadtest/README.md`.

```powershell
$env:BASE_URL="https://<staging-backend-url>"
$env:TEST_USER_TOKEN="<seeded-staging-jwt>"
$env:TEST_USER_ID="<matching-user-id>"

k6 run backend/scripts/loadtest/foods.js
k6 run backend/scripts/loadtest/meals.js
k6 run backend/scripts/loadtest/chat.js
```

Record p95/p99 and errors in a new report, for example:

```text
docs/LOAD_TEST_2026_04.md
```

### 7. Sentry SLO Dashboard

Code tagging exists, but dashboard/alerts still need UI setup.

Create alerts for:

- backend 5xx spike
- auth transaction error rate
- meal transaction p95 latency
- chat/LLM error rate
- Railway restart/crash if integrated

### 8. Fill Pre-Deploy Checklist

Use:

```text
docs/PRE_DEPLOY_TESTS.md
```

Fill `Result` and `Notes` for the release candidate before production deploy.

## P2 — Polish / Ops

### 9. Expand Thai Food Database

Existing importer:

```text
backend/scripts/seed_thai_foods.py
backend/scripts/data/thai_foods_v2.sample.csv
```

Goal:

- Add more verified Thai foods.
- Keep macros sane.
- Reduce dependence on `temp_food` admin review.

### 10. Publish Privacy Policy And Terms

Drafts exist:

```text
docs/privacy-policy.md
docs/terms-of-service.md
```

Need:

- deploy to public URL
- set Flutter build defines if needed:

```text
PRIVACY_POLICY_URL
TERMS_URL
```

### 11. Cross-Platform Verification

Still needs:

- iOS simulator build
- physical iOS build if possible
- Android release build after bundle id rename

### 12. Deeper Monitoring

Add or configure:

- uptime pings
- DB connection pool metrics
- LLM provider error rate
- synthetic E2E alert routing

## Known Tech Debt To Track

- `LLM_PROVIDER=local` may OOM on Railway.
- AI calls are synchronous, no queue.
- No Redis/application cache besides recipe JSONB.
- Legacy DB env vars still exist in config/docs.
- Forgot-password in-app OTP UI is still a placeholder around Supabase reset email.
- `recipe_favorites` is legacy; active mobile favorite route uses `user_favorites(food_id)`.

## Suggested Next Commit Order

1. Commit current v17/v18/v19 recipe + 3NF code/docs.
2. Rotate Supabase DB password.
3. Run Samsung real-device test and update `docs/STATUS.md`.
4. Create staging environment.
5. Run staging load tests.

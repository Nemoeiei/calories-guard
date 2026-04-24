# Supabase `cleangoal` Schema Review

Date: 2026-04-24  
Project ref: `zawlghlnzgftlxcoipuf`  
Scope: schema analysis + normalization recommendations for the Supabase-only database path.

## Verification Note

I attempted to connect to the live Supabase database from this workspace, but the direct DB host resolves as IPv6-only here and the common Supabase pooler endpoints did not match the tenant. So this review is based on repository truth:

- `docs/ER_DIAGRAM.md` post-v14 schema notes
- `docs/DATA_DICTIONARY.md`
- `backend/migrations/v14_*.sql`, `v15_*.sql`, `v16_a_recipes_ai_fields.sql`
- Current backend/router usage under `backend/app/`

Before applying any destructive normalization, verify against live Supabase with the queries in the last section.

## Executive Verdict

The `cleangoal` schema is broadly OK for a closed beta after v14/v15 hardening. The model has real primary keys, important uniqueness constraints, check constraints, `timestamptz`, public-schema cleanup, and a baseline RLS posture.

It is not fully clean yet. The main remaining normalization risk is the recipe domain: the app now chose `recipes` JSONB fields for AI-generated recipe detail, but older normalized recipe tables and current social endpoints still overlap. There are also two food-moderation flows and a few subtype/lookup tables that are either unused or only lightly used.

Recommended posture:

1. Keep Supabase `cleangoal` as the only database.
2. Keep backend SQL access through `DATABASE_URL`/`psycopg2` for now.
3. Apply `v16_a_recipes_ai_fields.sql` after schema qualification.
4. Do one small v17 cleanup migration for recipe review/favorite consistency before production.
5. Defer larger table drops until after closed beta telemetry confirms unused paths.

## Current Shape

### Strong Areas

- `cleangoal` is the canonical app schema; public duplicate tables were dropped in v15_a.
- User-owned tables have RLS enabled with explicit deny policies for anon/authenticated in v15_c.
- Reference tables have public read policies where appropriate.
- Most hot user data has FKs and cascade behavior: `meals`, `detail_items`, `daily_summaries`, `water_logs`, `exercise_logs`, `weight_logs`, `notifications`.
- v14 added the important integrity layer:
  - unique constraints for user/date and favorites
  - range checks for calories/macros/weight/water/exercise
  - `detail_items` parent exclusivity check
  - `timestamptz` conversion
- `units` is now seeded and used by `/units`, `/unit_conversions`, and meal detail joins.

### Areas That Need Attention

| Area | Current state | Risk | Recommendation |
|---|---|---|---|
| Recipe detail | `recipes` has prose fields and v16 JSONB AI cache fields | OK if v16_a is applied | Keep JSONB for generated recipe payload |
| Recipe review | Docs/schema model use `recipe_id`; current `social.py` queries `recipe_reviews.food_id` | Runtime failure or schema drift | Normalize reviews to `recipe_id`; API can still accept `food_id` and map internally |
| Recipe favorite | `recipe_favorites` exists, but current `/recipes/{food_id}/favorite` uses `user_favorites(food_id)` | Duplicate favorite concepts | Prefer `user_favorites` if favorite means food/menu; retire `recipe_favorites` later |
| Food moderation | `temp_food` + `verified_food` and legacy `food_requests` both exist | Duplicate workflows | Keep both for beta, but declare `food_requests` legacy unless admin still needs it |
| Food subtype tables | `beverages` and `snacks` exist while `foods.food_type/category` carries most behavior | Unused subtype drift | Drop later if no code/admin flow writes them |
| Ingredients catalog | `ingredients` + `food_ingredients` exist, but recipe screen now uses JSONB/free text | Possible unused model | Keep only if nutrition ingredient search is planned; otherwise drop after beta |
| Aggregates | `daily_summaries` caches totals and water | Intentional denormalization | Keep, but ensure all write paths update it consistently |
| RLS policies | v15_c denies direct authenticated access to user-owned data | Fine for backend-only data access | Replace with `auth.uid()` policies before any client writes directly to PostgREST |

## Recipe Normalization Decision

The app has now effectively chosen this model:

```text
foods 1--0/1 recipes
recipes stores:
  description
  instructions
  prep/cooking/serving
  ingredients_json
  tools_json
  tips_json
  generated_by
```

This is reasonable because LLM output is semi-structured and cache-like. It avoids forcing generated ingredients/tools/tips into row tables before the app has admin editing for each item.

What should not remain ambiguous:

- `GET /recipes/{food_id}` should continue to be owned by `backend/app/routers/foods.py`.
- `recipe_ingredients`, `recipe_steps`, `recipe_tools`, and `recipe_tips` should be treated as legacy/seeded recipe-detail tables unless a future admin editor actually writes them.
- `recipe_reviews` should not mix `food_id` and `recipe_id`. Pick `recipe_id` in the DB, because reviews belong to a recipe row. The endpoint can still take `food_id` for mobile compatibility.

Recommended v17 direction:

```sql
-- Verify before migration.
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'cleangoal'
  AND table_name = 'recipe_reviews'
ORDER BY ordinal_position;

-- Target shape:
-- recipe_reviews(review_id, recipe_id, user_id, rating, comment, created_at)
-- UNIQUE(recipe_id, user_id)
-- FK recipe_id -> recipes(recipe_id) ON DELETE CASCADE
-- FK user_id -> users(user_id) ON DELETE CASCADE
```

Then update `backend/app/routers/social.py` to:

1. Resolve `recipe_id` from `recipes WHERE food_id = %s`.
2. Query/insert reviews by `recipe_id`.
3. Keep the public API path `/recipes/{food_id}/reviews`.

## Food Moderation Normalization

There are two moderation concepts:

- `temp_food` + `verified_food`: current quick-add/admin approval path.
- `food_requests`: older request workflow with `ingredients_json` and reviewed status.

Closed beta recommendation: keep both, because admin code still reads both. Production recommendation: merge to one flow.

Better target model:

```text
food_requests
  request_id
  user_id
  food_name
  calories/protein/carbs/fat
  status pending|approved|rejected
  reviewed_by
  reviewed_at
  promoted_food_id
  source quick_add|ai_estimate|manual_request
```

Then `temp_food`/`verified_food` can be retired. This is not urgent for closed beta because the existing split is functional and easy to reason about.

## Tables To Keep For Now

- `users`, `roles`, auth code tables, notifications
- `foods`, `allergy_flags`, `food_allergy_flags`
- `meals`, `detail_items`, `daily_summaries`
- `water_logs`, `exercise_logs`, `weight_logs`
- `temp_food`, `verified_food`, `food_requests`
- `recipes`
- `user_favorites`
- `units`, `unit_conversions`
- `schema_migrations`

## Tables To Re-evaluate After Beta

| Table | Reason |
|---|---|
| `recipe_ingredients` | superseded by `recipes.ingredients_json` unless admin per-ingredient editing is built |
| `recipe_steps` | superseded by `instructions`/derived `steps` unless seeded content uses it |
| `recipe_tools` | superseded by `tools_json` |
| `recipe_tips` | superseded by `tips_json` |
| `recipe_favorites` | overlaps `user_favorites(food_id)` for one-recipe-per-food model |
| `ingredients` | unused by current food search/meal recording flow |
| `food_ingredients` | unused by current app flow |
| `beverages` | overlaps `foods.food_type/category` and is not referenced by routers |
| `snacks` | overlaps `foods.food_type/category` and is not referenced by routers |

Do not drop these until live row counts and code references are checked. If rows exist and contain useful seed data, archive or migrate them first.

## Migration Hygiene Issues

### `v16_a` Must Be Schema-Qualified

The migration has been updated in repo to use `cleangoal.recipes`. Without this, running it in Supabase SQL Editor could target the wrong search path or fail depending on the session.

### Migration Runner Is Outdated

`backend/run_migrations.py` still has a local/supabase split and a fixed target list that only covers older migrations. If Supabase is the only database, simplify it to:

- read `DATABASE_URL` or Supabase DB vars only
- apply every file in `backend/migrations/` in order
- track one canonical column in `cleangoal.schema_migrations` (`version`, not mixed `name`/`version`)

## Suggested Next Migration: `v17_recipe_consistency`

This should be done only after live verification.

Goal:

1. Ensure `recipes.food_id` is unique and not null.
2. Ensure `recipe_reviews` uses `recipe_id`, not `food_id`.
3. Decide whether `recipe_favorites` is kept or retired.
4. Add/confirm FKs for active recipe tables.
5. Add indexes for review listing.

Sketch:

```sql
BEGIN;

-- 1. Confirm recipes has one row per food.
ALTER TABLE cleangoal.recipes
  ALTER COLUMN food_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS recipes_food_id_uq
  ON cleangoal.recipes(food_id);

-- 2. If recipe_reviews has food_id, migrate it to recipe_id.
-- Exact SQL depends on the live column set; verify first.

-- 3. Ensure review uniqueness by recipe/user.
CREATE UNIQUE INDEX IF NOT EXISTS recipe_reviews_recipe_user_uq
  ON cleangoal.recipe_reviews(recipe_id, user_id);

CREATE INDEX IF NOT EXISTS recipe_reviews_recipe_created_idx
  ON cleangoal.recipe_reviews(recipe_id, created_at DESC);

COMMIT;
```

## Live Verification Queries

Run these in Supabase SQL Editor before any cleanup:

```sql
-- Applied migrations
SELECT *
FROM cleangoal.schema_migrations
ORDER BY applied_at NULLS LAST, version NULLS LAST, name NULLS LAST;

-- Current tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'cleangoal'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Public leftovers should be empty/only Supabase-owned objects.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Recipe review column shape: must settle recipe_id vs food_id.
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'cleangoal'
  AND table_name = 'recipe_reviews'
ORDER BY ordinal_position;

-- Candidate cleanup row counts.
SELECT 'recipe_ingredients' AS table_name, COUNT(*) FROM cleangoal.recipe_ingredients
UNION ALL SELECT 'recipe_steps', COUNT(*) FROM cleangoal.recipe_steps
UNION ALL SELECT 'recipe_tools', COUNT(*) FROM cleangoal.recipe_tools
UNION ALL SELECT 'recipe_tips', COUNT(*) FROM cleangoal.recipe_tips
UNION ALL SELECT 'recipe_favorites', COUNT(*) FROM cleangoal.recipe_favorites
UNION ALL SELECT 'ingredients', COUNT(*) FROM cleangoal.ingredients
UNION ALL SELECT 'food_ingredients', COUNT(*) FROM cleangoal.food_ingredients
UNION ALL SELECT 'beverages', COUNT(*) FROM cleangoal.beverages
UNION ALL SELECT 'snacks', COUNT(*) FROM cleangoal.snacks;

-- FK coverage for recipe tables.
SELECT
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table,
  ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'cleangoal'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name LIKE 'recipe%'
ORDER BY tc.table_name, tc.constraint_name;

-- RLS status.
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'cleangoal'
  AND c.relkind = 'r'
ORDER BY c.relname;
```

## Final Recommendation

For closed beta, the schema is acceptable if `v16_a` is applied and the app keeps using backend-only DB access. The one schema/code mismatch to resolve before production is recipe reviews/favorites. Do that as a focused v17 migration and router patch, rather than another broad normalization sweep.

# Supabase `cleangoal` Schema Review

Date: 2026-04-24  
Project ref: `zawlghlnzgftlxcoipuf`  
Scope: schema analysis + normalization recommendations for the Supabase-only database path.

## Verification Note

Initial direct DB connection failed because `db.zawlghlnzgftlxcoipuf.supabase.co` resolved as IPv6-only from this workspace. A Supabase session pooler URL later worked:

```text
postgres.zawlghlnzgftlxcoipuf @ aws-1-ap-southeast-1.pooler.supabase.com:5432
```

Live verification on 2026-04-24 confirmed:

- `cleangoal` has 40 base tables after v18.
- `v16_a_recipes_ai_fields`, `v17_recipe_consistency`, `v18_dishes_3nf_integrity`, and `v19_detail_items_unit_fk` are applied in `cleangoal.schema_migrations`.
- `recipes` has `ingredients_json`, `tools_json`, `tips_json`, and `generated_by`.
- `recipe_reviews` has valid FKs to `recipes(recipe_id)` and `users(user_id)`.
- 20 orphan seed reviews were archived to `cleangoal.recipe_reviews_orphan_archive`; remaining live review rows have no missing recipe/user references.
- `dish_categories` and `dishes` now exist; all 103 active `foods` rows have `dish_id`.
- `foods.serving_unit_id` now maps all live serving units to `units`.
- `detail_items.unit_id` now has an FK to `units`.
- Old orphan recipe relation rows and invalid unit conversions were archived before adding FKs.

- Current detailed audit: [SUPABASE_3NF_AUDIT_2026_04_24.md](SUPABASE_3NF_AUDIT_2026_04_24.md)
- Current column snapshot: [SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md](SUPABASE_DATA_DICTIONARY_LIVE_2026_04_24.md)

The original review was based on repository truth:

- `docs/ER_DIAGRAM.md` post-v14 schema notes
- `docs/DATA_DICTIONARY.md`
- `backend/migrations/v14_*.sql`, `v15_*.sql`, `v16_a_recipes_ai_fields.sql`
- Current backend/router usage under `backend/app/`

Use the queries in the last section after future migrations.

## Executive Verdict

The `cleangoal` schema is broadly OK for a closed beta after v14/v15 hardening. The model has real primary keys, important uniqueness constraints, check constraints, `timestamptz`, public-schema cleanup, and a baseline RLS posture.

It is not fully clean yet. The main remaining normalization risk is the recipe domain: the app now chose `recipes` JSONB fields for AI-generated recipe detail, but older normalized recipe tables and current social endpoints still overlap. There are also two food-moderation flows and a few subtype/lookup tables that are either unused or only lightly used.

Recommended posture:

1. Keep Supabase `cleangoal` as the only database.
2. Keep backend SQL access through `DATABASE_URL`/`psycopg2` for now.
3. Treat `v16`/`v17`/`v18`/`v19` as the current live DB baseline.
4. Use `dish_categories -> dishes -> foods` for the ER diagram and data dictionary.
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
| Recipe review | DB model uses `recipe_id`; API paths still accept `food_id` | Resolved by v17 | `v17_recipe_consistency.sql` and `social.py` resolve `recipe_id` from `food_id` |
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

Implemented v17 direction:

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

`backend/app/routers/social.py` now:

1. Resolve `recipe_id` from `recipes WHERE food_id = %s`.
2. Query/insert reviews by `recipe_id`.
3. Keep the public API path `/recipes/{food_id}/reviews`.

The migration file is `backend/migrations/v17_recipe_consistency.sql`. It is intentionally conservative: it backfills `recipe_id` from a legacy `food_id` column if that column exists, preserves the old column as legacy metadata, and fails loudly if any review row cannot be mapped to a recipe.

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

## Applied Normalization Migrations

The planned `v17` work is now complete, and `v18` adds the food taxonomy requested for ERD/data-dictionary work.

| Migration | Result |
|---|---|
| `v16_a_recipes_ai_fields.sql` | Adds AI recipe cache JSONB fields to `recipes` |
| `v17_recipe_consistency.sql` | Makes recipe reviews use `recipe_id`; archives unmappable seed reviews |
| `v18_dishes_3nf_integrity.sql` | Adds `dish_categories`, `dishes`, `foods.dish_id`, `foods.serving_unit_id`, missing recipe/unit FKs, and archive tables |
| `v19_detail_items_unit_fk.sql` | Adds the remaining FK from `detail_items.unit_id` to `units(unit_id)` |

The current detailed live audit is in [SUPABASE_3NF_AUDIT_2026_04_24.md](SUPABASE_3NF_AUDIT_2026_04_24.md).

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

For ER diagram and data dictionary work, use the live post-v18 shape as the current baseline. The database is now acceptable for closed beta from a relational-integrity perspective: recipe review consistency is fixed, dish/category taxonomy exists, serving units are FK-backed, and previously invalid legacy rows are archived. The main remaining product decision is whether to retire legacy compatibility columns/tables after the mobile/admin code has moved to the normalized references.

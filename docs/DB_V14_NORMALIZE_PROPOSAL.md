# Database v14 — Normalize & Optimize Migration Proposal

> **Status**: DRAFT — not yet applied. Requires user approval per-phase before any DDL runs.
> **Companion doc**: `docs/DATA_DICTIONARY.md` (current state + issues)
> **Target**: Supabase project `zawlghlnzgftlxcoipuf`, schema `cleangoal`
> **Pre-flight row counts (2026-04-18)**: users=0, meals=10, detail_items=15, daily_summaries=0, foods=239. User tables effectively empty → breaking changes are safe **now**, much harder later.

---

## Structure

The migration is split into **6 phases**, each independently reviewable and applicable. A phase can be skipped without breaking the next.

| Phase | Scope | Breaking? | Needs confirmation |
|---|---|---|---|
| A | Critical fixes — schema/code divergence, missing FKs, NOT NULLs | Yes (but fixes bugs) | Review only |
| B | Integrity — UNIQUE, CHECK, VARCHAR caps, drop duplicate constraints | Minor | Review only |
| C | De-duplicate columns (users.goal_type vs user_goals, water_glasses, etc.) | Yes | **Per-item approval** |
| D | Units table — seed or drop | Depends | Decision needed |
| E | Timezone — `timestamp` → `timestamptz` | Minor | Opt-in |
| F | Drop unused tables | Yes | **Per-table approval** |

Each phase file is standalone SQL in `backend/migrations/v14_<letter>_<name>.sql`. Run in order A→B→… via `backend/run_migrations.py`.

---

## Conventions

- All statements qualified with `cleangoal.` schema
- Single transaction per phase (`BEGIN; … COMMIT;`)
- Constraints named explicitly (`ck_*`, `fk_*`, `uq_*`) for predictable rollback
- Backfill before NOT NULL / before FK addition
- `schema_migrations` row inserted at end of each phase
- Rollback script provided per phase

---

## Phase A — Critical fixes (MUST DO)

Fixes the bugs identified in DATA_DICTIONARY §6.1–§6.2. Without this, `POST /meals` crashes at runtime.

### A.1 Add `meal_type` to `meals`

```sql
BEGIN;

-- 1. Add column as nullable first (backfill needed)
ALTER TABLE cleangoal.meals
    ADD COLUMN meal_type cleangoal.meal_type;

-- 2. Backfill existing 10 rows based on meal_time hour
--    06-10 → breakfast, 11-14 → lunch, 17-21 → dinner, else → snack
UPDATE cleangoal.meals
SET meal_type = CASE
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 6 AND 10 THEN 'breakfast'::cleangoal.meal_type
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 11 AND 14 THEN 'lunch'::cleangoal.meal_type
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 17 AND 21 THEN 'dinner'::cleangoal.meal_type
    ELSE 'snack'::cleangoal.meal_type
END
WHERE meal_type IS NULL;

-- 3. Enforce NOT NULL
ALTER TABLE cleangoal.meals
    ALTER COLUMN meal_type SET NOT NULL;

-- 4. Index for the common query  WHERE user_id=? AND DATE(meal_time)=? AND meal_type=?
CREATE INDEX idx_meals_user_date_type
    ON cleangoal.meals (user_id, (DATE(meal_time)), meal_type);

COMMIT;
```

**Rollback:**
```sql
DROP INDEX IF EXISTS cleangoal.idx_meals_user_date_type;
ALTER TABLE cleangoal.meals DROP COLUMN IF EXISTS meal_type;
```

### A.2 Add missing foreign keys

```sql
BEGIN;

-- meals.user_id → users (currently NO FK despite the column name)
ALTER TABLE cleangoal.meals
    ADD CONSTRAINT fk_meals_user
    FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id)
    ON DELETE CASCADE;

-- detail_items.food_id → foods
ALTER TABLE cleangoal.detail_items
    ADD CONSTRAINT fk_detail_items_food
    FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id)
    ON DELETE SET NULL;   -- keep history even if food deleted

-- detail_items.plan_id → user_meal_plans
ALTER TABLE cleangoal.detail_items
    ADD CONSTRAINT fk_detail_items_plan
    FOREIGN KEY (plan_id) REFERENCES cleangoal.user_meal_plans(plan_id)
    ON DELETE CASCADE;

COMMIT;
```

**Pre-check** (abort if any orphans):
```sql
-- Should all return 0 before running
SELECT COUNT(*) FROM cleangoal.meals m
  LEFT JOIN cleangoal.users u ON u.user_id = m.user_id
  WHERE m.user_id IS NOT NULL AND u.user_id IS NULL;

SELECT COUNT(*) FROM cleangoal.detail_items di
  LEFT JOIN cleangoal.foods f ON f.food_id = di.food_id
  WHERE di.food_id IS NOT NULL AND f.food_id IS NULL;
```

**Rollback:**
```sql
ALTER TABLE cleangoal.meals DROP CONSTRAINT IF EXISTS fk_meals_user;
ALTER TABLE cleangoal.detail_items DROP CONSTRAINT IF EXISTS fk_detail_items_food;
ALTER TABLE cleangoal.detail_items DROP CONSTRAINT IF EXISTS fk_detail_items_plan;
```

### A.3 NOT NULL on critical columns

```sql
BEGIN;

-- meals.user_id: every meal must belong to a user
ALTER TABLE cleangoal.meals
    ALTER COLUMN user_id SET NOT NULL;

-- daily_summaries.user_id + date_record
ALTER TABLE cleangoal.daily_summaries
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN date_record SET NOT NULL;

-- daily_summaries.user_id needs its FK too (was present but nullable)
-- (FK already exists, just enforcing NOT NULL above)

COMMIT;
```

**Rollback:**
```sql
ALTER TABLE cleangoal.meals ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE cleangoal.daily_summaries
    ALTER COLUMN user_id DROP NOT NULL,
    ALTER COLUMN date_record DROP NOT NULL;
```

### A.4 Drop orphan `item_id` columns

These three columns have no FK and no code reference:

```sql
BEGIN;

ALTER TABLE cleangoal.meals DROP COLUMN item_id;
ALTER TABLE cleangoal.daily_summaries DROP COLUMN item_id;
ALTER TABLE cleangoal.user_meal_plans DROP COLUMN item_id;

COMMIT;
```

**Rollback** (re-adds as nullable bigint — data is lost):
```sql
ALTER TABLE cleangoal.meals ADD COLUMN item_id bigint;
ALTER TABLE cleangoal.daily_summaries ADD COLUMN item_id bigint;
ALTER TABLE cleangoal.user_meal_plans ADD COLUMN item_id bigint;
```

### A.5 Record migration

```sql
INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_a_critical_fixes');
```

### ⚠ Backend code change required AFTER Phase A runs

None — `backend/app/routers/meals.py:29` already writes `meal_type`. It was the DB that was out of sync. Phase A actually makes existing code work correctly.

---

## Phase B — Integrity constraints

### B.1 UNIQUE constraints

```sql
BEGIN;

-- roles.role_name — lookup table should have unique names
ALTER TABLE cleangoal.roles
    ADD CONSTRAINT uq_roles_name UNIQUE (role_name);

-- users.email — must be unique (business rule + Supabase Auth mirror)
-- Verify no duplicates first:
--   SELECT email, COUNT(*) FROM cleangoal.users GROUP BY email HAVING COUNT(*) > 1;
ALTER TABLE cleangoal.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);

-- users.username — optional but recommended if enforcing unique display names
-- Skip for now unless app shows "username already taken" errors.

-- beverages / snacks — 1:1 with foods
ALTER TABLE cleangoal.beverages
    ADD CONSTRAINT uq_beverages_food UNIQUE (food_id);
ALTER TABLE cleangoal.snacks
    ADD CONSTRAINT uq_snacks_food UNIQUE (food_id);

COMMIT;
```

### B.2 Drop duplicate UNIQUE constraints

```sql
BEGIN;

-- daily_summaries has TWO unique constraints on (user_id, date_record)
ALTER TABLE cleangoal.daily_summaries
    DROP CONSTRAINT IF EXISTS daily_summaries_user_id_date_record_key;
-- keep uq_daily_summaries_user_date

-- water_logs same situation
ALTER TABLE cleangoal.water_logs
    DROP CONSTRAINT IF EXISTS water_logs_user_date_key;
-- keep uq_water_logs_user_date

-- food_allergy_flags has duplicate FK defs (2 per column)
-- Inspect first:  SELECT conname FROM pg_constraint WHERE conrelid = 'cleangoal.food_allergy_flags'::regclass;
-- Drop the auto-generated duplicates, keep named ones.
-- (DDL depends on actual conname values — generate after inspection.)

COMMIT;
```

### B.3 VARCHAR length caps

```sql
BEGIN;

-- Emails, usernames
ALTER TABLE cleangoal.users
    ALTER COLUMN email TYPE varchar(255),
    ALTER COLUMN username TYPE varchar(50),
    ALTER COLUMN password_hash TYPE varchar(255),
    ALTER COLUMN avatar_url TYPE varchar(500);

-- Food catalog
ALTER TABLE cleangoal.foods
    ALTER COLUMN food_name TYPE varchar(200),
    ALTER COLUMN serving_unit TYPE varchar(30),
    ALTER COLUMN image_url TYPE varchar(500);

-- Temp/verified food, requests
ALTER TABLE cleangoal.temp_food
    ALTER COLUMN food_name TYPE varchar(200);
ALTER TABLE cleangoal.food_requests
    ALTER COLUMN food_name TYPE varchar(200);

-- Roles, ingredients, units
ALTER TABLE cleangoal.roles
    ALTER COLUMN role_name TYPE varchar(30);
ALTER TABLE cleangoal.ingredients
    ALTER COLUMN name TYPE varchar(150),
    ALTER COLUMN category TYPE varchar(50);
ALTER TABLE cleangoal.units
    ALTER COLUMN name TYPE varchar(30);

-- Notifications, detail items
ALTER TABLE cleangoal.notifications
    ALTER COLUMN title TYPE varchar(200);
ALTER TABLE cleangoal.detail_items
    ALTER COLUMN food_name TYPE varchar(200),
    ALTER COLUMN note TYPE varchar(500);

COMMIT;
```

**Rollback** (back to unbounded `varchar`):
```sql
-- For each column above:
ALTER TABLE … ALTER COLUMN … TYPE varchar;
```

### B.4 CHECK constraints

```sql
BEGIN;

-- Biometrics sanity
ALTER TABLE cleangoal.users
    ADD CONSTRAINT ck_users_height CHECK (height_cm IS NULL OR height_cm BETWEEN 80 AND 250),
    ADD CONSTRAINT ck_users_weight CHECK (current_weight_kg IS NULL OR current_weight_kg BETWEEN 20 AND 300),
    ADD CONSTRAINT ck_users_target_weight CHECK (target_weight_kg IS NULL OR target_weight_kg BETWEEN 20 AND 300),
    ADD CONSTRAINT ck_users_target_calories CHECK (target_calories IS NULL OR target_calories BETWEEN 500 AND 6000),
    ADD CONSTRAINT ck_users_streak CHECK (current_streak >= 0),
    ADD CONSTRAINT ck_users_login_days CHECK (total_login_days >= 0);

-- Weight logs
ALTER TABLE cleangoal.weight_logs
    ADD CONSTRAINT ck_weight_logs_kg CHECK (weight_kg BETWEEN 20 AND 300);

-- Water
ALTER TABLE cleangoal.water_logs
    ADD CONSTRAINT ck_water_logs_glasses CHECK (glasses >= 0 AND glasses <= 30);

-- Exercise
ALTER TABLE cleangoal.exercise_logs
    ADD CONSTRAINT ck_exercise_duration CHECK (duration_minutes >= 0 AND duration_minutes <= 1440),
    ADD CONSTRAINT ck_exercise_calories CHECK (calories_burned IS NULL OR calories_burned >= 0);

-- Foods — no negative nutrition
ALTER TABLE cleangoal.foods
    ADD CONSTRAINT ck_foods_calories CHECK (calories IS NULL OR calories >= 0),
    ADD CONSTRAINT ck_foods_protein CHECK (protein IS NULL OR protein >= 0),
    ADD CONSTRAINT ck_foods_carbs CHECK (carbs IS NULL OR carbs >= 0),
    ADD CONSTRAINT ck_foods_fat CHECK (fat IS NULL OR fat >= 0),
    ADD CONSTRAINT ck_foods_serving CHECK (serving_quantity IS NULL OR serving_quantity > 0);

-- Daily summaries
ALTER TABLE cleangoal.daily_summaries
    ADD CONSTRAINT ck_daily_totals CHECK (
        total_calories_intake >= 0 AND total_protein >= 0 AND total_carbs >= 0 AND total_fat >= 0
    ),
    ADD CONSTRAINT ck_daily_water CHECK (water_glasses >= 0);

-- Ratings (if tables kept)
ALTER TABLE cleangoal.recipe_reviews
    ADD CONSTRAINT ck_recipe_rating CHECK (rating IS NULL OR rating BETWEEN 1 AND 5);

COMMIT;
```

### B.5 Polymorphic CHECK on `detail_items`

`detail_items` currently has three nullable parent FKs (`meal_id`, `plan_id`, `summary_id`). Enforce "exactly one":

```sql
BEGIN;

ALTER TABLE cleangoal.detail_items
    ADD CONSTRAINT ck_detail_items_one_parent CHECK (
        (meal_id IS NOT NULL)::int
      + (plan_id IS NOT NULL)::int
      + (summary_id IS NOT NULL)::int
      = 1
    );

COMMIT;
```

**Pre-check**:
```sql
SELECT COUNT(*) FROM cleangoal.detail_items
WHERE ((meal_id IS NOT NULL)::int + (plan_id IS NOT NULL)::int + (summary_id IS NOT NULL)::int) <> 1;
-- Must be 0. If not, fix data first.
```

### B.6 Record

```sql
INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_b_integrity');
```

### Rollback — Phase B

Drop all added constraints by name. Restore `varchar` types by `ALTER COLUMN ... TYPE varchar`.

---

## Phase C — De-duplication ⚠ needs per-item approval

Each item below removes one side of a duplicate. **Pick per-item** — don't assume all.

### C.1 `users.goal_type` vs `user_goals`

**Option 1** (recommended): keep `users.goal_type` as "current", keep `user_goals` as history log only.
- No schema change. Just document intent.
- App already reads from `users`.

**Option 2**: drop `user_goals` table entirely (it's unused).
```sql
DROP TABLE cleangoal.user_goals;
```

### C.2 `users.activity_level` vs `user_activities`

Same as C.1. Recommend keep `users.activity_level`, drop `user_activities` if not used.
```sql
DROP TABLE cleangoal.user_activities;
```

### C.3 `daily_summaries.water_glasses` vs `water_logs.glasses`

Two sources of truth. `water_logs` is the primary store (has UNIQUE on user+date). `daily_summaries.water_glasses` is a cache.

**Recommended**: keep `daily_summaries.water_glasses` as cache, ensure it's updated by trigger when `water_logs` changes. Trigger already exists from v8/v9 — verify with:
```sql
SELECT tgname FROM pg_trigger WHERE tgrelid = 'cleangoal.water_logs'::regclass;
```

If trigger missing or inconsistent, pick one:
- Drop `daily_summaries.water_glasses`, always compute from `water_logs`.
- Or re-install trigger.

### C.4 `recipe_ingredients` vs `food_ingredients`

Two parallel implementations. `food_ingredients` uses proper FKs (but `units` is empty). `recipe_ingredients` uses free text.

**Recommended**: keep `recipe_ingredients` (free text is fine for recipes), drop `food_ingredients` + `ingredients` + `units` + `unit_conversions` if unused by app (see Phase F).

---

## Phase D — Units table decision

`units` has 0 rows but is referenced by 5 FKs. Two options:

### D.1 Seed basic units

```sql
BEGIN;
INSERT INTO cleangoal.units(name, conversion_factor) VALUES
    ('g', 1.0),
    ('kg', 1000.0),
    ('ml', 1.0),
    ('l', 1000.0),
    ('tsp', 5.0),
    ('tbsp', 15.0),
    ('cup', 240.0),
    ('piece', NULL),
    ('serving', NULL),
    ('oz', 28.35);
COMMIT;
```

### D.2 Drop unit FKs (recommended if app doesn't use them)

```sql
BEGIN;

ALTER TABLE cleangoal.detail_items
    DROP CONSTRAINT IF EXISTS detail_items_unit_id_fkey,
    DROP COLUMN unit_id;

ALTER TABLE cleangoal.food_ingredients
    DROP CONSTRAINT IF EXISTS food_ingredients_unit_id_fkey;

ALTER TABLE cleangoal.ingredients
    DROP CONSTRAINT IF EXISTS ingredients_default_unit_id_fkey;

-- then (optional): DROP TABLE cleangoal.unit_conversions, cleangoal.units CASCADE;

COMMIT;
```

**Before deciding**: grep backend to confirm `unit_id` is unused:
```bash
grep -rn "unit_id" backend/app/
```

---

## Phase E — Timezone (`timestamp` → `timestamptz`)

`timestamptz` stores UTC internally and converts on read. Non-breaking if server clock is UTC. Large but mechanical change.

```sql
BEGIN;

-- Example for one table:
ALTER TABLE cleangoal.users
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN last_login_date TYPE timestamptz USING last_login_date AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN consent_accepted_at TYPE timestamptz USING consent_accepted_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN deleted_at TYPE timestamptz USING deleted_at AT TIME ZONE 'Asia/Bangkok';

-- Repeat for: meals, detail_items, daily_summaries, water_logs, exercise_logs, weight_logs,
--             notifications, temp_food, verified_food, food_requests, foods,
--             email_verification_codes, password_reset_codes, recipes, recipe_reviews,
--             health_contents, user_goals, user_activities, user_meal_plans, food_ingredients,
--             recipe_ingredients, unit_conversions, schema_migrations.

COMMIT;
```

**Risk**: Python `psycopg2` returns `datetime` with tzinfo after this change. Test API endpoints before applying in production.

**Rollback**: `ALTER COLUMN … TYPE timestamp USING … AT TIME ZONE 'Asia/Bangkok'`.

---

## Phase F — Drop unused tables ⚠ needs per-table approval

List candidates and reason. Check each against `grep -rn "<table>" backend/app/` before dropping.

Verified list of real tables (41). Candidates per `grep backend/app/`:

| Table | Reason | Drop? |
|---|---|---|
| `progress` | Overlaps `users.current_streak` + `weekly_summaries` | ? |
| `user_goals` | Superseded by `users.goal_type` + `users.goal_target_date` (see C.1) | ? |
| `user_activities` | Superseded by `users.activity_level` (see C.2) | ? |
| `ingredients`, `food_ingredients` | Empty; parallel to free-text `recipe_ingredients` (see D) | ? |
| `units`, `unit_conversions` | Empty (0 rows), 5 FKs reference (see D) | ? |
| `allergy_flags`, `food_allergy_flags`, `user_allergy_preferences` | Allergy feature — confirm | ? |
| `recipe_reviews` | Confirm if review UI exists in Flutter | ? |
| `user_health_content_views` | Analytics table — keep? | ? |
| `weekly_summaries` | Possibly derived from `daily_summaries` | ? |

**Suggested minimal sweep** (do NOT run yet — each needs `grep` verification):
```sql
BEGIN;
DROP TABLE IF EXISTS cleangoal.progress CASCADE;
DROP TABLE IF EXISTS cleangoal.user_goals CASCADE;        -- IF C.1 approved
DROP TABLE IF EXISTS cleangoal.user_activities CASCADE;   -- IF C.2 approved
-- Units cascade: see Phase D
DROP TABLE IF EXISTS cleangoal.food_ingredients CASCADE;
DROP TABLE IF EXISTS cleangoal.ingredients CASCADE;
DROP TABLE IF EXISTS cleangoal.unit_conversions CASCADE;
DROP TABLE IF EXISTS cleangoal.units CASCADE;
COMMIT;
```

> Phantom tables removed from this doc: `articles`, `chatbot_interactions`, `community_posts`, `follows`, `likes`, `recommendations`, `user_detail_logs`, `user_preferences`, `food_reviews`. These never existed. Confirmed real table count is **41**.

**Rollback**: recreate from `backend/init_database.sql` (which is the DDL source).

---

## Execution plan

1. **Backup Supabase** — take a manual snapshot via dashboard before anything.
2. **Apply Phase A** in staging Supabase branch → run backend test suite → verify meal logging end-to-end.
3. **Apply Phase B** → run test suite again.
4. **User review of Phase C** → apply chosen items.
5. **User decides Phase D** — seed or drop.
6. **Phase E** only after backend pool verified to handle tz-aware datetimes.
7. **User review of Phase F** — per-table confirmation.
8. **Merge to main Supabase** once staging is green.

Each phase adds a row to `cleangoal.schema_migrations`. Use that to know where we are.

---

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Phase A breaks the 10 existing meal rows if backfill misclassifies | User tables are effectively empty; can re-run backfill |
| FK ADD fails on orphan rows | Pre-check queries in A.2 return 0 before running |
| VARCHAR cap truncates existing long strings | Run `SELECT MAX(LENGTH(col))` per column before Phase B.3 |
| CHECK fails on existing out-of-range data | Pre-check each CHECK range against current data |
| Phase E breaks Python datetime handling | Deploy to staging first, test `/meals`, `/daily-summary`, `/login` |
| Drop table deletes real data | Phase F per-table + user approval + backup first |

---

## What's deliberately **out of scope** for v14

- Splitting `users` into `users` (auth) + `user_profiles` (biometrics) — bigger refactor
- Moving hardcoded food images to Supabase Storage
- Partitioning `meals` or `detail_items` for scale
- RLS policies for anon/authenticated roles (currently RLS on, no policies → backend only)
- Switching to Supabase Auth (tracked separately in Phase 1.3 of master plan)

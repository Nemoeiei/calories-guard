-- v14 Phase A — Critical fixes for schema/code divergence
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.

BEGIN;

-- A.1 Add meal_type to meals (backend/app/routers/meals.py:29 INSERTs this column,
--     but it was missing — would have errored at runtime once users existed)
ALTER TABLE cleangoal.meals ADD COLUMN IF NOT EXISTS meal_type cleangoal.meal_type;

-- Backfill rule (no rows at apply time, kept here for doc/replay):
UPDATE cleangoal.meals SET meal_type = CASE
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 6 AND 10 THEN 'breakfast'::cleangoal.meal_type
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 11 AND 14 THEN 'lunch'::cleangoal.meal_type
    WHEN EXTRACT(HOUR FROM meal_time) BETWEEN 17 AND 21 THEN 'dinner'::cleangoal.meal_type
    ELSE 'snack'::cleangoal.meal_type
END WHERE meal_type IS NULL;

ALTER TABLE cleangoal.meals ALTER COLUMN meal_type SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_meals_user_date_type
    ON cleangoal.meals (user_id, (DATE(meal_time)), meal_type);

-- A.2 Missing FKs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.meals'::regclass
          AND conname = 'fk_meals_user'
    ) THEN
        ALTER TABLE cleangoal.meals
            ADD CONSTRAINT fk_meals_user
            FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.detail_items'::regclass
          AND conname = 'fk_detail_items_food'
    ) THEN
        ALTER TABLE cleangoal.detail_items
            ADD CONSTRAINT fk_detail_items_food
            FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.detail_items'::regclass
          AND conname = 'fk_detail_items_plan'
    ) THEN
        ALTER TABLE cleangoal.detail_items
            ADD CONSTRAINT fk_detail_items_plan
            FOREIGN KEY (plan_id) REFERENCES cleangoal.user_meal_plans(plan_id) ON DELETE CASCADE;
    END IF;
END$$;

-- A.3 NOT NULL critical columns
ALTER TABLE cleangoal.meals ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE cleangoal.daily_summaries ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE cleangoal.daily_summaries ALTER COLUMN date_record SET NOT NULL;

-- A.4 Drop orphan item_id columns (no FK, no code references)
ALTER TABLE cleangoal.meals DROP COLUMN IF EXISTS item_id;
ALTER TABLE cleangoal.daily_summaries DROP COLUMN IF EXISTS item_id;
ALTER TABLE cleangoal.user_meal_plans DROP COLUMN IF EXISTS item_id;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_a_critical_fixes')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- ALTER TABLE cleangoal.meals DROP CONSTRAINT IF EXISTS fk_meals_user;
-- ALTER TABLE cleangoal.detail_items DROP CONSTRAINT IF EXISTS fk_detail_items_food;
-- ALTER TABLE cleangoal.detail_items DROP CONSTRAINT IF EXISTS fk_detail_items_plan;
-- ALTER TABLE cleangoal.meals ALTER COLUMN user_id DROP NOT NULL;
-- ALTER TABLE cleangoal.daily_summaries ALTER COLUMN user_id DROP NOT NULL;
-- ALTER TABLE cleangoal.daily_summaries ALTER COLUMN date_record DROP NOT NULL;
-- DROP INDEX IF EXISTS cleangoal.idx_meals_user_date_type;
-- ALTER TABLE cleangoal.meals DROP COLUMN IF EXISTS meal_type;
-- ALTER TABLE cleangoal.meals ADD COLUMN item_id bigint;
-- ALTER TABLE cleangoal.daily_summaries ADD COLUMN item_id bigint;
-- ALTER TABLE cleangoal.user_meal_plans ADD COLUMN item_id bigint;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_a_critical_fixes';

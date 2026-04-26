-- v24: Audit columns + cache-sync triggers.
--
-- Changes:
--   1. Add updated_at to detail_items, daily_summaries, exercise_logs
--      (water_logs already has updated_at; meals has only created_at — added here too)
--   2. Create fn_set_updated_at() trigger function that sets updated_at = NOW()
--      and attach it to the tables above.
--   3. Create fn_sync_detail_items_from_foods() trigger that propagates changes
--      from foods.{food_name, calories, protein, carbs, fat} → detail_items
--      when a foods row is updated, preventing stale cached values.

BEGIN;

-- -------------------------------------------------------------------------
-- 1. Add updated_at columns (idempotent)
-- -------------------------------------------------------------------------

ALTER TABLE cleangoal.detail_items
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE cleangoal.daily_summaries
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE cleangoal.exercise_logs
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE cleangoal.meals
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- -------------------------------------------------------------------------
-- 2. Generic updated_at trigger function
-- -------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cleangoal.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cleangoal, public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Attach to detail_items
DROP TRIGGER IF EXISTS trg_detail_items_updated_at ON cleangoal.detail_items;
CREATE TRIGGER trg_detail_items_updated_at
    BEFORE UPDATE ON cleangoal.detail_items
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_set_updated_at();

-- Attach to daily_summaries
DROP TRIGGER IF EXISTS trg_daily_summaries_updated_at ON cleangoal.daily_summaries;
CREATE TRIGGER trg_daily_summaries_updated_at
    BEFORE UPDATE ON cleangoal.daily_summaries
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_set_updated_at();

-- Attach to exercise_logs
DROP TRIGGER IF EXISTS trg_exercise_logs_updated_at ON cleangoal.exercise_logs;
CREATE TRIGGER trg_exercise_logs_updated_at
    BEFORE UPDATE ON cleangoal.exercise_logs
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_set_updated_at();

-- Attach to meals
DROP TRIGGER IF EXISTS trg_meals_updated_at ON cleangoal.meals;
CREATE TRIGGER trg_meals_updated_at
    BEFORE UPDATE ON cleangoal.meals
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_set_updated_at();

-- -------------------------------------------------------------------------
-- 3. Cache-sync trigger: foods → detail_items
--    When foods.food_name / calories / protein / carbs / fat changes,
--    propagate the new values to detail_items rows that reference that food.
-- -------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cleangoal.fn_sync_detail_items_from_foods()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cleangoal, public
AS $$
BEGIN
    -- Only act when the cached columns actually change.
    IF (NEW.food_name IS DISTINCT FROM OLD.food_name
     OR NEW.calories   IS DISTINCT FROM OLD.calories
     OR NEW.protein    IS DISTINCT FROM OLD.protein
     OR NEW.carbs      IS DISTINCT FROM OLD.carbs
     OR NEW.fat        IS DISTINCT FROM OLD.fat) THEN

        UPDATE cleangoal.detail_items
           SET food_name        = NEW.food_name,
               cal_per_unit     = NEW.calories,
               protein_per_unit = NEW.protein,
               carbs_per_unit   = NEW.carbs,
               fat_per_unit     = NEW.fat,
               updated_at       = NOW()
         WHERE food_id = NEW.food_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_foods_sync_detail_items ON cleangoal.foods;
CREATE TRIGGER trg_foods_sync_detail_items
    AFTER UPDATE ON cleangoal.foods
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_sync_detail_items_from_foods();

-- -------------------------------------------------------------------------
-- 4. Record migration
-- -------------------------------------------------------------------------

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v24_audit_columns_and_sync_triggers')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- BEGIN;
-- DROP TRIGGER IF EXISTS trg_foods_sync_detail_items ON cleangoal.foods;
-- DROP FUNCTION IF EXISTS cleangoal.fn_sync_detail_items_from_foods();
-- DROP TRIGGER IF EXISTS trg_meals_updated_at ON cleangoal.meals;
-- DROP TRIGGER IF EXISTS trg_exercise_logs_updated_at ON cleangoal.exercise_logs;
-- DROP TRIGGER IF EXISTS trg_daily_summaries_updated_at ON cleangoal.daily_summaries;
-- DROP TRIGGER IF EXISTS trg_detail_items_updated_at ON cleangoal.detail_items;
-- DROP FUNCTION IF EXISTS cleangoal.fn_set_updated_at();
-- ALTER TABLE cleangoal.meals DROP COLUMN IF EXISTS updated_at;
-- ALTER TABLE cleangoal.exercise_logs DROP COLUMN IF EXISTS updated_at;
-- ALTER TABLE cleangoal.daily_summaries DROP COLUMN IF EXISTS updated_at;
-- ALTER TABLE cleangoal.detail_items DROP COLUMN IF EXISTS updated_at;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v24_audit_columns_and_sync_triggers';
-- COMMIT;

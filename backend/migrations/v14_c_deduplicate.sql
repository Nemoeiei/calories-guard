-- v14 Phase C — Deduplicate redundant tables + tighten water sync trigger
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.

BEGIN;

-- C.1 Drop duplicate goal/activity state tables
-- The user-level goal and activity-level fields live on cleangoal.users
-- (goal_type, target_weight_kg, target_calories, activity_level). The
-- separate user_goals / user_activities tables were never written to by
-- the backend and carry stale/empty rows. Dropping removes the drift risk.
DROP TABLE IF EXISTS cleangoal.user_goals CASCADE;
DROP TABLE IF EXISTS cleangoal.user_activities CASCADE;

-- C.2 Make water_logs -> daily_summaries sync DELETE-safe
-- The existing trigger ignored DELETE, so removing a water log left
-- daily_summaries.water_glasses stale. Rewriting to handle INSERT / UPDATE
-- / DELETE consistently keeps the denormalized column in sync.
CREATE OR REPLACE FUNCTION cleangoal.fn_sync_water_to_daily()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        UPDATE cleangoal.daily_summaries
           SET water_glasses = 0
         WHERE user_id = OLD.user_id AND date_record = OLD.date_record;
        RETURN OLD;
    END IF;
    INSERT INTO cleangoal.daily_summaries (user_id, date_record, water_glasses)
    VALUES (NEW.user_id, NEW.date_record, NEW.glasses)
    ON CONFLICT (user_id, date_record)
    DO UPDATE SET water_glasses = EXCLUDED.water_glasses;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_water_to_daily ON cleangoal.water_logs;
CREATE TRIGGER trg_sync_water_to_daily
AFTER INSERT OR UPDATE OR DELETE ON cleangoal.water_logs
FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_sync_water_to_daily();

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_c_deduplicate')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- Recreating user_goals / user_activities requires the original DDL from
-- init_database.sql. The trigger rewrite is backwards compatible — to
-- revert to INSERT/UPDATE-only behavior, redefine fn_sync_water_to_daily
-- without the DELETE branch and recreate the trigger for INSERT OR UPDATE.
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_c_deduplicate';

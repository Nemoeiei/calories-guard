-- v15 Phase B — Pin search_path on trigger/helper functions
-- Applied to Supabase cleangoal schema on 2026-04-19.
-- See docs/PRODUCTION_READINESS.md task #4 for rationale.
--
-- Why: Supabase advisor function_search_path_mutable (WARN) on 8 functions.
-- An attacker with CREATE privilege on any schema on the session search_path
-- can shadow a cleangoal object (e.g. create cleangoal.users in public and
-- have a trigger pick that up instead). Pinning search_path to
-- `cleangoal, pg_catalog` eliminates this class of attack.

BEGIN;

DO $$
DECLARE
    fn regprocedure;
BEGIN
    FOR fn IN
        SELECT to_regprocedure(name)
        FROM (VALUES
            ('cleangoal.fn_sync_water_to_daily()'),
            ('cleangoal.fn_sync_daily_summary()'),
            ('cleangoal.fn_create_verified_food_on_temp_insert()'),
            ('cleangoal.fn_temp_food_touch_updated_at()'),
            ('cleangoal.fn_verified_food_touch_updated_at()'),
            ('cleangoal.update_recipe_favorite_count()'),
            ('cleangoal.update_recipe_rating()')
        ) AS f(name)
        WHERE to_regprocedure(name) IS NOT NULL
    LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = cleangoal, pg_catalog', fn);
    END LOOP;
END$$;

-- public.handle_new_user is the Supabase Auth trigger that fires when a
-- user signs up via gotrue. It needs to reach cleangoal.users, so include
-- both schemas.
DO $$
BEGIN
    IF to_regprocedure('public.handle_new_user()') IS NOT NULL THEN
        ALTER FUNCTION public.handle_new_user()
            SET search_path = cleangoal, public, pg_catalog;
    END IF;
END$$;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v15_b_function_search_path')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- ALTER FUNCTION ... RESET search_path;  (for each function listed above)
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v15_b_function_search_path';

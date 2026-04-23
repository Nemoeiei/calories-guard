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

ALTER FUNCTION cleangoal.fn_sync_water_to_daily()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.fn_sync_daily_summary()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.fn_create_verified_food_on_temp_insert()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.fn_temp_food_touch_updated_at()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.fn_verified_food_touch_updated_at()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.update_recipe_favorite_count()
    SET search_path = cleangoal, pg_catalog;

ALTER FUNCTION cleangoal.update_recipe_rating()
    SET search_path = cleangoal, pg_catalog;

-- public.handle_new_user is the Supabase Auth trigger that fires when a
-- user signs up via gotrue. It needs to reach cleangoal.users, so include
-- both schemas.
ALTER FUNCTION public.handle_new_user()
    SET search_path = cleangoal, public, pg_catalog;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v15_b_function_search_path')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- ALTER FUNCTION ... RESET search_path;  (for each function listed above)
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v15_b_function_search_path';

-- v15 Phase A — Drop leftover tables in public schema
-- Applied to Supabase cleangoal schema on 2026-04-19.
-- See docs/PRODUCTION_READINESS.md task #2 for rationale.
--
-- Background: an earlier Supabase init left 12 empty tables in the `public`
-- schema (duplicates of what lives in `cleangoal`). Because Supabase exposes
-- `public` via PostgREST, these were reachable with the anon key — no RLS,
-- no policies. Supabase security advisor flagged every one as ERROR-level
-- rls_disabled_in_public. All 12 tables verified:
--   - approx_rows = 0 (pg_stat_user_tables)
--   - zero references in backend/ or flutter_application_1/ (grep-verified)

BEGIN;

DROP TABLE IF EXISTS public.daily_summaries      CASCADE;
DROP TABLE IF EXISTS public.foods                CASCADE;
DROP TABLE IF EXISTS public.health_contents      CASCADE;
DROP TABLE IF EXISTS public.progress             CASCADE;
DROP TABLE IF EXISTS public.progress_snapshots   CASCADE;
DROP TABLE IF EXISTS public.roles                CASCADE;
DROP TABLE IF EXISTS public.units                CASCADE;
DROP TABLE IF EXISTS public.user_activities      CASCADE;
DROP TABLE IF EXISTS public.user_goals           CASCADE;
DROP TABLE IF EXISTS public.user_stats           CASCADE;
DROP TABLE IF EXISTS public.users                CASCADE;
DROP TABLE IF EXISTS public.weight_logs          CASCADE;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v15_a_drop_public_leftovers')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- Restore from Supabase daily backup (these tables were empty so nothing
-- functional depends on them — no code path reads public.* anywhere).
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v15_a_drop_public_leftovers';

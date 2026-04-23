-- v14 Phase F — Drop unused tables
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.
--
-- Rationale: each of these tables had no references from backend/app/routers
-- or flutter_application_1/lib (grep-verified before drop) and no rows of
-- user value. Keeping them on disk risks drift (columns added but never
-- written, FK graph noise, RLS policy gaps).
--
--   progress                    — superseded by weight_logs + daily_summaries
--   weekly_summaries            — computed on demand in /insights endpoints
--   chat_messages               — AI coach does not persist chat history
--   user_health_content_views   — analytics table never wired up

BEGIN;

DROP TABLE IF EXISTS cleangoal.progress CASCADE;
DROP TABLE IF EXISTS cleangoal.weekly_summaries CASCADE;
DROP TABLE IF EXISTS cleangoal.chat_messages CASCADE;
DROP TABLE IF EXISTS cleangoal.user_health_content_views CASCADE;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_f_drop_unused')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- Restore the original CREATE TABLE statements from init_database.sql for:
--   cleangoal.progress, cleangoal.weekly_summaries,
--   cleangoal.chat_messages, cleangoal.user_health_content_views.
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_f_drop_unused';

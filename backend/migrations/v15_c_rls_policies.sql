-- v15 Phase C — RLS policies baseline
-- Applied to Supabase cleangoal schema on 2026-04-19.
-- See docs/PRODUCTION_READINESS.md task #3 for rationale.
--
-- Baseline policy model (pre-Supabase-Auth migration):
--   * Backend talks to Postgres via the pooled `postgres` role (RLS-bypassing).
--     So these policies do not change runtime behaviour today.
--   * Goal: encode intent in source, silence `rls_enabled_no_policy` advisor,
--     and lock the data down before any client code ever touches PostgREST
--     with the anon/authenticated JWT.
--
-- Categories:
--   (1) User-owned tables (RLS already on, 0 policies): add explicit
--       `deny_anon` + `deny_authed_until_auth_migration` policies. These are
--       placeholders — once the Supabase Auth migration lands and the
--       cleangoal.users row carries a supabase_uid, replace them with
--       per-user policies keyed on auth.uid().
--   (2) Reference / public tables (RLS off): enable RLS + add a single
--       `public_read` policy so anon/authenticated can SELECT but not
--       mutate. Writes continue to happen via the backend's service role.
--   (3) Polymorphic + infra tables: enable RLS with no policies (deny-by-
--       default). `detail_items` ownership is through meals/meal_plans and
--       will be policy-expressed alongside the auth migration.

BEGIN;

-- =====================================================================
-- (1) User-owned tables — explicit deny for anon/authenticated
-- =====================================================================
DO $$
DECLARE t text;
DECLARE user_tables text[] := ARRAY[
    'users',
    'meals',
    'daily_summaries',
    'water_logs',
    'exercise_logs',
    'weight_logs',
    'notifications',
    'temp_food',
    'food_requests',
    'email_verification_codes',
    'password_reset_codes',
    'user_favorites',
    'user_meal_plans',
    'user_allergy_preferences',
    'recipe_favorites',
    'recipe_reviews'
];
BEGIN
  FOREACH t IN ARRAY user_tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "deny_anon" ON cleangoal.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "deny_authed_until_auth_migration" ON cleangoal.%I;', t);
    EXECUTE format(
      'CREATE POLICY "deny_anon" ON cleangoal.%I
         AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);',
      t);
    EXECUTE format(
      'CREATE POLICY "deny_authed_until_auth_migration" ON cleangoal.%I
         AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);',
      t);
  END LOOP;
END$$;

-- =====================================================================
-- (2) Reference tables — enable RLS + public_read
-- =====================================================================
DO $$
DECLARE t text;
DECLARE ref_tables text[] := ARRAY[
    'allergy_flags',
    'beverages',
    'food_allergy_flags',
    'food_ingredients',
    'foods',
    'health_contents',
    'ingredients',
    'recipe_ingredients',
    'recipe_steps',
    'recipe_tips',
    'recipe_tools',
    'recipes',
    'roles',
    'snacks',
    'unit_conversions',
    'units',
    'verified_food'
];
BEGIN
  FOREACH t IN ARRAY ref_tables LOOP
    EXECUTE format('ALTER TABLE cleangoal.%I ENABLE ROW LEVEL SECURITY;', t);
    EXECUTE format('DROP POLICY IF EXISTS "public_read" ON cleangoal.%I;', t);
    EXECUTE format(
      'CREATE POLICY "public_read" ON cleangoal.%I
         AS PERMISSIVE FOR SELECT TO anon, authenticated USING (true);',
      t);
  END LOOP;
END$$;

-- =====================================================================
-- (3) Polymorphic + infra tables — RLS on + explicit deny
-- =====================================================================
ALTER TABLE cleangoal.detail_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleangoal.schema_migrations  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "deny_anon" ON cleangoal.detail_items;
DROP POLICY IF EXISTS "deny_authed_until_auth_migration" ON cleangoal.detail_items;
CREATE POLICY "deny_anon" ON cleangoal.detail_items
  AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY "deny_authed_until_auth_migration" ON cleangoal.detail_items
  AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS "deny_anon" ON cleangoal.schema_migrations;
DROP POLICY IF EXISTS "deny_authenticated" ON cleangoal.schema_migrations;
CREATE POLICY "deny_anon" ON cleangoal.schema_migrations
  AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY "deny_authenticated" ON cleangoal.schema_migrations
  AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v15_c_rls_policies')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- DO $$ DECLARE t text; BEGIN
--   FOREACH t IN ARRAY ARRAY['users','meals','daily_summaries',...] LOOP
--     EXECUTE format('DROP POLICY IF EXISTS "deny_anon" ON cleangoal.%I;', t);
--     EXECUTE format('DROP POLICY IF EXISTS "deny_authed_until_auth_migration" ON cleangoal.%I;', t);
--   END LOOP;
--   FOREACH t IN ARRAY ARRAY['allergy_flags','beverages',...] LOOP
--     EXECUTE format('DROP POLICY IF EXISTS "public_read" ON cleangoal.%I;', t);
--     EXECUTE format('ALTER TABLE cleangoal.%I DISABLE ROW LEVEL SECURITY;', t);
--   END LOOP;
-- END$$;
-- ALTER TABLE cleangoal.detail_items      DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE cleangoal.schema_migrations DISABLE ROW LEVEL SECURITY;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v15_c_rls_policies';

-- v15 Phase D — Storage bucket policy hardening
-- Applied to Supabase on 2026-04-19.
-- See docs/PRODUCTION_READINESS.md task #11 for rationale.
--
-- Problem: the `food-images` bucket had four wide-open policies on
-- storage.objects keyed to the `{public}` role:
--   - SELECT (bucket_id='food-images') → allows LISTING every object
--     via the authenticated path (advisor WARN
--     public_bucket_allows_listing).
--   - INSERT / UPDATE / DELETE (bucket_id='food-images') → anyone with
--     the anon key could upload, overwrite, or delete any object.
--
-- Fix:
--   1. Drop all four policies.
--   2. The bucket remains `public=true`, so direct object URLs
--      `/storage/v1/object/public/food-images/<file>` keep working
--      — public buckets serve these without any SELECT policy.
--   3. Backend switches to SUPABASE_SERVICE_ROLE_KEY in supabase_storage.py;
--      service_role bypasses RLS so uploads continue to work without a
--      policy.
--
-- Net effect: direct object URLs still resolve for public reads, but
-- object listing and anon-key writes are blocked.

BEGIN;

DROP POLICY IF EXISTS "Public read food-images"   ON storage.objects;
DROP POLICY IF EXISTS "Allow upload food-images"  ON storage.objects;
DROP POLICY IF EXISTS "Allow update food-images"  ON storage.objects;
DROP POLICY IF EXISTS "Allow delete food-images"  ON storage.objects;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v15_d_storage_bucket_tighten')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- CREATE POLICY "Public read food-images"   ON storage.objects
--   FOR SELECT TO public USING (bucket_id = 'food-images');
-- CREATE POLICY "Allow upload food-images"  ON storage.objects
--   FOR INSERT TO public WITH CHECK (bucket_id = 'food-images');
-- CREATE POLICY "Allow update food-images"  ON storage.objects
--   FOR UPDATE TO public USING (bucket_id = 'food-images');
-- CREATE POLICY "Allow delete food-images"  ON storage.objects
--   FOR DELETE TO public USING (bucket_id = 'food-images');
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v15_d_storage_bucket_tighten';

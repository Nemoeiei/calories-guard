-- v22: Drop unused tables that were superseded in earlier migrations.
--
-- Retired tables:
--   * cleangoal.food_requests     — superseded by temp_food (v13+). No active router.
--   * cleangoal.food_ingredients  — no router; recipe ingredients use recipe_ingredients.
--   * cleangoal.ingredients       — referenced only by food_ingredients (dropped above).
--
-- Strategy: archive first, then drop. The _archive tables remain as a safety net and
-- can be dropped manually after verifying data integrity in production.

BEGIN;

-- -------------------------------------------------------------------------
-- 1. Archive
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cleangoal.food_requests_archive
    AS TABLE cleangoal.food_requests WITH NO DATA;

INSERT INTO cleangoal.food_requests_archive
SELECT * FROM cleangoal.food_requests
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS cleangoal.food_ingredients_archive
    AS TABLE cleangoal.food_ingredients WITH NO DATA;

INSERT INTO cleangoal.food_ingredients_archive
SELECT * FROM cleangoal.food_ingredients
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS cleangoal.ingredients_archive
    AS TABLE cleangoal.ingredients WITH NO DATA;

INSERT INTO cleangoal.ingredients_archive
SELECT * FROM cleangoal.ingredients
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------------------
-- 2. Drop (FK order: food_ingredients before ingredients)
-- -------------------------------------------------------------------------

DROP TABLE IF EXISTS cleangoal.food_ingredients;
DROP TABLE IF EXISTS cleangoal.ingredients;
DROP TABLE IF EXISTS cleangoal.food_requests;

-- -------------------------------------------------------------------------
-- 3. Record migration
-- -------------------------------------------------------------------------

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v22_drop_unused_tables')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- BEGIN;
-- -- Restore from archives (schema only — data is in the _archive tables)
-- CREATE TABLE cleangoal.food_requests AS SELECT * FROM cleangoal.food_requests_archive;
-- CREATE TABLE cleangoal.ingredients AS SELECT * FROM cleangoal.ingredients_archive;
-- CREATE TABLE cleangoal.food_ingredients AS SELECT * FROM cleangoal.food_ingredients_archive;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v22_drop_unused_tables';
-- COMMIT;

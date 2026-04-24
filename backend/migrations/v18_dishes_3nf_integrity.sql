-- v18: 3NF food taxonomy + relationship integrity cleanup.
--
-- Goals:
--   1) Normalize dish/category data out of free-text foods.food_category.
--   2) Keep the existing foods columns for app compatibility while adding
--      first-class FKs for ERD/data-dictionary correctness.
--   3) Archive invalid legacy recipe/unit rows, then enforce the missing FKs.
--
-- This migration is intentionally conservative: it does not drop legacy
-- columns such as foods.food_type, foods.food_category, or foods.serving_unit.
-- Those can be retired in a later app-breaking migration after Flutter/admin
-- read from dish_id / serving_unit_id.

BEGIN;

-- -------------------------------------------------------------------------
-- 1. Unit lookup cleanup
-- -------------------------------------------------------------------------

-- Current live foods use serving_unit='set' for a few rows; add a matching
-- unit before backfilling foods.serving_unit_id.
INSERT INTO cleangoal.units (name, quantity)
SELECT 'set', 1
WHERE NOT EXISTS (
    SELECT 1 FROM cleangoal.units WHERE lower(name) = 'set'
);

CREATE UNIQUE INDEX IF NOT EXISTS units_name_lower_uq
    ON cleangoal.units (lower(name));

ALTER TABLE cleangoal.foods
    ADD COLUMN IF NOT EXISTS serving_unit_id INTEGER;

UPDATE cleangoal.foods f
   SET serving_unit_id = u.unit_id
  FROM cleangoal.units u
 WHERE f.serving_unit_id IS NULL
   AND f.serving_unit IS NOT NULL
   AND lower(u.name) = lower(f.serving_unit);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'cleangoal.foods'::regclass
          AND conname = 'foods_serving_unit_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.foods
            ADD CONSTRAINT foods_serving_unit_id_fkey
            FOREIGN KEY (serving_unit_id)
            REFERENCES cleangoal.units(unit_id)
            ON DELETE SET NULL;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_foods_serving_unit_id
    ON cleangoal.foods(serving_unit_id);

-- detail_items.unit_id is written by meal logging and read by history screens.
-- It was previously a loose integer despite semantically referencing units.
UPDATE cleangoal.detail_items di
   SET unit_id = NULL
 WHERE di.unit_id IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM cleangoal.units u WHERE u.unit_id = di.unit_id
   );

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'cleangoal.detail_items'::regclass
          AND conname = 'detail_items_unit_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.detail_items
            ADD CONSTRAINT detail_items_unit_id_fkey
            FOREIGN KEY (unit_id)
            REFERENCES cleangoal.units(unit_id)
            ON DELETE SET NULL;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_detail_items_unit_id
    ON cleangoal.detail_items(unit_id);

-- -------------------------------------------------------------------------
-- 2. Dish/category taxonomy
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cleangoal.dish_categories (
    dish_category_id   BIGSERIAL PRIMARY KEY,
    category_name      VARCHAR(120) NOT NULL,
    canonical_food_type cleangoal.food_type,
    description        TEXT,
    display_order      INT NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (category_name, canonical_food_type)
);

CREATE TABLE IF NOT EXISTS cleangoal.dishes (
    dish_id             BIGSERIAL PRIMARY KEY,
    dish_name           VARCHAR(200) NOT NULL,
    dish_category_id    BIGINT NOT NULL
        REFERENCES cleangoal.dish_categories(dish_category_id)
        ON DELETE RESTRICT,
    canonical_food_type cleangoal.food_type,
    cuisine             VARCHAR(80),
    description         TEXT,
    image_url           VARCHAR(500),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ,
    deleted_at          TIMESTAMPTZ,
    UNIQUE (dish_name, dish_category_id)
);

ALTER TABLE cleangoal.dish_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleangoal.dishes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read" ON cleangoal.dish_categories;
CREATE POLICY "public_read" ON cleangoal.dish_categories
  AS PERMISSIVE FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "public_read" ON cleangoal.dishes;
CREATE POLICY "public_read" ON cleangoal.dishes
  AS PERMISSIVE FOR SELECT TO anon, authenticated USING (true);

INSERT INTO cleangoal.dish_categories (
    category_name,
    canonical_food_type,
    display_order
)
SELECT
    COALESCE(NULLIF(BTRIM(food_category), ''), food_type::text, 'uncategorized') AS category_name,
    food_type,
    MIN(food_id)::int AS display_order
FROM cleangoal.foods
WHERE deleted_at IS NULL
GROUP BY COALESCE(NULLIF(BTRIM(food_category), ''), food_type::text, 'uncategorized'), food_type
ON CONFLICT (category_name, canonical_food_type) DO NOTHING;

INSERT INTO cleangoal.dishes (
    dish_name,
    dish_category_id,
    canonical_food_type,
    cuisine,
    image_url
)
SELECT
    f.food_name,
    dc.dish_category_id,
    f.food_type,
    CASE
        WHEN f.food_category LIKE '%ไทย%' THEN 'ไทย'
        WHEN f.food_category LIKE '%ตะวันตก%' THEN 'ตะวันตก'
        ELSE NULL
    END AS cuisine,
    f.image_url
FROM cleangoal.foods f
JOIN cleangoal.dish_categories dc
  ON dc.category_name = COALESCE(NULLIF(BTRIM(f.food_category), ''), f.food_type::text, 'uncategorized')
 AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type
WHERE f.deleted_at IS NULL
ON CONFLICT (dish_name, dish_category_id) DO NOTHING;

ALTER TABLE cleangoal.foods
    ADD COLUMN IF NOT EXISTS dish_id BIGINT;

UPDATE cleangoal.foods f
   SET dish_id = d.dish_id
  FROM cleangoal.dishes d
  JOIN cleangoal.dish_categories dc ON dc.dish_category_id = d.dish_category_id
 WHERE f.dish_id IS NULL
   AND f.food_name = d.dish_name
   AND dc.category_name = COALESCE(NULLIF(BTRIM(f.food_category), ''), f.food_type::text, 'uncategorized')
   AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'cleangoal.foods'::regclass
          AND conname = 'foods_dish_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.foods
            ADD CONSTRAINT foods_dish_id_fkey
            FOREIGN KEY (dish_id)
            REFERENCES cleangoal.dishes(dish_id)
            ON DELETE SET NULL;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_foods_dish_id
    ON cleangoal.foods(dish_id);
CREATE INDEX IF NOT EXISTS idx_dishes_category
    ON cleangoal.dishes(dish_category_id);
CREATE INDEX IF NOT EXISTS idx_dishes_name_lower
    ON cleangoal.dishes(lower(dish_name));

-- -------------------------------------------------------------------------
-- 3. Archive invalid recipe relationships before enforcing FKs
-- -------------------------------------------------------------------------

-- Existing trigger cleangoal.update_recipe_favorite_count() expects this
-- aggregate column, and the Flutter recipe screen already reads it.
ALTER TABLE cleangoal.recipes
    ADD COLUMN IF NOT EXISTS favorite_count INTEGER NOT NULL DEFAULT 0;

UPDATE cleangoal.recipes r
   SET favorite_count = COALESCE(f.cnt, 0)
  FROM (
      SELECT recipe_id, COUNT(*)::int AS cnt
      FROM cleangoal.recipe_favorites
      GROUP BY recipe_id
  ) f
 WHERE r.recipe_id = f.recipe_id;

UPDATE cleangoal.recipes r
   SET favorite_count = 0
 WHERE favorite_count IS NULL;

CREATE TABLE IF NOT EXISTS cleangoal.recipe_relation_orphan_archive (
    archive_id       BIGSERIAL PRIMARY KEY,
    source_table     VARCHAR(80) NOT NULL,
    source_pk        BIGINT,
    legacy_recipe_id BIGINT,
    legacy_user_id   BIGINT,
    row_data         JSONB NOT NULL,
    archive_reason   TEXT NOT NULL,
    archived_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE cleangoal.recipe_relation_orphan_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "deny_anon" ON cleangoal.recipe_relation_orphan_archive;
DROP POLICY IF EXISTS "deny_authenticated" ON cleangoal.recipe_relation_orphan_archive;
CREATE POLICY "deny_anon" ON cleangoal.recipe_relation_orphan_archive
  AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY "deny_authenticated" ON cleangoal.recipe_relation_orphan_archive
  AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);

INSERT INTO cleangoal.recipe_relation_orphan_archive
    (source_table, source_pk, legacy_recipe_id, legacy_user_id, row_data, archive_reason)
SELECT 'recipe_ingredients', ri.ing_id, ri.recipe_id, NULL, to_jsonb(ri),
       'No matching cleangoal.recipes row during v18_dishes_3nf_integrity'
FROM cleangoal.recipe_ingredients ri
LEFT JOIN cleangoal.recipes r ON r.recipe_id = ri.recipe_id
WHERE r.recipe_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.recipe_relation_orphan_archive a
      WHERE a.source_table = 'recipe_ingredients' AND a.source_pk = ri.ing_id
  );

DELETE FROM cleangoal.recipe_ingredients ri
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.recipes r WHERE r.recipe_id = ri.recipe_id);

INSERT INTO cleangoal.recipe_relation_orphan_archive
    (source_table, source_pk, legacy_recipe_id, legacy_user_id, row_data, archive_reason)
SELECT 'recipe_steps', rs.step_id, rs.recipe_id, NULL, to_jsonb(rs),
       'No matching cleangoal.recipes row during v18_dishes_3nf_integrity'
FROM cleangoal.recipe_steps rs
LEFT JOIN cleangoal.recipes r ON r.recipe_id = rs.recipe_id
WHERE r.recipe_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.recipe_relation_orphan_archive a
      WHERE a.source_table = 'recipe_steps' AND a.source_pk = rs.step_id
  );

DELETE FROM cleangoal.recipe_steps rs
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.recipes r WHERE r.recipe_id = rs.recipe_id);

INSERT INTO cleangoal.recipe_relation_orphan_archive
    (source_table, source_pk, legacy_recipe_id, legacy_user_id, row_data, archive_reason)
SELECT 'recipe_tips', rt.tip_id, rt.recipe_id, NULL, to_jsonb(rt),
       'No matching cleangoal.recipes row during v18_dishes_3nf_integrity'
FROM cleangoal.recipe_tips rt
LEFT JOIN cleangoal.recipes r ON r.recipe_id = rt.recipe_id
WHERE r.recipe_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.recipe_relation_orphan_archive a
      WHERE a.source_table = 'recipe_tips' AND a.source_pk = rt.tip_id
  );

DELETE FROM cleangoal.recipe_tips rt
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.recipes r WHERE r.recipe_id = rt.recipe_id);

INSERT INTO cleangoal.recipe_relation_orphan_archive
    (source_table, source_pk, legacy_recipe_id, legacy_user_id, row_data, archive_reason)
SELECT 'recipe_tools', rt.tool_id, rt.recipe_id, NULL, to_jsonb(rt),
       'No matching cleangoal.recipes row during v18_dishes_3nf_integrity'
FROM cleangoal.recipe_tools rt
LEFT JOIN cleangoal.recipes r ON r.recipe_id = rt.recipe_id
WHERE r.recipe_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.recipe_relation_orphan_archive a
      WHERE a.source_table = 'recipe_tools' AND a.source_pk = rt.tool_id
  );

DELETE FROM cleangoal.recipe_tools rt
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.recipes r WHERE r.recipe_id = rt.recipe_id);

INSERT INTO cleangoal.recipe_relation_orphan_archive
    (source_table, source_pk, legacy_recipe_id, legacy_user_id, row_data, archive_reason)
SELECT 'recipe_favorites', rf.fav_id, rf.recipe_id, rf.user_id, to_jsonb(rf),
       CASE
           WHEN r.recipe_id IS NULL THEN 'No matching cleangoal.recipes row during v18_dishes_3nf_integrity'
           ELSE 'No matching cleangoal.users row during v18_dishes_3nf_integrity'
       END
FROM cleangoal.recipe_favorites rf
LEFT JOIN cleangoal.recipes r ON r.recipe_id = rf.recipe_id
LEFT JOIN cleangoal.users u ON u.user_id = rf.user_id
WHERE (r.recipe_id IS NULL OR u.user_id IS NULL)
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.recipe_relation_orphan_archive a
      WHERE a.source_table = 'recipe_favorites' AND a.source_pk = rf.fav_id
  );

DELETE FROM cleangoal.recipe_favorites rf
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.recipes r WHERE r.recipe_id = rf.recipe_id)
   OR NOT EXISTS (SELECT 1 FROM cleangoal.users u WHERE u.user_id = rf.user_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_ingredients'::regclass
          AND conname = 'recipe_ingredients_recipe_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_ingredients
            ADD CONSTRAINT recipe_ingredients_recipe_id_fkey
            FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_steps'::regclass
          AND conname = 'recipe_steps_recipe_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_steps
            ADD CONSTRAINT recipe_steps_recipe_id_fkey
            FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_tips'::regclass
          AND conname = 'recipe_tips_recipe_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_tips
            ADD CONSTRAINT recipe_tips_recipe_id_fkey
            FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_tools'::regclass
          AND conname = 'recipe_tools_recipe_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_tools
            ADD CONSTRAINT recipe_tools_recipe_id_fkey
            FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_favorites'::regclass
          AND conname = 'recipe_favorites_recipe_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_favorites
            ADD CONSTRAINT recipe_favorites_recipe_id_fkey
            FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_favorites'::regclass
          AND conname = 'recipe_favorites_user_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.recipe_favorites
            ADD CONSTRAINT recipe_favorites_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id)
            ON DELETE CASCADE;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe
    ON cleangoal.recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_tips_recipe
    ON cleangoal.recipe_tips(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_tools_recipe
    ON cleangoal.recipe_tools(recipe_id);

-- -------------------------------------------------------------------------
-- 4. Archive invalid unit conversions before enforcing FKs
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cleangoal.unit_conversion_orphan_archive (
    archive_id     BIGSERIAL PRIMARY KEY,
    conversion_id  INT,
    from_unit_id   INT,
    to_unit_id     INT,
    row_data       JSONB NOT NULL,
    archive_reason TEXT NOT NULL,
    archived_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE cleangoal.unit_conversion_orphan_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "deny_anon" ON cleangoal.unit_conversion_orphan_archive;
DROP POLICY IF EXISTS "deny_authenticated" ON cleangoal.unit_conversion_orphan_archive;
CREATE POLICY "deny_anon" ON cleangoal.unit_conversion_orphan_archive
  AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY "deny_authenticated" ON cleangoal.unit_conversion_orphan_archive
  AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);

INSERT INTO cleangoal.unit_conversion_orphan_archive
    (conversion_id, from_unit_id, to_unit_id, row_data, archive_reason)
SELECT uc.conversion_id, uc.from_unit_id, uc.to_unit_id, to_jsonb(uc),
       'Missing from_unit_id or to_unit_id in cleangoal.units during v18_dishes_3nf_integrity'
FROM cleangoal.unit_conversions uc
LEFT JOIN cleangoal.units fu ON fu.unit_id = uc.from_unit_id
LEFT JOIN cleangoal.units tu ON tu.unit_id = uc.to_unit_id
WHERE fu.unit_id IS NULL OR tu.unit_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM cleangoal.unit_conversion_orphan_archive a
      WHERE a.conversion_id = uc.conversion_id
  );

DELETE FROM cleangoal.unit_conversions uc
WHERE NOT EXISTS (SELECT 1 FROM cleangoal.units u WHERE u.unit_id = uc.from_unit_id)
   OR NOT EXISTS (SELECT 1 FROM cleangoal.units u WHERE u.unit_id = uc.to_unit_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.unit_conversions'::regclass
          AND conname = 'unit_conversions_from_unit_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.unit_conversions
            ADD CONSTRAINT unit_conversions_from_unit_id_fkey
            FOREIGN KEY (from_unit_id) REFERENCES cleangoal.units(unit_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'cleangoal.unit_conversions'::regclass
          AND conname = 'unit_conversions_to_unit_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.unit_conversions
            ADD CONSTRAINT unit_conversions_to_unit_id_fkey
            FOREIGN KEY (to_unit_id) REFERENCES cleangoal.units(unit_id)
            ON DELETE CASCADE;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_unit_conversions_from_unit
    ON cleangoal.unit_conversions(from_unit_id);
CREATE INDEX IF NOT EXISTS idx_unit_conversions_to_unit
    ON cleangoal.unit_conversions(to_unit_id);

-- -------------------------------------------------------------------------
-- 5. Drop redundant duplicate uniqueness objects created by older migrations
-- -------------------------------------------------------------------------

ALTER TABLE cleangoal.roles DROP CONSTRAINT IF EXISTS uq_roles_name;
ALTER TABLE cleangoal.users DROP CONSTRAINT IF EXISTS uq_users_email;
ALTER TABLE cleangoal.beverages DROP CONSTRAINT IF EXISTS uq_beverages_food;
ALTER TABLE cleangoal.snacks DROP CONSTRAINT IF EXISTS uq_snacks_food;
ALTER TABLE cleangoal.user_favorites DROP CONSTRAINT IF EXISTS uq_user_favorites_user_food;
ALTER TABLE cleangoal.recipe_favorites DROP CONSTRAINT IF EXISTS uq_recipe_favorites_user_recipe;
DROP INDEX IF EXISTS cleangoal.recipes_food_id_uq;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v18_dishes_3nf_integrity')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- Rollback notes:
--   * New FK constraints can be dropped by name if needed.
--   * Archived rows are preserved in:
--       cleangoal.recipe_relation_orphan_archive
--       cleangoal.unit_conversion_orphan_archive
--   * Legacy foods.food_type / foods.food_category / foods.serving_unit remain.
--   * dish_id / serving_unit_id are additive and nullable.

-- v21: Drop duplicate legacy foods columns after v18/v20 3NF cleanup.
--
-- Retires:
--   * cleangoal.foods.food_category  (replaced by foods.dish_id -> dishes)
--   * cleangoal.foods.serving_unit   (replaced by foods.serving_unit_id -> units)
--
-- The migration backfills any remaining NULL FK values first, then raises if
-- coverage is still incomplete. This keeps the destructive DROP honest.

BEGIN;

-- -------------------------------------------------------------------------
-- 1. serving_unit -> serving_unit_id backfill
-- -------------------------------------------------------------------------

INSERT INTO cleangoal.units (name, quantity)
SELECT 'serving', 1
WHERE NOT EXISTS (
    SELECT 1 FROM cleangoal.units WHERE lower(name) = 'serving'
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name = 'foods'
          AND column_name = 'serving_unit'
    ) THEN
        EXECUTE $sql$
            UPDATE cleangoal.foods f
               SET serving_unit_id = u.unit_id
              FROM cleangoal.units u
             WHERE f.serving_unit_id IS NULL
               AND f.serving_unit IS NOT NULL
               AND lower(u.name) = lower(f.serving_unit)
        $sql$;
    END IF;
END$$;

UPDATE cleangoal.foods
   SET serving_unit_id = (
       SELECT unit_id FROM cleangoal.units WHERE lower(name) = 'serving' LIMIT 1
   )
 WHERE serving_unit_id IS NULL
   AND deleted_at IS NULL;

-- -------------------------------------------------------------------------
-- 2. food_category -> dish_id backfill
-- -------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name = 'foods'
          AND column_name = 'food_category'
    ) THEN
        EXECUTE $sql$
            INSERT INTO cleangoal.dish_categories (
                category_name,
                canonical_food_type,
                display_order
            )
            SELECT
                COALESCE(NULLIF(BTRIM(food_category), ''), food_type::text, 'uncategorized'),
                food_type,
                MIN(food_id)::int
            FROM cleangoal.foods
            WHERE deleted_at IS NULL
            GROUP BY COALESCE(NULLIF(BTRIM(food_category), ''), food_type::text, 'uncategorized'), food_type
            ON CONFLICT (category_name, canonical_food_type) DO NOTHING
        $sql$;

        EXECUTE $sql$
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
                END,
                f.image_url
            FROM cleangoal.foods f
            JOIN cleangoal.dish_categories dc
              ON dc.category_name = COALESCE(NULLIF(BTRIM(f.food_category), ''), f.food_type::text, 'uncategorized')
             AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type
            WHERE f.deleted_at IS NULL
            ON CONFLICT (dish_name, dish_category_id) DO NOTHING
        $sql$;

        EXECUTE $sql$
            UPDATE cleangoal.foods f
               SET dish_id = d.dish_id
              FROM cleangoal.dishes d
              JOIN cleangoal.dish_categories dc ON dc.dish_category_id = d.dish_category_id
             WHERE f.dish_id IS NULL
               AND f.food_name = d.dish_name
               AND dc.category_name = COALESCE(NULLIF(BTRIM(f.food_category), ''), f.food_type::text, 'uncategorized')
               AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type
        $sql$;
    ELSE
        INSERT INTO cleangoal.dish_categories (
            category_name,
            canonical_food_type,
            display_order
        )
        SELECT
            COALESCE(food_type::text, 'uncategorized'),
            food_type,
            MIN(food_id)::int
        FROM cleangoal.foods
        WHERE deleted_at IS NULL
        GROUP BY food_type
        ON CONFLICT (category_name, canonical_food_type) DO NOTHING;

        INSERT INTO cleangoal.dishes (
            dish_name,
            dish_category_id,
            canonical_food_type,
            image_url
        )
        SELECT
            f.food_name,
            dc.dish_category_id,
            f.food_type,
            f.image_url
        FROM cleangoal.foods f
        JOIN cleangoal.dish_categories dc
          ON dc.category_name = COALESCE(f.food_type::text, 'uncategorized')
         AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type
        WHERE f.deleted_at IS NULL
        ON CONFLICT (dish_name, dish_category_id) DO NOTHING;

        UPDATE cleangoal.foods f
           SET dish_id = d.dish_id
          FROM cleangoal.dishes d
          JOIN cleangoal.dish_categories dc ON dc.dish_category_id = d.dish_category_id
         WHERE f.dish_id IS NULL
           AND f.food_name = d.dish_name
           AND dc.category_name = COALESCE(f.food_type::text, 'uncategorized')
           AND dc.canonical_food_type IS NOT DISTINCT FROM f.food_type;
    END IF;
END$$;

-- -------------------------------------------------------------------------
-- 3. Guardrails before DROP
-- -------------------------------------------------------------------------

DO $$
DECLARE
    missing_dish_count BIGINT;
    missing_unit_count BIGINT;
BEGIN
    SELECT COUNT(*)
      INTO missing_dish_count
      FROM cleangoal.foods
     WHERE dish_id IS NULL
       AND deleted_at IS NULL;

    SELECT COUNT(*)
      INTO missing_unit_count
      FROM cleangoal.foods
     WHERE serving_unit_id IS NULL
       AND deleted_at IS NULL;

    IF missing_dish_count > 0 THEN
        RAISE EXCEPTION 'Cannot drop foods.food_category: % live foods still have NULL dish_id', missing_dish_count;
    END IF;

    IF missing_unit_count > 0 THEN
        RAISE EXCEPTION 'Cannot drop foods.serving_unit: % live foods still have NULL serving_unit_id', missing_unit_count;
    END IF;
END$$;

-- -------------------------------------------------------------------------
-- 4. Drop duplicate columns
-- -------------------------------------------------------------------------

ALTER TABLE cleangoal.foods
    DROP COLUMN IF EXISTS food_category,
    DROP COLUMN IF EXISTS serving_unit;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v21_drop_foods_legacy_columns')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- BEGIN;
-- ALTER TABLE cleangoal.foods ADD COLUMN IF NOT EXISTS food_category VARCHAR(100);
-- ALTER TABLE cleangoal.foods ADD COLUMN IF NOT EXISTS serving_unit VARCHAR(30);
-- UPDATE cleangoal.foods f
--    SET serving_unit = u.name
--   FROM cleangoal.units u
--  WHERE f.serving_unit_id = u.unit_id;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v21_drop_foods_legacy_columns';
-- COMMIT;

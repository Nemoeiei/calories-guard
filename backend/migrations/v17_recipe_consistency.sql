-- v17: Recipe review/favorite consistency.
--
-- Public mobile APIs still address a recipe by food_id because every food has
-- at most one recipe (`recipes.food_id` is unique). Internally, social recipe
-- data should key off recipes.recipe_id so review rows survive future food
-- catalogue edits and match the existing recipe_* table family.

BEGIN;

-- Ensure one recipe row maps to one food row.
ALTER TABLE cleangoal.recipes
    ALTER COLUMN food_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS recipes_food_id_uq
    ON cleangoal.recipes(food_id);

-- Normalize recipe_reviews to recipe_id. Some older deployments created
-- recipe_reviews(food_id, user_id, ...) at app startup; the canonical schema
-- uses recipe_reviews(recipe_id, user_id, ...). This block is idempotent and
-- preserves any old food_id column as read-only legacy metadata.
ALTER TABLE cleangoal.recipe_reviews
    ADD COLUMN IF NOT EXISTS recipe_id BIGINT;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name = 'recipe_reviews'
          AND column_name = 'food_id'
    ) THEN
        UPDATE cleangoal.recipe_reviews rr
           SET recipe_id = r.recipe_id
          FROM cleangoal.recipes r
         WHERE rr.recipe_id IS NULL
           AND rr.food_id = r.food_id;

        COMMENT ON COLUMN cleangoal.recipe_reviews.food_id IS
            'Legacy compatibility column. New code writes recipe_id.';
    END IF;
END$$;

-- Some seed/live data used recipe_reviews.recipe_id as if it were food_id.
-- If a review points to no recipe, but that numeric value matches a food_id
-- that already has a recipe row, remap it to the real recipe_id.
UPDATE cleangoal.recipe_reviews rr
   SET recipe_id = r.recipe_id
  FROM cleangoal.recipes r
 WHERE NOT EXISTS (
        SELECT 1
        FROM cleangoal.recipes existing
        WHERE existing.recipe_id = rr.recipe_id
    )
   AND r.food_id = rr.recipe_id;

-- Preserve any remaining orphaned reviews before deleting them so the FK can
-- be installed. These are not addressable by the current API because there is
-- no matching recipes row to resolve from a food_id.
CREATE TABLE IF NOT EXISTS cleangoal.recipe_reviews_orphan_archive (
    archive_id       BIGSERIAL PRIMARY KEY,
    review_id        BIGINT,
    legacy_recipe_id BIGINT,
    legacy_food_id   BIGINT,
    user_id          BIGINT,
    rating           SMALLINT,
    comment          TEXT,
    created_at       TIMESTAMPTZ,
    archived_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    archive_reason   TEXT NOT NULL
);

ALTER TABLE cleangoal.recipe_reviews_orphan_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "deny_anon" ON cleangoal.recipe_reviews_orphan_archive;
DROP POLICY IF EXISTS "deny_authenticated" ON cleangoal.recipe_reviews_orphan_archive;
CREATE POLICY "deny_anon" ON cleangoal.recipe_reviews_orphan_archive
  AS PERMISSIVE FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY "deny_authenticated" ON cleangoal.recipe_reviews_orphan_archive
  AS PERMISSIVE FOR ALL TO authenticated USING (false) WITH CHECK (false);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name = 'recipe_reviews'
          AND column_name = 'food_id'
    ) THEN
        INSERT INTO cleangoal.recipe_reviews_orphan_archive (
            review_id, legacy_recipe_id, legacy_food_id, user_id, rating,
            comment, created_at, archive_reason
        )
        SELECT rr.review_id, rr.recipe_id, rr.food_id, rr.user_id, rr.rating,
               rr.comment, rr.created_at,
               'No matching cleangoal.recipes row during v17_recipe_consistency'
          FROM cleangoal.recipe_reviews rr
          LEFT JOIN cleangoal.recipes r ON r.recipe_id = rr.recipe_id
         WHERE r.recipe_id IS NULL
           AND NOT EXISTS (
                SELECT 1
                FROM cleangoal.recipe_reviews_orphan_archive a
                WHERE a.review_id = rr.review_id
                  AND a.legacy_recipe_id = rr.recipe_id
           );
    ELSE
        INSERT INTO cleangoal.recipe_reviews_orphan_archive (
            review_id, legacy_recipe_id, legacy_food_id, user_id, rating,
            comment, created_at, archive_reason
        )
        SELECT rr.review_id, rr.recipe_id, NULL, rr.user_id, rr.rating,
               rr.comment, rr.created_at,
               'No matching cleangoal.recipes row during v17_recipe_consistency'
          FROM cleangoal.recipe_reviews rr
          LEFT JOIN cleangoal.recipes r ON r.recipe_id = rr.recipe_id
         WHERE r.recipe_id IS NULL
           AND NOT EXISTS (
                SELECT 1
                FROM cleangoal.recipe_reviews_orphan_archive a
                WHERE a.review_id = rr.review_id
                  AND a.legacy_recipe_id = rr.recipe_id
           );
    END IF;
END$$;

DELETE FROM cleangoal.recipe_reviews rr
 WHERE NOT EXISTS (
        SELECT 1
        FROM cleangoal.recipes r
        WHERE r.recipe_id = rr.recipe_id
    );

-- Archive reviews whose user no longer exists before installing the user FK.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name = 'recipe_reviews'
          AND column_name = 'food_id'
    ) THEN
        INSERT INTO cleangoal.recipe_reviews_orphan_archive (
            review_id, legacy_recipe_id, legacy_food_id, user_id, rating,
            comment, created_at, archive_reason
        )
        SELECT rr.review_id, rr.recipe_id, rr.food_id, rr.user_id, rr.rating,
               rr.comment, rr.created_at,
               'No matching cleangoal.users row during v17_recipe_consistency'
          FROM cleangoal.recipe_reviews rr
          LEFT JOIN cleangoal.users u ON u.user_id = rr.user_id
         WHERE u.user_id IS NULL
           AND NOT EXISTS (
                SELECT 1
                FROM cleangoal.recipe_reviews_orphan_archive a
                WHERE a.review_id = rr.review_id
                  AND a.legacy_recipe_id = rr.recipe_id
                  AND a.user_id = rr.user_id
           );
    ELSE
        INSERT INTO cleangoal.recipe_reviews_orphan_archive (
            review_id, legacy_recipe_id, legacy_food_id, user_id, rating,
            comment, created_at, archive_reason
        )
        SELECT rr.review_id, rr.recipe_id, NULL, rr.user_id, rr.rating,
               rr.comment, rr.created_at,
               'No matching cleangoal.users row during v17_recipe_consistency'
          FROM cleangoal.recipe_reviews rr
          LEFT JOIN cleangoal.users u ON u.user_id = rr.user_id
         WHERE u.user_id IS NULL
           AND NOT EXISTS (
                SELECT 1
                FROM cleangoal.recipe_reviews_orphan_archive a
                WHERE a.review_id = rr.review_id
                  AND a.legacy_recipe_id = rr.recipe_id
                  AND a.user_id = rr.user_id
           );
    END IF;
END$$;

DELETE FROM cleangoal.recipe_reviews rr
 WHERE NOT EXISTS (
        SELECT 1
        FROM cleangoal.users u
        WHERE u.user_id = rr.user_id
    );

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cleangoal.recipe_reviews WHERE recipe_id IS NULL) THEN
        RAISE EXCEPTION
            'recipe_reviews has rows with NULL recipe_id; create matching recipes rows before applying v17';
    END IF;
END$$;

ALTER TABLE cleangoal.recipe_reviews
    ALTER COLUMN recipe_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'recipe_reviews_recipe_id_fkey'
          AND conrelid = 'cleangoal.recipe_reviews'::regclass
    ) THEN
        ALTER TABLE cleangoal.recipe_reviews
            ADD CONSTRAINT recipe_reviews_recipe_id_fkey
            FOREIGN KEY (recipe_id)
            REFERENCES cleangoal.recipes(recipe_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'recipe_reviews_user_id_fkey'
          AND conrelid = 'cleangoal.recipe_reviews'::regclass
    ) THEN
        ALTER TABLE cleangoal.recipe_reviews
            ADD CONSTRAINT recipe_reviews_user_id_fkey
            FOREIGN KEY (user_id)
            REFERENCES cleangoal.users(user_id)
            ON DELETE CASCADE;
    END IF;
END$$;

DROP INDEX IF EXISTS cleangoal.recipe_reviews_food_user_uq;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'cleangoal.recipe_reviews'::regclass
          AND contype = 'u'
          AND conkey = ARRAY[
              (SELECT attnum FROM pg_attribute
               WHERE attrelid = 'cleangoal.recipe_reviews'::regclass
                 AND attname = 'recipe_id'),
              (SELECT attnum FROM pg_attribute
               WHERE attrelid = 'cleangoal.recipe_reviews'::regclass
                 AND attname = 'user_id')
          ]::smallint[]
    )
    AND NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'cleangoal'
          AND tablename = 'recipe_reviews'
          AND indexname = 'recipe_reviews_recipe_user_uq'
    ) THEN
        CREATE UNIQUE INDEX recipe_reviews_recipe_user_uq
            ON cleangoal.recipe_reviews(recipe_id, user_id);
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS recipe_reviews_recipe_created_idx
    ON cleangoal.recipe_reviews(recipe_id, created_at DESC);

-- Favorites: the active API stores food/menu favorites in user_favorites.
-- Keep recipe_favorites for compatibility with older seed/admin data, but make
-- its ownership explicit and documented so it does not drift silently.
COMMENT ON TABLE cleangoal.recipe_favorites IS
    'Legacy recipe-specific favorites. Active mobile API uses user_favorites(food_id).';

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v17_recipe_consistency')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- DROP INDEX IF EXISTS cleangoal.recipe_reviews_recipe_created_idx;
-- DROP INDEX IF EXISTS cleangoal.recipe_reviews_recipe_user_uq;
-- ALTER TABLE cleangoal.recipe_reviews DROP CONSTRAINT IF EXISTS recipe_reviews_recipe_id_fkey;
-- ALTER TABLE cleangoal.recipe_reviews ALTER COLUMN recipe_id DROP NOT NULL;
-- Restore archived rows manually from cleangoal.recipe_reviews_orphan_archive if needed.
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v17_recipe_consistency';

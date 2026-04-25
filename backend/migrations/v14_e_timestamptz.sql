-- v14 Phase E — Convert timestamp without time zone -> timestamptz
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- All stored values interpreted as Asia/Bangkok (UTC+7), stored as UTC.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.

BEGIN;

-- Drop dependencies before altering column types.
--   v_admin_temp_food_review: reads temp_food.created_at / updated_at / verified_at.
--   idx_meals_user_date*: functional indexes on DATE(meal_time) which become
--   non-IMMUTABLE once meal_time is timestamptz — Postgres rejects the ALTER.
DROP VIEW IF EXISTS cleangoal.v_admin_temp_food_review;
DROP INDEX IF EXISTS cleangoal.idx_meals_user_date_type;
DROP INDEX IF EXISTS cleangoal.idx_meals_user_date;

DO $$
DECLARE
    target record;
BEGIN
    FOR target IN
        SELECT *
        FROM (VALUES
            ('detail_items', 'created_at'),
            ('email_verification_codes', 'created_at'),
            ('email_verification_codes', 'expires_at'),
            ('exercise_logs', 'created_at'),
            ('food_requests', 'created_at'),
            ('foods', 'created_at'),
            ('foods', 'updated_at'),
            ('foods', 'deleted_at'),
            ('health_contents', 'created_at'),
            ('ingredients', 'created_at'),
            ('meals', 'created_at'),
            ('meals', 'updated_at'),
            ('meals', 'meal_time'),
            ('notifications', 'created_at'),
            ('password_reset_codes', 'created_at'),
            ('password_reset_codes', 'expires_at'),
            ('recipe_favorites', 'created_at'),
            ('recipe_ingredients', 'created_at'),
            ('recipe_reviews', 'created_at'),
            ('recipe_steps', 'created_at'),
            ('recipe_tips', 'created_at'),
            ('recipe_tools', 'created_at'),
            ('recipes', 'created_at'),
            ('recipes', 'deleted_at'),
            ('schema_migrations', 'applied_at'),
            ('temp_food', 'created_at'),
            ('temp_food', 'updated_at'),
            ('unit_conversions', 'created_at'),
            ('user_allergy_preferences', 'created_at'),
            ('user_favorites', 'created_at'),
            ('user_meal_plans', 'created_at'),
            ('users', 'created_at'),
            ('users', 'updated_at'),
            ('users', 'deleted_at'),
            ('users', 'last_login_date'),
            ('users', 'consent_accepted_at'),
            ('verified_food', 'created_at'),
            ('verified_food', 'updated_at'),
            ('verified_food', 'verified_at'),
            ('water_logs', 'updated_at'),
            ('weight_logs', 'created_at')
        ) AS t(table_name, column_name)
    LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'cleangoal'
              AND table_name = target.table_name
              AND column_name = target.column_name
              AND data_type = 'timestamp without time zone'
        ) THEN
            EXECUTE format(
                'ALTER TABLE cleangoal.%I ALTER COLUMN %I TYPE timestamptz USING %I AT TIME ZONE %L',
                target.table_name,
                target.column_name,
                target.column_name,
                'Asia/Bangkok'
            );
        END IF;
    END LOOP;
END$$;

-- Recreate functional indexes using an IMMUTABLE expression.
-- Casting to date with a literal time zone is IMMUTABLE (vs DATE(timestamptz)
-- which is STABLE because it depends on the session TimeZone setting).
CREATE INDEX idx_meals_user_date_type
    ON cleangoal.meals (user_id, ((meal_time AT TIME ZONE 'Asia/Bangkok')::date), meal_type);

CREATE INDEX idx_meals_user_date
    ON cleangoal.meals (user_id, ((meal_time AT TIME ZONE 'Asia/Bangkok')::date) DESC);

-- Recreate admin review view (identical to v14_b definition, just against tz columns)
CREATE VIEW cleangoal.v_admin_temp_food_review AS
 SELECT tf.tf_id,
        tf.food_name,
        tf.protein,
        tf.fat,
        tf.carbs,
        tf.calories,
        tf.user_id AS submitted_by,
        u.username AS submitted_by_username,
        tf.created_at AS submitted_at,
        tf.updated_at AS last_edited_at,
        vf.vf_id,
        vf.is_verify,
        vf.verified_by,
        vf.verified_at
   FROM cleangoal.temp_food tf
   LEFT JOIN cleangoal.verified_food vf ON vf.tf_id = tf.tf_id
   LEFT JOIN cleangoal.users u ON u.user_id = tf.user_id;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_e_timestamptz')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- For each ALTER above, revert with:
--   ALTER TABLE cleangoal.<t> ALTER COLUMN <c> TYPE timestamp
--     USING <c> AT TIME ZONE 'Asia/Bangkok';
-- Recreate the original indexes with DATE(meal_time). Recreate the view.
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_e_timestamptz';

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

ALTER TABLE cleangoal.detail_items
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.email_verification_codes
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN expires_at TYPE timestamptz USING expires_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.exercise_logs
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.food_requests
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.foods
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN deleted_at TYPE timestamptz USING deleted_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.health_contents
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.ingredients
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.meals
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN meal_time  TYPE timestamptz USING meal_time  AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.notifications
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.password_reset_codes
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN expires_at TYPE timestamptz USING expires_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_favorites
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_ingredients
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_reviews
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_steps
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_tips
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipe_tools
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.recipes
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN deleted_at TYPE timestamptz USING deleted_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.schema_migrations
    ALTER COLUMN applied_at TYPE timestamptz USING applied_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.temp_food
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.unit_conversions
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.user_allergy_preferences
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.user_favorites
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.user_meal_plans
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.users
    ALTER COLUMN created_at          TYPE timestamptz USING created_at          AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at          TYPE timestamptz USING updated_at          AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN deleted_at          TYPE timestamptz USING deleted_at          AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN last_login_date     TYPE timestamptz USING last_login_date     AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN consent_accepted_at TYPE timestamptz USING consent_accepted_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.verified_food
    ALTER COLUMN created_at  TYPE timestamptz USING created_at  AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN updated_at  TYPE timestamptz USING updated_at  AT TIME ZONE 'Asia/Bangkok',
    ALTER COLUMN verified_at TYPE timestamptz USING verified_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.water_logs
    ALTER COLUMN updated_at TYPE timestamptz USING updated_at AT TIME ZONE 'Asia/Bangkok';

ALTER TABLE cleangoal.weight_logs
    ALTER COLUMN created_at TYPE timestamptz USING created_at AT TIME ZONE 'Asia/Bangkok';

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

-- v14 Phase B — Integrity constraints (UNIQUE, CHECK, VARCHAR caps)
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.

BEGIN;

-- View v_admin_temp_food_review depends on users.username; drop and recreate
DROP VIEW IF EXISTS cleangoal.v_admin_temp_food_review;

-- B.1 UNIQUE constraints
ALTER TABLE cleangoal.roles ADD CONSTRAINT uq_roles_name UNIQUE (role_name);
ALTER TABLE cleangoal.users ADD CONSTRAINT uq_users_email UNIQUE (email);
ALTER TABLE cleangoal.beverages ADD CONSTRAINT uq_beverages_food UNIQUE (food_id);
ALTER TABLE cleangoal.snacks ADD CONSTRAINT uq_snacks_food UNIQUE (food_id);
ALTER TABLE cleangoal.user_favorites ADD CONSTRAINT uq_user_favorites_user_food UNIQUE (user_id, food_id);
ALTER TABLE cleangoal.recipe_favorites ADD CONSTRAINT uq_recipe_favorites_user_recipe UNIQUE (user_id, recipe_id);

-- B.2 Drop duplicate constraints
ALTER TABLE cleangoal.daily_summaries DROP CONSTRAINT IF EXISTS daily_summaries_user_id_date_record_key;
ALTER TABLE cleangoal.water_logs DROP CONSTRAINT IF EXISTS water_logs_user_date_key;
ALTER TABLE cleangoal.food_allergy_flags DROP CONSTRAINT IF EXISTS food_allergy_flags_flag_id_fkey;
ALTER TABLE cleangoal.food_allergy_flags DROP CONSTRAINT IF EXISTS food_allergy_flags_food_id_fkey;

-- B.3 VARCHAR length caps
ALTER TABLE cleangoal.users
    ALTER COLUMN email TYPE varchar(255),
    ALTER COLUMN username TYPE varchar(50),
    ALTER COLUMN password_hash TYPE varchar(255),
    ALTER COLUMN avatar_url TYPE varchar(500);
ALTER TABLE cleangoal.foods
    ALTER COLUMN food_name TYPE varchar(200),
    ALTER COLUMN serving_unit TYPE varchar(30),
    ALTER COLUMN image_url TYPE varchar(500);
ALTER TABLE cleangoal.temp_food ALTER COLUMN food_name TYPE varchar(200);
ALTER TABLE cleangoal.food_requests ALTER COLUMN food_name TYPE varchar(200);
ALTER TABLE cleangoal.roles ALTER COLUMN role_name TYPE varchar(30);
ALTER TABLE cleangoal.ingredients ALTER COLUMN name TYPE varchar(150), ALTER COLUMN category TYPE varchar(50);
ALTER TABLE cleangoal.units ALTER COLUMN name TYPE varchar(30);
ALTER TABLE cleangoal.notifications ALTER COLUMN title TYPE varchar(200);
ALTER TABLE cleangoal.detail_items
    ALTER COLUMN food_name TYPE varchar(200),
    ALTER COLUMN note TYPE varchar(500);

-- Recreate admin view
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

-- B.4 CHECK constraints
ALTER TABLE cleangoal.users
    ADD CONSTRAINT ck_users_height CHECK (height_cm IS NULL OR height_cm BETWEEN 80 AND 250),
    ADD CONSTRAINT ck_users_weight CHECK (current_weight_kg IS NULL OR current_weight_kg BETWEEN 20 AND 300),
    ADD CONSTRAINT ck_users_target_weight CHECK (target_weight_kg IS NULL OR target_weight_kg BETWEEN 20 AND 300),
    ADD CONSTRAINT ck_users_target_calories CHECK (target_calories IS NULL OR target_calories BETWEEN 500 AND 6000),
    ADD CONSTRAINT ck_users_streak CHECK (current_streak IS NULL OR current_streak >= 0),
    ADD CONSTRAINT ck_users_login_days CHECK (total_login_days IS NULL OR total_login_days >= 0);
ALTER TABLE cleangoal.weight_logs
    ADD CONSTRAINT ck_weight_logs_kg CHECK (weight_kg BETWEEN 20 AND 300);
ALTER TABLE cleangoal.water_logs
    ADD CONSTRAINT ck_water_logs_glasses CHECK (glasses >= 0 AND glasses <= 30);
ALTER TABLE cleangoal.exercise_logs
    ADD CONSTRAINT ck_exercise_duration CHECK (duration_minutes >= 0 AND duration_minutes <= 1440),
    ADD CONSTRAINT ck_exercise_calories CHECK (calories_burned IS NULL OR calories_burned >= 0);
ALTER TABLE cleangoal.foods
    ADD CONSTRAINT ck_foods_calories CHECK (calories IS NULL OR calories >= 0),
    ADD CONSTRAINT ck_foods_protein CHECK (protein IS NULL OR protein >= 0),
    ADD CONSTRAINT ck_foods_carbs CHECK (carbs IS NULL OR carbs >= 0),
    ADD CONSTRAINT ck_foods_fat CHECK (fat IS NULL OR fat >= 0),
    ADD CONSTRAINT ck_foods_serving CHECK (serving_quantity IS NULL OR serving_quantity > 0);
ALTER TABLE cleangoal.daily_summaries
    ADD CONSTRAINT ck_daily_totals CHECK (
        total_calories_intake >= 0 AND total_protein >= 0 AND total_carbs >= 0 AND total_fat >= 0
    ),
    ADD CONSTRAINT ck_daily_water CHECK (water_glasses >= 0);
ALTER TABLE cleangoal.recipe_reviews
    ADD CONSTRAINT ck_recipe_rating CHECK (rating IS NULL OR rating BETWEEN 1 AND 5);

-- B.5 Polymorphic CHECK on detail_items (exactly one of meal_id / plan_id / summary_id must be set)
ALTER TABLE cleangoal.detail_items
    ADD CONSTRAINT ck_detail_items_one_parent CHECK (
        (meal_id IS NOT NULL)::int + (plan_id IS NOT NULL)::int + (summary_id IS NOT NULL)::int = 1
    );

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_b_integrity')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- Drop every constraint added above by name (uq_*, ck_*). Restore varchar types with
-- ALTER COLUMN ... TYPE varchar. Recreate the view as-is.
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_b_integrity';

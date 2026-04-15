-- ============================================================
--  CalGuard: Combined Migrations Script
--  รันไฟล์นี้ใน pgAdmin หลังจากรัน databaseV4.sql แล้ว
--

-- ============================================================

SET search_path TO cleangoal, public;

-- ============================================================
--  STEP 1: database_fix_migration.sql  (2026-03-29)
-- ============================================================

-- 1a. foods
ALTER TABLE cleangoal.foods
    ADD COLUMN IF NOT EXISTS fiber_g        NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS food_category  VARCHAR;

-- 1b. food_requests macros
ALTER TABLE cleangoal.food_requests
    ADD COLUMN IF NOT EXISTS calories  NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS protein   NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS carbs     NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS fat       NUMERIC(6,2);

-- 1c. recipes
ALTER TABLE cleangoal.recipes
    ADD COLUMN IF NOT EXISTS recipe_name    VARCHAR,
    ADD COLUMN IF NOT EXISTS category       VARCHAR,
    ADD COLUMN IF NOT EXISTS cuisine        VARCHAR,
    ADD COLUMN IF NOT EXISTS difficulty     VARCHAR DEFAULT 'Easy',
    ADD COLUMN IF NOT EXISTS avg_rating     NUMERIC(3,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS review_count   INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS favorite_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_published   BOOLEAN DEFAULT true;

ALTER TABLE cleangoal.recipes
    ADD COLUMN IF NOT EXISTS total_time_minutes INTEGER
        GENERATED ALWAYS AS (prep_time_minutes + cooking_time_minutes) STORED;

-- 1d. detail_items macros
ALTER TABLE cleangoal.detail_items
    ADD COLUMN IF NOT EXISTS protein_per_unit NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS carbs_per_unit   NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fat_per_unit     NUMERIC(6,2) DEFAULT 0;

-- 1e. notifications deep-link columns
ALTER TABLE cleangoal.notifications
    ADD COLUMN IF NOT EXISTS related_id  BIGINT,
    ADD COLUMN IF NOT EXISTS action_url  VARCHAR;

-- 2a. food_requests FK fix
ALTER TABLE cleangoal.food_requests
    DROP CONSTRAINT IF EXISTS food_requests_reviewed_by_fkey;

ALTER TABLE cleangoal.food_requests
    ADD CONSTRAINT food_requests_reviewed_by_fkey
    FOREIGN KEY (reviewed_by)
    REFERENCES cleangoal.users(user_id)
    ON DELETE SET NULL;

-- 2b. clean invalid zero values ก่อนสร้าง CHECK constraints
UPDATE cleangoal.users SET target_calories    = NULL WHERE target_calories    <= 0;
UPDATE cleangoal.users SET height_cm          = NULL WHERE height_cm          <= 0;
UPDATE cleangoal.users SET current_weight_kg  = NULL WHERE current_weight_kg  <= 0;
UPDATE cleangoal.users SET target_weight_kg   = NULL WHERE target_weight_kg   <= 0;

-- 2b. users CHECK constraints
ALTER TABLE cleangoal.users DROP CONSTRAINT IF EXISTS users_target_calories_check;
ALTER TABLE cleangoal.users DROP CONSTRAINT IF EXISTS users_height_check;
ALTER TABLE cleangoal.users DROP CONSTRAINT IF EXISTS users_weight_check;
ALTER TABLE cleangoal.users DROP CONSTRAINT IF EXISTS users_target_weight_check;

ALTER TABLE cleangoal.users
    ADD CONSTRAINT users_target_calories_check
        CHECK (target_calories IS NULL OR target_calories > 0),
    ADD CONSTRAINT users_height_check
        CHECK (height_cm IS NULL OR height_cm > 0),
    ADD CONSTRAINT users_weight_check
        CHECK (current_weight_kg IS NULL OR current_weight_kg > 0),
    ADD CONSTRAINT users_target_weight_check
        CHECK (target_weight_kg IS NULL OR target_weight_kg > 0);

-- 3a. recipe_ingredients
CREATE TABLE IF NOT EXISTS cleangoal.recipe_ingredients (
    ing_id          BIGINT  NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id       BIGINT  NOT NULL,
    ingredient_name VARCHAR NOT NULL,
    quantity        NUMERIC(8,2),
    unit            VARCHAR,
    is_optional     BOOLEAN DEFAULT false,
    note            VARCHAR,
    sort_order      INTEGER DEFAULT 0,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_ingredients_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE
);

-- 3b. recipe_steps
CREATE TABLE IF NOT EXISTS cleangoal.recipe_steps (
    step_id       BIGINT  NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id     BIGINT  NOT NULL,
    step_number   INTEGER NOT NULL,
    title         VARCHAR,
    instruction   TEXT    NOT NULL,
    time_minutes  INTEGER DEFAULT 0,
    image_url     VARCHAR,
    tips          TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_steps_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE
);

-- 3c. recipe_tips
CREATE TABLE IF NOT EXISTS cleangoal.recipe_tips (
    tip_id      BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id   BIGINT NOT NULL,
    tip_text    TEXT   NOT NULL,
    sort_order  INTEGER DEFAULT 0,
    created_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_tips_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE
);

-- 3d. recipe_tools
CREATE TABLE IF NOT EXISTS cleangoal.recipe_tools (
    tool_id     BIGINT  NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id   BIGINT  NOT NULL,
    tool_name   VARCHAR NOT NULL,
    tool_emoji  VARCHAR,
    sort_order  INTEGER DEFAULT 0,
    created_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_tools_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE
);

-- 3e. recipe_reviews
CREATE TABLE IF NOT EXISTS cleangoal.recipe_reviews (
    review_id   BIGINT   NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id   BIGINT   NOT NULL,
    user_id     BIGINT   NOT NULL,
    rating      SMALLINT,
    comment     TEXT,
    created_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_reviews_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE,
    CONSTRAINT recipe_reviews_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    CONSTRAINT recipe_reviews_rating_check
        CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT recipe_reviews_recipe_id_user_id_key
        UNIQUE (recipe_id, user_id)
);

-- 3f. recipe_favorites
CREATE TABLE IF NOT EXISTS cleangoal.recipe_favorites (
    fav_id      BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id   BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    created_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT recipe_favorites_recipe_id_fkey
        FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE,
    CONSTRAINT recipe_favorites_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    CONSTRAINT recipe_favorites_recipe_id_user_id_key
        UNIQUE (recipe_id, user_id)
);

-- Triggers: auto-update recipe rating & favorite_count
CREATE OR REPLACE FUNCTION cleangoal.update_recipe_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cleangoal.recipes
    SET
        avg_rating   = (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM cleangoal.recipe_reviews WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)),
        review_count = (SELECT COUNT(*) FROM cleangoal.recipe_reviews WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id))
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION cleangoal.update_recipe_favorite_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cleangoal.recipes
    SET favorite_count = (
        SELECT COUNT(*) FROM cleangoal.recipe_favorites
        WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)
    )
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_recipe_rating ON cleangoal.recipe_reviews;
CREATE TRIGGER trg_update_recipe_rating
    AFTER INSERT OR UPDATE OR DELETE ON cleangoal.recipe_reviews
    FOR EACH ROW EXECUTE FUNCTION cleangoal.update_recipe_rating();

DROP TRIGGER IF EXISTS trg_update_recipe_favorite_count ON cleangoal.recipe_favorites;
CREATE TRIGGER trg_update_recipe_favorite_count
    AFTER INSERT OR DELETE ON cleangoal.recipe_favorites
    FOR EACH ROW EXECUTE FUNCTION cleangoal.update_recipe_favorite_count();

-- 5a. food_allergy_flags
CREATE TABLE IF NOT EXISTS cleangoal.food_allergy_flags (
    food_id  BIGINT  NOT NULL,
    flag_id  INTEGER NOT NULL,
    PRIMARY KEY (food_id, flag_id),
    CONSTRAINT faf_food_id_fkey
        FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE,
    CONSTRAINT faf_flag_id_fkey
        FOREIGN KEY (flag_id) REFERENCES cleangoal.allergy_flags(flag_id) ON DELETE CASCADE
);

-- 5b. water_logs
CREATE TABLE IF NOT EXISTS cleangoal.water_logs (
    log_id       BIGINT  NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      BIGINT  NOT NULL,
    glasses      INTEGER NOT NULL DEFAULT 1,
    date_record  DATE    NOT NULL DEFAULT CURRENT_DATE,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT water_logs_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    CONSTRAINT water_logs_user_date_key
        UNIQUE (user_id, date_record),
    CONSTRAINT water_logs_glasses_check
        CHECK (glasses >= 0 AND glasses <= 30)
);

-- 5c. chat_messages
CREATE TABLE IF NOT EXISTS cleangoal.chat_messages (
    message_id  BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    role        VARCHAR(10) NOT NULL,
    content     TEXT   NOT NULL,
    created_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT chat_messages_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    CONSTRAINT chat_messages_role_check
        CHECK (role IN ('user', 'assistant'))
);

-- 5d. user_health_content_views
CREATE TABLE IF NOT EXISTS cleangoal.user_health_content_views (
    user_id       BIGINT  NOT NULL,
    content_id    BIGINT  NOT NULL,
    viewed_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    is_bookmarked BOOLEAN DEFAULT false,
    PRIMARY KEY (user_id, content_id),
    CONSTRAINT uhcv_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    CONSTRAINT uhcv_content_id_fkey
        FOREIGN KEY (content_id) REFERENCES cleangoal.health_contents(content_id) ON DELETE CASCADE
);

-- Indexes (fix_migration)
CREATE INDEX IF NOT EXISTS idx_meals_user_meal_time        ON cleangoal.meals(user_id, meal_time);
CREATE INDEX IF NOT EXISTS idx_detail_items_meal_id        ON cleangoal.detail_items(meal_id);
CREATE INDEX IF NOT EXISTS idx_detail_items_food_id        ON cleangoal.detail_items(food_id);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date   ON cleangoal.daily_summaries(user_id, date_record);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date       ON cleangoal.weight_logs(user_id, recorded_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread   ON cleangoal.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_foods_name                  ON cleangoal.foods(food_name);
CREATE INDEX IF NOT EXISTS idx_foods_category              ON cleangoal.foods(food_category);
CREATE INDEX IF NOT EXISTS idx_foods_active                ON cleangoal.foods(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_created  ON cleangoal.chat_messages(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_date_fix    ON cleangoal.water_logs(user_id, date_record);
CREATE INDEX IF NOT EXISTS idx_food_allergy_flags_flag     ON cleangoal.food_allergy_flags(flag_id);
CREATE INDEX IF NOT EXISTS idx_recipe_reviews_recipe       ON cleangoal.recipe_reviews(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_favorites_user       ON cleangoal.recipe_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe         ON cleangoal.recipe_steps(recipe_id, step_number);


-- ============================================================
--  STEP 2: update_database_v5.sql
--  (search_path ถูก set ไว้ด้านบนแล้ว)
-- ============================================================

ALTER TABLE weight_logs
ADD COLUMN IF NOT EXISTS body_fat_percent DECIMAL(4,2),
ADD COLUMN IF NOT EXISTS waist_cm DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS hip_cm DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS photo_front_url VARCHAR,
ADD COLUMN IF NOT EXISTS photo_side_url VARCHAR,
ADD COLUMN IF NOT EXISTS note TEXT;

ALTER TABLE food_requests
ADD COLUMN IF NOT EXISTS image_url VARCHAR,
ADD COLUMN IF NOT EXISTS cooking_instructions TEXT,
ADD COLUMN IF NOT EXISTS admin_comment TEXT;

ALTER TABLE notifications
ADD COLUMN IF NOT EXISTS target_role VARCHAR,
ADD COLUMN IF NOT EXISTS image_url VARCHAR;

ALTER TABLE weekly_summaries
ADD COLUMN IF NOT EXISTS week_number INT,
ADD COLUMN IF NOT EXISTS year INT,
ADD COLUMN IF NOT EXISTS total_calories_burned INT,
ADD COLUMN IF NOT EXISTS avg_weight DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS goal_met_count INT;

ALTER TABLE progress
ADD COLUMN IF NOT EXISTS login_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS last_login_date DATE,
ADD COLUMN IF NOT EXISTS monthly_target VARCHAR;

CREATE TABLE IF NOT EXISTS dishes (
  dishes_id BIGSERIAL PRIMARY KEY,
  food_id BIGINT REFERENCES foods(food_id) ON DELETE CASCADE,
  name VARCHAR NOT NULL UNIQUE,
  category VARCHAR,
  calories_per_unit DECIMAL(6,2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS food_sources (
  source_id BIGSERIAL PRIMARY KEY,
  food_id BIGINT REFERENCES foods(food_id) ON DELETE SET NULL,
  source_name VARCHAR,
  source_url VARCHAR,
  raw_calories DECIMAL(6,2),
  recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_active_plans (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  plan_id BIGINT REFERENCES user_meal_plans(plan_id) ON DELETE CASCADE,
  start_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR DEFAULT 'ACTIVE'
);

CREATE TABLE IF NOT EXISTS user_reports (
  report_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  report_type VARCHAR,
  start_date DATE,
  end_date DATE,
  avg_daily_calories INT,
  total_weight_change DECIMAL(5,2),
  compliance_score INT,
  insight_text TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS daily_recommendations (
  recommendation_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  item_id BIGINT REFERENCES detail_items(item_id) ON DELETE CASCADE,
  date_for DATE,
  meal_type VARCHAR(50),
  food_id BIGINT REFERENCES foods(food_id) ON DELETE CASCADE,
  reason_text VARCHAR,
  is_accepted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS achievements (
  achievement_id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  description VARCHAR,
  icon_url VARCHAR,
  criteria_type VARCHAR,
  criteria_value INT
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  achievement_id INT REFERENCES achievements(achievement_id) ON DELETE CASCADE,
  earned_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_reads (
  read_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  notification_id BIGINT REFERENCES notifications(notification_id) ON DELETE CASCADE,
  read_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, notification_id)
);

CREATE TABLE IF NOT EXISTS user_saved_contents (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  content_id BIGINT REFERENCES health_contents(content_id) ON DELETE CASCADE,
  saved_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, content_id)
);

CREATE TABLE IF NOT EXISTS content_view_logs (
  log_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
  content_id BIGINT REFERENCES health_contents(content_id) ON DELETE SET NULL,
  viewed_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  log_id BIGSERIAL PRIMARY KEY,
  admin_id BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
  action_type VARCHAR,
  target_id BIGINT,
  target_table VARCHAR,
  details JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS monthly_summaries (
  monthly_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
  month INT NOT NULL,
  year INT NOT NULL,
  avg_daily_calories INT,
  start_weight DECIMAL(5,2),
  end_weight DECIMAL(5,2),
  weight_change DECIMAL(5,2),
  compliance_score INT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, month, year)
);

CREATE TABLE IF NOT EXISTS recommendation_plan (
  rec_com BIGSERIAL PRIMARY KEY,
  plan_id BIGINT REFERENCES user_active_plans(id) ON DELETE CASCADE
);


-- ============================================================
--  STEP 3: update_database_v6_notifications.sql
--  (notifications มีอยู่แล้วใน dump — IF NOT EXISTS = safe)
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- ============================================================
--  STEP 4: update_database_v7_er_additions.sql
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'cleangoal'
          AND table_name   = 'users'
          AND column_name  = 'target_water_ml'
    ) THEN
        ALTER TABLE users ADD COLUMN target_water_ml INT DEFAULT 2000 CHECK (target_water_ml >= 0);
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS user_settings (
    user_id INT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'th',
    theme_mode VARCHAR(20) DEFAULT 'light',
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    ai_recommendations_enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exercise_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    exercise_type VARCHAR(100) NOT NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    calories_burned INT NOT NULL DEFAULT 0,
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS food_search_history (
    search_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    search_keyword VARCHAR(255) NOT NULL,
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_history_user_time ON food_search_history(user_id, searched_at DESC);


-- ============================================================
--  STEP 5: migrations/v8_add_macros_water_to_daily_summaries.sql
-- ============================================================

ALTER TABLE cleangoal.daily_summaries
  ADD COLUMN IF NOT EXISTS total_protein   NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_carbs     NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_fat       NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_glasses   INTEGER DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'uq_daily_summaries_user_date'
      AND conrelid = 'cleangoal.daily_summaries'::regclass
  ) THEN
    ALTER TABLE cleangoal.daily_summaries
      ADD CONSTRAINT uq_daily_summaries_user_date UNIQUE (user_id, date_record);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION cleangoal.fn_sync_daily_summary()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id   BIGINT;
  v_date_rec  DATE;
  v_meal_id   BIGINT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_meal_id := OLD.meal_id;
  ELSE
    v_meal_id := NEW.meal_id;
  END IF;

  IF v_meal_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT user_id, DATE(meal_time)
    INTO v_user_id, v_date_rec
  FROM cleangoal.meals
  WHERE meal_id = v_meal_id;

  IF v_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO cleangoal.daily_summaries
    (user_id, date_record, total_calories_intake, total_protein, total_carbs, total_fat, is_goal_met)
  SELECT
    v_user_id,
    v_date_rec,
    COALESCE(SUM(di.amount * di.cal_per_unit), 0),
    COALESCE(SUM(di.amount * COALESCE(di.protein_per_unit, 0)), 0),
    COALESCE(SUM(di.amount * COALESCE(di.carbs_per_unit,   0)), 0),
    COALESCE(SUM(di.amount * COALESCE(di.fat_per_unit,     0)), 0),
    FALSE
  FROM cleangoal.detail_items di
  JOIN cleangoal.meals m ON m.meal_id = di.meal_id
  WHERE m.user_id = v_user_id
    AND DATE(m.meal_time) = v_date_rec
  ON CONFLICT (user_id, date_record) DO UPDATE SET
    total_calories_intake = EXCLUDED.total_calories_intake,
    total_protein         = EXCLUDED.total_protein,
    total_carbs           = EXCLUDED.total_carbs,
    total_fat             = EXCLUDED.total_fat,
    is_goal_met           = (
      EXCLUDED.total_calories_intake <= COALESCE(
        (SELECT target_calories FROM cleangoal.users WHERE user_id = v_user_id),
        9999
      )
    );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_daily_summary ON cleangoal.detail_items;
CREATE TRIGGER trg_sync_daily_summary
  AFTER INSERT OR UPDATE OR DELETE
  ON cleangoal.detail_items
  FOR EACH ROW
  EXECUTE FUNCTION cleangoal.fn_sync_daily_summary();

UPDATE cleangoal.daily_summaries ds
SET
  total_protein = sub.p,
  total_carbs   = sub.c,
  total_fat     = sub.f
FROM (
  SELECT
    m.user_id,
    DATE(m.meal_time) AS date_rec,
    COALESCE(SUM(di.amount * COALESCE(di.protein_per_unit, 0)), 0) AS p,
    COALESCE(SUM(di.amount * COALESCE(di.carbs_per_unit,   0)), 0) AS c,
    COALESCE(SUM(di.amount * COALESCE(di.fat_per_unit,     0)), 0) AS f
  FROM cleangoal.detail_items di
  JOIN cleangoal.meals m ON m.meal_id = di.meal_id
  GROUP BY m.user_id, DATE(m.meal_time)
) sub
WHERE ds.user_id    = sub.user_id
  AND ds.date_record = sub.date_rec;


-- ============================================================
--  STEP 6: migrations/v9_create_water_logs.sql
--  (water_logs ถูกสร้างในขั้นตอน 1 แล้ว — IF NOT EXISTS = safe)
-- ============================================================

CREATE TABLE IF NOT EXISTS cleangoal.water_logs (
  log_id       BIGSERIAL PRIMARY KEY,
  user_id      BIGINT      NOT NULL REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
  date_record  DATE        NOT NULL DEFAULT CURRENT_DATE,
  glasses      INTEGER     NOT NULL DEFAULT 0 CHECK (glasses >= 0 AND glasses <= 30),
  updated_at   TIMESTAMP   DEFAULT NOW(),
  CONSTRAINT uq_water_logs_user_date UNIQUE (user_id, date_record)
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_date
  ON cleangoal.water_logs(user_id, date_record DESC);


-- ============================================================
--  STEP 7: migrations/v10_create_exercise_logs.sql
--  (exercise_logs ถูกสร้างในขั้นตอน 4 แล้ว — IF NOT EXISTS = safe)
-- ============================================================

CREATE TABLE IF NOT EXISTS cleangoal.exercise_logs (
  log_id            BIGSERIAL   PRIMARY KEY,
  user_id           BIGINT      NOT NULL REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
  date_record       DATE        NOT NULL DEFAULT CURRENT_DATE,
  activity_name     VARCHAR(100) NOT NULL,
  duration_minutes  INT         NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
  calories_burned   DECIMAL(8,2) DEFAULT 0 CHECK (calories_burned >= 0),
  intensity         VARCHAR(20)  DEFAULT 'moderate'
                    CHECK (intensity IN ('low','moderate','high')),
  note              VARCHAR(255),
  created_at        TIMESTAMP   DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercise_logs_user_date
  ON cleangoal.exercise_logs(user_id, date_record DESC);


-- ============================================================
--  STEP 8: migrations/v11_add_performance_indexes.sql
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_meals_user_date
  ON cleangoal.meals(user_id, DATE(meal_time) DESC);

CREATE INDEX IF NOT EXISTS idx_detail_items_meal_id_v11
  ON cleangoal.detail_items(meal_id);

CREATE INDEX IF NOT EXISTS idx_detail_items_food_id_v11
  ON cleangoal.detail_items(food_id)
  WHERE food_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date_v11
  ON cleangoal.daily_summaries(user_id, date_record DESC);

CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date_v11
  ON cleangoal.weight_logs(user_id, recorded_date DESC);

CREATE INDEX IF NOT EXISTS idx_foods_name_lower
  ON cleangoal.foods(LOWER(food_name));

CREATE INDEX IF NOT EXISTS idx_foods_not_deleted
  ON cleangoal.foods(food_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_users_email
  ON cleangoal.users(email)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_allergy_prefs_user
  ON cleangoal.user_allergy_preferences(user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread_v11
  ON cleangoal.notifications(user_id, is_read)
  WHERE is_read = FALSE;


-- ============================================================
--  STEP 9: migrations/v12_add_consent_and_detail_macros.sql
-- ============================================================

ALTER TABLE cleangoal.users
  ADD COLUMN IF NOT EXISTS consent_accepted_at TIMESTAMP;

ALTER TABLE cleangoal.detail_items
  ADD COLUMN IF NOT EXISTS protein_per_unit DECIMAL(8,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS carbs_per_unit   DECIMAL(8,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fat_per_unit     DECIMAL(8,2) DEFAULT 0;

UPDATE cleangoal.detail_items di
SET
  protein_per_unit = COALESCE(f.protein, 0),
  carbs_per_unit   = COALESCE(f.carbs,   0),
  fat_per_unit     = COALESCE(f.fat,     0)
FROM cleangoal.foods f
WHERE di.food_id = f.food_id
  AND (di.protein_per_unit = 0 OR di.protein_per_unit IS NULL);


-- ============================================================
--  STEP 10: migrations/v13_create_temp_and_verified_food.sql
--  (search_path ถูก set ไว้ด้านบน → temp_food = cleangoal.temp_food)
-- ============================================================

CREATE TABLE IF NOT EXISTS temp_food (
    tf_id        BIGSERIAL PRIMARY KEY,
    food_name    VARCHAR NOT NULL,
    protein      DECIMAL(6,2) DEFAULT 0,
    fat          DECIMAL(6,2) DEFAULT 0,
    carbs        DECIMAL(6,2) DEFAULT 0,
    calories     DECIMAL(6,2) DEFAULT 0,
    user_id      BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_temp_food_user_id   ON temp_food (user_id);
CREATE INDEX IF NOT EXISTS idx_temp_food_created_at ON temp_food (created_at DESC);

CREATE TABLE IF NOT EXISTS verified_food (
    vf_id        BIGSERIAL PRIMARY KEY,
    tf_id        BIGINT NOT NULL UNIQUE
                  REFERENCES temp_food(tf_id) ON DELETE CASCADE,
    is_verify    BOOLEAN NOT NULL DEFAULT FALSE,
    verified_by  BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    verified_at  TIMESTAMP,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_verified_food_tf_id     ON verified_food (tf_id);
CREATE INDEX IF NOT EXISTS idx_verified_food_is_verify ON verified_food (is_verify);

CREATE OR REPLACE FUNCTION fn_create_verified_food_on_temp_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO verified_food (tf_id, is_verify, created_at)
    VALUES (NEW.tf_id, FALSE, NOW())
    ON CONFLICT (tf_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_create_verified_food ON temp_food;
CREATE TRIGGER trg_create_verified_food
    AFTER INSERT ON temp_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_create_verified_food_on_temp_insert();

CREATE OR REPLACE FUNCTION fn_temp_food_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_temp_food_touch_updated_at ON temp_food;
CREATE TRIGGER trg_temp_food_touch_updated_at
    BEFORE UPDATE ON temp_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_temp_food_touch_updated_at();

CREATE OR REPLACE FUNCTION fn_verified_food_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    IF NEW.is_verify = TRUE AND (OLD.is_verify IS DISTINCT FROM TRUE) THEN
        NEW.verified_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verified_food_touch_updated_at ON verified_food;
CREATE TRIGGER trg_verified_food_touch_updated_at
    BEFORE UPDATE ON verified_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_verified_food_touch_updated_at();

CREATE OR REPLACE VIEW v_admin_temp_food_review AS
SELECT
    tf.tf_id,
    tf.food_name,
    tf.protein,
    tf.fat,
    tf.carbs,
    tf.calories,
    tf.user_id         AS submitted_by,
    u.username         AS submitted_by_username,
    tf.created_at      AS submitted_at,
    tf.updated_at      AS last_edited_at,
    vf.vf_id,
    vf.is_verify,
    vf.verified_by,
    vf.verified_at
FROM temp_food tf
LEFT JOIN verified_food vf ON vf.tf_id  = tf.tf_id
LEFT JOIN users         u  ON u.user_id = tf.user_id;

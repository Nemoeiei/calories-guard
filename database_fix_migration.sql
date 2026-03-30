-- ============================================================
--  CalGuard Database Fix Migration (v2 — corrected for live DB)
--  Date: 2026-03-29
-- ============================================================

BEGIN;

-- ============================================================
--  SECTION 1: ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================================

-- 1a. foods — add fiber_g and food_category (in dump, missing in live)
ALTER TABLE cleangoal.foods
    ADD COLUMN IF NOT EXISTS fiber_g        NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS food_category  VARCHAR;

-- 1b. food_requests — add macro columns (from direct-addfood merge)
ALTER TABLE cleangoal.food_requests
    ADD COLUMN IF NOT EXISTS calories  NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS protein   NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS carbs     NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS fat       NUMERIC(6,2);

-- 1c. recipes — add missing columns (recipe_name, ratings, etc.)
ALTER TABLE cleangoal.recipes
    ADD COLUMN IF NOT EXISTS recipe_name    VARCHAR,
    ADD COLUMN IF NOT EXISTS category       VARCHAR,
    ADD COLUMN IF NOT EXISTS cuisine        VARCHAR,
    ADD COLUMN IF NOT EXISTS difficulty     VARCHAR DEFAULT 'Easy',
    ADD COLUMN IF NOT EXISTS avg_rating     NUMERIC(3,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS review_count   INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS favorite_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_published   BOOLEAN DEFAULT true;

-- total_time_minutes is a generated column — add separately
ALTER TABLE cleangoal.recipes
    ADD COLUMN IF NOT EXISTS total_time_minutes INTEGER
        GENERATED ALWAYS AS (prep_time_minutes + cooking_time_minutes) STORED;

-- 1d. detail_items — add macro columns per food item logged
--     Stores macros at log-time so history stays accurate even if food data changes later
ALTER TABLE cleangoal.detail_items
    ADD COLUMN IF NOT EXISTS protein_per_unit NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS carbs_per_unit   NUMERIC(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fat_per_unit     NUMERIC(6,2) DEFAULT 0;

-- 1e. notifications — add deep-link columns
ALTER TABLE cleangoal.notifications
    ADD COLUMN IF NOT EXISTS related_id  BIGINT,
    ADD COLUMN IF NOT EXISTS action_url  VARCHAR;

-- ============================================================
--  SECTION 2: FIX EXISTING CONSTRAINTS
-- ============================================================

-- 2a. food_requests.reviewed_by — add ON DELETE SET NULL
ALTER TABLE cleangoal.food_requests
    DROP CONSTRAINT IF EXISTS food_requests_reviewed_by_fkey;

ALTER TABLE cleangoal.food_requests
    ADD CONSTRAINT food_requests_reviewed_by_fkey
    FOREIGN KEY (reviewed_by)
    REFERENCES cleangoal.users(user_id)
    ON DELETE SET NULL;

-- 2b. users — CHECK constraints to prevent invalid data
ALTER TABLE cleangoal.users
    ADD CONSTRAINT users_target_calories_check
        CHECK (target_calories IS NULL OR target_calories > 0),
    ADD CONSTRAINT users_height_check
        CHECK (height_cm IS NULL OR height_cm > 0),
    ADD CONSTRAINT users_weight_check
        CHECK (current_weight_kg IS NULL OR current_weight_kg > 0),
    ADD CONSTRAINT users_target_weight_check
        CHECK (target_weight_kg IS NULL OR target_weight_kg > 0);

-- ============================================================
--  SECTION 3: CREATE MISSING RECIPE TABLES
-- ============================================================

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

-- ============================================================
--  SECTION 4: ADD TRIGGERS FOR RECIPES (auto-update rating & favorites)
-- ============================================================

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

-- ============================================================
--  SECTION 5: ADD NEW TABLES
-- ============================================================

-- 5a. food_allergy_flags — links foods to allergens
CREATE TABLE IF NOT EXISTS cleangoal.food_allergy_flags (
    food_id  BIGINT  NOT NULL,
    flag_id  INTEGER NOT NULL,
    PRIMARY KEY (food_id, flag_id),
    CONSTRAINT faf_food_id_fkey
        FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE,
    CONSTRAINT faf_flag_id_fkey
        FOREIGN KEY (flag_id) REFERENCES cleangoal.allergy_flags(flag_id) ON DELETE CASCADE
);
COMMENT ON TABLE cleangoal.food_allergy_flags IS
    'Maps which allergens are present in each food. Used to filter foods based on user allergy preferences.';

-- 5b. water_logs — persists daily water intake
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
COMMENT ON TABLE cleangoal.water_logs IS
    'Tracks daily water intake (glasses) per user. Goal is 8 glasses/day.';

-- 5c. chat_messages — persists AI chatbot history
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
COMMENT ON TABLE cleangoal.chat_messages IS
    'Persists AI chatbot coach conversation history per user.';

-- 5d. user_health_content_views — tracks read/bookmarked articles
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
COMMENT ON TABLE cleangoal.user_health_content_views IS
    'Tracks which health content each user has viewed or bookmarked.';

-- ============================================================
--  SECTION 6: INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_meals_user_meal_time
    ON cleangoal.meals(user_id, meal_time);

CREATE INDEX IF NOT EXISTS idx_detail_items_meal_id
    ON cleangoal.detail_items(meal_id);

CREATE INDEX IF NOT EXISTS idx_detail_items_food_id
    ON cleangoal.detail_items(food_id);

CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date
    ON cleangoal.daily_summaries(user_id, date_record);

CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date
    ON cleangoal.weight_logs(user_id, recorded_date);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON cleangoal.notifications(user_id, is_read);

CREATE INDEX IF NOT EXISTS idx_foods_name
    ON cleangoal.foods(food_name);

CREATE INDEX IF NOT EXISTS idx_foods_category
    ON cleangoal.foods(food_category);

CREATE INDEX IF NOT EXISTS idx_foods_active
    ON cleangoal.foods(deleted_at)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_messages_user_created
    ON cleangoal.chat_messages(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_date
    ON cleangoal.water_logs(user_id, date_record);

CREATE INDEX IF NOT EXISTS idx_food_allergy_flags_flag
    ON cleangoal.food_allergy_flags(flag_id);

CREATE INDEX IF NOT EXISTS idx_recipe_reviews_recipe
    ON cleangoal.recipe_reviews(recipe_id);

CREATE INDEX IF NOT EXISTS idx_recipe_favorites_user
    ON cleangoal.recipe_favorites(user_id);

CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe
    ON cleangoal.recipe_steps(recipe_id, step_number);

COMMIT;

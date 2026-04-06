-- Update Database v7: ER Diagram Completeness Additions
-- This script adds tables and columns discovered during the ER diagram completeness scan
-- to ensure the database truly tracks all aspects of the application's functionality.

-- 1. Add target_water_ml to users
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


-- 2. User Settings Table
-- Replaces SharedPreferences for cross-device persistence
CREATE TABLE IF NOT EXISTS user_settings (
    user_id INT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'th',
    theme_mode VARCHAR(20) DEFAULT 'light',
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    ai_recommendations_enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 3. Exercise Logs / Burned Calories
-- Tracks daily active burned calories to offset total intake correctly
CREATE TABLE IF NOT EXISTS exercise_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    exercise_type VARCHAR(100) NOT NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    calories_burned INT NOT NULL DEFAULT 0,
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 4. Food Search History
-- Tracks what the user searches. Useful for "Recent Searches" UI and AI food recommendations
CREATE TABLE IF NOT EXISTS food_search_history (
    search_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    search_keyword VARCHAR(255) NOT NULL,
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_history_user_time ON food_search_history(user_id, searched_at DESC);

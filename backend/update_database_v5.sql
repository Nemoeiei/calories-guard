-- Update Script to bring the database to the latest ERD version

-- 1. ALTER existing tables
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


-- 2. CREATE missing tables
CREATE TABLE IF NOT EXISTS dishes (
  dishes_id BIGSERIAL PRIMARY KEY,
  food_id BIGINT REFERENCES foods(food_id) ON DELETE CASCADE,
  name VARCHAR NOT NULL UNIQUE,
  category VARCHAR,
  calories_per_unit DECIMAL(6,2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS food_allergy_flags (
  food_id BIGINT REFERENCES foods(food_id) ON DELETE CASCADE,
  flag_id INT REFERENCES allergy_flags(flag_id) ON DELETE CASCADE,
  PRIMARY KEY (food_id, flag_id)
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
  meal_type VARCHAR(50),  -- Can cast to meal_type enum later if needed
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

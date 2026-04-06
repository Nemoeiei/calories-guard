-- ============================================================
-- Migration v11: เพิ่ม Performance Indexes ที่สำคัญ
-- ============================================================

-- meals: query บ่อยมากด้วย user_id + date
CREATE INDEX IF NOT EXISTS idx_meals_user_date
  ON cleangoal.meals(user_id, DATE(meal_time) DESC);

-- detail_items: JOIN target หลัก
CREATE INDEX IF NOT EXISTS idx_detail_items_meal_id
  ON cleangoal.detail_items(meal_id);

CREATE INDEX IF NOT EXISTS idx_detail_items_food_id
  ON cleangoal.detail_items(food_id)
  WHERE food_id IS NOT NULL;

-- daily_summaries: query รายวัน/รายสัปดาห์
CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date
  ON cleangoal.daily_summaries(user_id, date_record DESC);

-- weight_logs: ดู trend น้ำหนัก
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date
  ON cleangoal.weight_logs(user_id, recorded_date DESC);

-- foods: ค้นหาชื่ออาหาร (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_foods_name_lower
  ON cleangoal.foods(LOWER(food_name));

CREATE INDEX IF NOT EXISTS idx_foods_not_deleted
  ON cleangoal.foods(food_id)
  WHERE deleted_at IS NULL;

-- users: soft delete + email lookup
CREATE INDEX IF NOT EXISTS idx_users_email
  ON cleangoal.users(email)
  WHERE deleted_at IS NULL;

-- user_allergy_preferences: ตรวจสอบ allergy
CREATE INDEX IF NOT EXISTS idx_allergy_prefs_user
  ON cleangoal.user_allergy_preferences(user_id);

-- notifications: ดึง unread ของ user
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON cleangoal.notifications(user_id, is_read)
  WHERE is_read = FALSE;

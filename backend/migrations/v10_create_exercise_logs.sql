-- ============================================================
-- Migration v10: สร้างตาราง exercise_logs สำหรับบันทึกการออกกำลังกายรายวัน
-- (แตกต่างจาก user_activities ที่เก็บแค่ระดับ activity)
-- ============================================================

CREATE TABLE IF NOT EXISTS cleangoal.exercise_logs (
  log_id            BIGSERIAL   PRIMARY KEY,
  user_id           BIGINT      NOT NULL REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
  date_record       DATE        NOT NULL DEFAULT CURRENT_DATE,
  activity_name     VARCHAR(100) NOT NULL,           -- ชื่อกิจกรรม เช่น วิ่ง, ว่ายน้ำ, ยกน้ำหนัก
  duration_minutes  INT         NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
  calories_burned   DECIMAL(8,2) DEFAULT 0 CHECK (calories_burned >= 0),
  intensity         VARCHAR(20)  DEFAULT 'moderate'  -- low / moderate / high
                    CHECK (intensity IN ('low','moderate','high')),
  note              VARCHAR(255),
  created_at        TIMESTAMP   DEFAULT NOW()
);

COMMENT ON TABLE  cleangoal.exercise_logs                   IS 'บันทึกการออกกำลังกายรายวันของผู้ใช้';
COMMENT ON COLUMN cleangoal.exercise_logs.activity_name     IS 'ชื่อกิจกรรม เช่น วิ่ง ว่ายน้ำ ยกน้ำหนัก';
COMMENT ON COLUMN cleangoal.exercise_logs.duration_minutes  IS 'ระยะเวลา (นาที)';
COMMENT ON COLUMN cleangoal.exercise_logs.calories_burned   IS 'แคลอรี่ที่เผาผลาญ';
COMMENT ON COLUMN cleangoal.exercise_logs.intensity         IS 'ความหนัก: low / moderate / high';

-- Index สำหรับ query ตาม user และวันที่
CREATE INDEX IF NOT EXISTS idx_exercise_logs_user_date
  ON cleangoal.exercise_logs(user_id, date_record DESC);

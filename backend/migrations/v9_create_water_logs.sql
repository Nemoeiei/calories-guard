-- ============================================================
-- Migration v9: สร้างตาราง water_logs สำหรับบันทึกน้ำดื่มรายวัน
-- ============================================================

CREATE TABLE IF NOT EXISTS cleangoal.water_logs (
  log_id       BIGSERIAL PRIMARY KEY,
  user_id      BIGINT      NOT NULL REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
  date_record  DATE        NOT NULL DEFAULT CURRENT_DATE,
  glasses      INTEGER     NOT NULL DEFAULT 0 CHECK (glasses >= 0 AND glasses <= 30),
  updated_at   TIMESTAMP   DEFAULT NOW(),
  CONSTRAINT uq_water_logs_user_date UNIQUE (user_id, date_record)
);

COMMENT ON TABLE  cleangoal.water_logs              IS 'บันทึกจำนวนแก้วน้ำที่ดื่มต่อวัน';
COMMENT ON COLUMN cleangoal.water_logs.glasses      IS 'จำนวนแก้วน้ำ (1 แก้ว = ~250 ml)';

-- Index สำหรับ query รายวัน
CREATE INDEX IF NOT EXISTS idx_water_logs_user_date
  ON cleangoal.water_logs(user_id, date_record DESC);

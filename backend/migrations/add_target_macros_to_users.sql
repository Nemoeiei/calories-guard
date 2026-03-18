-- เพิ่มคอลัมน์ target_protein, target_carbs, target_fat ในตาราง users (schema cleangoal)
-- รันใน PostgreSQL (หรือใช้ search_path ถ้าเชื่อมต่อแบบกำหนด schema แล้ว)

ALTER TABLE cleangoal.users
  ADD COLUMN IF NOT EXISTS target_protein INTEGER,
  ADD COLUMN IF NOT EXISTS target_carbs INTEGER,
  ADD COLUMN IF NOT EXISTS target_fat INTEGER;

COMMENT ON COLUMN cleangoal.users.target_protein IS 'เป้าหมายโปรตีน (กรัม/วัน)';
COMMENT ON COLUMN cleangoal.users.target_carbs IS 'เป้าหมายคาร์บ (กรัม/วัน)';
COMMENT ON COLUMN cleangoal.users.target_fat IS 'เป้าหมายไขมัน (กรัม/วัน)';

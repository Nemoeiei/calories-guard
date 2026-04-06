-- ============================================================
-- Migration v12: เพิ่ม consent_accepted_at ใน users
--               + macro columns ใน detail_items (ถ้ายังไม่มี)
-- ============================================================

-- 1. เพิ่ม consent column ใน users
ALTER TABLE cleangoal.users
  ADD COLUMN IF NOT EXISTS consent_accepted_at TIMESTAMP;

COMMENT ON COLUMN cleangoal.users.consent_accepted_at
  IS 'เวลาที่ user ยอมรับ data consent (NULL = ยังไม่ยอมรับ)';

-- 2. เพิ่ม macro columns ใน detail_items (กรณียังไม่มี)
ALTER TABLE cleangoal.detail_items
  ADD COLUMN IF NOT EXISTS protein_per_unit DECIMAL(8,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS carbs_per_unit   DECIMAL(8,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fat_per_unit     DECIMAL(8,2) DEFAULT 0;

COMMENT ON COLUMN cleangoal.detail_items.protein_per_unit IS 'โปรตีน (กรัม) ต่อหน่วย';
COMMENT ON COLUMN cleangoal.detail_items.carbs_per_unit   IS 'คาร์บ (กรัม) ต่อหน่วย';
COMMENT ON COLUMN cleangoal.detail_items.fat_per_unit     IS 'ไขมัน (กรัม) ต่อหน่วย';

-- 3. Backfill: ดึงค่า macro จาก foods มาใส่ detail_items ที่มี food_id
UPDATE cleangoal.detail_items di
SET
  protein_per_unit = COALESCE(f.protein, 0),
  carbs_per_unit   = COALESCE(f.carbs,   0),
  fat_per_unit     = COALESCE(f.fat,     0)
FROM cleangoal.foods f
WHERE di.food_id = f.food_id
  AND (di.protein_per_unit = 0 OR di.protein_per_unit IS NULL);

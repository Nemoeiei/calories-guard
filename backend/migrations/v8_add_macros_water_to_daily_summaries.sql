-- ============================================================
-- Migration v8: เพิ่ม macro columns + water_glasses ใน daily_summaries
-- พร้อม trigger อัปเดตอัตโนมัติเมื่อบันทึกอาหาร
-- ============================================================

-- 1. เพิ่ม columns ใหม่
ALTER TABLE cleangoal.daily_summaries
  ADD COLUMN IF NOT EXISTS total_protein   NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_carbs     NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_fat       NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_glasses   INTEGER DEFAULT 0;

COMMENT ON COLUMN cleangoal.daily_summaries.total_protein  IS 'โปรตีนรวม (กรัม) ของวันนั้น';
COMMENT ON COLUMN cleangoal.daily_summaries.total_carbs    IS 'คาร์บรวม (กรัม) ของวันนั้น';
COMMENT ON COLUMN cleangoal.daily_summaries.total_fat      IS 'ไขมันรวม (กรัม) ของวันนั้น';
COMMENT ON COLUMN cleangoal.daily_summaries.water_glasses  IS 'จำนวนแก้วน้ำที่ดื่มในวันนั้น';

-- 2. เพิ่ม UNIQUE constraint สำหรับ trigger upsert (ถ้ายังไม่มี)
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

-- 3. ฟังก์ชัน trigger: คำนวณและอัปเดต daily_summaries ทุกครั้งที่มีการ INSERT/UPDATE/DELETE detail_items
CREATE OR REPLACE FUNCTION cleangoal.fn_sync_daily_summary()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id   BIGINT;
  v_date_rec  DATE;
  v_meal_id   BIGINT;
BEGIN
  -- หา meal_id ที่เกี่ยวข้อง
  IF TG_OP = 'DELETE' THEN
    v_meal_id := OLD.meal_id;
  ELSE
    v_meal_id := NEW.meal_id;
  END IF;

  IF v_meal_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- หา user_id และ date จาก meals
  SELECT user_id, DATE(meal_time)
    INTO v_user_id, v_date_rec
  FROM cleangoal.meals
  WHERE meal_id = v_meal_id;

  IF v_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Upsert daily_summaries
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

-- 4. สร้าง trigger บน detail_items
DROP TRIGGER IF EXISTS trg_sync_daily_summary ON cleangoal.detail_items;
CREATE TRIGGER trg_sync_daily_summary
  AFTER INSERT OR UPDATE OR DELETE
  ON cleangoal.detail_items
  FOR EACH ROW
  EXECUTE FUNCTION cleangoal.fn_sync_daily_summary();

-- 5. Backfill: คำนวณค่า macro ย้อนหลังสำหรับ rows ที่มีอยู่แล้ว
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

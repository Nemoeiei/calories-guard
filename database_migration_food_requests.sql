-- Migration: เพิ่มคอลัมน์โภชนาการใน food_requests
-- วันที่: 2026-03-26
-- จุดประสงค์: เก็บข้อมูล calories, protein, carbs, fat ที่ user กรอกเมื่อขอเพิ่มเมนูใหม่

ALTER TABLE cleangoal.food_requests 
ADD COLUMN IF NOT EXISTS calories NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS protein NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS carbs NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS fat NUMERIC(6,2);

-- เพิ่ม comment อธิบายคอลัมน์
COMMENT ON COLUMN cleangoal.food_requests.calories IS 'แคลอรี่ต่อหน่วย (kcal)';
COMMENT ON COLUMN cleangoal.food_requests.protein IS 'โปรตีนต่อหน่วย (กรัม)';
COMMENT ON COLUMN cleangoal.food_requests.carbs IS 'คาร์โบไฮเดรตต่อหน่วย (กรัม)';
COMMENT ON COLUMN cleangoal.food_requests.fat IS 'ไขมันต่อหน่วย (กรัม)';

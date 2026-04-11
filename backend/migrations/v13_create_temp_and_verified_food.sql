-- ============================================================
-- Migration v13: เพิ่มตาราง temp_food และ verified_food
--   เพื่อรองรับฟีเจอร์ "บันทึกอาหารด่วน" (Quick Add Food)
--
--   Flow:
--     1) User กรอกแค่ชื่ออาหาร (ค่าโภชนาการไม่บังคับ) → INSERT temp_food
--     2) ระบบสร้าง verified_food ที่เชื่อมกับ tf_id โดย is_verify = FALSE
--     3) Admin (role_id = 1) เข้ามาแก้ไขค่าโภชนาการใน temp_food แล้ว
--        ตั้ง is_verify = TRUE ใน verified_food เมื่อยืนยันแล้ว
-- ============================================================

-- ------------------------------------------------------------
-- 1) ตาราง temp_food
--    เก็บเมนูที่ user บันทึกด่วน (ยังไม่ตรวจสอบ)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS temp_food (
    tf_id        BIGSERIAL PRIMARY KEY,
    food_name    VARCHAR NOT NULL,
    protein      DECIMAL(6,2) DEFAULT 0,
    fat          DECIMAL(6,2) DEFAULT 0,
    carbs        DECIMAL(6,2) DEFAULT 0,
    calories     DECIMAL(6,2) DEFAULT 0,
    user_id      BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

COMMENT ON TABLE  temp_food                 IS 'เมนูอาหารที่ user บันทึกด่วน รอ admin ตรวจสอบ';
COMMENT ON COLUMN temp_food.tf_id           IS 'Primary key ของ temp_food';
COMMENT ON COLUMN temp_food.food_name       IS 'ชื่อเมนูอาหาร (บังคับกรอก)';
COMMENT ON COLUMN temp_food.protein         IS 'โปรตีน (กรัม) — ไม่บังคับ default 0';
COMMENT ON COLUMN temp_food.fat             IS 'ไขมัน (กรัม) — ไม่บังคับ default 0';
COMMENT ON COLUMN temp_food.carbs           IS 'คาร์โบไฮเดรต (กรัม) — ไม่บังคับ default 0';
COMMENT ON COLUMN temp_food.calories        IS 'แคลอรี่ (kcal) — ไม่บังคับ default 0';
COMMENT ON COLUMN temp_food.user_id         IS 'ผู้ใช้ที่เป็นคนเพิ่ม (track ว่าใครเพิ่ม)';
COMMENT ON COLUMN temp_food.created_at      IS 'เวลา timestamp ที่เพิ่มเข้าระบบ';
COMMENT ON COLUMN temp_food.updated_at      IS 'เวลาที่ admin แก้ไขล่าสุด';

CREATE INDEX IF NOT EXISTS idx_temp_food_user_id
    ON temp_food (user_id);
CREATE INDEX IF NOT EXISTS idx_temp_food_created_at
    ON temp_food (created_at DESC);


-- ------------------------------------------------------------
-- 2) ตาราง verified_food
--    เก็บสถานะการตรวจสอบเมนูใน temp_food
--    เชื่อมกับ temp_food ผ่าน tf_id (1:1)
--    admin (users.role_id = 1) เท่านั้นที่ควรแก้ไข (บังคับที่ application layer)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS verified_food (
    vf_id        BIGSERIAL PRIMARY KEY,
    tf_id        BIGINT NOT NULL UNIQUE
                  REFERENCES temp_food(tf_id) ON DELETE CASCADE,
    is_verify    BOOLEAN NOT NULL DEFAULT FALSE,
    verified_by  BIGINT REFERENCES users(user_id) ON DELETE SET NULL,
    verified_at  TIMESTAMP,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

COMMENT ON TABLE  verified_food              IS 'สถานะการตรวจสอบเมนูที่ user เพิ่มเข้ามาใน temp_food';
COMMENT ON COLUMN verified_food.vf_id        IS 'Primary key ของ verified_food';
COMMENT ON COLUMN verified_food.tf_id        IS 'FK → temp_food.tf_id (1:1)';
COMMENT ON COLUMN verified_food.is_verify    IS 'FALSE = unverified, TRUE = verified โดย admin';
COMMENT ON COLUMN verified_food.verified_by  IS 'admin user_id ที่เป็นคน verify (role_id = 1)';
COMMENT ON COLUMN verified_food.verified_at  IS 'เวลาที่ admin ยืนยัน (NULL ถ้ายังไม่ verify)';
COMMENT ON COLUMN verified_food.created_at   IS 'เวลาที่ record ถูกสร้าง (ตอน user เพิ่มอาหารด่วน)';
COMMENT ON COLUMN verified_food.updated_at   IS 'เวลาที่ status ถูกแก้ไขล่าสุด';

CREATE INDEX IF NOT EXISTS idx_verified_food_tf_id
    ON verified_food (tf_id);
CREATE INDEX IF NOT EXISTS idx_verified_food_is_verify
    ON verified_food (is_verify);


-- ------------------------------------------------------------
-- 3) Trigger: สร้าง verified_food อัตโนมัติเมื่อ insert temp_food
--    เพื่อให้ทุกเมนูใหม่มีสถานะ unverified ตั้งต้นเสมอ
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_create_verified_food_on_temp_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO verified_food (tf_id, is_verify, created_at)
    VALUES (NEW.tf_id, FALSE, NOW())
    ON CONFLICT (tf_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_create_verified_food ON temp_food;
CREATE TRIGGER trg_create_verified_food
    AFTER INSERT ON temp_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_create_verified_food_on_temp_insert();


-- ------------------------------------------------------------
-- 4) Trigger: อัปเดต updated_at ใน temp_food อัตโนมัติ
--    และ sync verified_food.updated_at เมื่อ admin แก้ไขค่าโภชนาการ
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_temp_food_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_temp_food_touch_updated_at ON temp_food;
CREATE TRIGGER trg_temp_food_touch_updated_at
    BEFORE UPDATE ON temp_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_temp_food_touch_updated_at();


CREATE OR REPLACE FUNCTION fn_verified_food_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    -- ถ้ากำลังเปลี่ยนเป็น verified ให้ตั้ง verified_at
    IF NEW.is_verify = TRUE AND (OLD.is_verify IS DISTINCT FROM TRUE) THEN
        NEW.verified_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verified_food_touch_updated_at ON verified_food;
CREATE TRIGGER trg_verified_food_touch_updated_at
    BEFORE UPDATE ON verified_food
    FOR EACH ROW
    EXECUTE FUNCTION fn_verified_food_touch_updated_at();


-- ------------------------------------------------------------
-- 5) View สำหรับ admin: รวมข้อมูล temp_food + verified_food
--    เพื่อให้ query รายการ pending/verified ได้สะดวก
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_admin_temp_food_review AS
SELECT
    tf.tf_id,
    tf.food_name,
    tf.protein,
    tf.fat,
    tf.carbs,
    tf.calories,
    tf.user_id         AS submitted_by,
    u.username         AS submitted_by_username,
    tf.created_at      AS submitted_at,
    tf.updated_at      AS last_edited_at,
    vf.vf_id,
    vf.is_verify,
    vf.verified_by,
    vf.verified_at
FROM temp_food tf
LEFT JOIN verified_food vf ON vf.tf_id  = tf.tf_id
LEFT JOIN users         u  ON u.user_id = tf.user_id;

COMMENT ON VIEW v_admin_temp_food_review
    IS 'มุมมองรวมสำหรับ admin ตรวจสอบเมนูที่ user เพิ่มด่วน';

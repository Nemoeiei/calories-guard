-- v20: Regional Thai food names + user.region preference
--
-- Why: Thai dialects use different names for the same dish (e.g. "ขนมจีน"
-- in Central = "ข้าวปุ้น" in Isan, "ขนมเส้น" in the North). The product
-- needs to (a) match dialect terms in search and (b) display the
-- region-preferred name on cards/details. We also need a moderation flow
-- so users can contribute new variants without touching foods directly.
--
-- Adds:
--   * ENUM cleangoal.thai_region (4 regions)
--   * cleangoal.users.region + region_source columns
--   * cleangoal.food_regional_names (1 food → many alt names per region)
--   * cleangoal.food_regional_popularity (popularity 1-5 per food/region)
--   * cleangoal.food_regional_name_submissions (mirrors temp_food flow)
--   * RLS policies matching the v15_c pattern
--   * Seed: ~30+ curated dialect variants for canonical seed dishes

BEGIN;

-- -------------------------------------------------------------------------
-- 1. ENUM thai_region (CREATE TYPE has no IF NOT EXISTS; gate with DO block)
-- -------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'thai_region' AND n.nspname = 'cleangoal'
    ) THEN
        CREATE TYPE cleangoal.thai_region AS ENUM (
            'central', 'northern', 'northeastern', 'southern'
        );
    END IF;
END$$;

-- -------------------------------------------------------------------------
-- 2. ALTER users — region preference (NULL = not set, fallback to Central)
-- -------------------------------------------------------------------------
ALTER TABLE cleangoal.users
    ADD COLUMN IF NOT EXISTS region cleangoal.thai_region;

ALTER TABLE cleangoal.users
    ADD COLUMN IF NOT EXISTS region_source VARCHAR(20) NOT NULL DEFAULT 'unset';

-- region_source values: 'unset' (default), 'manual' (user picked it),
-- 'auto_ip' (reserved for future geo detection — not used in v20).
ALTER TABLE cleangoal.users
    DROP CONSTRAINT IF EXISTS users_region_source_check;
ALTER TABLE cleangoal.users
    ADD  CONSTRAINT users_region_source_check
         CHECK (region_source IN ('unset', 'manual', 'auto_ip'));

CREATE INDEX IF NOT EXISTS idx_users_region
    ON cleangoal.users (region)
    WHERE region IS NOT NULL AND deleted_at IS NULL;

COMMENT ON COLUMN cleangoal.users.region
    IS 'Preferred Thai region for food name display (NULL = use canonical Central name)';
COMMENT ON COLUMN cleangoal.users.region_source
    IS 'How region was set: unset|manual|auto_ip';

-- -------------------------------------------------------------------------
-- 3. food_regional_names (alt name per food per region)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cleangoal.food_regional_names (
    variant_id   BIGSERIAL PRIMARY KEY,
    food_id      BIGINT NOT NULL REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE,
    region       cleangoal.thai_region NOT NULL,
    name_th      VARCHAR(200) NOT NULL,
    is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
    created_by   BIGINT REFERENCES cleangoal.users(user_id) ON DELETE SET NULL,
    approved_by  BIGINT REFERENCES cleangoal.users(user_id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,
    CONSTRAINT uq_food_region_name UNIQUE (food_id, region, name_th),
    CONSTRAINT ck_food_regional_name_not_blank CHECK (length(btrim(name_th)) > 0)
);

-- Exactly one primary alias per (food, region), live rows only.
CREATE UNIQUE INDEX IF NOT EXISTS uq_food_regional_primary
    ON cleangoal.food_regional_names (food_id, region)
    WHERE is_primary AND deleted_at IS NULL;

-- Search index (case-insensitive) for resolving dialect → canonical food.
CREATE INDEX IF NOT EXISTS idx_food_regional_lookup
    ON cleangoal.food_regional_names (region, lower(name_th))
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_food_regional_food
    ON cleangoal.food_regional_names (food_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE cleangoal.food_regional_names
    IS 'Alternative Thai names for foods per region (dialect / regional naming)';

-- -------------------------------------------------------------------------
-- 4. food_regional_popularity (popularity 1-5 per food per region)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cleangoal.food_regional_popularity (
    food_id      BIGINT NOT NULL REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE,
    region       cleangoal.thai_region NOT NULL,
    popularity   SMALLINT NOT NULL CHECK (popularity BETWEEN 1 AND 5),
    note         VARCHAR(200),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (food_id, region)
);

COMMENT ON TABLE cleangoal.food_regional_popularity
    IS 'How common a food is in each region (1=rare, 5=ubiquitous)';

-- -------------------------------------------------------------------------
-- 5. food_regional_name_submissions (mirrors temp_food contribute flow)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cleangoal.food_regional_name_submissions (
    submission_id  BIGSERIAL PRIMARY KEY,
    food_id        BIGINT NOT NULL REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE,
    region         cleangoal.thai_region NOT NULL,
    name_th        VARCHAR(200) NOT NULL,
    popularity     SMALLINT CHECK (popularity BETWEEN 1 AND 5),
    user_id        BIGINT NOT NULL REFERENCES cleangoal.users(user_id) ON DELETE CASCADE,
    status         cleangoal.request_status NOT NULL DEFAULT 'pending',
    reviewed_by    BIGINT REFERENCES cleangoal.users(user_id) ON DELETE SET NULL,
    reviewed_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_subm_name_not_blank CHECK (length(btrim(name_th)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_food_regional_subm_status
    ON cleangoal.food_regional_name_submissions (status, created_at);

CREATE INDEX IF NOT EXISTS idx_food_regional_subm_user
    ON cleangoal.food_regional_name_submissions (user_id);

COMMENT ON TABLE cleangoal.food_regional_name_submissions
    IS 'User-submitted regional name suggestions awaiting admin review';

-- -------------------------------------------------------------------------
-- 6. RLS policies (match v15_c patterns)
-- -------------------------------------------------------------------------

-- Reference tables: public_read (everyone can SELECT, writes via service role).
ALTER TABLE cleangoal.food_regional_names      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleangoal.food_regional_popularity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read" ON cleangoal.food_regional_names;
CREATE POLICY "public_read" ON cleangoal.food_regional_names
    AS PERMISSIVE FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read" ON cleangoal.food_regional_popularity;
CREATE POLICY "public_read" ON cleangoal.food_regional_popularity
    AS PERMISSIVE FOR SELECT USING (true);

-- User-owned table: deny anon + deny authed-pre-auth-migration (placeholder).
ALTER TABLE cleangoal.food_regional_name_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "deny_all_until_auth_migration" ON cleangoal.food_regional_name_submissions;
CREATE POLICY "deny_all_until_auth_migration" ON cleangoal.food_regional_name_submissions
    AS PERMISSIVE FOR ALL USING (false) WITH CHECK (false);

-- -------------------------------------------------------------------------
-- 7. Seed curated dialect variants
-- -------------------------------------------------------------------------
-- Strategy: for each (canonical food_name, region, dialect_name, popularity)
-- tuple, look up the food by name and INSERT into food_regional_names if
-- the food row actually exists (skip silently otherwise so the migration
-- stays safe regardless of which food seeds have been applied).
--
-- Format of v_seed: (food_name_canonical, region, alias, is_primary, popularity).
-- popularity NULL = no popularity row recorded.

WITH v_seed(canonical, region, alias, is_primary, popularity) AS (
    VALUES
    -- ── ขนมจีน ────────────────────────────────────────────────
    ('ขนมจีนน้ำยา', 'central'::cleangoal.thai_region,      'ขนมจีนน้ำยา',  TRUE,  5::SMALLINT),
    ('ขนมจีนน้ำยา', 'northern'::cleangoal.thai_region,     'ขนมเส้น',     TRUE,  4::SMALLINT),
    ('ขนมจีนน้ำยา', 'northeastern'::cleangoal.thai_region, 'ข้าวปุ้น',    TRUE,  5::SMALLINT),
    ('ขนมจีนน้ำยา', 'southern'::cleangoal.thai_region,     'ขนมจีน',      TRUE,  5::SMALLINT),
    ('ขนมจีนน้ำพริก', 'northeastern'::cleangoal.thai_region, 'ข้าวปุ้นน้ำพริก', FALSE, 3::SMALLINT),
    ('ขนมจีนน้ำพริก', 'northern'::cleangoal.thai_region,     'ขนมเส้นน้ำพริก',   FALSE, 3::SMALLINT),

    -- ── ส้มตำ ─────────────────────────────────────────────────
    ('ส้มตำไทย', 'central'::cleangoal.thai_region,      'ส้มตำไทย',  TRUE,  5::SMALLINT),
    ('ส้มตำไทย', 'northeastern'::cleangoal.thai_region, 'ตำหมากหุ่ง', TRUE,  5::SMALLINT),
    ('ส้มตำไทย', 'northern'::cleangoal.thai_region,     'ตำส้ม',     TRUE,  4::SMALLINT),
    ('ส้มตำไทย', 'southern'::cleangoal.thai_region,     'ส้มตำ',     TRUE,  4::SMALLINT),
    ('ส้มตำปูปลาร้า', 'northeastern'::cleangoal.thai_region, 'ตำปูปลาแดก', TRUE, 5::SMALLINT),

    -- ── ลาบ ───────────────────────────────────────────────────
    ('ลาบหมู',  'central'::cleangoal.thai_region,      'ลาบหมู',     TRUE, 4::SMALLINT),
    ('ลาบหมู',  'northeastern'::cleangoal.thai_region, 'ลาบหมูอีสาน', TRUE, 5::SMALLINT),
    ('ลาบหมู',  'northern'::cleangoal.thai_region,     'ลาบเมือง',   TRUE, 5::SMALLINT),
    ('ลาบไก่',  'northeastern'::cleangoal.thai_region, 'ก้อยไก่',    FALSE, 4::SMALLINT),
    ('ลาบปลา',  'northeastern'::cleangoal.thai_region, 'ก้อยปลา',    FALSE, 4::SMALLINT),

    -- ── ข้าวเหนียวมะม่วง / ข้าวเหนียว ───────────────────────────
    ('ข้าวเหนียวมะม่วง', 'central'::cleangoal.thai_region,      'ข้าวเหนียวมะม่วง', TRUE,  5::SMALLINT),
    ('ข้าวเหนียวมะม่วง', 'northern'::cleangoal.thai_region,     'ข้าวนึ่งมะม่วง',   TRUE,  3::SMALLINT),
    ('ข้าวเหนียวมะม่วง', 'northeastern'::cleangoal.thai_region, 'ข้าวเหนียวบักม่วง', TRUE, 4::SMALLINT),

    -- ── หมูปิ้ง / ข้าวเหนียวหมูปิ้ง ─────────────────────────────
    ('ข้าวเหนียวหมูปิ้ง', 'northeastern'::cleangoal.thai_region, 'ข้าวเหนียวหมูปิ้งอีสาน', TRUE, 5::SMALLINT),
    ('ข้าวเหนียวหมูปิ้ง', 'northern'::cleangoal.thai_region,     'ข้าวนึ่งหมูปิ้ง',         TRUE, 4::SMALLINT),
    ('หมูปิ้ง',          'northeastern'::cleangoal.thai_region, 'หมูจุ่ม',                FALSE, 3::SMALLINT),

    -- ── แกงไตปลา (Southern signature) ──────────────────────────
    ('แกงไตปลา', 'southern'::cleangoal.thai_region, 'แกงพุงปลา', TRUE, 5::SMALLINT),
    ('แกงไตปลา', 'central'::cleangoal.thai_region,  'แกงไตปลา',  TRUE, 3::SMALLINT),

    -- ── แกงฮังเล (Northern signature) ──────────────────────────
    ('แกงฮังเล', 'northern'::cleangoal.thai_region, 'แกงฮังเล',     TRUE, 5::SMALLINT),
    ('แกงฮังเล', 'central'::cleangoal.thai_region,  'แกงฮังเลพม่า', TRUE, 2::SMALLINT),

    -- ── แกงเขียวหวาน ──────────────────────────────────────────
    ('แกงเขียวหวานไก่', 'central'::cleangoal.thai_region, 'แกงเขียวหวานไก่', TRUE, 5::SMALLINT),
    ('แกงเขียวหวานไก่', 'southern'::cleangoal.thai_region,'แกงเขียวหวานไก่ใต้', TRUE, 4::SMALLINT),

    -- ── ผัดไทย ────────────────────────────────────────────────
    ('ผัดไทยกุ้ง', 'central'::cleangoal.thai_region,  'ผัดไทยกุ้ง', TRUE, 5::SMALLINT),
    ('ผัดไทยกุ้ง', 'southern'::cleangoal.thai_region, 'ผัดไทยกุ้งสด', FALSE, 4::SMALLINT),

    -- ── ขนมครก ────────────────────────────────────────────────
    ('ขนมครก', 'central'::cleangoal.thai_region,      'ขนมครก',          TRUE, 5::SMALLINT),
    ('ขนมครก', 'northern'::cleangoal.thai_region,     'ขนมครกหน้าหวาน',   TRUE, 4::SMALLINT),
    ('ขนมครก', 'northeastern'::cleangoal.thai_region, 'ขนมครกอีสาน',     TRUE, 3::SMALLINT),
    ('ขนมครก', 'southern'::cleangoal.thai_region,     'ขนมครกหน้ากุ้ง',   TRUE, 3::SMALLINT),

    -- ── ก๋วยเตี๋ยว ────────────────────────────────────────────
    ('ก๋วยเตี๋ยวเรือ',   'central'::cleangoal.thai_region,  'ก๋วยเตี๋ยวเรือ',     TRUE, 5::SMALLINT),
    ('ก๋วยเตี๋ยวต้มยำหมู','northeastern'::cleangoal.thai_region, 'ก๋วยเตี๋ยวต้มแซ่บ', TRUE, 4::SMALLINT),

    -- ── น้ำพริก / แจ่ว (regional staple alias) ─────────────────
    ('แกงเลียง', 'northeastern'::cleangoal.thai_region, 'แจ่วฮ้อน', FALSE, 2::SMALLINT),

    -- ── ต้มยำ ─────────────────────────────────────────────────
    ('ต้มยำกุ้งน้ำใส', 'central'::cleangoal.thai_region,  'ต้มยำกุ้งน้ำใส', TRUE, 5::SMALLINT),
    ('ต้มยำกุ้งน้ำข้น', 'central'::cleangoal.thai_region, 'ต้มยำกุ้งน้ำข้น', TRUE, 5::SMALLINT),

    -- ── ปลาทู (raw ingredient) ─────────────────────────────────
    ('ปลาทู', 'southern'::cleangoal.thai_region, 'ปลาทูสด', FALSE, 5::SMALLINT)
)
INSERT INTO cleangoal.food_regional_names (food_id, region, name_th, is_primary)
SELECT f.food_id, s.region, s.alias, s.is_primary
FROM v_seed s
JOIN cleangoal.foods f ON f.food_name = s.canonical AND f.deleted_at IS NULL
ON CONFLICT (food_id, region, name_th) DO NOTHING;

-- Popularity rows (one per (food, region) where popularity is provided).
WITH v_seed(canonical, region, popularity) AS (
    VALUES
    ('ขนมจีนน้ำยา',      'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ขนมจีนน้ำยา',      'northern'::cleangoal.thai_region,     4::SMALLINT),
    ('ขนมจีนน้ำยา',      'northeastern'::cleangoal.thai_region, 5::SMALLINT),
    ('ขนมจีนน้ำยา',      'southern'::cleangoal.thai_region,     5::SMALLINT),
    ('ส้มตำไทย',         'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ส้มตำไทย',         'northeastern'::cleangoal.thai_region, 5::SMALLINT),
    ('ส้มตำไทย',         'northern'::cleangoal.thai_region,     4::SMALLINT),
    ('ส้มตำไทย',         'southern'::cleangoal.thai_region,     4::SMALLINT),
    ('ลาบหมู',           'northeastern'::cleangoal.thai_region, 5::SMALLINT),
    ('ลาบหมู',           'northern'::cleangoal.thai_region,     5::SMALLINT),
    ('ข้าวเหนียวมะม่วง',  'central'::cleangoal.thai_region,      5::SMALLINT),
    ('แกงไตปลา',         'southern'::cleangoal.thai_region,     5::SMALLINT),
    ('แกงไตปลา',         'central'::cleangoal.thai_region,      3::SMALLINT),
    ('แกงฮังเล',         'northern'::cleangoal.thai_region,     5::SMALLINT),
    ('แกงฮังเล',         'central'::cleangoal.thai_region,      2::SMALLINT),
    ('แกงเขียวหวานไก่',   'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ผัดไทยกุ้ง',        'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ขนมครก',           'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ก๋วยเตี๋ยวเรือ',     'central'::cleangoal.thai_region,      5::SMALLINT),
    ('ต้มยำกุ้งน้ำใส',     'central'::cleangoal.thai_region,      5::SMALLINT)
)
INSERT INTO cleangoal.food_regional_popularity (food_id, region, popularity)
SELECT f.food_id, s.region, s.popularity
FROM v_seed s
JOIN cleangoal.foods f ON f.food_name = s.canonical AND f.deleted_at IS NULL
ON CONFLICT (food_id, region) DO UPDATE
    SET popularity = EXCLUDED.popularity,
        updated_at = NOW();

-- -------------------------------------------------------------------------
-- 8. Track migration
-- -------------------------------------------------------------------------
INSERT INTO cleangoal.schema_migrations(version) VALUES ('v20_regional_names_and_user_region')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- BEGIN;
-- DROP TABLE IF EXISTS cleangoal.food_regional_name_submissions;
-- DROP TABLE IF EXISTS cleangoal.food_regional_popularity;
-- DROP TABLE IF EXISTS cleangoal.food_regional_names;
-- ALTER TABLE cleangoal.users DROP COLUMN IF EXISTS region_source;
-- ALTER TABLE cleangoal.users DROP COLUMN IF EXISTS region;
-- DROP TYPE IF EXISTS cleangoal.thai_region;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v20_regional_names_and_user_region';
-- COMMIT;

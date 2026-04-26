# สรุปการปรับฐานข้อมูล v20–v24

เอกสารนี้สรุปการเปลี่ยนแปลง schema ฐานข้อมูล PostgreSQL (schema `cleangoal` บน Supabase) ตั้งแต่ migration **v20** ถึง **v24** — ทำไมถึงปรับ เพิ่ม/ลบอะไร และเหตุผลเชิงเทคนิค

| Migration | จุดประสงค์ | Risk |
|-----------|-----------|------|
| [v20](../backend/migrations/v20_regional_names_and_user_region.sql) | เพิ่ม Thai regional food names + user region preference | Low–Med |
| [v21](../backend/migrations/v21_drop_foods_legacy_columns.sql) | ลบคอลัมน์ legacy ซ้ำซ้อนใน `foods` | Med |
| [v22](../backend/migrations/v22_drop_unused_tables.sql) | ลบตารางที่ไม่มี router ใช้แล้ว | Low |
| [v24](../backend/migrations/v24_audit_columns_and_sync_triggers.sql) | เพิ่ม `updated_at` audit + sync trigger ป้องกัน stale cache | Low |

> **หมายเหตุ:** v23 (Phase 4 — split `detail_items` polymorphism) ยังไม่ได้ทำ เพราะ blast radius สูง (4 routers + 1 trigger function) จะทำหลัง v20–v24 stable บน production แล้ว

---

## v20 — Regional Thai Food Names + User Region

### ทำไมถึงปรับ

ผู้ใช้ภาคเหนือเรียก "ขนมจีน" ว่า **"ขนมเส้น"**, ภาคอีสานเรียกว่า **"ข้าวปุ้น"** — ถ้า user ค้นด้วยคำท้องถิ่นแล้วระบบหาไม่เจอ จะใช้งานไม่สะดวก ฟีเจอร์นี้ต้องการรองรับทั้ง:

1. **Search** — ค้น "ข้าวปุ้น" → match canonical "ขนมจีนน้ำยา"
2. **Display** — user ตั้งภาคแล้ว เห็นชื่อท้องถิ่นบน food card แทนชื่อกลาง
3. **Popularity** — บางเมนูพบมากในภาคใดภาคหนึ่ง (เช่น แกงไตปลา = 5 ในภาคใต้, 1 ในภาคเหนือ)
4. **Crowdsource** — admin/user ส่งชื่อท้องถิ่นใหม่ผ่าน flow คล้าย `temp_food`

### เพิ่มอะไร

#### 1. ENUM `thai_region`

```sql
CREATE TYPE cleangoal.thai_region AS ENUM
  ('central','northern','northeastern','southern');
```

**เหตุผล:** บังคับ valid values ที่ database level — ป้องกัน typo ภาษาไทย/อังกฤษปนกัน และทำให้ index มีประสิทธิภาพกว่า VARCHAR + CHECK

#### 2. คอลัมน์ใหม่ใน `users`

```sql
ALTER TABLE cleangoal.users
  ADD COLUMN region thai_region NULL,
  ADD COLUMN region_source VARCHAR(20) DEFAULT 'unset';
  -- 'manual' | 'auto_ip' | 'unset'
```

- `region NULL` = user ยังไม่ตั้ง → fallback ใช้ canonical name (ภาคกลาง)
- `region_source` แยกระหว่างผู้ใช้ตั้งเอง vs auto-detect (อนาคต) เพื่อไม่ override เลือกของ user

#### 3. ตาราง `food_regional_names`

```sql
food_id, region, name_th, is_primary,
created_by, approved_by, created_at, updated_at, deleted_at
```

**Constraints สำคัญ:**
- `UNIQUE (food_id, region, name_th)` — กันชื่อซ้ำใน food/region เดียวกัน
- Partial unique index `uq_food_regional_primary` — บังคับ **1 primary ต่อ (food, region)** เฉพาะ row ที่ live
- `idx_food_regional_lookup ON (region, lower(name_th))` — fast case-insensitive search

**ทำไมแยกตาราง ไม่ใส่เป็น JSONB ใน `foods`?**
1. Search performance — INDEX ที่ระดับ row เร็วกว่า GIN บน JSONB
2. Audit trail — `created_by`/`approved_by` ต่อชื่อ ทำได้สะอาดกว่า
3. RLS policy ระดับชื่อแต่ละอันได้
4. Soft delete แต่ละชื่อโดยไม่กระทบชื่ออื่น

#### 4. ตาราง `food_regional_popularity`

```sql
PRIMARY KEY (food_id, region),
popularity SMALLINT CHECK (1..5),
note VARCHAR(200)
```

**ทำไมแยก ไม่ใส่ใน `food_regional_names`?**
- Popularity เป็นค่า **per (food, region)** ไม่ใช่ **per name** — ขนมจีนมีชื่อหลายอันในอีสาน แต่ความนิยมของ "ขนมจีน" ในอีสานคือค่าเดียว
- ทำให้ aggregate query (`SELECT * WHERE popularity >= 4`) ง่ายและเร็วขึ้น

#### 5. ตาราง `food_regional_name_submissions`

Mirror pattern จาก `temp_food` — user ส่งชื่อท้องถิ่นใหม่, admin review แล้ว approve เข้า `food_regional_names`

```sql
status request_status DEFAULT 'pending',
reviewed_by, reviewed_at
```

**ทำไมไม่ insert ตรงเข้า `food_regional_names`?**
- ป้องกัน spam/troll
- ให้ admin verify ความถูกต้องของชื่อ + ภาค ก่อน
- เก็บประวัติคนเสนอ (`user_id`) ไว้ — ใช้ track contributor ในอนาคต

#### 6. RLS Policies

ตาม pattern v15_c:
- `food_regional_names`, `food_regional_popularity` → `public_read` (ทุกคนอ่านได้, write ผ่าน service-role เท่านั้น)
- `food_regional_name_submissions` → `deny_all_until_auth_migration` (รอ Supabase Auth migration)

#### 7. Seed Data (~30+ เมนู)

Embedded ใน migration — Curated list:

| Canonical (ภาคกลาง) | เหนือ | อีสาน | ใต้ |
|---|---|---|---|
| ขนมจีนน้ำยา | ขนมเส้น | ข้าวปุ้น | ขนมจีน |
| ส้มตำไทย | ตำไทย | ตำหมากหุ่ง / ตำส้ม | ส้มตำ |
| ลาบหมู | ลาบเมือง | ลาบ / ก้อย | ลาบ |
| แกงไตปลา | — | — | แกงพุงปลา (primary) |
| แกงฮังเล (primary) | — | — | — |
| ข้าวเหนียวมะม่วง | — | ข้าวเหนียวบักม่วง | — |
| หมูปิ้ง | หมูจุ่ม | หมูปิ้ง | — |
| ก๋วยเตี๋ยวต้มยำหมู | — | ก๋วยเตี๋ยวต้มแซ่บ | — |

> **หมายเหตุ:** Seed ใช้ `ON CONFLICT (food_id, region, name_th) DO NOTHING` — รัน migration ซ้ำได้โดยไม่พัง

---

## v21 — Drop Legacy Duplicate Columns

### ทำไมถึงปรับ

จาก migration v17–v19 ทำ 3NF ไปบางส่วน — สร้าง:
- `dishes` table (FK `foods.dish_id` → dishes)
- `units` table (FK `foods.serving_unit_id` → units)

แต่คอลัมน์ legacy **ยังอยู่:**
- `foods.food_category` VARCHAR(100) — ซ้ำกับ `foods.dish_id`
- `foods.serving_unit` VARCHAR(30) — ซ้ำกับ `foods.serving_unit_id`

**ปัญหา:**
1. **Data drift** — code เก่าอ่าน `food_category` (string), code ใหม่ join `dishes` — ค่าอาจไม่ตรงกัน
2. **Storage waste** — VARCHAR ยาวซ้ำในทุก row
3. **Confusion** — developer ใหม่ไม่รู้ควรใช้ column ไหน

### ปรับยังไง

#### 1. Backfill ก่อน drop

```sql
-- serving_unit → serving_unit_id (default 'serving' unit)
INSERT INTO cleangoal.units (name, quantity)
SELECT 'serving', 1 WHERE NOT EXISTS (...);

UPDATE cleangoal.foods f
   SET serving_unit_id = u.unit_id
  FROM cleangoal.units u
 WHERE f.serving_unit_id IS NULL
   AND lower(u.name) = lower(f.serving_unit);
```

```sql
-- food_category → dish_id (ผ่าน dish_categories + dishes)
INSERT INTO cleangoal.dish_categories (...)
SELECT food_category, food_type, ... FROM cleangoal.foods
ON CONFLICT DO NOTHING;

INSERT INTO cleangoal.dishes (...)
SELECT food_name, dish_category_id, food_type, ... FROM cleangoal.foods f
JOIN cleangoal.dish_categories dc ON ...
ON CONFLICT DO NOTHING;

UPDATE cleangoal.foods SET dish_id = ... WHERE dish_id IS NULL;
```

#### 2. Guardrail ก่อน DROP

```sql
DO $$
DECLARE missing_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO missing_count
      FROM cleangoal.foods
     WHERE dish_id IS NULL AND deleted_at IS NULL;

    IF missing_count > 0 THEN
        RAISE EXCEPTION 'Cannot drop: % live foods still NULL dish_id', missing_count;
    END IF;
END$$;
```

**ทำไมต้องมี guardrail?** ถ้า backfill ล้มเหลว row ใดไม่ได้ map → drop column = data loss ถาวร

#### 3. Drop จริง

```sql
ALTER TABLE cleangoal.foods
    DROP COLUMN IF EXISTS food_category,
    DROP COLUMN IF EXISTS serving_unit;
```

### ลบอะไร

- `cleangoal.foods.food_category` — แทนด้วย `dish_id` → `dishes` → `dish_categories.category_name`
- `cleangoal.foods.serving_unit` — แทนด้วย `serving_unit_id` → `units.name`

---

## v22 — Drop Unused Tables

### ทำไมถึงปรับ

ตาราง 3 ตัวเหลือมาจาก architecture เก่า ไม่มี router ใช้แล้ว แต่ยังกินพื้นที่ + ทำให้ schema สับสน:

| ตาราง | ทำไมไม่ใช้แล้ว |
|---|---|
| `food_requests` | ถูกแทนด้วย `temp_food` ใน v13 (newer flow ที่รองรับ verified_food + auto-add) |
| `food_ingredients` | ส่วน recipe ingredients ย้ายไปใช้ `recipe_ingredients` แล้ว |
| `ingredients` | ถูก reference จาก `food_ingredients` เท่านั้น (ที่ก็ตายแล้ว) |

**Pre-flight check:**
```bash
grep -rn "food_requests\|food_ingredients\|FROM cleangoal.ingredients\b" backend/app/
# ผลลัพธ์: ไม่มี (หลังลบ /admin/food-requests endpoints ใน commit เดียวกัน)
```

### ปรับยังไง

#### 1. Archive ก่อน drop

```sql
CREATE TABLE IF NOT EXISTS cleangoal.food_requests_archive
    AS TABLE cleangoal.food_requests WITH NO DATA;

INSERT INTO cleangoal.food_requests_archive
SELECT * FROM cleangoal.food_requests
ON CONFLICT DO NOTHING;
```

**ทำไม archive?** ถ้าพบว่ามีข้อมูลที่ต้องการกู้คืน (เช่น admin อยากดู food request เก่า) — ยังเรียกได้จาก `_archive` table โดยไม่ต้อง restore backup ทั้งฐาน

#### 2. Drop ตาม FK order

```sql
DROP TABLE IF EXISTS cleangoal.food_ingredients;  -- มี FK → ingredients
DROP TABLE IF EXISTS cleangoal.ingredients;
DROP TABLE IF EXISTS cleangoal.food_requests;
```

#### 3. ลบ code reference

- `backend/app/routers/admin.py` — ลบ `GET/PUT /admin/food-requests` endpoints
- `backend/app/routers/users.py` — ลบ `("food_requests", "user_id")` จาก `OWNED_TABLES` (table ที่ลบเมื่อ user delete account)

---

## v24 — Audit Columns + Cache-Sync Triggers

### ทำไมถึงปรับ

#### ปัญหา 1: ไม่มี `updated_at` ในตารางที่ user แก้ไขได้

ตาราง `detail_items`, `daily_summaries`, `exercise_logs`, `meals` มีแค่ `created_at` — ทำให้:
- ไม่รู้ว่า row ถูกแก้ไขล่าสุดเมื่อไหร่
- Sync logic ฝั่ง client ทำ delta sync ไม่ได้
- Audit trail หายเมื่อมี update

#### ปัญหา 2: Cache columns ไม่ sync เมื่อ source เปลี่ยน

`detail_items` cache ค่าจาก `foods`:
- `food_name`
- `cal_per_unit`
- `protein_per_unit`, `carbs_per_unit`, `fat_per_unit`

**ทำไมต้อง denormalize?** เวลาดูประวัติการกิน user ต้องการเห็นว่าตอนกินมีกี่แคล — ถ้า admin แก้ค่าใน `foods` ทีหลัง ค่าประวัติต้องไม่เปลี่ยนตาม (immutable history) **แต่...**

**ปัญหาที่เจอ:** ถ้า admin แก้ `foods.calories` แล้วผู้ใช้บันทึกใหม่ → row ใหม่ใน `detail_items` ก็ยัง cache ค่า**เก่า** จาก foods เพราะ trigger ไม่มี

> **Trade-off ที่เลือก:** sync `detail_items` กับ `foods` ทุกครั้งที่ foods update — เพื่อให้ค่าตรงกันเสมอ ถ้าต้องการ immutable history ในอนาคต จะใช้วิธี append-only + version column แทน

### ปรับยังไง

#### 1. เพิ่มคอลัมน์ `updated_at`

```sql
ALTER TABLE cleangoal.detail_items
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
-- เหมือนกันกับ daily_summaries, exercise_logs, meals
```

**ทำไม `TIMESTAMPTZ` ไม่ใช่ `TIMESTAMP`?**
- `TIMESTAMPTZ` เก็บ UTC + timezone aware → app ฝั่ง mobile (iOS/Android) ที่ user อยู่หลายโซนเวลาแสดงผลถูกต้อง
- `TIMESTAMP` เก็บแค่ wall-clock → confusion เมื่อ server กับ client คนละ timezone

#### 2. Trigger function `fn_set_updated_at()`

```sql
CREATE OR REPLACE FUNCTION cleangoal.fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cleangoal, public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;
```

แล้วผูกกับทั้ง 4 table:

```sql
CREATE TRIGGER trg_detail_items_updated_at
    BEFORE UPDATE ON cleangoal.detail_items
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_set_updated_at();
```

**ทำไมใช้ trigger ไม่ให้ application code set?**
- บังคับ invariant ที่ database level — ไม่ว่าจะ insert/update ผ่าน router, psql, หรือ Supabase dashboard `updated_at` ก็จะถูกเสมอ
- Code review ไม่ต้องตรวจว่า application ลืม set ไหม

#### 3. Cache-sync trigger `fn_sync_detail_items_from_foods()`

```sql
CREATE OR REPLACE FUNCTION cleangoal.fn_sync_detail_items_from_foods()
RETURNS TRIGGER LANGUAGE plpgsql
AS $$
BEGIN
    IF (NEW.food_name IS DISTINCT FROM OLD.food_name
     OR NEW.calories   IS DISTINCT FROM OLD.calories
     OR NEW.protein    IS DISTINCT FROM OLD.protein
     OR NEW.carbs      IS DISTINCT FROM OLD.carbs
     OR NEW.fat        IS DISTINCT FROM OLD.fat) THEN

        UPDATE cleangoal.detail_items
           SET food_name        = NEW.food_name,
               cal_per_unit     = NEW.calories,
               protein_per_unit = NEW.protein,
               carbs_per_unit   = NEW.carbs,
               fat_per_unit     = NEW.fat,
               updated_at       = NOW()
         WHERE food_id = NEW.food_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_foods_sync_detail_items
    AFTER UPDATE ON cleangoal.foods
    FOR EACH ROW EXECUTE FUNCTION cleangoal.fn_sync_detail_items_from_foods();
```

**ทำไม `IS DISTINCT FROM`?** เทียบ NULL-safe — `NULL = NULL` คืน NULL ใน SQL แต่ `NULL IS DISTINCT FROM NULL` คืน FALSE

**ทำไม `AFTER UPDATE` ไม่ใช่ `BEFORE`?**
- `BEFORE`: trigger รันก่อน row ถูกเขียนจริง — ถ้า abort, propagation จะผิด
- `AFTER`: รันหลัง commit ของ row ปัจจุบัน → safer สำหรับ side effects

**Performance impact:**
- Update foods 1 row → cascade UPDATE ทุก row ใน `detail_items` ที่ `food_id` ตรง
- ถ้าอาหารนี้มี logging history เยอะ (เช่น "ข้าวสวย" มี 100K rows) — query นี้จะนาน
- **Mitigation:** มี `INDEX foods_food_id` (PK) อยู่แล้ว และ `detail_items.food_id` ก็ควรมี index — ตรวจสอบใน v11 indexes

---

## ผลรวมหลัง v20–v24

### Schema cleangoal เปลี่ยนแปลง

**เพิ่ม:**
- ENUM `thai_region`
- 3 ตารางใหม่: `food_regional_names`, `food_regional_popularity`, `food_regional_name_submissions`
- 2 columns ใน `users`: `region`, `region_source`
- 4 columns `updated_at` ใน `detail_items`, `daily_summaries`, `exercise_logs`, `meals`
- 5 triggers: `trg_*_updated_at` (4 ตัว) + `trg_foods_sync_detail_items`
- 2 trigger functions: `fn_set_updated_at()`, `fn_sync_detail_items_from_foods()`

**ลบ:**
- 2 columns: `foods.food_category`, `foods.serving_unit`
- 3 ตาราง: `food_requests`, `food_ingredients`, `ingredients` (archive ไว้ใน `*_archive`)

### Backend code ที่ตามไปแก้

- `app/routers/foods.py` — search query รวม `food_regional_names`, endpoint `/foods/{id}/regional-names`
- `app/routers/users.py` — `GET/PUT /users/{id}/region`, ลบ `food_requests` จาก OWNED_TABLES
- `app/routers/admin.py` — `/admin/regional-name-submissions` GET/approve/reject, ลบ `/admin/food-requests`
- `app/models/schemas.py` — `ThaiRegion`, `UserRegionUpdate`, `RegionalNameSubmission`, `RegionalNameApprove`

### Flutter code ที่ตามไปแก้

- `setting_screen.dart` — region picker UI + persist
- `recommend_food_screen.dart`, `record_food_screen.dart`, `recipe_detail_screen.dart` — อ่าน `display_name` จาก response

---

## สิ่งที่ยังไม่ได้ทำ (Phase 4)

**v23 — Split `detail_items` polymorphism** ยังเป็น optional/pending

ปัจจุบัน `detail_items` มีคอลัมน์ FK 3 ตัวที่ exclusive (CHECK บังคับเลือก 1):
- `meal_id` — ใช้จริง (8 จุดใน meals.py)
- `plan_id` — ไม่มี router ใช้
- `summary_id` — ไม่มี router ใช้

**แผน:** แยกเป็น 3 ตาราง — `meal_items`, `meal_plan_items`, `daily_summary_items`

**Risk:** ต้อง rewrite SQL ใน 3 routers (meals, insights, users) + trigger `fn_sync_daily_summary` + เทสครบทุก meal-logging flow → จะทำหลัง v20–v24 stable บน production แล้ว

---

## Rollback แต่ละ migration

ทุก migration มีคำแนะนำ ROLLBACK ใน comment ท้ายไฟล์ — เช่น v22:

```sql
-- ROLLBACK:
-- BEGIN;
-- CREATE TABLE cleangoal.food_requests AS SELECT * FROM cleangoal.food_requests_archive;
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v22_drop_unused_tables';
-- COMMIT;
```

> **ข้อจำกัด:** v21 (drop columns) rollback ได้แค่ schema — **ข้อมูล** ใน column ที่ drop ไปแล้วหายถาวร (ต้อง restore จาก Supabase PITR backup) ดังนั้นทดสอบบน staging ก่อน apply production

---

## References

- [v20 migration](../backend/migrations/v20_regional_names_and_user_region.sql)
- [v21 migration](../backend/migrations/v21_drop_foods_legacy_columns.sql)
- [v22 migration](../backend/migrations/v22_drop_unused_tables.sql)
- [v24 migration](../backend/migrations/v24_audit_columns_and_sync_triggers.sql)
- [SUPABASE_3NF_AUDIT_2026_04_24.md](SUPABASE_3NF_AUDIT_2026_04_24.md) — audit ที่ทำให้เห็นว่าควรปรับอะไร
- [DATA_DICTIONARY.md](DATA_DICTIONARY.md) — schema ปัจจุบันแบบเต็ม

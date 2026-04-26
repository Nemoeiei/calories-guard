# Calories Guard — Data Dictionary (ฉบับสมบูรณ์)

**Schema:** `cleangoal` (PostgreSQL บน Supabase)
**Migrations Applied:** v8 → v24 (+ `add_target_macros_to_users.sql`) — เลขเวอร์ชัน v23 ข้ามไป (ไม่เคยเขียน)
**อัปเดตล่าสุด:** 2026-04-26
**ภาษา:** ไทย (เอกสารอธิบาย) / อังกฤษ (ชื่อตารางและ identifier)

เอกสารนี้รวม 2 ส่วน:
1. **เหตุผลของการปรับโครงสร้าง** — ทำไมจึงต้องลบและแยกตาราง
2. **Data Dictionary แบบละเอียด** — ทุกตารางในสถานะปัจจุบัน + ทุกคอลัมน์ + index + RLS + trigger

---

## สารบัญ

- [Part A — เหตุผลของการปรับโครงสร้าง](#part-a--เหตุผลของการปรับโครงสร้าง)
  - [A.1 ทำไมต้องลบตาราง](#a1-ทำไมต้องลบตาราง)
  - [A.2 ทำไมต้องลบคอลัมน์](#a2-ทำไมต้องลบคอลัมน์)
  - [A.3 ทำไมต้องแยกตารางใหม่](#a3-ทำไมต้องแยกตารางใหม่)
  - [A.4 ทำไมต้องเพิ่ม audit + sync trigger](#a4-ทำไมต้องเพิ่ม-audit--sync-trigger)
  - [A.5 หนี้ทางเทคนิคที่ยังเหลือ (Phase 4)](#a5-หนี้ทางเทคนิคที่ยังเหลือ-phase-4)
- [Part B — Data Dictionary](#part-b--data-dictionary)
  - [1. Identity & Authentication](#1-identity--authentication)
  - [2. Food Catalog & Taxonomy](#2-food-catalog--taxonomy)
  - [3. Recipes & Social Features](#3-recipes--social-features)
  - [4. Meal Logging & Daily Tracking](#4-meal-logging--daily-tracking)
  - [5. Goals & Activity Management](#5-goals--activity-management)
  - [6. User Preferences & Health](#6-user-preferences--health)
  - [7. Admin & Regional Data](#7-admin--regional-data)
  - [8. Archive Tables](#8-archive-tables)
  - [9. Infrastructure](#9-infrastructure)
- [Part C — ENUMs, Triggers, RLS Summary](#part-c--enums-triggers-rls-summary)

---

# Part A — เหตุผลของการปรับโครงสร้าง

## A.1 ทำไมต้องลบตาราง

| ตารางที่ลบ | ลบที่ migration | เหตุผล | แทนที่ด้วย | Archive |
|---|---|---|---|---|
| `food_requests` | v22 | Superseded — pattern เดิมที่รับคำขออาหารจากผู้ใช้ ถูกแทนด้วยคู่ `temp_food` + `verified_food` ที่มี trigger auto-create และมี view `v_admin_temp_food_review` รองรับ admin moderation อยู่แล้ว ไม่มี router อ้างถึงแล้ว | `temp_food` + `verified_food` (v13) | `food_requests_archive` |
| `food_ingredients` | v22 | Orphan — ไม่มี router หรือ service อ้างถึง การเก็บส่วนประกอบของอาหารใช้ `recipe_ingredients` (ผูกกับ `recipes` ตามรูปแบบ 1 recipe → many ingredients) แทนทั้งหมด | `recipe_ingredients` | `food_ingredients_archive` |
| `ingredients` | v22 | Orphan — เคยมีไว้รองรับ `food_ingredients` แต่เมื่อ `food_ingredients` ไม่ได้ใช้แล้ว `ingredients` จึงไม่มีผู้บริโภค | (ไม่มี) | `ingredients_archive` |
| `user_goals` | v14_c | Denormalize — ผู้ใช้ 1 คนมีเป้าหมาย active อย่างเดียว การเก็บใน sub-table ทำให้ต้อง JOIN ตลอด ย้ายฟิลด์ทั้งหมด (`goal_type`, `target_weight_kg`, `target_calories`, `goal_start_date`, `goal_target_date`) เข้าไปใน `users` ตรง ๆ | คอลัมน์ใน `users` | (ไม่มี) |
| `user_activities` | v14_c | Denormalize เช่นเดียวกัน — ผู้ใช้ 1 คนมี activity_level เดียว ย้ายเป็นคอลัมน์ใน `users` | `users.activity_level` | (ไม่มี) |
| `progress` | v14_f | Redundant — น้ำหนักเก็บใน `weight_logs`, สรุปแคลอรี/มาโครเก็บใน `daily_summaries` อยู่แล้ว `progress` เป็นการเก็บซ้ำ | `weight_logs` + `daily_summaries` | (ไม่มี) |
| `weekly_summaries` | v14_f | Pre-computed → on-demand — สามารถคำนวณจาก `daily_summaries` ได้เร็วพอ ไม่จำเป็นต้องเก็บล่วงหน้า ลดความเสี่ยงข้อมูลไม่ตรงกัน | endpoint `/insights` คำนวณ on-demand | (ไม่มี) |
| `chat_messages` | v14_f | Out of scope — AI coach (Gemini) ไม่ persist conversation history ใน production | (ไม่มี) | (ไม่มี) |
| `user_health_content_views` | v14_f | Never used — ตาราง analytics ที่วางไว้แต่ไม่มี endpoint ใดเขียนลง ลบเพื่อลด noise | (ไม่มี) | (ไม่มี) |

**หลักการเลือก archive vs ลบเลย:**
- **Archive** เมื่อมีโอกาสมีข้อมูลผู้ใช้จริงที่อาจต้องกู้คืน → v22 archive ทั้ง 3 ตารางก่อน drop
- **ลบเลย** เมื่อยืนยันแล้วว่า table ว่าง / ไม่เคยถูกเขียน หรือข้อมูลซ้ำกับตารางอื่น → v14_c, v14_f

---

## A.2 ทำไมต้องลบคอลัมน์

### v21 — `foods.food_category` และ `foods.serving_unit`

ทั้งสองคอลัมน์เป็น **VARCHAR ที่ซ้ำกับ FK columns** ที่เพิ่มใน v18:

```
foods.food_category  (VARCHAR)  ←  ซ้ำกับ  →  foods.dish_id (FK → dishes)
foods.serving_unit   (VARCHAR)  ←  ซ้ำกับ  →  foods.serving_unit_id (FK → units)
```

**ปัญหา 3NF:**
- ชื่อหมวดหมู่ ("Thai", "ไทย", "Thai Food") เก็บแบบสตริงในแต่ละแถว → typo / ตัวพิมพ์เล็กใหญ่ทำให้กรองพลาด
- เปลี่ยนชื่อหมวดต้อง UPDATE ทุก row ของ `foods` แทนที่จะแก้แค่ `dishes.dish_category_id`
- หน่วยบริโภค ("g", "กรัม", "G") ก็มีปัญหาเดียวกัน

**การแก้ (v18 → v21):**
1. v18 สร้าง `dishes` และ backfill `foods.dish_id` จากค่าเดิมของ `food_category`
2. v18 backfill `foods.serving_unit_id` จากชื่อหน่วยใน `serving_unit`
3. v21 drop คอลัมน์ VARCHAR ทั้งสอง (หลังตรวจว่า backend และ Flutter ไม่อ่านแล้ว)

**Pre-flight check ที่รันก่อน drop:**
```sql
SELECT COUNT(*) FROM cleangoal.foods WHERE dish_id IS NULL;          -- expect 0
SELECT COUNT(*) FROM cleangoal.foods WHERE serving_unit_id IS NULL;  -- expect 0
```

### v14_a — orphan `item_id` columns

`meals.item_id`, `daily_summaries.item_id`, `user_meal_plans.item_id` เป็น **คอลัมน์ที่ตั้งใจจะเป็น FK แต่ไม่เคยมี FK constraint** และไม่เคยถูกเขียนค่าจริง — เป็นซากการออกแบบเก่าที่ถูกแทนด้วยตาราง `detail_items` (1 row ต่อ item ใน meal/plan/summary).

---

## A.3 ทำไมต้องแยกตารางใหม่

### v18 — แยก `dishes` และ `dish_categories` ออกจาก `foods`

**Before (v17 และก่อนหน้า):**
```
foods (food_id, food_name, food_category VARCHAR, ...)
```
หมวดหมู่อาหารฝังเป็นสตริง → ไม่มี taxonomy ที่ search/filter ได้แม่นยำ.

**After (v18):**
```
dish_categories (dish_category_id, category_name, canonical_food_type, display_order)
   ↓ FK
dishes (dish_id, dish_name, dish_category_id, cuisine, ...)
   ↓ FK
foods (food_id, food_name, dish_id, ...)
```
- 1 หมวดหมู่ → many เมนู (dishes) → many อาหาร (foods) แบบ proper 3NF
- รองรับ multi-language ในอนาคตได้ง่าย (เพิ่ม `dish_category_name_translations` ได้)

### v20 — แยกชื่อภูมิภาคออกจาก `foods.food_name`

**Problem:** "ขนมจีน" (กลาง) = "ข้าวปุ้น" (อีสาน) = "ขนมเส้น" (เหนือ) — เป็นอาหารตัวเดียวกันแต่ผู้ใช้แต่ละภาคเรียกต่างกัน. ถ้าเก็บแค่ `food_name` ผู้ใช้อีสานพิมพ์ "ข้าวปุ้น" แล้ว search ไม่เจอ.

**Solution (v20):** สร้าง 3 ตารางใหม่:

```
food_regional_names           — 1 food → many alt names per region (มี is_primary)
food_regional_popularity      — popularity 1-5 ต่อ (food, region)
food_regional_name_submissions — pending review (mirror pattern temp_food)
```

ที่เพิ่มใน `users` ด้วย:
- `users.region` (ENUM `thai_region`)
- `users.region_source` (manual/auto_ip/unset)

**Search query หลังการแยก:**
```sql
SELECT f.*, COALESCE(frn_user.name_th, f.food_name) AS display_name
FROM foods f
LEFT JOIN food_regional_names frn_user
  ON frn_user.food_id = f.food_id
 AND frn_user.region = $user_region
 AND frn_user.is_primary
WHERE f.food_name ILIKE $q
   OR EXISTS (SELECT 1 FROM food_regional_names WHERE ...)
```

### v17 — แยก `recipes` ออกจาก `foods` (1:1) + แยก orphan reviews

ก่อน v17 `recipes` กับ `foods` ไม่มี clear FK และมี review ที่ผูกกับ `food_id` ตรง ๆ. v17 ทำ:
1. เพิ่ม `recipes.food_id UNIQUE` (1:1 ระหว่าง food กับ recipe)
2. ย้าย `recipe_reviews` ให้อ้าง `recipe_id` แทน `food_id`
3. Archive review ที่หา recipe matching ไม่ได้ลง `recipe_reviews_orphan_archive`

### v13 — แยก `verified_food` ออกจาก `temp_food`

**Why:** Single Responsibility. `temp_food` เก็บข้อมูล user input, `verified_food` เก็บสถานะ admin moderation (verified by, verified at). ถ้ารวมในตารางเดียว → ไม่สามารถสร้าง view สำหรับ admin ได้ง่าย และ RLS policy จะซับซ้อน (admin column ต้อง read แต่ user เขียนไม่ได้).

---

## A.4 ทำไมต้องเพิ่ม audit + sync trigger

### v24 — เพิ่ม `updated_at` กับ 4 ตาราง

ตารางที่มีแค่ `created_at` ทำให้ debug ปัญหา data drift ยาก: ไม่รู้ว่า row ถูกแก้เมื่อไร ใครแก้.

เพิ่ม `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` + BEFORE UPDATE trigger ใน:
- `detail_items`
- `daily_summaries`
- `exercise_logs`
- `meals`

Trigger ใช้ฟังก์ชันกลาง `cleangoal.fn_set_updated_at()` (SECURITY DEFINER, search_path pinned).

### v24 — เพิ่ม sync trigger จาก `foods` → `detail_items`

**Problem:** `detail_items` cache ค่า nutrition (`food_name`, `cal_per_unit`, `protein_per_unit`, `carbs_per_unit`, `fat_per_unit`) จาก `foods` เพื่อ:
- Snapshot ค่าตอน log meal — เผื่อ admin แก้ `foods` ภายหลัง user ยังเห็นค่าเก่า
- ลด JOIN cost ตอนคำนวณ daily summary

**แต่ก่อนหน้านี้ไม่มี mechanism sync** → ถ้า admin แก้แคลอรีของ "ส้มตำ" ใน `foods`, รายการ "ส้มตำ" ใน `detail_items` ของ user จะไม่เปลี่ยน (stale cache).

**Solution (v24):** AFTER UPDATE trigger บน `foods`:
```sql
IF (NEW.food_name IS DISTINCT FROM OLD.food_name
 OR NEW.calories  IS DISTINCT FROM OLD.calories
 OR NEW.protein   IS DISTINCT FROM OLD.protein
 OR NEW.carbs     IS DISTINCT FROM OLD.carbs
 OR NEW.fat       IS DISTINCT FROM OLD.fat) THEN
    UPDATE cleangoal.detail_items
       SET food_name        = NEW.food_name,
           cal_per_unit     = NEW.calories,
           protein_per_unit = NEW.protein,
           carbs_per_unit   = NEW.carbs,
           fat_per_unit     = NEW.fat,
           updated_at       = NOW()
     WHERE food_id = NEW.food_id;
END IF;
```

ใช้ `IS DISTINCT FROM` เพื่อ NULL-safe comparison.

---

## A.5 หนี้ทางเทคนิคที่ยังเหลือ (Phase 4)

### `detail_items` polymorphism

ตอนนี้ `detail_items` มี 3 FK columns ที่ exclusive:
```
detail_items.meal_id     → meals(meal_id)
detail_items.plan_id     → user_meal_plans(plan_id)
detail_items.summary_id  → daily_summaries(summary_id)
```
+ CHECK constraint บังคับให้มี **1 ตัวเท่านั้น** ที่ไม่ NULL.

**ปัญหา 2NF:** row นี้มี 3 ความหมายขึ้นกับว่า column ไหนตั้ง — เป็น polymorphic FK anti-pattern.

**แผนแก้ (Phase 4 — DEFERRED):**
แยกเป็น 3 ตาราง:
```
meal_items          (item_id, meal_id FK, food_id, ...)
meal_plan_items     (item_id, plan_id FK, food_id, ...)
daily_summary_items (item_id, summary_id FK, ...)
```

**Blast radius:** 4 routers (`meals.py`, `users.py`, `insights.py`, `social.py`) + trigger `fn_sync_daily_summary` + Flutter screens. ประเมิน ~6 ชั่วโมง. รอ user approve หลัง v22+v24 deploy stable.

---

# Part B — Data Dictionary

## วิธีอ่านส่วน Data Dictionary

แต่ละตารางมีหัวข้อย่อย:
- **Purpose** — ใช้ทำอะไร
- **Columns** — ตารางคอลัมน์ครบทุกฟิลด์
- **Indexes** — ทุก index รวม partial/expression
- **Constraints** — UNIQUE, CHECK, FK
- **RLS** — Row Level Security policy
- **Soft Delete** — มี `deleted_at` หรือไม่
- **Audit** — มี `created_at` / `updated_at` หรือไม่
- **Triggers** — trigger ที่ผูกกับ table นี้
- **Dropped columns** (ถ้ามี) — คอลัมน์ที่เคยมีแต่ลบไป

ใน Columns table:
- `Type` — PostgreSQL type
- `NN` — Not Null (✓ = NOT NULL, — = nullable)
- `Default` — ค่า default
- `FK/Constraint` — foreign key + check
- `อธิบาย` — ความหมายภาคปฏิบัติ

---

# 1. Identity & Authentication

## 1.1 `roles`
**Purpose:** ลิสต์บทบาท (admin / user) สำหรับ authorization
**Thai:** ระดับสิทธิ์ของผู้ใช้

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| role_id | SERIAL | ✓ | (auto) | PK | รหัสบทบาท |
| role_name | VARCHAR(30) | ✓ | — | UNIQUE | ชื่อบทบาท ("admin", "user") |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `public_read` (SELECT only)
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —

---

## 1.2 `users`
**Purpose:** Identity หลัก + เป้าหมายโภชนาการ + profile
**Thai:** บัญชีผู้ใช้

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| user_id | BIGSERIAL | ✓ | (auto) | PK | รหัสผู้ใช้ |
| username | VARCHAR(50) | — | — | — | ชื่อแสดงใน UI |
| email | VARCHAR(255) | ✓ | — | UNIQUE | อีเมล (ใช้ login) |
| password_hash | VARCHAR(255) | ✓ | — | — | bcrypt hash |
| gender | gender_type | — | — | CHECK male/female | เพศ (ใช้คำนวณ BMR) |
| birth_date | DATE | — | — | — | วันเกิด |
| height_cm | DECIMAL(5,2) | — | — | CHECK 80–250 | ส่วนสูง (ซม.) |
| current_weight_kg | DECIMAL(5,2) | — | — | CHECK 20–300 | น้ำหนักปัจจุบัน (กก.) |
| goal_type | goal_type_enum | — | — | CHECK lose_weight/maintain_weight/gain_muscle | เป้าหมาย |
| target_weight_kg | DECIMAL(5,2) | — | — | CHECK 20–300 | น้ำหนักเป้าหมาย |
| target_calories | INT | — | — | CHECK 500–6000 | แคลอรีเป้าหมาย/วัน |
| target_protein | INT | — | — | — | โปรตีนเป้าหมาย/วัน (กรัม) |
| target_carbs | INT | — | — | — | คาร์บเป้าหมาย/วัน (กรัม) |
| target_fat | INT | — | — | — | ไขมันเป้าหมาย/วัน (กรัม) |
| activity_level | activity_level | — | — | CHECK sedentary/lightly_active/moderately_active/very_active | ระดับกิจกรรม |
| goal_start_date | DATE | — | CURRENT_DATE | — | วันเริ่มเป้าหมาย |
| goal_target_date | DATE | — | — | — | วันเป้าหมายสำเร็จ |
| last_kpi_check_date | DATE | — | CURRENT_DATE | — | วันเช็ค KPI ล่าสุด |
| current_streak | INT | — | 0 | CHECK ≥0 | streak ปัจจุบัน (วัน) |
| last_login_date | TIMESTAMPTZ | — | — | — | เวลาเข้าระบบล่าสุด |
| total_login_days | INT | — | 0 | CHECK ≥0 | จำนวนวันที่ใช้งานทั้งหมด |
| avatar_url | VARCHAR(500) | — | — | — | URL รูปโปรไฟล์ |
| role_id | INT | — | 2 | FK → roles | บทบาท (default = "user") |
| is_email_verified | BOOLEAN | — | FALSE | — | ยืนยันอีเมลแล้วหรือยัง |
| consent_accepted_at | TIMESTAMPTZ | — | — | — | เวลายอมรับ PDPA (NULL = ยังไม่ยอม) |
| **region** | **thai_region** | — | — | CHECK central/northern/northeastern/southern | **(v20)** ภาคที่ผู้ใช้ระบุ |
| **region_source** | **VARCHAR(20)** | ✓ | 'unset' | CHECK unset/manual/auto_ip | **(v20)** ที่มาของค่า region |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | เวลาสร้างบัญชี |
| updated_at | TIMESTAMPTZ | — | — | — | เวลาแก้ไขล่าสุด |
| deleted_at | TIMESTAMPTZ | — | — | — | soft delete (PDPA: เก็บ 30 วัน) |

- **Indexes:**
  - PRIMARY KEY (user_id)
  - `idx_users_email (email) WHERE deleted_at IS NULL`
  - `users_deleted_at_idx (deleted_at) WHERE deleted_at IS NOT NULL`
  - **`idx_users_region (region) WHERE region IS NOT NULL AND deleted_at IS NULL`** (v20)
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** YES (`deleted_at`)
- **Audit:** `created_at`, `updated_at`, `deleted_at`
- **Triggers:** Supabase Auth trigger `public.handle_new_user()` (fires บน auth.users insert)

---

## 1.3 `password_reset_codes`
**Purpose:** โค้ดรีเซ็ตรหัสผ่าน

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | เจ้าของ |
| code | VARCHAR(10) | ✓ | — | — | โค้ด 10 ตัวอักษร |
| expires_at | TIMESTAMPTZ | ✓ | — | — | หมดอายุ (~24 ชม.) |
| used | BOOLEAN | ✓ | FALSE | — | ใช้ไปแล้วหรือยัง |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | เวลาออกโค้ด |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at` only
- **Triggers:** —

---

## 1.4 `email_verification_codes`
**Purpose:** โค้ดยืนยันอีเมลตอน signup

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | เจ้าของ |
| code | VARCHAR(10) | ✓ | — | — | โค้ด 10 ตัวอักษร |
| expires_at | TIMESTAMPTZ | ✓ | — | — | หมดอายุ (~48 ชม.) |
| used | BOOLEAN | ✓ | FALSE | — | ใช้ไปแล้วหรือยัง |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | เวลาออกโค้ด |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at` only
- **Triggers:** —

---

# 2. Food Catalog & Taxonomy

## 2.1 `units`
**Purpose:** หน่วยวัด (g, kg, ml, ช้อนชา, ถ้วย, ฯลฯ)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| unit_id | SERIAL | ✓ | (auto) | PK | |
| name | VARCHAR(30) | ✓ | — | UNIQUE on lower(name) | ชื่อหน่วย |
| quantity | DECIMAL(10,4) | — | — | — | conversion factor (เช่น kg = 1000 ของ g) |

- **Indexes:** PRIMARY KEY, `units_name_lower_uq (lower(name))`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —
- **Seeded Data (v14_d):** 15 หน่วยมาตรฐาน — g, kg, ml, l, mg, tsp, tbsp, cup, oz, piece, serving, slice, bowl, plate, glass, set

---

## 2.2 `unit_conversions`
**Purpose:** การแปลงข้ามหน่วย (เช่น kg → g, ช้อนโต๊ะ → กรัม)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| conversion_id | SERIAL | ✓ | (auto) | PK | |
| from_unit_id | INT | ✓ | — | FK → units ON DELETE CASCADE | หน่วยต้นทาง |
| to_unit_id | INT | ✓ | — | FK → units ON DELETE CASCADE | หน่วยปลายทาง |
| factor | DECIMAL(10,4) | ✓ | — | — | from × factor = to |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** `idx_unit_conversions_from_unit`, `idx_unit_conversions_to_unit`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —
- **Seeded Data:** 5 การแปลงพื้นฐาน — kg↔g, l↔ml, tbsp→g, tsp→g, cup→ml

---

## 2.3 `dish_categories` (v18)
**Purpose:** หมวดหมู่ระดับสูงของเมนู (อาหารไทย, อาหารตะวันตก, ฯลฯ)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| dish_category_id | BIGSERIAL | ✓ | (auto) | PK | |
| category_name | VARCHAR(120) | ✓ | — | UNIQUE (category_name, canonical_food_type) | ชื่อหมวด |
| canonical_food_type | food_type | — | — | — | ผูกกับชนิดอาหาร (raw_ingredient/recipe_dish) |
| description | TEXT | — | — | — | คำอธิบาย |
| display_order | INT | ✓ | 0 | — | ลำดับแสดงผลใน UI |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 2.4 `dishes` (v18)
**Purpose:** เมนูที่ normalize แล้ว — ผูกกับ category

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| dish_id | BIGSERIAL | ✓ | (auto) | PK | |
| dish_name | VARCHAR(200) | ✓ | — | UNIQUE (dish_name, dish_category_id) | ชื่อเมนู |
| dish_category_id | BIGINT | ✓ | — | FK → dish_categories ON DELETE RESTRICT | หมวด |
| canonical_food_type | food_type | — | — | — | ชนิด |
| cuisine | VARCHAR(80) | — | — | — | ครัว (ไทย, ตะวันตก, ฯลฯ) |
| description | TEXT | — | — | — | |
| image_url | VARCHAR(500) | — | — | — | รูป |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| updated_at | TIMESTAMPTZ | — | — | — | |
| deleted_at | TIMESTAMPTZ | — | — | — | soft delete |

- **Indexes:** PRIMARY KEY, `idx_dishes_category (dish_category_id)`, `idx_dishes_name_lower (lower(dish_name))`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** YES
- **Audit:** `created_at`, `updated_at`, `deleted_at`
- **Triggers:** —

---

## 2.5 `foods`
**Purpose:** Master catalog ของอาหารทั้งหมด (ทั้งวัตถุดิบดิบและเมนูสำเร็จ)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| food_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_name | VARCHAR(200) | ✓ | — | — | ชื่อ canonical (ภาคกลาง) |
| food_type | food_type | — | 'raw_ingredient' | CHECK raw_ingredient/recipe_dish | ชนิด |
| calories | DECIMAL(6,2) | — | — | CHECK ≥0 | kcal ต่อ serving |
| protein | DECIMAL(6,2) | — | — | CHECK ≥0 | g ต่อ serving |
| carbs | DECIMAL(6,2) | — | — | CHECK ≥0 | g ต่อ serving |
| fat | DECIMAL(6,2) | — | — | CHECK ≥0 | g ต่อ serving |
| sodium | DECIMAL(6,2) | — | — | — | mg ต่อ serving |
| sugar | DECIMAL(6,2) | — | — | — | g ต่อ serving |
| cholesterol | DECIMAL(6,2) | — | — | — | mg ต่อ serving |
| serving_quantity | DECIMAL(6,2) | — | 100 | CHECK >0 | ขนาด serving |
| serving_unit_id | INT | — | — | FK → units ON DELETE SET NULL | หน่วย serving |
| dish_id | BIGINT | — | — | FK → dishes ON DELETE SET NULL | เมนู (v18) |
| image_url | VARCHAR(500) | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| updated_at | TIMESTAMPTZ | — | — | — | |
| deleted_at | TIMESTAMPTZ | — | — | — | soft delete |

- **Indexes:**
  - PRIMARY KEY
  - `idx_foods_name_lower (lower(food_name))`
  - `idx_foods_not_deleted (food_id) WHERE deleted_at IS NULL`
  - `idx_foods_serving_unit_id`
  - `idx_foods_dish_id`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** YES
- **Audit:** `created_at`, `updated_at`, `deleted_at`
- **Triggers:** **`trg_foods_sync_detail_items` (AFTER UPDATE)** — v24 ส่งค่าใหม่ไป sync `detail_items.food_name/cal_per_unit/protein_per_unit/carbs_per_unit/fat_per_unit`
- **Dropped Columns (v21):**
  - ~~`food_category VARCHAR`~~ → แทนด้วย `dish_id` → `dishes`
  - ~~`serving_unit VARCHAR`~~ → แทนด้วย `serving_unit_id` → `units`

---

## 2.6 `allergy_flags`
**Purpose:** ลิสต์สารก่อภูมิแพ้ที่ระบบรู้จัก

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| flag_id | SERIAL | ✓ | (auto) | PK | |
| name | VARCHAR(150) | ✓ | — | — | ชื่อ allergen (peanuts, shellfish, milk, ฯลฯ) |
| description | TEXT | — | — | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —

---

## 2.7 `user_allergy_preferences`
**Purpose:** allergen ที่ผู้ใช้ตั้งไว้

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| user_id | BIGINT | ✓ | — | PK + FK → users ON DELETE CASCADE | |
| flag_id | INT | ✓ | — | PK + FK → allergy_flags ON DELETE CASCADE | |
| preference_type | VARCHAR(50) | — | — | — | avoid / warn / prefer |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY (user_id, flag_id), `idx_allergy_prefs_user (user_id)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 2.8 `food_allergy_flags`
**Purpose:** จับคู่ many-to-many ระหว่างอาหารกับสารก่อภูมิแพ้

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| food_id | BIGINT | ✓ | — | PK + FK → foods ON DELETE CASCADE | |
| flag_id | INT | ✓ | — | PK + FK → allergy_flags ON DELETE CASCADE | |

- **Indexes:** PRIMARY KEY (food_id, flag_id)
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —

---

## 2.9 `beverages`
**Purpose:** Metadata เฉพาะของเครื่องดื่ม (1:1 กับ `foods`)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| beverage_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_id | BIGINT | ✓ | — | UNIQUE + FK → foods ON DELETE CASCADE | |
| volume_ml | DECIMAL(6,2) | — | — | — | ปริมาตรมาตรฐาน |
| is_alcoholic | BOOLEAN | — | FALSE | — | มีแอลกอฮอล์ |
| caffeine_mg | DECIMAL(6,2) | — | 0 | — | คาเฟอีน |
| sugar_level_label | VARCHAR(50) | — | — | — | none / low / medium / high |
| container_type | VARCHAR(50) | — | — | — | can / bottle / carton / glass |

- **Indexes:** PRIMARY KEY, UNIQUE (food_id)
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —

---

## 2.10 `snacks`
**Purpose:** Metadata เฉพาะของของกินเล่น (1:1 กับ `foods`)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| snack_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_id | BIGINT | ✓ | — | UNIQUE + FK → foods ON DELETE CASCADE | |
| is_sweet | BOOLEAN | — | TRUE | — | หวาน vs เค็ม |
| packaging_type | VARCHAR(50) | — | — | — | bag / box / wrapper |
| trans_fat | DECIMAL(6,2) | — | — | — | g ต่อ serving |

- **Indexes:** PRIMARY KEY, UNIQUE (food_id)
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** —
- **Triggers:** —

---

# 3. Recipes & Social Features

## 3.1 `recipes`
**Purpose:** สูตรอาหารพร้อมข้อมูล AI generation

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| recipe_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_id | BIGINT | ✓ | — | UNIQUE + FK → foods ON DELETE CASCADE | 1:1 กับ foods |
| description | TEXT | — | — | — | |
| instructions | TEXT | — | — | — | คำอธิบายแบบ free text |
| prep_time_minutes | INT | — | 0 | — | เวลาเตรียม |
| cooking_time_minutes | INT | — | 0 | — | เวลาทำ |
| serving_people | DECIMAL(3,1) | — | 1.0 | — | เสิร์ฟกี่คน |
| source_reference | VARCHAR(500) | — | — | — | URL หรือเครดิตแหล่ง |
| image_url | VARCHAR(500) | — | — | — | |
| ingredients_json | JSONB | — | — | — | (v16_a) AI-generated structured ingredients |
| tools_json | JSONB | — | — | — | (v16_a) AI-generated tools |
| tips_json | JSONB | — | — | — | (v16_a) AI-generated tips |
| generated_by | VARCHAR(32) | — | — | — | (v16_a) seed / gpt-4 / llm-name |
| favorite_count | INT | ✓ | 0 | — | (v18) denormalized count |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| deleted_at | TIMESTAMPTZ | — | — | — | soft delete |

- **Indexes:** PRIMARY KEY, `recipes_food_id_uq (food_id)`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** YES
- **Audit:** `created_at`
- **Triggers:** `update_recipe_favorite_count()` (อัปเดต `favorite_count` เมื่อ `recipe_favorites` เปลี่ยน)

---

## 3.2 `recipe_ingredients`
**Purpose:** วัตถุดิบของสูตร

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| ing_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| ingredient_name | VARCHAR(200) | — | — | — | ชื่อ (free text) |
| amount | DECIMAL(6,2) | — | — | — | ปริมาณ |
| unit_id | INT | — | — | FK → units ON DELETE SET NULL | หน่วย |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** `idx_recipe_ingredients_recipe (recipe_id)`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 3.3 `recipe_steps`
**Purpose:** ขั้นตอนการปรุง

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| step_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| step_number | INT | — | — | — | ลำดับขั้น |
| instruction | TEXT | — | — | — | คำอธิบายขั้น |
| duration_minutes | INT | — | — | — | ระยะเวลา |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY (recipe_id index assumed)
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 3.4 `recipe_tips`
**Purpose:** เคล็ดลับ/ข้อแนะนำของสูตร

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| tip_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| tip_text | TEXT | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** `idx_recipe_tips_recipe (recipe_id)`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 3.5 `recipe_tools`
**Purpose:** อุปกรณ์ทำอาหาร

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| tool_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| tool_name | VARCHAR(120) | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 3.6 `recipe_reviews`
**Purpose:** ความเห็น/คะแนนของผู้ใช้ต่อสูตร

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| review_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| rating | SMALLINT | — | — | CHECK 1–5 | |
| comment | TEXT | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY, `recipe_reviews_recipe_user_uq (recipe_id, user_id)`, `recipe_reviews_recipe_created_idx (recipe_id, created_at DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** `update_recipe_rating()` — aggregate rating
- **Note:** v17 ย้ายจาก food_id → recipe_id; orphan ที่หา recipe ไม่เจอเก็บใน `recipe_reviews_orphan_archive`

---

## 3.7 `recipe_favorites` *(legacy)*
**Purpose:** การ bookmark สูตร — **legacy, ไม่ใช้ใน mobile API ปัจจุบัน**

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| fav_id | BIGSERIAL | ✓ | (auto) | PK | |
| recipe_id | BIGINT | ✓ | — | FK → recipes ON DELETE CASCADE | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** UNIQUE (recipe_id, user_id)
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Triggers:** `update_recipe_favorite_count()` — sync `recipes.favorite_count`
- **Note:** Mobile API ใช้ `user_favorites(food_id)` แทน

---

## 3.8 `user_favorites`
**Purpose:** อาหารที่ผู้ใช้บันทึกเป็นรายการโปรด (active table)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| favorite_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| food_id | BIGINT | ✓ | — | FK → foods ON DELETE CASCADE | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** UNIQUE (user_id, food_id)
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

# 4. Meal Logging & Daily Tracking

## 4.1 `meals`
**Purpose:** บันทึกมื้ออาหาร (เช้า/กลางวัน/เย็น/snack)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| meal_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| meal_type | meal_type | ✓ | — | CHECK breakfast/lunch/dinner/snack | ประเภทมื้อ |
| meal_time | TIMESTAMPTZ | ✓ | NOW() | — | เวลากิน (Asia/Bangkok) |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| **updated_at** | TIMESTAMPTZ | ✓ | NOW() | — | **(v24)** |

- **Indexes:**
  - PRIMARY KEY
  - `idx_meals_user_date_type (user_id, (meal_time AT TIME ZONE 'Asia/Bangkok')::date, meal_type)`
  - `idx_meals_user_date (user_id, (meal_time AT TIME ZONE 'Asia/Bangkok')::date DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:**
  - `trg_sync_daily_summary` — sync ไปยัง `daily_summaries` (ผ่าน detail_items อีกที)
  - **`trg_meals_updated_at` (BEFORE UPDATE)** — v24 ตั้ง `updated_at`
- **Dropped Columns (v14_a):** ~~`item_id`~~ (orphan)

---

## 4.2 `detail_items` ⚠ *polymorphic*
**Purpose:** รายการอาหารแต่ละชิ้นใน meal / plan / summary

⚠ ตารางนี้เป็น **polymorphic** — มี FK 3 ตัวที่ exclusive (`meal_id` / `plan_id` / `summary_id`). Phase 4 จะแยกเป็น 3 ตาราง.

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| item_id | BIGSERIAL | ✓ | (auto) | PK | |
| meal_id | BIGINT | — | — | FK → meals ON DELETE CASCADE | parent meal |
| plan_id | BIGINT | — | — | FK → user_meal_plans ON DELETE CASCADE | parent plan |
| summary_id | BIGINT | — | — | FK → daily_summaries ON DELETE CASCADE | parent summary |
| food_id | BIGINT | — | — | FK → foods ON DELETE SET NULL | อาหารที่อ้าง |
| food_name | VARCHAR(200) | — | — | — | snapshot ชื่อ (cached) |
| day_number | INT | — | — | — | วันใน plan (ถ้าอยู่ใน plan) |
| amount | DECIMAL(8,2) | — | 1.0 | — | ปริมาณที่กิน |
| unit_id | INT | — | — | FK → units ON DELETE SET NULL | (v19) FK |
| cal_per_unit | DECIMAL(10,2) | — | — | — | snapshot kcal/unit |
| protein_per_unit | DECIMAL(8,2) | — | 0 | — | (v12) snapshot |
| carbs_per_unit | DECIMAL(8,2) | — | 0 | — | (v12) snapshot |
| fat_per_unit | DECIMAL(8,2) | — | 0 | — | (v12) snapshot |
| note | VARCHAR(500) | — | — | — | บันทึกผู้ใช้ |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| **updated_at** | TIMESTAMPTZ | ✓ | NOW() | — | **(v24)** |

- **Constraints (v14_b):** CHECK `(meal_id IS NOT NULL)::int + (plan_id IS NOT NULL)::int + (summary_id IS NOT NULL)::int = 1`
- **Indexes:**
  - PRIMARY KEY
  - `idx_detail_items_meal_id (meal_id)`
  - `idx_detail_items_food_id (food_id) WHERE food_id IS NOT NULL`
  - `idx_detail_items_unit_id (unit_id)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:**
  - `trg_sync_daily_summary` — recompute totals
  - **`trg_detail_items_updated_at`** — v24 ตั้ง updated_at

---

## 4.3 `daily_summaries`
**Purpose:** สรุปการบริโภคต่อวัน (เป้า + จริง)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| summary_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| date_record | DATE | ✓ | CURRENT_DATE | — | วันของสรุป |
| total_calories_intake | DECIMAL(10,2) | ✓ | 0 | CHECK ≥0 | kcal รวม |
| goal_calories | INT | — | — | — | snapshot จาก `users.target_calories` |
| is_goal_met | BOOLEAN | — | FALSE | — | บรรลุเป้าหรือไม่ |
| total_protein | NUMERIC | ✓ | 0 | CHECK ≥0 | (v8) g |
| total_carbs | NUMERIC | ✓ | 0 | CHECK ≥0 | (v8) g |
| total_fat | NUMERIC | ✓ | 0 | CHECK ≥0 | (v8) g |
| water_glasses | INTEGER | ✓ | 0 | CHECK 0–30 | (v8/v14_c) sync จาก water_logs |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| **updated_at** | TIMESTAMPTZ | ✓ | NOW() | — | **(v24)** |

- **Constraints:** UNIQUE `(user_id, date_record)` (`uq_daily_summaries_user_date`)
- **Indexes:** PRIMARY KEY, `idx_daily_summaries_user_date (user_id, date_record DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:**
  - `trg_sync_daily_summary` (บน detail_items) — คำนวณ total_*
  - `trg_sync_water_to_daily` (บน water_logs) — sync `water_glasses`
  - **`trg_daily_summaries_updated_at`** — v24
- **Dropped Columns (v14_a):** ~~`item_id`~~ (orphan)

---

## 4.4 `user_meal_plans`
**Purpose:** แผนมื้ออาหาร (system-defined หรือ user-created)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| plan_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | — | — | FK → users ON DELETE SET NULL | NULL = system plan |
| name | VARCHAR(200) | ✓ | — | — | ชื่อแผน |
| description | TEXT | — | — | — | |
| source_type | VARCHAR(30) | — | 'SYSTEM' | — | SYSTEM / USER_CREATED / AI_GENERATED |
| is_premium | BOOLEAN | — | FALSE | — | premium flag |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —
- **Dropped Columns (v14_a):** ~~`item_id`~~ (orphan)

---

# 5. Goals & Activity Management

## 5.1 `water_logs`
**Purpose:** บันทึกการดื่มน้ำต่อวัน

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| log_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| date_record | DATE | ✓ | CURRENT_DATE | — | |
| glasses | INTEGER | ✓ | 0 | CHECK 0–30 | (v9) จำนวนแก้ว (~250 ml/แก้ว) |
| updated_at | TIMESTAMPTZ | ✓ | NOW() | — | (v9) |

- **Constraints:** UNIQUE `(user_id, date_record)` (`uq_water_logs_user_date`)
- **Indexes:** PRIMARY KEY, `idx_water_logs_user_date (user_id, date_record DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `updated_at`
- **Triggers:** `trg_sync_water_to_daily` — sync ไปยัง `daily_summaries.water_glasses` (v14_c)

---

## 5.2 `weight_logs`
**Purpose:** บันทึกน้ำหนักเพื่อ track progress

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| log_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| weight_kg | DECIMAL(5,2) | ✓ | — | CHECK 20–300 | |
| recorded_date | DATE | ✓ | CURRENT_DATE | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Constraints:** UNIQUE `(user_id, recorded_date)`
- **Indexes:** PRIMARY KEY, `idx_weight_logs_user_date (user_id, recorded_date DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 5.3 `exercise_logs`
**Purpose:** บันทึกการออกกำลังกาย

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| log_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| date_record | DATE | ✓ | CURRENT_DATE | — | |
| activity_name | VARCHAR(100) | ✓ | — | — | ชื่อกิจกรรม |
| duration_minutes | INT | ✓ | 0 | CHECK 0–1440 | (v10) นาที |
| calories_burned | DECIMAL(8,2) | — | 0 | CHECK ≥0 | kcal เผาผลาญ |
| intensity | VARCHAR(20) | — | 'moderate' | CHECK low/moderate/high | (v10) |
| note | VARCHAR(255) | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| **updated_at** | TIMESTAMPTZ | ✓ | NOW() | — | **(v24)** |

- **Indexes:** PRIMARY KEY, `idx_exercise_logs_user_date (user_id, date_record DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:** **`trg_exercise_logs_updated_at`** (v24)

---

# 6. User Preferences & Health

## 6.1 `health_contents`
**Purpose:** บทความ/วิดีโอด้านสุขภาพ-โภชนาการ

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| content_id | BIGSERIAL | ✓ | (auto) | PK | |
| title | VARCHAR(200) | ✓ | — | — | |
| type | content_type | — | — | CHECK article/video | |
| thumbnail_url | VARCHAR(500) | — | — | — | |
| resource_url | VARCHAR(500) | — | — | — | |
| description | TEXT | — | — | — | |
| category_tag | VARCHAR(100) | — | — | — | nutrition / fitness / wellness |
| difficulty_level | VARCHAR(50) | — | — | — | beginner / intermediate / advanced |
| is_published | BOOLEAN | — | TRUE | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

## 6.2 `notifications`
**Purpose:** การแจ้งเตือนของระบบ/ความสำเร็จ

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| notification_id | BIGSERIAL | ✓ | (auto) | PK | |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | |
| title | VARCHAR(200) | ✓ | — | — | |
| message | TEXT | — | — | — | |
| type | notification_type | — | — | CHECK system_alert/achievement/content_update/system_announcement | |
| is_read | BOOLEAN | — | FALSE | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY, `idx_notifications_user_unread (user_id, is_read) WHERE is_read = FALSE`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`
- **Triggers:** —

---

# 7. Admin & Regional Data

## 7.1 `temp_food` (v13)
**Purpose:** อาหารที่ผู้ใช้เพิ่ม รอ admin verify

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| tf_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_name | VARCHAR(200) | ✓ | — | — | |
| protein | DECIMAL(6,2) | — | 0 | — | g |
| fat | DECIMAL(6,2) | — | 0 | — | g |
| carbs | DECIMAL(6,2) | — | 0 | — | g |
| calories | DECIMAL(6,2) | — | 0 | — | kcal |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | (v13) ผู้เสนอ |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| updated_at | TIMESTAMPTZ | — | — | — | |

- **Indexes:** PRIMARY KEY, `idx_temp_food_user_id (user_id)`, `idx_temp_food_created_at (created_at DESC)`
- **RLS:** ENABLED — `deny_anon`, `deny_authed_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:**
  - `trg_create_verified_food` (AFTER INSERT) — สร้าง verified_food row อัตโนมัติ
  - `trg_temp_food_touch_updated_at` (BEFORE UPDATE) — ตั้ง updated_at

---

## 7.2 `verified_food` (v13)
**Purpose:** สถานะการ verify ของ temp_food

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| vf_id | BIGSERIAL | ✓ | (auto) | PK | |
| tf_id | BIGINT | ✓ | — | UNIQUE + FK → temp_food ON DELETE CASCADE | 1:1 กับ temp_food |
| is_verify | BOOLEAN | ✓ | FALSE | — | |
| verified_by | BIGINT | — | — | FK → users ON DELETE SET NULL | admin ที่ verify |
| verified_at | TIMESTAMPTZ | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| updated_at | TIMESTAMPTZ | — | — | — | |

- **Indexes:** PRIMARY KEY, `idx_verified_food_tf_id (tf_id)`, `idx_verified_food_is_verify (is_verify)`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `created_at`, `updated_at`
- **Triggers:** `trg_verified_food_touch_updated_at` — ตั้ง `updated_at` และ `verified_at`

---

## 7.3 `food_regional_names` (v20)
**Purpose:** ชื่อท้องถิ่นของอาหารในแต่ละภาค

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| variant_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_id | BIGINT | ✓ | — | FK → foods ON DELETE CASCADE | |
| region | thai_region | ✓ | — | — | central/northern/northeastern/southern |
| name_th | VARCHAR(200) | ✓ | — | CHECK length(btrim) > 0 | ชื่อในภาคนั้น |
| is_primary | BOOLEAN | ✓ | FALSE | — | เป็นชื่อหลักของภาคนั้นหรือไม่ |
| created_by | BIGINT | — | — | FK → users ON DELETE SET NULL | ผู้เสนอ |
| approved_by | BIGINT | — | — | FK → users ON DELETE SET NULL | admin ที่อนุมัติ |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| updated_at | TIMESTAMPTZ | ✓ | NOW() | — | |
| deleted_at | TIMESTAMPTZ | — | — | — | soft delete |

- **Constraints:**
  - UNIQUE `(food_id, region, name_th)` — ห้ามซ้ำ
  - **`uq_food_regional_primary`** — UNIQUE `(food_id, region) WHERE is_primary AND deleted_at IS NULL` (1 primary ต่อ region)
- **Indexes:**
  - PRIMARY KEY
  - `uq_food_regional_primary` (partial unique)
  - `idx_food_regional_lookup (region, lower(name_th)) WHERE deleted_at IS NULL` — search index
  - `idx_food_regional_food (food_id) WHERE deleted_at IS NULL`
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** YES
- **Audit:** `created_at`, `updated_at`, `deleted_at`
- **Triggers:** —

---

## 7.4 `food_regional_popularity` (v20)
**Purpose:** คะแนนความนิยมของอาหารในแต่ละภาค

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| food_id | BIGINT | ✓ | — | PK + FK → foods ON DELETE CASCADE | |
| region | thai_region | ✓ | — | PK | |
| popularity | SMALLINT | ✓ | — | CHECK 1–5 | 1=หายาก, 5=ทุกที่ |
| note | VARCHAR(200) | — | — | — | บันทึกย่อ |
| updated_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY (food_id, region)
- **RLS:** ENABLED — `public_read`
- **Soft Delete:** No
- **Audit:** `updated_at`
- **Triggers:** —

---

## 7.5 `food_regional_name_submissions` (v20)
**Purpose:** ข้อเสนอชื่อท้องถิ่นจากผู้ใช้ (รอ admin review)

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| submission_id | BIGSERIAL | ✓ | (auto) | PK | |
| food_id | BIGINT | ✓ | — | FK → foods ON DELETE CASCADE | |
| region | thai_region | ✓ | — | — | |
| name_th | VARCHAR(200) | ✓ | — | CHECK length(btrim) > 0 | |
| popularity | SMALLINT | — | — | CHECK 1–5 | optional |
| user_id | BIGINT | ✓ | — | FK → users ON DELETE CASCADE | ผู้เสนอ |
| status | request_status | ✓ | 'pending' | CHECK pending/approved/rejected | |
| reviewed_by | BIGINT | — | — | FK → users ON DELETE SET NULL | admin |
| reviewed_at | TIMESTAMPTZ | — | — | — | |
| created_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY, `idx_food_regional_subm_status (status, created_at)`, `idx_food_regional_subm_user (user_id)`
- **RLS:** ENABLED — `deny_all_until_auth_migration`
- **Soft Delete:** No
- **Audit:** `created_at`, `reviewed_at`
- **Triggers:** —

---

# 8. Archive Tables

## 8.1 `food_requests_archive` (v22)
**Purpose:** Snapshot ของ `food_requests` ก่อนถูก drop
**Structure:** Exact copy ของ `food_requests` (`request_id`, `food_name`, `nutritional_info`, `user_id`, `status`, `created_at`, ฯลฯ)
- **Indexes:** PRIMARY KEY only
- **RLS:** Not enabled (admin-only via service-role)
- **Triggers:** —

## 8.2 `food_ingredients_archive` (v22)
**Purpose:** Snapshot ของ `food_ingredients` ก่อนถูก drop
**Structure:** Exact copy
- **Indexes:** PRIMARY KEY only
- **RLS:** Not enabled
- **Triggers:** —

## 8.3 `ingredients_archive` (v22)
**Purpose:** Snapshot ของ `ingredients` ก่อนถูก drop
**Structure:** Exact copy
- **Indexes:** PRIMARY KEY only
- **RLS:** Not enabled
- **Triggers:** —

## 8.4 `recipe_reviews_orphan_archive` (v17)
**Purpose:** เก็บ recipe_reviews ที่หา recipe matching ไม่เจอ

| Column | Type | NN | Default | อธิบาย |
|---|---|---|---|---|
| archive_id | BIGSERIAL | ✓ | (auto) | PK |
| review_id | BIGINT | — | — | review_id เดิม |
| legacy_recipe_id | BIGINT | — | — | recipe_id ในข้อมูลเดิม |
| legacy_food_id | BIGINT | — | — | food_id ในข้อมูลเดิม |
| user_id | BIGINT | — | — | |
| rating | SMALLINT | — | — | |
| comment | TEXT | — | — | |
| created_at | TIMESTAMPTZ | — | — | เวลา review เดิม |
| archived_at | TIMESTAMPTZ | ✓ | NOW() | |
| archive_reason | TEXT | ✓ | — | "No matching recipes row" |

- **RLS:** ENABLED — `deny_anon`, `deny_authenticated`

## 8.5 `recipe_relation_orphan_archive` (v18)
**Purpose:** เก็บ recipe-related rows (ingredients/steps/tips/tools/favorites) ที่ FK พัง

| Column | Type | NN | Default | อธิบาย |
|---|---|---|---|---|
| archive_id | BIGSERIAL | ✓ | (auto) | PK |
| source_table | VARCHAR(80) | ✓ | — | recipe_ingredients / recipe_steps / recipe_tips / recipe_tools / recipe_favorites |
| source_pk | BIGINT | — | — | PK เดิม |
| legacy_recipe_id | BIGINT | — | — | |
| legacy_user_id | BIGINT | — | — | |
| row_data | JSONB | ✓ | — | row ทั้งแถวเก็บเป็น JSON |
| archive_reason | TEXT | ✓ | — | |
| archived_at | TIMESTAMPTZ | ✓ | NOW() | |

- **RLS:** ENABLED — `deny_anon`, `deny_authenticated`

## 8.6 `unit_conversion_orphan_archive` (v18)
**Purpose:** เก็บ unit conversion ที่ FK ชี้ไปยัง unit ที่ถูกลบ

| Column | Type | NN | Default | อธิบาย |
|---|---|---|---|---|
| archive_id | BIGSERIAL | ✓ | (auto) | PK |
| conversion_id | INT | — | — | |
| from_unit_id | INT | — | — | |
| to_unit_id | INT | — | — | |
| row_data | JSONB | ✓ | — | |
| archive_reason | TEXT | ✓ | — | |
| archived_at | TIMESTAMPTZ | ✓ | NOW() | |

- **RLS:** ENABLED — `deny_anon`, `deny_authenticated`

---

# 9. Infrastructure

## 9.1 `schema_migrations`
**Purpose:** Track ว่ามี migration ใดถูก apply แล้ว

| Column | Type | NN | Default | FK/Constraint | อธิบาย |
|---|---|---|---|---|---|
| version | VARCHAR(100) | ✓ | — | PK | v8, v9, ..., v24, add_target_macros_to_users |
| applied_at | TIMESTAMPTZ | ✓ | NOW() | — | |

- **Indexes:** PRIMARY KEY
- **RLS:** ENABLED — `deny_anon`, `deny_authenticated`
- **Idempotent:** migration ใช้ `INSERT ... ON CONFLICT (version) DO NOTHING`

## 9.2 View: `v_admin_temp_food_review` (v13)
**Purpose:** JOIN ของ temp_food + verified_food + users สำหรับหน้า admin
**Columns:** `tf_id, food_name, protein, fat, carbs, calories, submitted_by, submitted_by_username, submitted_at, last_edited_at, vf_id, is_verify, verified_by, verified_at`

---

# Part C — ENUMs, Triggers, RLS Summary

## C.1 Custom ENUM Types

```sql
goal_type_enum:     lose_weight, maintain_weight, gain_muscle
activity_level:     sedentary, lightly_active, moderately_active, very_active
content_type:       article, video
food_type:          raw_ingredient, recipe_dish
gender_type:        male, female
meal_type:          breakfast, lunch, dinner, snack
notification_type:  system_alert, achievement, content_update, system_announcement
request_status:     pending, approved, rejected
thai_region:        central, northern, northeastern, southern   -- (v20)
```

## C.2 Triggers สำคัญ

| Trigger | Table | Event | Function | Why |
|---|---|---|---|---|
| `trg_sync_daily_summary` | `detail_items` | AFTER INSERT/UPDATE/DELETE | `fn_sync_daily_summary()` | คำนวณ totals ใน daily_summaries (v8) |
| `trg_sync_water_to_daily` | `water_logs` | AFTER INSERT/UPDATE/DELETE | `fn_sync_water_to_daily()` | sync water_glasses (v14_c) |
| `trg_create_verified_food` | `temp_food` | AFTER INSERT | `fn_create_verified_food_on_temp_insert()` | auto สร้าง verified_food (v13) |
| `trg_temp_food_touch_updated_at` | `temp_food` | BEFORE UPDATE | `fn_temp_food_touch_updated_at()` | (v13) |
| `trg_verified_food_touch_updated_at` | `verified_food` | BEFORE UPDATE | `fn_verified_food_touch_updated_at()` | ตั้ง verified_at ด้วย (v13) |
| **`trg_meals_updated_at`** | `meals` | BEFORE UPDATE | `fn_set_updated_at()` | **(v24)** |
| **`trg_detail_items_updated_at`** | `detail_items` | BEFORE UPDATE | `fn_set_updated_at()` | **(v24)** |
| **`trg_daily_summaries_updated_at`** | `daily_summaries` | BEFORE UPDATE | `fn_set_updated_at()` | **(v24)** |
| **`trg_exercise_logs_updated_at`** | `exercise_logs` | BEFORE UPDATE | `fn_set_updated_at()` | **(v24)** |
| **`trg_foods_sync_detail_items`** | `foods` | AFTER UPDATE | `fn_sync_detail_items_from_foods()` | **(v24)** sync cache จาก foods → detail_items |
| `update_recipe_favorite_count` | `recipe_favorites` | AFTER INSERT/DELETE | `update_recipe_favorite_count()` | sync `recipes.favorite_count` |
| `update_recipe_rating` | `recipe_reviews` | AFTER INSERT/UPDATE/DELETE | `update_recipe_rating()` | aggregate rating |

ฟังก์ชันทั้งหมดเป็น `SECURITY DEFINER` กับ pinned `search_path = cleangoal, pg_catalog` (v15_b) เพื่อกัน schema-shadowing attack.

## C.3 RLS Summary

**User-owned tables** (deny anon + deny authed-until-migration):
`users`, `meals`, `detail_items`, `daily_summaries`, `water_logs`, `exercise_logs`, `weight_logs`, `notifications`, `temp_food`, `email_verification_codes`, `password_reset_codes`, `user_favorites`, `user_meal_plans`, `user_allergy_preferences`, `recipe_favorites`, `recipe_reviews`, `food_regional_name_submissions`

**Public reference tables** (`public_read` = SELECT-only โดยไม่ต้อง auth):
`roles`, `units`, `unit_conversions`, `dish_categories`, `dishes`, `foods`, `allergy_flags`, `food_allergy_flags`, `beverages`, `snacks`, `recipes`, `recipe_ingredients`, `recipe_steps`, `recipe_tips`, `recipe_tools`, `health_contents`, `verified_food`, `food_regional_names`, `food_regional_popularity`

**Infra/archive tables** (deny ทั้งหมดยกเว้น service-role):
`schema_migrations`, `recipe_reviews_orphan_archive`, `recipe_relation_orphan_archive`, `unit_conversion_orphan_archive`

---

# สรุปการเปลี่ยนแปลงสำคัญ (v8 → v24)

| Migration | สิ่งที่เพิ่ม | สิ่งที่ลบ | ทำไม |
|---|---|---|---|
| v8 | `total_protein/carbs/fat`, `water_glasses` ใน `daily_summaries`; trigger sync | — | ทำ daily summary ให้ครบมาโคร |
| v9 | `glasses`, `updated_at` ใน `water_logs` | — | normalize water tracking |
| v10 | `duration_minutes`, `intensity` ใน `exercise_logs` | — | track ออกกำลังกายแบบมีรายละเอียด |
| v12 | `protein/carbs/fat_per_unit` ใน `detail_items` | — | snapshot มาโครต่อหน่วย |
| v13 | `temp_food`, `verified_food`, view, triggers | — | flow user-submit + admin-verify |
| v14_a | — | orphan `item_id` ใน 3 ตาราง | clean up dead columns |
| v14_b | CHECK constraints | — | bound numeric values |
| v14_c | trigger sync water_logs → daily_summaries | `user_goals`, `user_activities` | denormalize 1:1 ลง users |
| v14_d | seeded `units` | — | populate standard units |
| v14_f | — | `progress`, `weekly_summaries`, `chat_messages`, `user_health_content_views` | ลบตารางที่ซ้ำ/ไม่ใช้ |
| v15_b | pinned search_path | — | security hardening |
| v15_c | RLS policies ทุก table | — | Supabase security |
| v15_e | `users.deleted_at` + soft delete | — | PDPA compliance |
| v16_a | `ingredients_json/tools_json/tips_json/generated_by` ใน `recipes` | — | รองรับ AI generation |
| v17 | `recipes.food_id UNIQUE`, recipe_id ใน `recipe_reviews` | orphan reviews → archive | normalize recipe relationships |
| v18 | `dish_categories`, `dishes`, `foods.dish_id`, `foods.serving_unit_id`, `recipes.favorite_count` | (orphan archives) | 3NF taxonomy |
| v19 | `detail_items.unit_id` (FK) | — | normalize unit reference |
| **v20** | **`thai_region` ENUM**, **`users.region/region_source`**, **`food_regional_names`**, **`food_regional_popularity`**, **`food_regional_name_submissions`** | — | **รองรับชื่ออาหารท้องถิ่น 4 ภาค** |
| **v21** | — | **`foods.food_category`, `foods.serving_unit`** | **drop legacy duplicate columns** |
| **v22** | archive tables | **`food_requests`, `food_ingredients`, `ingredients`** | **drop unused tables** |
| v23 | (ข้าม — ไม่เคยเขียน) | | |
| **v24** | **`updated_at` ใน 4 tables**, **5 triggers**, **`fn_sync_detail_items_from_foods`** | — | **audit + cache-sync** |

---

**END OF DATA DICTIONARY**

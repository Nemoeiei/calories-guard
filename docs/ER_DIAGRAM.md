# ER Diagram — Calories Guard (`cleangoal` schema, post-v14)

_Source of truth: live Supabase introspection on 2026-04-19._
_Scope: 35 base tables + 8 enums + 1 admin view._
_Generated after v14 phases A–F applied (see `DB_V14_NORMALIZE_PROPOSAL.md`)._

## 0. Legend

- `PK` primary key · `FK` foreign key · `UQ` unique constraint · `CK` check constraint
- Relationship lines follow Mermaid's crow-foot notation:
  - `||--o{` one-to-many (optional many)
  - `||--|{` one-to-many (mandatory many)
  - `||--||` one-to-one
  - `}o--o{` many-to-many via junction table
- Dashed lines in §2 mark **logical** relationships that are not enforced by a DB-level FK (v14 did not add them because of naming/legacy reasons — see §6).

---

## 1. Enum types

| Enum | Values |
|---|---|
| `activity_level` | `sedentary`, `lightly_active`, `moderately_active`, `very_active` |
| `content_type` | `article`, `video` |
| `food_type` | `raw_ingredient`, `recipe_dish` |
| `gender_type` | `male`, `female` |
| `goal_type_enum` | `lose_weight`, `maintain_weight`, `gain_muscle` |
| `meal_type` | `breakfast`, `lunch`, `dinner`, `snack` |
| `notification_type` | `system_alert`, `achievement`, `content_update`, `system_announcement` |
| `request_status` | `pending`, `approved`, `rejected` |

---

## 2. Full ER Diagram (Mermaid)

```mermaid
erDiagram

    %% ====================== AUTH / ACCOUNT ======================
    roles ||--o{ users : "role_id"
    users ||--o{ email_verification_codes : "user_id"
    users ||--o{ password_reset_codes    : "user_id"
    users ||--o{ notifications           : "user_id"

    %% ====================== FOOD CATALOG ========================
    foods ||--o| beverages : "food_id (table-per-type)"
    foods ||--o| snacks    : "food_id (table-per-type)"
    foods ||--o{ food_ingredients : "food_id"
    ingredients ||--o{ food_ingredients : "ingredient_id"
    units ||--o{ food_ingredients : "unit_id"
    units ||--o{ ingredients      : "default_unit_id"
    units ||--o{ unit_conversions : "from_unit_id / to_unit_id"
    foods ||--o{ food_allergy_flags : "food_id"
    allergy_flags ||--o{ food_allergy_flags : "flag_id"
    users ||--o{ user_favorites : "user_id"
    foods ||--o{ user_favorites : "food_id"
    users ||--o{ user_allergy_preferences : "user_id"
    allergy_flags ||--o{ user_allergy_preferences : "flag_id"

    %% ====================== FOOD REQUEST QUEUE ==================
    users ||--o{ temp_food       : "user_id (submitted_by)"
    temp_food ||--|| verified_food : "tf_id (1-1 approval)"
    users ||--o{ verified_food   : "verified_by"
    users ||--o{ food_requests   : "user_id (submitted_by)"
    users ||--o{ food_requests   : "reviewed_by (admin)"

    %% ====================== MEALS / TRACKING ====================
    users ||--o{ meals           : "user_id"
    users ||--o{ daily_summaries : "user_id"
    users ||--o{ user_meal_plans : "user_id (ON DELETE SET NULL)"
    meals           ||--o{ detail_items : "meal_id"
    daily_summaries ||--o{ detail_items : "summary_id"
    user_meal_plans ||--o{ detail_items : "plan_id"
    foods ||--o{ detail_items : "food_id (ON DELETE SET NULL)"

    users ||--o{ water_logs    : "user_id"
    users ||--o{ exercise_logs : "user_id"
    users ||--o{ weight_logs   : "user_id"

    %% ====================== RECIPES =============================
    foods ||--o{ recipes : "food_id"
    recipes ||..o{ recipe_ingredients : "recipe_id (logical)"
    recipes ||..o{ recipe_steps       : "recipe_id (logical)"
    recipes ||..o{ recipe_tips        : "recipe_id (logical)"
    recipes ||..o{ recipe_tools       : "recipe_id (logical)"
    recipes ||..o{ recipe_reviews     : "recipe_id (logical)"
    recipes ||..o{ recipe_favorites   : "recipe_id (logical)"
    users   ||..o{ recipe_reviews     : "user_id (logical)"
    users   ||..o{ recipe_favorites   : "user_id (logical)"

    %% ====================== ADMIN / CONTENT =====================
    health_contents {
        int8 content_id PK
        varchar title
        content_type type
    }

    %% ====================== TABLE DEFINITIONS ===================

    roles {
        int4    role_id PK
        varchar role_name UQ
    }

    users {
        int8           user_id PK
        varchar        username
        varchar        email UQ
        varchar        password_hash
        gender_type    gender
        date           birth_date
        numeric        height_cm "CK 80-250"
        numeric        current_weight_kg "CK 20-300"
        goal_type_enum goal_type
        numeric        target_weight_kg "CK 20-300"
        int4           target_calories "CK 500-6000"
        int4           target_protein
        int4           target_carbs
        int4           target_fat
        activity_level activity_level
        date           goal_start_date
        date           goal_target_date
        date           last_kpi_check_date
        int4           current_streak "CK >=0"
        timestamptz    last_login_date
        int4           total_login_days "CK >=0"
        varchar        avatar_url
        int4           role_id FK
        bool           is_email_verified
        timestamptz    consent_accepted_at
        timestamptz    created_at
        timestamptz    updated_at
        timestamptz    deleted_at
    }

    email_verification_codes {
        int8        id PK
        int8        user_id FK
        varchar     code
        timestamptz expires_at
        bool        used
        timestamptz created_at
    }

    password_reset_codes {
        int8        id PK
        int8        user_id FK
        varchar     code
        timestamptz expires_at
        bool        used
        timestamptz created_at
    }

    notifications {
        int8              notification_id PK
        int8              user_id FK
        varchar           title
        text              message
        notification_type type
        bool              is_read
        timestamptz       created_at
    }

    allergy_flags {
        int4    flag_id PK
        varchar name
        varchar description
    }

    user_allergy_preferences {
        int8        user_id PK_FK
        int4        flag_id PK_FK
        varchar     preference_type
        timestamptz created_at
    }

    foods {
        int8        food_id PK
        varchar     food_name
        food_type   food_type
        numeric     calories "CK >=0"
        numeric     protein  "CK >=0"
        numeric     carbs    "CK >=0"
        numeric     fat      "CK >=0"
        numeric     sodium
        numeric     sugar
        numeric     cholesterol
        numeric     serving_quantity "CK >0"
        varchar     serving_unit
        varchar     image_url
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    beverages {
        int8    beverage_id PK
        int8    food_id FK UQ
        numeric volume_ml
        bool    is_alcoholic
        numeric caffeine_mg
        varchar sugar_level_label
        varchar container_type
    }

    snacks {
        int8    snack_id PK
        int8    food_id FK UQ
        bool    is_sweet
        varchar packaging_type
        numeric trans_fat
    }

    ingredients {
        int8        ingredient_id PK
        varchar     name
        varchar     category
        int4        default_unit_id FK
        numeric     calories_per_unit
        timestamptz created_at
    }

    units {
        int4    unit_id PK
        varchar name "seeded: g,kg,mg,ml,l,tsp,tbsp,cup,oz,piece,serving,slice,bowl,plate,glass"
        numeric quantity "was conversion_factor before v14_d"
    }

    unit_conversions {
        int4        conversion_id PK
        int4        from_unit_id
        int4        to_unit_id
        numeric     factor
        varchar     note
        timestamptz created_at
    }

    food_ingredients {
        int8    food_ing_id PK
        int8    food_id FK
        int8    ingredient_id FK
        numeric amount
        int4    unit_id FK
        numeric calculated_grams
        varchar note
    }

    food_allergy_flags {
        int8 food_id PK_FK
        int4 flag_id PK_FK
    }

    user_favorites {
        int8        id PK
        int8        user_id FK
        int8        food_id FK
        timestamptz created_at
    }

    temp_food {
        int8        tf_id PK
        varchar     food_name
        numeric     protein
        numeric     fat
        numeric     carbs
        numeric     calories
        int8        user_id FK
        timestamptz created_at
        timestamptz updated_at
    }

    verified_food {
        int8        vf_id PK
        int8        tf_id FK UQ
        bool        is_verify
        int8        verified_by FK
        timestamptz verified_at
        timestamptz created_at
        timestamptz updated_at
    }

    food_requests {
        int8           request_id PK
        int8           user_id FK
        varchar        food_name
        request_status status
        jsonb          ingredients_json
        int8           reviewed_by FK
        timestamptz    created_at
    }

    meals {
        int8        meal_id PK
        int8        user_id FK
        timestamptz meal_time
        numeric     total_amount
        meal_type   meal_type "NOT NULL, added in v14_a"
        timestamptz created_at
        timestamptz updated_at
    }

    daily_summaries {
        int8    summary_id PK
        int8    user_id FK
        date    date_record UQ
        numeric total_calories_intake "CK >=0"
        numeric total_protein "CK >=0"
        numeric total_carbs   "CK >=0"
        numeric total_fat     "CK >=0"
        int4    water_glasses "CK >=0"
        int4    goal_calories
        bool    is_goal_met
    }

    user_meal_plans {
        int8        plan_id PK
        int8        user_id FK
        varchar     name
        text        description
        varchar     source_type
        bool        is_premium
        timestamptz created_at
    }

    detail_items {
        int8        item_id PK
        int8        meal_id FK "exactly one of meal_id"
        int8        plan_id FK "plan_id"
        int8        summary_id FK "summary_id must be set (CK)"
        int8        food_id FK "SET NULL"
        varchar     food_name
        int4        day_number
        numeric     amount
        int4        unit_id
        numeric     cal_per_unit
        numeric     protein_per_unit
        numeric     carbs_per_unit
        numeric     fat_per_unit
        varchar     note
        timestamptz created_at
    }

    water_logs {
        int8        log_id PK
        int8        user_id FK
        date        date_record "UQ(user,date)"
        int4        glasses "CK 0-30"
        timestamptz updated_at
    }

    exercise_logs {
        int8        log_id PK
        int8        user_id FK
        date        date_record
        varchar     activity_name
        int4        duration_minutes "CK 0-1440"
        numeric     calories_burned "CK >=0"
        varchar     intensity
        varchar     note
        timestamptz created_at
    }

    weight_logs {
        int8        log_id PK
        int8        user_id FK
        numeric     weight_kg "CK 20-300"
        date        recorded_date
        timestamptz created_at
    }

    recipes {
        int8        recipe_id PK
        int8        food_id FK
        varchar     description
        text        instructions
        int4        prep_time_minutes
        int4        cooking_time_minutes
        numeric     serving_people
        varchar     source_reference
        varchar     image_url
        timestamptz created_at
        timestamptz deleted_at
    }

    recipe_ingredients {
        int8        ing_id PK
        int8        recipe_id "logical FK"
        varchar     ingredient_name
        numeric     quantity
        varchar     unit
        bool        is_optional
        varchar     note
        int4        sort_order
        timestamptz created_at
    }

    recipe_steps {
        int8        step_id PK
        int8        recipe_id "logical FK"
        int4        step_number
        varchar     title
        text        instruction
        int4        time_minutes
        varchar     image_url
        text        tips
        timestamptz created_at
    }

    recipe_tips {
        int8        tip_id PK
        int8        recipe_id "logical FK"
        text        tip_text
        int4        sort_order
        timestamptz created_at
    }

    recipe_tools {
        int8        tool_id PK
        int8        recipe_id "logical FK"
        varchar     tool_name
        varchar     tool_emoji
        int4        sort_order
        timestamptz created_at
    }

    recipe_reviews {
        int8        review_id PK
        int8        recipe_id "logical FK"
        int8        user_id   "logical FK"
        int2        rating "CK 1-5"
        text        comment
        timestamptz created_at
    }

    recipe_favorites {
        int8        fav_id PK
        int8        recipe_id "logical FK, UQ(user,recipe)"
        int8        user_id   "logical FK"
        timestamptz created_at
    }

    schema_migrations {
        varchar     version PK
        timestamptz applied_at
    }
```

---

## 3. Domain clusters

### 3.1 Auth / Account (6 tables)
`roles` · `users` · `email_verification_codes` · `password_reset_codes` · `notifications` · `user_allergy_preferences`

The `users` table is the hub — 21 of the 35 tables reference it. `role_id` drives admin access (role 1 = admin, 2 = user by convention). `allergy_flags` is a seeded lookup.

### 3.2 Food catalog (8 tables)
`foods` (core) + two table-per-type extensions `beverages` (`food_id` UQ) and `snacks` (`food_id` UQ) · `ingredients` · `units` · `unit_conversions` · `food_ingredients` (bridge) · `food_allergy_flags` (bridge).

`foods.food_type` distinguishes `raw_ingredient` (added quickly, macros only) vs `recipe_dish` (linked to a `recipes` row).

### 3.3 User food preferences (1 table)
`user_favorites` (user ↔ food, UQ after v14_b).

### 3.4 Food request / moderation queue (3 tables)
`temp_food` → `verified_food` (1-1, UQ tf_id) → admin approve/reject flips `is_verify` and (out-of-band) promotes to `foods`. `food_requests` is the older free-form request channel kept for audit.

### 3.5 Meals & intake (5 tables)
`meals` (header, `meal_type` NOT NULL since v14_a) + `daily_summaries` (per-day rollup, UQ user+date) + `user_meal_plans` (templates) + `detail_items` (polymorphic child: exactly one of `meal_id` / `plan_id` / `summary_id` set, enforced by `ck_detail_items_one_parent`).

### 3.6 Tracking logs (3 tables)
`water_logs` (UQ user+date, INSERT/UPDATE/DELETE-synced to `daily_summaries.water_glasses` via trigger `trg_sync_water_to_daily` — rewritten in v14_c) · `exercise_logs` · `weight_logs`.

### 3.7 Recipes (7 tables)
`recipes` (FK to `foods`) + `recipe_ingredients` + `recipe_steps` + `recipe_tips` + `recipe_tools` + `recipe_reviews` + `recipe_favorites`. The last six reference `recipe_id` / `user_id` without enforced FKs (see §6).

### 3.8 Admin / content (3 tables)
`health_contents` (public articles/videos) · `food_requests` (moderated queue, see §3.4) · `schema_migrations` (meta).

---

## 4. Enforced integrity summary (post-v14)

- **Unique constraints**: `roles.role_name`, `users.email`, `beverages.food_id`, `snacks.food_id`, `user_favorites(user_id,food_id)`, `recipe_favorites(user_id,recipe_id)`, `daily_summaries(user_id,date_record)`, `water_logs(user_id,date_record)`.
- **Check constraints**: biometric ranges on `users`, non-negative macros on `foods` / `daily_summaries`, rating `1..5` on `recipe_reviews`, `glasses 0..30` on `water_logs`, `duration_minutes 0..1440` on `exercise_logs`, polymorphic `ck_detail_items_one_parent`.
- **Varchar caps**: `users.email(255)`, `users.username(50)`, `foods.food_name(200)`, `detail_items.note(500)`, etc. (see `v14_b_integrity.sql`).
- **All timestamp columns** are `timestamptz` as of v14_e; display layer converts to `Asia/Bangkok`.

---

## 5. Functional indexes (non-PK/UQ highlights)

| Index | Definition | Purpose |
|---|---|---|
| `idx_meals_user_date_type` | `meals(user_id, (meal_time AT TIME ZONE 'Asia/Bangkok')::date, meal_type)` | Record-food screen daily lookup |
| `idx_meals_user_date` | `meals(user_id, (meal_time AT TIME ZONE 'Asia/Bangkok')::date DESC)` | Recent meals |
| `idx_daily_summaries_user_date` | `daily_summaries(user_id, date_record)` | /progress_summary |
| `idx_water_logs_user_date` | `water_logs(user_id, date_record)` | Hydration widget |
| `idx_detail_items_meal` / `plan` / `summary` | parent lookup indexes | /daily_logs |

_Rebuilt with IMMUTABLE `AT TIME ZONE 'Asia/Bangkok'` expression in v14_e so the planner can still use them on `timestamptz` columns._

---

## 6. Known gaps (followup)

- **Missing FKs on recipe_* tables**: `recipe_ingredients`, `recipe_steps`, `recipe_tips`, `recipe_tools`, `recipe_reviews`, `recipe_favorites` all store `recipe_id` / `user_id` without a DB-level FK. Add `ON DELETE CASCADE` in a future phase once we confirm no orphan data.
- **`unit_conversions.from_unit_id` / `to_unit_id`** have no FK to `units`. Same remedy.
- **`user_meal_plans.user_id` ON DELETE SET NULL** – intentional so a deleted user's templates survive for other users, but confirm product intent.
- **`food_requests.reviewed_by` ON DELETE NO ACTION** – will block deleting admin accounts; consider `SET NULL`.
- **`beverages.food_id` / `snacks.food_id`** are `NO ACTION` — dropping a `foods` row leaves orphans. Consider `CASCADE` since these are strict extensions.

---

## 7. Source queries

All data above comes from `information_schema.columns`, `information_schema.table_constraints`, `pg_catalog.pg_enum`, and `pg_indexes`, run against project `zawlghlnzgftlxcoipuf` schema `cleangoal` on 2026-04-19 after `v14_e_timestamptz` applied.

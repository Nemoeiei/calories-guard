# 📖 Full Data Dictionary - Schema: cleangoal

## Table: allergy_flags
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| flag_id | integer | **NO** | nextval('cleangoal.allergy_flags_flag_id_seq'::regclass) | |
| name | character varying | **NO** | - | |
| description | character varying | Yes | - | |


## Table: beverages
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| beverage_id | bigint | **NO** | nextval('cleangoal.beverages_beverage_id_seq'::regclass) | |
| food_id | bigint | Yes | - | |
| volume_ml | numeric | Yes | - | |
| is_alcoholic | boolean | Yes | false | |
| caffeine_mg | numeric | Yes | 0 | |
| sugar_level_label | character varying | Yes | - | |
| container_type | character varying | Yes | - | |


## Table: daily_summaries
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| summary_id | bigint | **NO** | nextval('cleangoal.daily_summaries_summary_id_seq'::regclass) | |
| user_id | bigint | Yes | - | |
| item_id | bigint | Yes | - | |
| date_record | date | Yes | CURRENT_DATE | |
| total_calories_intake | numeric | Yes | 0 | |
| goal_calories | integer | Yes | - | |
| is_goal_met | boolean | Yes | false | |


## Table: detail_items
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| item_id | bigint | **NO** | nextval('cleangoal.detail_items_item_id_seq'::regclass) | |
| meal_id | bigint | Yes | - | |
| plan_id | bigint | Yes | - | |
| summary_id | bigint | Yes | - | |
| food_id | bigint | Yes | - | |
| food_name | character varying | Yes | - | |
| day_number | integer | Yes | - | |
| amount | numeric | Yes | 1.0 | |
| unit_id | integer | Yes | - | |
| cal_per_unit | numeric | Yes | - | |
| note | character varying | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: email_verification_codes
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | bigint | **NO** | nextval('cleangoal.email_verification_codes_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| code | character varying | **NO** | - | |
| expires_at | timestamp without time zone | **NO** | - | |
| used | boolean | Yes | false | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: food_ingredients
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| food_ing_id | bigint | **NO** | nextval('cleangoal.food_ingredients_food_ing_id_seq'::regclass) | |
| food_id | bigint | Yes | - | |
| ingredient_id | bigint | Yes | - | |
| amount | numeric | Yes | - | |
| unit_id | integer | Yes | - | |
| calculated_grams | numeric | Yes | - | |
| note | character varying | Yes | - | |


## Table: food_requests
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| request_id | bigint | **NO** | nextval('cleangoal.food_requests_request_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| food_name | character varying | **NO** | - | |
| status | USER-DEFINED | Yes | 'pending'::cleangoal.request_status | |
| ingredients_json | jsonb | Yes | - | |
| reviewed_by | bigint | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: foods
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| food_id | bigint | **NO** | nextval('cleangoal.foods_food_id_seq'::regclass) | |
| food_name | character varying | **NO** | - | |
| food_type | USER-DEFINED | Yes | 'raw_ingredient'::cleangoal.food_type | |
| calories | numeric | Yes | - | |
| protein | numeric | Yes | - | |
| carbs | numeric | Yes | - | |
| fat | numeric | Yes | - | |
| sodium | numeric | Yes | - | |
| sugar | numeric | Yes | - | |
| cholesterol | numeric | Yes | - | |
| serving_quantity | numeric | Yes | 100 | |
| serving_unit | character varying | Yes | 'g'::character varying | |
| image_url | character varying | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |
| updated_at | timestamp without time zone | Yes | - | |
| deleted_at | timestamp without time zone | Yes | - | |


## Table: health_contents
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| content_id | bigint | **NO** | nextval('cleangoal.health_contents_content_id_seq'::regclass) | |
| title | character varying | **NO** | - | |
| type | USER-DEFINED | Yes | - | |
| thumbnail_url | character varying | Yes | - | |
| resource_url | character varying | Yes | - | |
| description | text | Yes | - | |
| category_tag | character varying | Yes | - | |
| difficulty_level | character varying | Yes | - | |
| is_published | boolean | Yes | true | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: ingredients
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| ingredient_id | bigint | **NO** | nextval('cleangoal.ingredients_ingredient_id_seq'::regclass) | |
| name | character varying | **NO** | - | |
| category | character varying | Yes | - | |
| default_unit_id | integer | Yes | - | |
| calories_per_unit | numeric | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: meals
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| meal_id | bigint | **NO** | nextval('cleangoal.meals_meal_id_seq'::regclass) | |
| user_id | bigint | Yes | - | |
| item_id | bigint | Yes | - | |
| meal_type | USER-DEFINED | Yes | - | |
| meal_time | timestamp without time zone | Yes | now() | |
| total_amount | numeric | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: notifications
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| notification_id | bigint | **NO** | nextval('cleangoal.notifications_notification_id_seq'::regclass) | |
| user_id | bigint | Yes | - | |
| title | character varying | **NO** | - | |
| message | text | Yes | - | |
| type | USER-DEFINED | Yes | - | |
| is_read | boolean | Yes | false | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: password_reset_codes
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | bigint | **NO** | nextval('cleangoal.password_reset_codes_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| code | character varying | **NO** | - | |
| expires_at | timestamp without time zone | **NO** | - | |
| used | boolean | Yes | false | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: progress
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| progress_id | bigint | **NO** | nextval('cleangoal.progress_progress_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| weight_id | bigint | Yes | - | |
| daily_id | bigint | Yes | - | |
| current_streak | integer | Yes | 0 | |
| weekly_target | character varying | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: recipes
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| recipe_id | bigint | **NO** | nextval('cleangoal.recipes_recipe_id_seq'::regclass) | |
| food_id | bigint | Yes | - | |
| description | character varying | Yes | - | |
| instructions | text | Yes | - | |
| prep_time_minutes | integer | Yes | 0 | |
| cooking_time_minutes | integer | Yes | 0 | |
| serving_people | numeric | Yes | 1.0 | |
| source_reference | character varying | Yes | - | |
| image_url | character varying | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |
| deleted_at | timestamp without time zone | Yes | - | |


## Table: roles
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| role_id | integer | **NO** | nextval('cleangoal.roles_role_id_seq'::regclass) | |
| role_name | character varying | **NO** | - | |


## Table: snacks
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| snack_id | bigint | **NO** | nextval('cleangoal.snacks_snack_id_seq'::regclass) | |
| food_id | bigint | Yes | - | |
| is_sweet | boolean | Yes | true | |
| packaging_type | character varying | Yes | - | |
| trans_fat | numeric | Yes | - | |


## Table: units
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| unit_id | integer | **NO** | nextval('cleangoal.units_unit_id_seq'::regclass) | |
| name | character varying | **NO** | - | |
| conversion_factor | numeric | Yes | - | |


## Table: user_activities
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| activity_id | bigint | **NO** | nextval('cleangoal.user_activities_activity_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| activity_level | USER-DEFINED | **NO** | - | |
| is_current | boolean | Yes | true | |
| date_record | date | Yes | CURRENT_DATE | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: user_allergy_preferences
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| user_id | bigint | **NO** | - | |
| flag_id | integer | **NO** | - | |
| preference_type | character varying | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: user_goals
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| goal_id | bigint | **NO** | nextval('cleangoal.user_goals_goal_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| goal_name | character varying | Yes | - | |
| goal_type | USER-DEFINED | **NO** | - | |
| target_weight_kg | numeric | Yes | - | |
| is_current | boolean | Yes | true | |
| goal_start_at | date | Yes | CURRENT_DATE | |
| goal_target_date | date | Yes | - | |
| goal_end_at | date | Yes | - | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: user_meal_plans
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| plan_id | bigint | **NO** | nextval('cleangoal.user_meal_plans_plan_id_seq'::regclass) | |
| user_id | bigint | Yes | - | |
| item_id | bigint | Yes | - | |
| name | character varying | **NO** | - | |
| description | text | Yes | - | |
| source_type | character varying | Yes | 'SYSTEM'::character varying | |
| is_premium | boolean | Yes | false | |
| created_at | timestamp without time zone | Yes | now() | |


## Table: users
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| user_id | bigint | **NO** | nextval('cleangoal.users_user_id_seq'::regclass) | |
| username | character varying | Yes | - | |
| email | character varying | **NO** | - | |
| password_hash | character varying | **NO** | - | |
| gender | USER-DEFINED | Yes | - | |
| birth_date | date | Yes | - | |
| height_cm | numeric | Yes | - | |
| current_weight_kg | numeric | Yes | - | |
| goal_type | USER-DEFINED | Yes | - | |
| target_weight_kg | numeric | Yes | - | |
| target_calories | integer | Yes | - | |
| activity_level | USER-DEFINED | Yes | - | |
| goal_start_date | date | Yes | CURRENT_DATE | |
| goal_target_date | date | Yes | - | |
| last_kpi_check_date | date | Yes | CURRENT_DATE | |
| current_streak | integer | Yes | 0 | |
| last_login_date | timestamp without time zone | Yes | - | |
| total_login_days | integer | Yes | 0 | |
| avatar_url | character varying | Yes | - | |
| role_id | integer | Yes | 2 | |
| created_at | timestamp without time zone | Yes | now() | |
| updated_at | timestamp without time zone | Yes | - | |
| deleted_at | timestamp without time zone | Yes | - | |
| target_protein | integer | Yes | - | |
| target_carbs | integer | Yes | - | |
| target_fat | integer | Yes | - | |
| is_email_verified | boolean | Yes | false | |


## Table: weekly_summaries
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| weekly_id | bigint | **NO** | nextval('cleangoal.weekly_summaries_weekly_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| start_date | date | **NO** | - | |
| avg_daily_calories | integer | Yes | - | |
| days_logged_count | integer | Yes | - | |


## Table: weight_logs
| Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| log_id | bigint | **NO** | nextval('cleangoal.weight_logs_log_id_seq'::regclass) | |
| user_id | bigint | **NO** | - | |
| weight_kg | numeric | **NO** | - | |
| recorded_date | date | Yes | CURRENT_DATE | |
| created_at | timestamp without time zone | Yes | now() | |



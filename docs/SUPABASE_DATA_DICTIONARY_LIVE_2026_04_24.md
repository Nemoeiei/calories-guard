# Supabase Live Data Dictionary Snapshot

Date: 2026-04-24  
Project ref: `zawlghlnzgftlxcoipuf`  
Schema: `cleangoal`  
Baseline: post `v19_detail_items_unit_fk`  

This is a live column-level snapshot for building the final data dictionary. It is intentionally factual: table purpose and business descriptions should be refined in the final coursework document.

Key notation: `PK` = primary key, `FK` = foreign key, `UNIQUE(a,b)` = composite or single-column uniqueness constraint containing this column.

## Enums

| Enum | Values |
|---|---|
| `activity_level` | sedentary, lightly_active, moderately_active, very_active |
| `content_type` | article, video |
| `food_type` | raw_ingredient, recipe_dish, dish, beverage, snack |
| `gender_type` | male, female |
| `goal_type_enum` | lose_weight, maintain_weight, gain_muscle |
| `meal_type` | breakfast, lunch, dinner, snack |
| `notification_type` | system_alert, achievement, content_update, system_announcement |
| `request_status` | pending, approved, rejected |

## Tables And Views

| Object | Type | Rows |
|---|---|---:|
| `allergy_flags` | BASE TABLE | 20 |
| `beverages` | BASE TABLE | 0 |
| `daily_summaries` | BASE TABLE | 12 |
| `detail_items` | BASE TABLE | 26 |
| `dish_categories` | BASE TABLE | 6 |
| `dishes` | BASE TABLE | 103 |
| `email_verification_codes` | BASE TABLE | 0 |
| `exercise_logs` | BASE TABLE | 0 |
| `food_allergy_flags` | BASE TABLE | 0 |
| `food_ingredients` | BASE TABLE | 0 |
| `food_requests` | BASE TABLE | 0 |
| `foods` | BASE TABLE | 103 |
| `health_contents` | BASE TABLE | 20 |
| `ingredients` | BASE TABLE | 0 |
| `meals` | BASE TABLE | 23 |
| `notifications` | BASE TABLE | 14 |
| `password_reset_codes` | BASE TABLE | 0 |
| `recipe_favorites` | BASE TABLE | 0 |
| `recipe_ingredients` | BASE TABLE | 35 |
| `recipe_relation_orphan_archive` | BASE TABLE | 100 |
| `recipe_reviews` | BASE TABLE | 1 |
| `recipe_reviews_orphan_archive` | BASE TABLE | 20 |
| `recipe_steps` | BASE TABLE | 20 |
| `recipe_tips` | BASE TABLE | 10 |
| `recipe_tools` | BASE TABLE | 12 |
| `recipes` | BASE TABLE | 5 |
| `roles` | BASE TABLE | 2 |
| `schema_migrations` | BASE TABLE | 22 |
| `snacks` | BASE TABLE | 0 |
| `temp_food` | BASE TABLE | 5 |
| `unit_conversion_orphan_archive` | BASE TABLE | 19 |
| `unit_conversions` | BASE TABLE | 5 |
| `units` | BASE TABLE | 16 |
| `user_allergy_preferences` | BASE TABLE | 1 |
| `user_favorites` | BASE TABLE | 0 |
| `user_meal_plans` | BASE TABLE | 0 |
| `users` | BASE TABLE | 19 |
| `verified_food` | BASE TABLE | 5 |
| `water_logs` | BASE TABLE | 8 |
| `weight_logs` | BASE TABLE | 14 |
| `v_admin_temp_food_review` | VIEW |  |

## `allergy_flags`

Type: BASE TABLE; rows: 20

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `flag_id` | `integer` | NO | PK |  | `nextval('cleangoal.allergy_flags_flag_id_seq'::regclass)` |
| `name` | `character varying` | NO |  |  | `` |
| `description` | `character varying` | YES |  |  | `` |

## `beverages`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `beverage_id` | `bigint` | NO | PK |  | `nextval('cleangoal.beverages_beverage_id_seq'::regclass)` |
| `food_id` | `bigint` | YES | FK; UNIQUE(food_id) | foods(food_id) | `` |
| `volume_ml` | `numeric` | YES |  |  | `` |
| `is_alcoholic` | `boolean` | YES |  |  | `false` |
| `caffeine_mg` | `numeric` | YES |  |  | `0` |
| `sugar_level_label` | `character varying` | YES |  |  | `` |
| `container_type` | `character varying` | YES |  |  | `` |

## `daily_summaries`

Type: BASE TABLE; rows: 12

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `summary_id` | `bigint` | NO | PK |  | `nextval('cleangoal.daily_summaries_summary_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK; UNIQUE(user_id,date_record) | users(user_id) | `` |
| `date_record` | `date` | NO | UNIQUE(user_id,date_record) |  | `CURRENT_DATE` |
| `total_calories_intake` | `numeric` | YES |  |  | `0` |
| `total_protein` | `numeric` | YES |  |  | `0` |
| `total_carbs` | `numeric` | YES |  |  | `0` |
| `total_fat` | `numeric` | YES |  |  | `0` |
| `water_glasses` | `integer` | YES |  |  | `0` |
| `goal_calories` | `integer` | YES |  |  | `` |
| `is_goal_met` | `boolean` | YES |  |  | `false` |

## `detail_items`

Type: BASE TABLE; rows: 26

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `item_id` | `bigint` | NO | PK |  | `` |
| `meal_id` | `bigint` | YES | FK | meals(meal_id) | `` |
| `plan_id` | `bigint` | YES | FK | user_meal_plans(plan_id) | `` |
| `summary_id` | `bigint` | YES | FK | daily_summaries(summary_id) | `` |
| `food_id` | `bigint` | YES | FK | foods(food_id) | `` |
| `food_name` | `character varying(200)` | YES |  |  | `` |
| `day_number` | `integer` | YES |  |  | `` |
| `amount` | `numeric` | YES |  |  | `1` |
| `unit_id` | `integer` | YES | FK | units(unit_id) | `` |
| `cal_per_unit` | `numeric` | YES |  |  | `` |
| `protein_per_unit` | `numeric` | YES |  |  | `` |
| `carbs_per_unit` | `numeric` | YES |  |  | `` |
| `fat_per_unit` | `numeric` | YES |  |  | `` |
| `note` | `character varying(500)` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `dish_categories`

Type: BASE TABLE; rows: 6

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `dish_category_id` | `bigint` | NO | PK |  | `nextval('cleangoal.dish_categories_dish_category_id_seq'::regclass)` |
| `category_name` | `character varying(120)` | NO | UNIQUE(category_name,canonical_food_type) |  | `` |
| `canonical_food_type` | `food_type` | YES | UNIQUE(category_name,canonical_food_type) |  | `` |
| `description` | `text` | YES |  |  | `` |
| `display_order` | `integer` | NO |  |  | `0` |
| `created_at` | `timestamp with time zone` | NO |  |  | `now()` |

## `dishes`

Type: BASE TABLE; rows: 103

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `dish_id` | `bigint` | NO | PK |  | `nextval('cleangoal.dishes_dish_id_seq'::regclass)` |
| `dish_name` | `character varying(200)` | NO | UNIQUE(dish_name,dish_category_id) |  | `` |
| `dish_category_id` | `bigint` | NO | FK; UNIQUE(dish_name,dish_category_id) | dish_categories(dish_category_id) | `` |
| `canonical_food_type` | `food_type` | YES |  |  | `` |
| `cuisine` | `character varying(80)` | YES |  |  | `` |
| `description` | `text` | YES |  |  | `` |
| `image_url` | `character varying(500)` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | NO |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |
| `deleted_at` | `timestamp with time zone` | YES |  |  | `` |

## `email_verification_codes`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `id` | `bigint` | NO | PK |  | `nextval('cleangoal.email_verification_codes_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `code` | `character varying(10)` | NO |  |  | `` |
| `expires_at` | `timestamp with time zone` | NO |  |  | `` |
| `used` | `boolean` | YES |  |  | `false` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `exercise_logs`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `log_id` | `bigint` | NO | PK |  | `nextval('cleangoal.exercise_logs_log_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `date_record` | `date` | NO |  |  | `CURRENT_DATE` |
| `activity_name` | `character varying(100)` | NO |  |  | `` |
| `duration_minutes` | `integer` | NO |  |  | `0` |
| `calories_burned` | `numeric` | YES |  |  | `0` |
| `intensity` | `character varying(20)` | YES |  |  | `'moderate'::character varying` |
| `note` | `character varying(255)` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `food_allergy_flags`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `food_id` | `bigint` | NO | FK; PK(food_id,flag_id) | foods(food_id) | `` |
| `flag_id` | `integer` | NO | FK; PK(food_id,flag_id) | allergy_flags(flag_id) | `` |

## `food_ingredients`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `food_ing_id` | `bigint` | NO | PK |  | `nextval('cleangoal.food_ingredients_food_ing_id_seq'::regclass)` |
| `food_id` | `bigint` | YES | FK | foods(food_id) | `` |
| `ingredient_id` | `bigint` | YES | FK | ingredients(ingredient_id) | `` |
| `amount` | `numeric` | YES |  |  | `` |
| `unit_id` | `integer` | YES | FK | units(unit_id) | `` |
| `calculated_grams` | `numeric` | YES |  |  | `` |
| `note` | `character varying` | YES |  |  | `` |

## `food_requests`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `request_id` | `bigint` | NO | PK |  | `nextval('cleangoal.food_requests_request_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `food_name` | `character varying(200)` | NO |  |  | `` |
| `status` | `request_status` | YES |  |  | `'pending'::cleangoal.request_status` |
| `ingredients_json` | `jsonb` | YES |  |  | `` |
| `reviewed_by` | `bigint` | YES | FK | users(user_id) | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `foods`

Type: BASE TABLE; rows: 103

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `food_id` | `bigint` | NO | PK |  | `nextval('cleangoal.foods_food_id_seq'::regclass)` |
| `food_name` | `character varying(200)` | NO | UNIQUE(food_name) |  | `` |
| `food_type` | `food_type` | YES |  |  | `'raw_ingredient'::cleangoal.food_type` |
| `calories` | `numeric` | YES |  |  | `` |
| `protein` | `numeric` | YES |  |  | `` |
| `carbs` | `numeric` | YES |  |  | `` |
| `fat` | `numeric` | YES |  |  | `` |
| `sodium` | `numeric` | YES |  |  | `` |
| `sugar` | `numeric` | YES |  |  | `` |
| `cholesterol` | `numeric` | YES |  |  | `` |
| `serving_quantity` | `numeric` | YES |  |  | `100` |
| `serving_unit` | `character varying(30)` | YES |  |  | `'g'::character varying` |
| `image_url` | `character varying(500)` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |
| `deleted_at` | `timestamp with time zone` | YES |  |  | `` |
| `fiber_g` | `numeric` | YES |  |  | `0` |
| `food_category` | `character varying` | YES |  |  | `` |
| `serving_unit_id` | `integer` | YES | FK | units(unit_id) | `` |
| `dish_id` | `bigint` | YES | FK | dishes(dish_id) | `` |

## `health_contents`

Type: BASE TABLE; rows: 20

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `content_id` | `bigint` | NO | PK |  | `nextval('cleangoal.health_contents_content_id_seq'::regclass)` |
| `title` | `character varying` | NO |  |  | `` |
| `type` | `content_type` | YES |  |  | `` |
| `thumbnail_url` | `character varying` | YES |  |  | `` |
| `resource_url` | `character varying` | YES |  |  | `` |
| `description` | `text` | YES |  |  | `` |
| `category_tag` | `character varying` | YES |  |  | `` |
| `difficulty_level` | `character varying` | YES |  |  | `` |
| `is_published` | `boolean` | YES |  |  | `true` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `ingredients`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `ingredient_id` | `bigint` | NO | PK |  | `nextval('cleangoal.ingredients_ingredient_id_seq'::regclass)` |
| `name` | `character varying(150)` | NO | UNIQUE(name) |  | `` |
| `category` | `character varying(50)` | YES |  |  | `` |
| `default_unit_id` | `integer` | YES | FK | units(unit_id) | `` |
| `calories_per_unit` | `numeric` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `meals`

Type: BASE TABLE; rows: 23

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `meal_id` | `bigint` | NO | PK |  | `` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `meal_time` | `timestamp with time zone` | YES |  |  | `now()` |
| `total_amount` | `numeric` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |
| `meal_type` | `meal_type` | NO |  |  | `` |

## `notifications`

Type: BASE TABLE; rows: 14

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `notification_id` | `bigint` | NO | PK |  | `nextval('cleangoal.notifications_notification_id_seq'::regclass)` |
| `user_id` | `bigint` | YES | FK | users(user_id) | `` |
| `title` | `character varying(200)` | NO |  |  | `` |
| `message` | `text` | YES |  |  | `` |
| `type` | `notification_type` | YES |  |  | `` |
| `is_read` | `boolean` | YES |  |  | `false` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `password_reset_codes`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `id` | `bigint` | NO | PK |  | `nextval('cleangoal.password_reset_codes_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `code` | `character varying(10)` | NO |  |  | `` |
| `expires_at` | `timestamp with time zone` | NO |  |  | `` |
| `used` | `boolean` | YES |  |  | `false` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_favorites`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `fav_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK; UNIQUE(recipe_id,user_id) | recipes(recipe_id) | `` |
| `user_id` | `bigint` | NO | FK; UNIQUE(recipe_id,user_id) | users(user_id) | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_ingredients`

Type: BASE TABLE; rows: 35

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `ing_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK | recipes(recipe_id) | `` |
| `ingredient_name` | `character varying` | NO |  |  | `` |
| `quantity` | `numeric` | YES |  |  | `` |
| `unit` | `character varying` | YES |  |  | `` |
| `is_optional` | `boolean` | YES |  |  | `false` |
| `note` | `character varying` | YES |  |  | `` |
| `sort_order` | `integer` | YES |  |  | `0` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_relation_orphan_archive`

Type: BASE TABLE; rows: 100

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `archive_id` | `bigint` | NO | PK |  | `nextval('cleangoal.recipe_relation_orphan_archive_archive_id_seq'::regclass)` |
| `source_table` | `character varying(80)` | NO |  |  | `` |
| `source_pk` | `bigint` | YES |  |  | `` |
| `legacy_recipe_id` | `bigint` | YES |  |  | `` |
| `legacy_user_id` | `bigint` | YES |  |  | `` |
| `row_data` | `jsonb` | NO |  |  | `` |
| `archive_reason` | `text` | NO |  |  | `` |
| `archived_at` | `timestamp with time zone` | NO |  |  | `now()` |

## `recipe_reviews`

Type: BASE TABLE; rows: 1

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `review_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK; UNIQUE(recipe_id,user_id) | recipes(recipe_id) | `` |
| `user_id` | `bigint` | NO | FK; UNIQUE(recipe_id,user_id) | users(user_id) | `` |
| `rating` | `smallint` | YES |  |  | `` |
| `comment` | `text` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_reviews_orphan_archive`

Type: BASE TABLE; rows: 20

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `archive_id` | `bigint` | NO | PK |  | `nextval('cleangoal.recipe_reviews_orphan_archive_archive_id_seq'::regclass)` |
| `review_id` | `bigint` | YES |  |  | `` |
| `legacy_recipe_id` | `bigint` | YES |  |  | `` |
| `legacy_food_id` | `bigint` | YES |  |  | `` |
| `user_id` | `bigint` | YES |  |  | `` |
| `rating` | `smallint` | YES |  |  | `` |
| `comment` | `text` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `` |
| `archived_at` | `timestamp with time zone` | NO |  |  | `now()` |
| `archive_reason` | `text` | NO |  |  | `` |

## `recipe_steps`

Type: BASE TABLE; rows: 20

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `step_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK | recipes(recipe_id) | `` |
| `step_number` | `integer` | NO |  |  | `` |
| `title` | `character varying` | YES |  |  | `` |
| `instruction` | `text` | NO |  |  | `` |
| `time_minutes` | `integer` | YES |  |  | `0` |
| `image_url` | `character varying` | YES |  |  | `` |
| `tips` | `text` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_tips`

Type: BASE TABLE; rows: 10

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `tip_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK | recipes(recipe_id) | `` |
| `tip_text` | `text` | NO |  |  | `` |
| `sort_order` | `integer` | YES |  |  | `0` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipe_tools`

Type: BASE TABLE; rows: 12

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `tool_id` | `bigint` | NO | PK |  | `` |
| `recipe_id` | `bigint` | NO | FK | recipes(recipe_id) | `` |
| `tool_name` | `character varying` | NO |  |  | `` |
| `tool_emoji` | `character varying` | YES |  |  | `` |
| `sort_order` | `integer` | YES |  |  | `0` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `recipes`

Type: BASE TABLE; rows: 5

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `recipe_id` | `bigint` | NO | PK |  | `nextval('cleangoal.recipes_recipe_id_seq'::regclass)` |
| `food_id` | `bigint` | NO | FK; UNIQUE(food_id) | foods(food_id) | `` |
| `description` | `character varying` | YES |  |  | `` |
| `instructions` | `text` | YES |  |  | `` |
| `prep_time_minutes` | `integer` | YES |  |  | `0` |
| `cooking_time_minutes` | `integer` | YES |  |  | `0` |
| `serving_people` | `numeric` | YES |  |  | `1.0` |
| `source_reference` | `character varying` | YES |  |  | `` |
| `image_url` | `character varying` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |
| `deleted_at` | `timestamp with time zone` | YES |  |  | `` |
| `avg_rating` | `numeric` | YES |  |  | `0` |
| `review_count` | `integer` | YES |  |  | `0` |
| `ingredients_json` | `jsonb` | YES |  |  | `` |
| `tools_json` | `jsonb` | YES |  |  | `` |
| `tips_json` | `jsonb` | YES |  |  | `` |
| `generated_by` | `character varying(32)` | YES |  |  | `` |
| `favorite_count` | `integer` | NO |  |  | `0` |

## `roles`

Type: BASE TABLE; rows: 2

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `role_id` | `integer` | NO | PK |  | `nextval('cleangoal.roles_role_id_seq'::regclass)` |
| `role_name` | `character varying(30)` | NO | UNIQUE(role_name) |  | `` |

## `schema_migrations`

Type: BASE TABLE; rows: 22

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `version` | `character varying(255)` | NO | PK |  | `` |
| `applied_at` | `timestamp with time zone` | YES |  |  | `CURRENT_TIMESTAMP` |

## `snacks`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `snack_id` | `bigint` | NO | PK |  | `nextval('cleangoal.snacks_snack_id_seq'::regclass)` |
| `food_id` | `bigint` | YES | FK; UNIQUE(food_id) | foods(food_id) | `` |
| `is_sweet` | `boolean` | YES |  |  | `true` |
| `packaging_type` | `character varying` | YES |  |  | `` |
| `trans_fat` | `numeric` | YES |  |  | `` |

## `temp_food`

Type: BASE TABLE; rows: 5

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `tf_id` | `bigint` | NO | PK |  | `nextval('cleangoal.temp_food_tf_id_seq'::regclass)` |
| `food_name` | `character varying(200)` | NO |  |  | `` |
| `protein` | `numeric` | YES |  |  | `0` |
| `fat` | `numeric` | YES |  |  | `0` |
| `carbs` | `numeric` | YES |  |  | `0` |
| `calories` | `numeric` | YES |  |  | `0` |
| `user_id` | `bigint` | NO | FK | users(user_id) | `` |
| `created_at` | `timestamp with time zone` | NO |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |

## `unit_conversion_orphan_archive`

Type: BASE TABLE; rows: 19

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `archive_id` | `bigint` | NO | PK |  | `nextval('cleangoal.unit_conversion_orphan_archive_archive_id_seq'::regclass)` |
| `conversion_id` | `integer` | YES |  |  | `` |
| `from_unit_id` | `integer` | YES |  |  | `` |
| `to_unit_id` | `integer` | YES |  |  | `` |
| `row_data` | `jsonb` | NO |  |  | `` |
| `archive_reason` | `text` | NO |  |  | `` |
| `archived_at` | `timestamp with time zone` | NO |  |  | `now()` |

## `unit_conversions`

Type: BASE TABLE; rows: 5

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `conversion_id` | `integer` | NO | PK |  | `nextval('cleangoal.unit_conversions_conversion_id_seq'::regclass)` |
| `from_unit_id` | `integer` | NO | FK; UNIQUE(from_unit_id,to_unit_id) | units(unit_id) | `` |
| `to_unit_id` | `integer` | NO | FK; UNIQUE(from_unit_id,to_unit_id) | units(unit_id) | `` |
| `factor` | `numeric` | NO |  |  | `` |
| `note` | `character varying` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `units`

Type: BASE TABLE; rows: 16

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `unit_id` | `integer` | NO | PK |  | `nextval('cleangoal.units_unit_id_seq'::regclass)` |
| `name` | `character varying(30)` | NO |  |  | `` |
| `quantity` | `numeric` | YES |  |  | `` |

## `user_allergy_preferences`

Type: BASE TABLE; rows: 1

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `user_id` | `bigint` | NO | FK; PK(user_id,flag_id) | users(user_id) | `` |
| `flag_id` | `integer` | NO | FK; PK(user_id,flag_id) | allergy_flags(flag_id) | `` |
| `preference_type` | `character varying` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `user_favorites`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `id` | `bigint` | NO | PK |  | `nextval('cleangoal.user_favorites_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK; UNIQUE(user_id,food_id) | users(user_id) | `` |
| `food_id` | `bigint` | NO | FK; UNIQUE(user_id,food_id) | foods(food_id) | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `user_meal_plans`

Type: BASE TABLE; rows: 0

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `plan_id` | `bigint` | NO | PK |  | `nextval('cleangoal.user_meal_plans_plan_id_seq'::regclass)` |
| `user_id` | `bigint` | YES | FK | users(user_id) | `` |
| `name` | `character varying` | NO |  |  | `` |
| `description` | `text` | YES |  |  | `` |
| `source_type` | `character varying` | YES |  |  | `'SYSTEM'::character varying` |
| `is_premium` | `boolean` | YES |  |  | `false` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `users`

Type: BASE TABLE; rows: 19

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `user_id` | `bigint` | NO | PK |  | `nextval('cleangoal.users_user_id_seq'::regclass)` |
| `username` | `character varying(50)` | YES |  |  | `` |
| `email` | `character varying(255)` | NO | UNIQUE(email) |  | `` |
| `password_hash` | `character varying(255)` | NO |  |  | `` |
| `gender` | `gender_type` | YES |  |  | `` |
| `birth_date` | `date` | YES |  |  | `` |
| `height_cm` | `numeric` | YES |  |  | `` |
| `current_weight_kg` | `numeric` | YES |  |  | `` |
| `goal_type` | `goal_type_enum` | YES |  |  | `` |
| `target_weight_kg` | `numeric` | YES |  |  | `` |
| `target_calories` | `integer` | YES |  |  | `` |
| `target_protein` | `integer` | YES |  |  | `` |
| `target_carbs` | `integer` | YES |  |  | `` |
| `target_fat` | `integer` | YES |  |  | `` |
| `activity_level` | `activity_level` | YES |  |  | `` |
| `goal_start_date` | `date` | YES |  |  | `CURRENT_DATE` |
| `goal_target_date` | `date` | YES |  |  | `` |
| `last_kpi_check_date` | `date` | YES |  |  | `CURRENT_DATE` |
| `current_streak` | `integer` | YES |  |  | `0` |
| `last_login_date` | `timestamp with time zone` | YES |  |  | `` |
| `total_login_days` | `integer` | YES |  |  | `0` |
| `avatar_url` | `character varying(500)` | YES |  |  | `` |
| `role_id` | `integer` | YES | FK | roles(role_id) | `2` |
| `is_email_verified` | `boolean` | YES |  |  | `false` |
| `consent_accepted_at` | `timestamp with time zone` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |
| `deleted_at` | `timestamp with time zone` | YES |  |  | `` |
| `last_tdee_recalc_date` | `date` | YES |  |  | `` |

## `verified_food`

Type: BASE TABLE; rows: 5

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `vf_id` | `bigint` | NO | PK |  | `nextval('cleangoal.verified_food_vf_id_seq'::regclass)` |
| `tf_id` | `bigint` | NO | FK; UNIQUE(tf_id) | temp_food(tf_id) | `` |
| `is_verify` | `boolean` | NO |  |  | `false` |
| `verified_by` | `bigint` | YES | FK | users(user_id) | `` |
| `verified_at` | `timestamp with time zone` | YES |  |  | `` |
| `created_at` | `timestamp with time zone` | NO |  |  | `now()` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `` |

## `water_logs`

Type: BASE TABLE; rows: 8

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `log_id` | `bigint` | NO | PK |  | `nextval('cleangoal.water_logs_log_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK; UNIQUE(user_id,date_record) | users(user_id) | `` |
| `date_record` | `date` | NO | UNIQUE(user_id,date_record) |  | `CURRENT_DATE` |
| `glasses` | `integer` | NO |  |  | `0` |
| `updated_at` | `timestamp with time zone` | YES |  |  | `now()` |
| `amount_ml` | `integer` | NO |  |  | `0` |

## `weight_logs`

Type: BASE TABLE; rows: 14

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `log_id` | `bigint` | NO | PK |  | `nextval('cleangoal.weight_logs_log_id_seq'::regclass)` |
| `user_id` | `bigint` | NO | FK; UNIQUE(user_id,recorded_date) | users(user_id) | `` |
| `weight_kg` | `numeric` | NO |  |  | `` |
| `recorded_date` | `date` | YES | UNIQUE(user_id,recorded_date) |  | `CURRENT_DATE` |
| `created_at` | `timestamp with time zone` | YES |  |  | `now()` |

## `v_admin_temp_food_review`

Type: VIEW

| Column | Type | Null | Key | References | Default |
|---|---|---|---|---|---|
| `tf_id` | `bigint` | YES |  |  | `` |
| `food_name` | `character varying(200)` | YES |  |  | `` |
| `protein` | `numeric` | YES |  |  | `` |
| `fat` | `numeric` | YES |  |  | `` |
| `carbs` | `numeric` | YES |  |  | `` |
| `calories` | `numeric` | YES |  |  | `` |
| `submitted_by` | `bigint` | YES |  |  | `` |
| `submitted_by_username` | `character varying(50)` | YES |  |  | `` |
| `submitted_at` | `timestamp with time zone` | YES |  |  | `` |
| `last_edited_at` | `timestamp with time zone` | YES |  |  | `` |
| `vf_id` | `bigint` | YES |  |  | `` |
| `is_verify` | `boolean` | YES |  |  | `` |
| `verified_by` | `bigint` | YES |  |  | `` |
| `verified_at` | `timestamp with time zone` | YES |  |  | `` |

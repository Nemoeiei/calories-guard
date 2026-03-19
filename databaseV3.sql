--
-- PostgreSQL database dump
--

\restrict q5N7IVVZBaDp9Q3ptT3ow45Se8MJWDPXqUKj4go51lN3y6TSGOdPI8N3lP1vmew

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-16 11:20:24

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 17529)
-- Name: cleangoal; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA cleangoal;


ALTER SCHEMA cleangoal OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 20590)
-- Name: pubilc; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pubilc;


ALTER SCHEMA pubilc OWNER TO postgres;

--
-- TOC entry 915 (class 1247 OID 20600)
-- Name: activity_level; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.activity_level AS ENUM (
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active'
);


ALTER TYPE cleangoal.activity_level OWNER TO postgres;

--
-- TOC entry 918 (class 1247 OID 20610)
-- Name: content_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.content_type AS ENUM (
    'article',
    'video'
);


ALTER TYPE cleangoal.content_type OWNER TO postgres;

--
-- TOC entry 921 (class 1247 OID 20616)
-- Name: food_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.food_type AS ENUM (
    'raw_ingredient',
    'recipe_dish',
    'dish',
    'beverage',
    'snack'
);


ALTER TYPE cleangoal.food_type OWNER TO postgres;

--
-- TOC entry 924 (class 1247 OID 20622)
-- Name: gender_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.gender_type AS ENUM (
    'male',
    'female'
);


ALTER TYPE cleangoal.gender_type OWNER TO postgres;

--
-- TOC entry 912 (class 1247 OID 20592)
-- Name: goal_type_enum; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.goal_type_enum AS ENUM (
    'lose_weight',
    'maintain_weight',
    'gain_muscle'
);


ALTER TYPE cleangoal.goal_type_enum OWNER TO postgres;

--
-- TOC entry 927 (class 1247 OID 20628)
-- Name: meal_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.meal_type AS ENUM (
    'breakfast',
    'lunch',
    'dinner',
    'snack'
);


ALTER TYPE cleangoal.meal_type OWNER TO postgres;

--
-- TOC entry 930 (class 1247 OID 20638)
-- Name: notification_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.notification_type AS ENUM (
    'system_alert',
    'achievement',
    'content_update',
    'system_announcement'
);


ALTER TYPE cleangoal.notification_type OWNER TO postgres;

--
-- TOC entry 933 (class 1247 OID 20648)
-- Name: request_status; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.request_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE cleangoal.request_status OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 20694)
-- Name: allergy_flags; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.allergy_flags (
    flag_id integer NOT NULL,
    name character varying NOT NULL,
    description character varying
);


ALTER TABLE cleangoal.allergy_flags OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 20693)
-- Name: allergy_flags_flag_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.allergy_flags_flag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.allergy_flags_flag_id_seq OWNER TO postgres;

--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 224
-- Name: allergy_flags_flag_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.allergy_flags_flag_id_seq OWNED BY cleangoal.allergy_flags.flag_id;


--
-- TOC entry 236 (class 1259 OID 20795)
-- Name: beverages; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.beverages (
    beverage_id bigint NOT NULL,
    food_id bigint,
    volume_ml numeric(6,2),
    is_alcoholic boolean DEFAULT false,
    caffeine_mg numeric(6,2) DEFAULT 0,
    sugar_level_label character varying,
    container_type character varying
);


ALTER TABLE cleangoal.beverages OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 20794)
-- Name: beverages_beverage_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.beverages_beverage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.beverages_beverage_id_seq OWNER TO postgres;

--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 235
-- Name: beverages_beverage_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.beverages_beverage_id_seq OWNED BY cleangoal.beverages.beverage_id;


--
-- TOC entry 246 (class 1259 OID 20889)
-- Name: daily_summaries; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.daily_summaries (
    summary_id bigint NOT NULL,
    user_id bigint,
    item_id bigint,
    date_record date DEFAULT CURRENT_DATE,
    total_calories_intake numeric(10,2) DEFAULT 0,
    goal_calories integer,
    is_goal_met boolean DEFAULT false
);


ALTER TABLE cleangoal.daily_summaries OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 20888)
-- Name: daily_summaries_summary_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.daily_summaries_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.daily_summaries_summary_id_seq OWNER TO postgres;

--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 245
-- Name: daily_summaries_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.daily_summaries_summary_id_seq OWNED BY cleangoal.daily_summaries.summary_id;


--
-- TOC entry 248 (class 1259 OID 20907)
-- Name: detail_items; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.detail_items (
    item_id bigint NOT NULL,
    meal_id bigint,
    plan_id bigint,
    summary_id bigint,
    food_id bigint,
    food_name character varying,
    day_number integer,
    amount numeric(8,2) DEFAULT 1.0,
    unit_id integer,
    cal_per_unit numeric(10,2),
    note character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.detail_items OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 20906)
-- Name: detail_items_item_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.detail_items_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.detail_items_item_id_seq OWNER TO postgres;

--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 247
-- Name: detail_items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.detail_items_item_id_seq OWNED BY cleangoal.detail_items.item_id;


--
-- TOC entry 234 (class 1259 OID 20770)
-- Name: food_ingredients; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.food_ingredients (
    food_ing_id bigint NOT NULL,
    food_id bigint,
    ingredient_id bigint,
    amount numeric(6,2),
    unit_id integer,
    calculated_grams numeric(6,2),
    note character varying
);


ALTER TABLE cleangoal.food_ingredients OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 20769)
-- Name: food_ingredients_food_ing_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.food_ingredients_food_ing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.food_ingredients_food_ing_id_seq OWNER TO postgres;

--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 233
-- Name: food_ingredients_food_ing_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.food_ingredients_food_ing_id_seq OWNED BY cleangoal.food_ingredients.food_ing_id;


--
-- TOC entry 258 (class 1259 OID 21029)
-- Name: food_requests; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.food_requests (
    request_id bigint NOT NULL,
    user_id bigint NOT NULL,
    food_name character varying NOT NULL,
    status cleangoal.request_status DEFAULT 'pending'::cleangoal.request_status,
    ingredients_json jsonb,
    reviewed_by bigint,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.food_requests OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 21028)
-- Name: food_requests_request_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.food_requests_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.food_requests_request_id_seq OWNER TO postgres;

--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 257
-- Name: food_requests_request_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.food_requests_request_id_seq OWNED BY cleangoal.food_requests.request_id;


--
-- TOC entry 230 (class 1259 OID 20736)
-- Name: foods; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.foods (
    food_id bigint NOT NULL,
    food_name character varying NOT NULL,
    food_type cleangoal.food_type DEFAULT 'raw_ingredient'::cleangoal.food_type,
    calories numeric(6,2),
    protein numeric(6,2),
    carbs numeric(6,2),
    fat numeric(6,2),
    sodium numeric(6,2),
    sugar numeric(6,2),
    cholesterol numeric(6,2),
    serving_quantity numeric(6,2) DEFAULT 100,
    serving_unit character varying DEFAULT 'g'::character varying,
    image_url character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE cleangoal.foods OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 20735)
-- Name: foods_food_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.foods_food_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.foods_food_id_seq OWNER TO postgres;

--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 229
-- Name: foods_food_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.foods_food_id_seq OWNED BY cleangoal.foods.food_id;


--
-- TOC entry 264 (class 1259 OID 21088)
-- Name: health_contents; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.health_contents (
    content_id bigint NOT NULL,
    title character varying NOT NULL,
    type cleangoal.content_type,
    thumbnail_url character varying,
    resource_url character varying,
    description text,
    category_tag character varying,
    difficulty_level character varying,
    is_published boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.health_contents OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 21087)
-- Name: health_contents_content_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.health_contents_content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.health_contents_content_id_seq OWNER TO postgres;

--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 263
-- Name: health_contents_content_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.health_contents_content_id_seq OWNED BY cleangoal.health_contents.content_id;


--
-- TOC entry 232 (class 1259 OID 20751)
-- Name: ingredients; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.ingredients (
    ingredient_id bigint NOT NULL,
    name character varying NOT NULL,
    category character varying,
    default_unit_id integer,
    calories_per_unit numeric(6,2),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.ingredients OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 20750)
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.ingredients_ingredient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.ingredients_ingredient_id_seq OWNER TO postgres;

--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 231
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.ingredients_ingredient_id_seq OWNED BY cleangoal.ingredients.ingredient_id;


--
-- TOC entry 242 (class 1259 OID 20853)
-- Name: meals; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.meals (
    meal_id bigint NOT NULL,
    user_id bigint,
    item_id bigint,
    meal_type cleangoal.meal_type,
    meal_time timestamp without time zone DEFAULT now(),
    total_amount numeric,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.meals OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 20852)
-- Name: meals_meal_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.meals_meal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.meals_meal_id_seq OWNER TO postgres;

--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 241
-- Name: meals_meal_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.meals_meal_id_seq OWNED BY cleangoal.meals.meal_id;


--
-- TOC entry 262 (class 1259 OID 21070)
-- Name: notifications; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.notifications (
    notification_id bigint NOT NULL,
    user_id bigint,
    title character varying NOT NULL,
    message text,
    type cleangoal.notification_type,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.notifications OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 21069)
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.notifications_notification_id_seq OWNER TO postgres;

--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 261
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.notifications_notification_id_seq OWNED BY cleangoal.notifications.notification_id;


--
-- TOC entry 256 (class 1259 OID 21001)
-- Name: progress; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.progress (
    progress_id bigint NOT NULL,
    user_id bigint NOT NULL,
    weight_id bigint,
    daily_id bigint,
    current_streak integer DEFAULT 0,
    weekly_target character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.progress OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 21000)
-- Name: progress_progress_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.progress_progress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.progress_progress_id_seq OWNER TO postgres;

--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 255
-- Name: progress_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.progress_progress_id_seq OWNED BY cleangoal.progress.progress_id;


--
-- TOC entry 240 (class 1259 OID 20832)
-- Name: recipes; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipes (
    recipe_id bigint NOT NULL,
    food_id bigint,
    description character varying,
    instructions text,
    prep_time_minutes integer DEFAULT 0,
    cooking_time_minutes integer DEFAULT 0,
    serving_people numeric(3,1) DEFAULT 1.0,
    source_reference character varying,
    image_url character varying,
    created_at timestamp without time zone DEFAULT now(),
    deleted_at timestamp without time zone
);


ALTER TABLE cleangoal.recipes OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 20831)
-- Name: recipes_recipe_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipes_recipe_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipes_recipe_id_seq OWNER TO postgres;

--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 239
-- Name: recipes_recipe_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipes_recipe_id_seq OWNED BY cleangoal.recipes.recipe_id;


--
-- TOC entry 221 (class 1259 OID 20656)
-- Name: roles; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.roles (
    role_id integer NOT NULL,
    role_name character varying NOT NULL
);


ALTER TABLE cleangoal.roles OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 20655)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.roles_role_id_seq OWNER TO postgres;

--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 220
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.roles_role_id_seq OWNED BY cleangoal.roles.role_id;


--
-- TOC entry 238 (class 1259 OID 20814)
-- Name: snacks; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.snacks (
    snack_id bigint NOT NULL,
    food_id bigint,
    is_sweet boolean DEFAULT true,
    packaging_type character varying,
    trans_fat numeric(6,2)
);


ALTER TABLE cleangoal.snacks OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 20813)
-- Name: snacks_snack_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.snacks_snack_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.snacks_snack_id_seq OWNER TO postgres;

--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 237
-- Name: snacks_snack_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.snacks_snack_id_seq OWNED BY cleangoal.snacks.snack_id;


--
-- TOC entry 228 (class 1259 OID 20725)
-- Name: units; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.units (
    unit_id integer NOT NULL,
    name character varying NOT NULL,
    conversion_factor numeric(10,4)
);


ALTER TABLE cleangoal.units OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 20724)
-- Name: units_unit_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.units_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.units_unit_id_seq OWNER TO postgres;

--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 227
-- Name: units_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.units_unit_id_seq OWNED BY cleangoal.units.unit_id;


--
-- TOC entry 250 (class 1259 OID 20944)
-- Name: user_activities; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.user_activities (
    activity_id bigint NOT NULL,
    user_id bigint NOT NULL,
    activity_level cleangoal.activity_level NOT NULL,
    is_current boolean DEFAULT true,
    date_record date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.user_activities OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 20943)
-- Name: user_activities_activity_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.user_activities_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.user_activities_activity_id_seq OWNER TO postgres;

--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_activities_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.user_activities_activity_id_seq OWNED BY cleangoal.user_activities.activity_id;


--
-- TOC entry 226 (class 1259 OID 20704)
-- Name: user_allergy_preferences; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.user_allergy_preferences (
    user_id bigint NOT NULL,
    flag_id integer NOT NULL,
    preference_type character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.user_allergy_preferences OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 20962)
-- Name: user_goals; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.user_goals (
    goal_id bigint NOT NULL,
    user_id bigint NOT NULL,
    goal_name character varying,
    goal_type cleangoal.goal_type_enum NOT NULL,
    target_weight_kg numeric(5,2),
    is_current boolean DEFAULT true,
    goal_start_at date DEFAULT CURRENT_DATE,
    goal_target_date date,
    goal_end_at date,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.user_goals OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 20961)
-- Name: user_goals_goal_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.user_goals_goal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.user_goals_goal_id_seq OWNER TO postgres;

--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 251
-- Name: user_goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.user_goals_goal_id_seq OWNED BY cleangoal.user_goals.goal_id;


--
-- TOC entry 244 (class 1259 OID 20870)
-- Name: user_meal_plans; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.user_meal_plans (
    plan_id bigint NOT NULL,
    user_id bigint,
    item_id bigint,
    name character varying NOT NULL,
    description text,
    source_type character varying DEFAULT 'SYSTEM'::character varying,
    is_premium boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.user_meal_plans OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 20869)
-- Name: user_meal_plans_plan_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.user_meal_plans_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.user_meal_plans_plan_id_seq OWNER TO postgres;

--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 243
-- Name: user_meal_plans_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.user_meal_plans_plan_id_seq OWNED BY cleangoal.user_meal_plans.plan_id;


--
-- TOC entry 223 (class 1259 OID 20669)
-- Name: users; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.users (
    user_id bigint NOT NULL,
    username character varying,
    email character varying NOT NULL,
    password_hash character varying NOT NULL,
    gender cleangoal.gender_type,
    birth_date date,
    height_cm numeric(5,2),
    current_weight_kg numeric(5,2),
    goal_type cleangoal.goal_type_enum,
    target_weight_kg numeric(5,2),
    target_calories integer,
    activity_level cleangoal.activity_level,
    goal_start_date date DEFAULT CURRENT_DATE,
    goal_target_date date,
    last_kpi_check_date date DEFAULT CURRENT_DATE,
    current_streak integer DEFAULT 0,
    last_login_date timestamp without time zone,
    total_login_days integer DEFAULT 0,
    avatar_url character varying,
    role_id integer DEFAULT 2,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    target_protein integer,
    target_carbs integer,
    target_fat integer
);


ALTER TABLE cleangoal.users OWNER TO postgres;

--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_protein; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_protein IS 'เป้าหมายโปรตีน (กรัม/วัน)';


--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_carbs; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_carbs IS 'เป้าหมายคาร์บ (กรัม/วัน)';


--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_fat; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_fat IS 'เป้าหมายไขมัน (กรัม/วัน)';


--
-- TOC entry 222 (class 1259 OID 20668)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 222
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.users_user_id_seq OWNED BY cleangoal.users.user_id;


--
-- TOC entry 260 (class 1259 OID 21053)
-- Name: weekly_summaries; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.weekly_summaries (
    weekly_id bigint NOT NULL,
    user_id bigint NOT NULL,
    start_date date NOT NULL,
    avg_daily_calories integer,
    days_logged_count integer
);


ALTER TABLE cleangoal.weekly_summaries OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 21052)
-- Name: weekly_summaries_weekly_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.weekly_summaries_weekly_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.weekly_summaries_weekly_id_seq OWNER TO postgres;

--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 259
-- Name: weekly_summaries_weekly_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.weekly_summaries_weekly_id_seq OWNED BY cleangoal.weekly_summaries.weekly_id;


--
-- TOC entry 254 (class 1259 OID 20982)
-- Name: weight_logs; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.weight_logs (
    log_id bigint NOT NULL,
    user_id bigint NOT NULL,
    weight_kg numeric(5,2) NOT NULL,
    recorded_date date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.weight_logs OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 20981)
-- Name: weight_logs_log_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.weight_logs_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.weight_logs_log_id_seq OWNER TO postgres;

--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 253
-- Name: weight_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.weight_logs_log_id_seq OWNED BY cleangoal.weight_logs.log_id;


--
-- TOC entry 4998 (class 2604 OID 20697)
-- Name: allergy_flags flag_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.allergy_flags ALTER COLUMN flag_id SET DEFAULT nextval('cleangoal.allergy_flags_flag_id_seq'::regclass);


--
-- TOC entry 5009 (class 2604 OID 20798)
-- Name: beverages beverage_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages ALTER COLUMN beverage_id SET DEFAULT nextval('cleangoal.beverages_beverage_id_seq'::regclass);


--
-- TOC entry 5026 (class 2604 OID 20892)
-- Name: daily_summaries summary_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries ALTER COLUMN summary_id SET DEFAULT nextval('cleangoal.daily_summaries_summary_id_seq'::regclass);


--
-- TOC entry 5030 (class 2604 OID 20910)
-- Name: detail_items item_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items ALTER COLUMN item_id SET DEFAULT nextval('cleangoal.detail_items_item_id_seq'::regclass);


--
-- TOC entry 5008 (class 2604 OID 20773)
-- Name: food_ingredients food_ing_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients ALTER COLUMN food_ing_id SET DEFAULT nextval('cleangoal.food_ingredients_food_ing_id_seq'::regclass);


--
-- TOC entry 5047 (class 2604 OID 21032)
-- Name: food_requests request_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests ALTER COLUMN request_id SET DEFAULT nextval('cleangoal.food_requests_request_id_seq'::regclass);


--
-- TOC entry 5001 (class 2604 OID 20739)
-- Name: foods food_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.foods ALTER COLUMN food_id SET DEFAULT nextval('cleangoal.foods_food_id_seq'::regclass);


--
-- TOC entry 5054 (class 2604 OID 21091)
-- Name: health_contents content_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.health_contents ALTER COLUMN content_id SET DEFAULT nextval('cleangoal.health_contents_content_id_seq'::regclass);


--
-- TOC entry 5006 (class 2604 OID 20754)
-- Name: ingredients ingredient_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients ALTER COLUMN ingredient_id SET DEFAULT nextval('cleangoal.ingredients_ingredient_id_seq'::regclass);


--
-- TOC entry 5019 (class 2604 OID 20856)
-- Name: meals meal_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals ALTER COLUMN meal_id SET DEFAULT nextval('cleangoal.meals_meal_id_seq'::regclass);


--
-- TOC entry 5051 (class 2604 OID 21073)
-- Name: notifications notification_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications ALTER COLUMN notification_id SET DEFAULT nextval('cleangoal.notifications_notification_id_seq'::regclass);


--
-- TOC entry 5044 (class 2604 OID 21004)
-- Name: progress progress_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress ALTER COLUMN progress_id SET DEFAULT nextval('cleangoal.progress_progress_id_seq'::regclass);


--
-- TOC entry 5014 (class 2604 OID 20835)
-- Name: recipes recipe_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes ALTER COLUMN recipe_id SET DEFAULT nextval('cleangoal.recipes_recipe_id_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 20659)
-- Name: roles role_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles ALTER COLUMN role_id SET DEFAULT nextval('cleangoal.roles_role_id_seq'::regclass);


--
-- TOC entry 5012 (class 2604 OID 20817)
-- Name: snacks snack_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks ALTER COLUMN snack_id SET DEFAULT nextval('cleangoal.snacks_snack_id_seq'::regclass);


--
-- TOC entry 5000 (class 2604 OID 20728)
-- Name: units unit_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.units ALTER COLUMN unit_id SET DEFAULT nextval('cleangoal.units_unit_id_seq'::regclass);


--
-- TOC entry 5033 (class 2604 OID 20947)
-- Name: user_activities activity_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities ALTER COLUMN activity_id SET DEFAULT nextval('cleangoal.user_activities_activity_id_seq'::regclass);


--
-- TOC entry 5037 (class 2604 OID 20965)
-- Name: user_goals goal_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals ALTER COLUMN goal_id SET DEFAULT nextval('cleangoal.user_goals_goal_id_seq'::regclass);


--
-- TOC entry 5022 (class 2604 OID 20873)
-- Name: user_meal_plans plan_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans ALTER COLUMN plan_id SET DEFAULT nextval('cleangoal.user_meal_plans_plan_id_seq'::regclass);


--
-- TOC entry 4991 (class 2604 OID 20672)
-- Name: users user_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users ALTER COLUMN user_id SET DEFAULT nextval('cleangoal.users_user_id_seq'::regclass);


--
-- TOC entry 5050 (class 2604 OID 21056)
-- Name: weekly_summaries weekly_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries ALTER COLUMN weekly_id SET DEFAULT nextval('cleangoal.weekly_summaries_weekly_id_seq'::regclass);


--
-- TOC entry 5041 (class 2604 OID 20985)
-- Name: weight_logs log_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs ALTER COLUMN log_id SET DEFAULT nextval('cleangoal.weight_logs_log_id_seq'::regclass);


--
-- TOC entry 5301 (class 0 OID 20694)
-- Dependencies: 225
-- Data for Name: allergy_flags; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.allergy_flags (flag_id, name, description) FROM stdin;
\.


--
-- TOC entry 5312 (class 0 OID 20795)
-- Dependencies: 236
-- Data for Name: beverages; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.beverages (beverage_id, food_id, volume_ml, is_alcoholic, caffeine_mg, sugar_level_label, container_type) FROM stdin;
\.


--
-- TOC entry 5322 (class 0 OID 20889)
-- Dependencies: 246
-- Data for Name: daily_summaries; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.daily_summaries (summary_id, user_id, item_id, date_record, total_calories_intake, goal_calories, is_goal_met) FROM stdin;
1	1	\N	2026-02-17	140.00	\N	f
2	1	\N	2026-02-16	140.00	\N	f
64	2	\N	2026-02-14	1156.00	\N	f
66	2	\N	2026-02-13	1156.00	\N	f
68	2	\N	2026-02-12	1156.00	\N	f
3	1	\N	2026-02-15	3330.00	\N	f
70	2	\N	2026-02-11	1156.00	\N	f
173	12	\N	2026-02-18	650.00	\N	f
124	6	\N	2026-02-17	9770.00	\N	f
74	2	\N	2026-02-09	3002.00	\N	f
139	7	\N	2026-02-18	1380.00	\N	f
171	12	\N	2026-02-19	690.00	\N	f
141	7	\N	2026-02-17	2030.00	\N	f
144	7	\N	2026-02-15	1936.00	\N	f
72	2	\N	2026-02-10	4848.00	\N	f
146	7	\N	2026-02-16	1936.00	\N	f
174	13	\N	2026-02-20	690.00	\N	f
175	13	\N	2026-02-19	695.00	\N	f
138	7	\N	2026-02-19	650.00	\N	f
150	8	\N	2026-02-19	626.00	\N	f
45	2	\N	2026-02-17	10830.00	\N	f
43	2	\N	2026-02-18	0.00	\N	f
12	1	\N	2026-02-18	3572.00	\N	f
99	3	\N	2026-02-15	2070.00	\N	f
102	3	\N	2026-02-14	1380.00	\N	f
151	8	\N	2026-02-18	3084.00	\N	f
104	3	\N	2026-02-13	3356.00	\N	f
109	4	\N	2026-02-14	1986.00	\N	f
60	2	\N	2026-02-16	1156.00	\N	f
62	2	\N	2026-02-15	1156.00	\N	f
113	4	\N	2026-02-16	1291.00	\N	f
176	18	\N	2026-02-24	2525.00	\N	f
115	4	\N	2026-02-17	1887.00	\N	f
112	4	\N	2026-02-18	1887.00	\N	f
121	6	\N	2026-02-19	1882.00	\N	f
123	6	\N	2026-02-18	596.00	\N	f
180	20	\N	2026-02-24	0.00	\N	f
181	23	\N	2026-02-25	596.00	\N	f
182	24	\N	2026-02-25	596.00	\N	f
156	9	\N	2026-02-19	596.00	\N	f
160	9	\N	2026-02-18	1976.00	\N	f
164	10	\N	2026-02-19	540.00	\N	f
165	10	\N	2026-02-18	540.00	\N	f
167	11	\N	2026-02-19	0.00	\N	f
\.


--
-- TOC entry 5324 (class 0 OID 20907)
-- Dependencies: 248
-- Data for Name: detail_items; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.detail_items (item_id, meal_id, plan_id, summary_id, food_id, food_name, day_number, amount, unit_id, cal_per_unit, note, created_at) FROM stdin;
1	1	\N	\N	93	เบียร์ (Lager)	\N	1.00	\N	140.00	\N	2026-02-17 17:40:15.11826
2	2	\N	\N	93	เบียร์ (Lager)	\N	1.00	\N	140.00	\N	2026-02-17 17:40:39.126043
3	3	\N	\N	93	เบียร์ (Lager)	\N	1.00	\N	140.00	\N	2026-02-17 17:41:03.463756
4	4	\N	\N	18	น้ำตกหมู	\N	1.00	\N	280.00	\N	2026-02-17 17:41:03.554438
5	5	\N	\N	93	เบียร์ (Lager)	\N	1.00	\N	140.00	\N	2026-02-17 17:44:25.007393
6	6	\N	\N	18	น้ำตกหมู	\N	1.00	\N	280.00	\N	2026-02-17 17:44:25.131413
7	7	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-17 17:44:25.372233
8	8	\N	\N	93	เบียร์ (Lager)	\N	1.00	\N	140.00	\N	2026-02-17 17:44:41.682962
9	9	\N	\N	18	น้ำตกหมู	\N	1.00	\N	280.00	\N	2026-02-17 17:44:41.798502
10	10	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-17 17:44:41.896719
11	11	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-17 17:44:42.009813
86	86	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:03:01.307826
88	88	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:03:15.239332
90	90	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:04:16.576869
92	92	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:04:45.784274
94	94	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:04:45.956946
98	98	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:46:47.530845
100	100	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:47:08.103362
102	102	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:47:08.448262
104	104	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-18 23:48:06.161926
106	106	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 01:07:42.170936
109	108	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 01:08:16.9273
112	110	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:08:53.944735
114	112	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:09:14.372907
31	31	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-18 20:45:49.241566
32	32	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 20:45:49.324268
33	33	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-18 20:45:49.409517
34	34	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-18 20:45:56.227041
35	35	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 20:45:56.320067
36	36	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-18 20:45:56.402629
116	114	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:09:34.754041
118	116	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:09:50.908661
120	118	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:10:03.204472
121	118	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 01:10:03.204472
123	120	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:10:14.976519
124	120	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 01:10:14.976519
128	122	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 01:10:28.002682
129	122	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 01:10:28.002682
131	124	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:36:52.191624
133	126	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:38:08.339023
135	128	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-19 21:38:08.499222
138	130	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-19 21:39:13.268013
141	132	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-19 21:40:01.757387
144	134	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-19 21:41:29.861174
147	136	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 22:19:16.583063
148	136	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:19:16.583063
150	138	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 22:20:43.888106
151	138	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:20:43.888106
154	140	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 22:30:07.764194
155	140	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:30:07.764194
159	144	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 22:36:00.209783
163	148	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 22:36:38.322155
164	148	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 22:36:38.322155
177	158	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-02-19 23:55:15.982446
179	160	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-20 00:25:17.038099
181	162	\N	\N	30	หมูกระเทียมราดข้าว	\N	1.00	\N	560.00	\N	2026-02-24 20:25:26.279335
182	162	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-24 20:25:26.279335
183	162	\N	\N	15	ไข่เจียวหมูสับ (ราดข้าว)	\N	1.00	\N	580.00	\N	2026-02-24 20:25:26.279335
186	164	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-24 20:46:29.082337
189	166	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-25 14:27:01.657436
85	85	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:02:45.818038
87	87	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:03:01.37836
89	89	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:03:15.322597
91	91	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:04:16.649799
93	93	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-18 23:04:45.858685
99	99	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-18 23:46:47.634782
101	101	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-18 23:47:08.327214
103	103	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:48:06.078737
105	105	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-18 23:48:06.258137
107	107	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 01:07:53.785614
108	107	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 01:07:53.785614
110	109	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:08:53.859796
111	109	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:08:53.859796
113	111	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:09:14.158237
115	113	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:09:34.613908
117	115	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:09:50.759826
119	117	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:10:03.088435
122	119	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:10:14.611968
125	121	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 01:10:27.775706
126	121	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-02-19 01:10:27.775706
127	121	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 01:10:27.775706
132	125	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:36:52.265907
134	127	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:38:08.417908
136	129	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:39:13.1976
137	129	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 21:39:13.1976
139	131	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 21:40:01.673806
140	131	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 21:40:01.673806
145	135	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 22:18:44.252435
146	135	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:18:44.252435
149	137	\N	\N	27	ข้าวซอยไก่	\N	1.00	\N	580.00	\N	2026-02-19 22:19:16.658064
152	139	\N	\N	65	ข้าวโพดหวาน	\N	1.00	\N	86.00	\N	2026-02-19 22:27:33.838693
153	139	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:27:33.838693
162	147	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-19 22:36:38.242714
165	149	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:55:09.171577
167	151	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-02-19 22:57:34.893675
176	157	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-19 23:47:02.203895
178	159	\N	\N	3	ข้าวขาหมู	\N	1.00	\N	690.00	\N	2026-02-20 00:25:03.383692
190	167	\N	\N	1	ข้าวมันไก่ต้ม	\N	1.00	\N	596.00	\N	2026-02-25 15:20:17.566805
\.


--
-- TOC entry 5310 (class 0 OID 20770)
-- Dependencies: 234
-- Data for Name: food_ingredients; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.food_ingredients (food_ing_id, food_id, ingredient_id, amount, unit_id, calculated_grams, note) FROM stdin;
\.


--
-- TOC entry 5334 (class 0 OID 21029)
-- Dependencies: 258
-- Data for Name: food_requests; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.food_requests (request_id, user_id, food_name, status, ingredients_json, reviewed_by, created_at) FROM stdin;
\.


--
-- TOC entry 5306 (class 0 OID 20736)
-- Dependencies: 230
-- Data for Name: foods; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.foods (food_id, food_name, food_type, calories, protein, carbs, fat, sodium, sugar, cholesterol, serving_quantity, serving_unit, image_url, created_at, updated_at, deleted_at) FROM stdin;
3	ข้าวขาหมู	dish	690.00	25.00	55.00	38.00	1400.00	12.00	150.00	1.00	plate	https://placehold.co/400?text=Pork+Leg	2026-02-17 17:37:50.735627	\N	\N
4	ข้าวหมูแดง	dish	540.00	20.00	78.00	14.00	1100.00	18.00	75.00	1.00	plate	https://placehold.co/400?text=Red+Pork	2026-02-17 17:37:50.735627	\N	\N
5	ข้าวหมูกรอบ	dish	650.00	18.00	60.00	35.00	1250.00	5.00	110.00	1.00	plate	https://placehold.co/400?text=Crispy+Pork	2026-02-17 17:37:50.735627	\N	\N
6	ผัดไทยกุ้งสด	dish	585.00	21.00	68.00	25.00	1300.00	22.00	145.00	1.00	plate	https://placehold.co/400?text=Pad+Thai	2026-02-17 17:37:50.735627	\N	\N
7	ราดหน้าหมูหมัก	dish	480.00	22.00	55.00	18.00	1150.00	8.00	65.00	1.00	plate	https://placehold.co/400?text=Rad+Na	2026-02-17 17:37:50.735627	\N	\N
8	ผัดซีอิ๊วหมู	dish	679.00	26.00	72.00	30.00	1280.00	10.00	95.00	1.00	plate	https://placehold.co/400?text=Pad+See+Ew	2026-02-17 17:37:50.735627	\N	\N
9	สุกี้น้ำรวมมิตร	dish	350.00	25.00	45.00	8.00	1600.00	15.00	120.00	1.00	bowl	https://placehold.co/400?text=Suki+Soup	2026-02-17 17:37:50.735627	\N	\N
10	สุกี้แห้งรวมมิตร	dish	420.00	25.00	50.00	15.00	1550.00	18.00	120.00	1.00	plate	https://placehold.co/400?text=Dry+Suki	2026-02-17 17:37:50.735627	\N	\N
11	ข้าวคลุกกะปิ	dish	615.00	22.00	75.00	24.00	1800.00	14.00	110.00	1.00	plate	https://placehold.co/400?text=Kapi+Rice	2026-02-17 17:37:50.735627	\N	\N
12	แกงเขียวหวานไก่ (ราดข้าว)	dish	550.00	18.00	55.00	28.00	1350.00	12.00	95.00	1.00	plate	https://placehold.co/400?text=Green+Curry	2026-02-17 17:37:50.735627	\N	\N
13	ต้มข่าไก่ (ถ้วย)	dish	320.00	18.00	12.00	24.00	1100.00	6.00	60.00	1.00	bowl	https://placehold.co/400?text=Tom+Kha	2026-02-17 17:37:50.735627	\N	\N
14	แกงส้มชะอมกุ้ง (ถ้วย)	dish	280.00	22.00	18.00	12.00	1450.00	10.00	140.00	1.00	bowl	https://placehold.co/400?text=Sour+Soup	2026-02-17 17:37:50.735627	\N	\N
15	ไข่เจียวหมูสับ (ราดข้าว)	dish	580.00	16.00	48.00	35.00	850.00	1.00	420.00	1.00	plate	https://placehold.co/400?text=Omelet+Rice	2026-02-17 17:37:50.735627	\N	\N
16	ยำวุ้นเส้นหมูสับ	dish	380.00	18.00	52.00	8.00	1600.00	12.00	65.00	1.00	plate	https://placehold.co/400?text=Spicy+Noodle	2026-02-17 17:37:50.735627	\N	\N
17	ลาบหมู	dish	250.00	22.00	12.00	12.00	1300.00	3.00	60.00	1.00	plate	https://placehold.co/400?text=Larb+Pork	2026-02-17 17:37:50.735627	\N	\N
18	น้ำตกหมู	dish	280.00	24.00	10.00	16.00	1250.00	3.00	70.00	1.00	plate	https://placehold.co/400?text=Nam+Tok	2026-02-17 17:37:50.735627	\N	\N
19	ไก่ย่าง (น่องติดสะโพก)	dish	320.00	28.00	2.00	22.00	650.00	4.00	105.00	1.00	piece	https://placehold.co/400?text=Grilled+Chicken	2026-02-17 17:37:50.735627	\N	\N
20	คอหมูย่าง	dish	450.00	18.00	4.00	38.00	700.00	6.00	95.00	1.00	plate	https://placehold.co/400?text=Grilled+Pork+Neck	2026-02-17 17:37:50.735627	\N	\N
21	ก๋วยเตี๋ยวเรือน้ำตกหมู	dish	450.00	20.00	55.00	15.00	1650.00	6.00	80.00	1.00	bowl	https://placehold.co/400?text=Boat+Noodle	2026-02-17 17:37:50.735627	\N	\N
22	บะหมี่เกี๊ยวหมูแดง	dish	480.00	22.00	62.00	14.00	1300.00	5.00	95.00	1.00	bowl	https://placehold.co/400?text=Wonton+Noodle	2026-02-17 17:37:50.735627	\N	\N
23	เย็นตาโฟ	dish	420.00	16.00	58.00	12.00	1700.00	14.00	75.00	1.00	bowl	https://placehold.co/400?text=Yentafo	2026-02-17 17:37:50.735627	\N	\N
24	ก๋วยจั๊บน้ำข้น	dish	520.00	24.00	60.00	20.00	1400.00	4.00	180.00	1.00	bowl	https://placehold.co/400?text=Guay+Jub	2026-02-17 17:37:50.735627	\N	\N
25	ขนมจีนน้ำยา	dish	380.00	12.00	55.00	14.00	1100.00	6.00	45.00	1.00	plate	https://placehold.co/400?text=Kanom+Jeen	2026-02-17 17:37:50.735627	\N	\N
26	ขนมจีนแกงเขียวหวาน	dish	450.00	15.00	58.00	22.00	1250.00	8.00	65.00	1.00	plate	https://placehold.co/400?text=Kanom+Jeen+Green	2026-02-17 17:37:50.735627	\N	\N
27	ข้าวซอยไก่	dish	580.00	24.00	45.00	32.00	1350.00	6.00	110.00	1.00	bowl	https://placehold.co/400?text=Khao+Soi	2026-02-17 17:37:50.735627	\N	\N
28	โจ๊กหมูใส่ไข่	dish	350.00	14.00	48.00	10.00	850.00	0.00	240.00	1.00	bowl	https://placehold.co/400?text=Congee	2026-02-17 17:37:50.735627	\N	\N
29	ต้มเลือดหมู (ไม่รวมข้าว)	dish	250.00	28.00	5.00	12.00	1100.00	0.00	180.00	1.00	bowl	https://placehold.co/400?text=Pork+Blood+Soup	2026-02-17 17:37:50.735627	\N	\N
30	หมูกระเทียมราดข้าว	dish	560.00	22.00	65.00	22.00	1050.00	2.00	85.00	1.00	plate	https://placehold.co/400?text=Garlic+Pork	2026-02-17 17:37:50.735627	\N	\N
31	ผัดพริกแกงหมู (ราดข้าว)	dish	590.00	20.00	62.00	26.00	1300.00	5.00	80.00	1.00	plate	https://placehold.co/400?text=Curry+Paste+Pork	2026-02-17 17:37:50.735627	\N	\N
32	ผัดผักบุ้งไฟแดง (กับข้าว)	dish	180.00	4.00	8.00	14.00	950.00	4.00	0.00	1.00	plate	https://placehold.co/400?text=Morning+Glory	2026-02-17 17:37:50.735627	\N	\N
33	ไข่พะโล้ (ถ้วย)	dish	320.00	16.00	12.00	22.00	1100.00	15.00	380.00	1.00	bowl	https://placehold.co/400?text=Pa+Lo	2026-02-17 17:37:50.735627	\N	\N
34	แกงจืดเต้าหู้หมูสับ	dish	150.00	12.00	8.00	6.00	800.00	2.00	35.00	1.00	bowl	https://placehold.co/400?text=Clear+Soup	2026-02-17 17:37:50.735627	\N	\N
36	ปลานิลทอด	dish	450.00	38.00	0.00	32.00	450.00	0.00	85.00	1.00	plate	https://placehold.co/400?text=Fried+Fish	2026-02-17 17:37:50.735627	\N	\N
37	แหนมเนือง (ชุดเล็ก)	dish	420.00	18.00	45.00	16.00	1400.00	12.00	65.00	1.00	set	https://placehold.co/400?text=Nam+Neung	2026-02-17 17:37:50.735627	\N	\N
38	สเต็กหมู	dish	550.00	35.00	25.00	32.00	950.00	4.00	95.00	1.00	plate	https://placehold.co/400?text=Pork+Steak	2026-02-17 17:37:50.735627	\N	\N
40	สปาเก็ตตี้คาโบนาร่า	dish	680.00	22.00	58.00	38.00	980.00	4.00	120.00	1.00	plate	https://placehold.co/400?text=Carbonara	2026-02-17 17:37:50.735627	\N	\N
41	สันในไก่	raw_ingredient	110.00	24.00	0.00	1.00	50.00	0.00	55.00	100.00	g	https://placehold.co/400?text=Chicken+Tender	2026-02-17 17:37:50.735627	\N	\N
42	ปีกไก่	raw_ingredient	203.00	18.00	0.00	14.00	70.00	0.00	80.00	100.00	g	https://placehold.co/400?text=Chicken+Wing	2026-02-17 17:37:50.735627	\N	\N
1	ข้าวมันไก่ต้ม	dish	596.00	29.00	69.00	21.00	1150.00	2.00	85.00	1.00	plate	http://10.0.2.2:8000/images/food_b286b614-d176-41e5-b6bb-a7ab48d50a0b.png	2026-02-17 17:37:50.735627	\N	\N
39	สเต็กไก่	dish	480.00	40.00	25.00	22.00	850.00	3.00	90.00	1.00	plate	http://10.0.2.2:8000/images/food_d14928dd-816f-476c-895f-3b945cdae5d0.jpg	2026-02-17 17:37:50.735627	\N	\N
43	น่องไก่	raw_ingredient	160.00	19.00	0.00	9.00	65.00	0.00	75.00	100.00	g	https://placehold.co/400?text=Chicken+Drumstick	2026-02-17 17:37:50.735627	\N	\N
44	หมูสามชั้น	raw_ingredient	518.00	9.00	0.00	53.00	30.00	0.00	70.00	100.00	g	https://placehold.co/400?text=Pork+Belly	2026-02-17 17:37:50.735627	\N	\N
45	สันนอกหมู	raw_ingredient	242.00	27.00	0.00	14.00	55.00	0.00	80.00	100.00	g	https://placehold.co/400?text=Pork+Loin	2026-02-17 17:37:50.735627	\N	\N
46	สันคอหมู	raw_ingredient	280.00	24.00	0.00	20.00	60.00	0.00	85.00	100.00	g	https://placehold.co/400?text=Pork+Neck	2026-02-17 17:37:50.735627	\N	\N
47	เนื้อวัว (สันนอก)	raw_ingredient	250.00	26.00	0.00	15.00	60.00	0.00	90.00	100.00	g	https://placehold.co/400?text=Beef+Sirloin	2026-02-17 17:37:50.735627	\N	\N
48	เนื้อวัว (ริบอาย)	raw_ingredient	290.00	24.00	0.00	22.00	65.00	0.00	95.00	100.00	g	https://placehold.co/400?text=Ribeye	2026-02-17 17:37:50.735627	\N	\N
49	กุ้งขาว	raw_ingredient	85.00	20.00	0.50	0.50	120.00	0.00	150.00	100.00	g	https://placehold.co/400?text=Shrimp	2026-02-17 17:37:50.735627	\N	\N
50	หมึกกล้วย	raw_ingredient	92.00	16.00	3.00	1.40	44.00	0.00	233.00	100.00	g	https://placehold.co/400?text=Squid	2026-02-17 17:37:50.735627	\N	\N
51	ปลากะพง (เนื้อ)	raw_ingredient	97.00	20.00	0.00	1.50	70.00	0.00	40.00	100.00	g	https://placehold.co/400?text=Seabass	2026-02-17 17:37:50.735627	\N	\N
52	เต้าหู้ขาว (แข็ง)	raw_ingredient	76.00	8.00	1.90	4.80	7.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Tofu	2026-02-17 17:37:50.735627	\N	\N
53	เส้นใหญ่ (ดิบ)	raw_ingredient	220.00	2.00	48.00	1.50	30.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Wide+Rice+Noodle	2026-02-17 17:37:50.735627	\N	\N
54	เส้นหมี่ (แห้ง)	raw_ingredient	360.00	6.00	80.00	0.50	15.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Rice+Vermicelli	2026-02-17 17:37:50.735627	\N	\N
55	วุ้นเส้น (แห้ง)	raw_ingredient	330.00	0.20	82.00	0.00	10.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Glass+Noodle	2026-02-17 17:37:50.735627	\N	\N
56	ผักคะน้า	raw_ingredient	25.00	2.50	4.00	0.30	20.00	0.50	0.00	100.00	g	https://placehold.co/400?text=Kale	2026-02-17 17:37:50.735627	\N	\N
57	ผักบุ้งจีน	raw_ingredient	20.00	2.00	3.50	0.20	25.00	0.40	0.00	100.00	g	https://placehold.co/400?text=Morning+Glory	2026-02-17 17:37:50.735627	\N	\N
58	กะหล่ำปลี	raw_ingredient	25.00	1.30	6.00	0.10	18.00	3.20	0.00	100.00	g	https://placehold.co/400?text=Cabbage	2026-02-17 17:37:50.735627	\N	\N
59	ผักกาดขาว	raw_ingredient	16.00	1.20	3.00	0.20	15.00	1.50	0.00	100.00	g	https://placehold.co/400?text=Chinese+Cabbage	2026-02-17 17:37:50.735627	\N	\N
60	แครอท	raw_ingredient	41.00	0.90	10.00	0.20	69.00	4.70	0.00	100.00	g	https://placehold.co/400?text=Carrot	2026-02-17 17:37:50.735627	\N	\N
61	แตงกวา	raw_ingredient	15.00	0.70	3.60	0.10	2.00	1.70	0.00	100.00	g	https://placehold.co/400?text=Cucumber	2026-02-17 17:37:50.735627	\N	\N
62	มะเขือเทศ	raw_ingredient	18.00	0.90	3.90	0.20	5.00	2.60	0.00	100.00	g	https://placehold.co/400?text=Tomato	2026-02-17 17:37:50.735627	\N	\N
63	ฟักทอง	raw_ingredient	26.00	1.00	6.50	0.10	1.00	2.80	0.00	100.00	g	https://placehold.co/400?text=Pumpkin	2026-02-17 17:37:50.735627	\N	\N
64	มันฝรั่ง	raw_ingredient	77.00	2.00	17.00	0.10	6.00	0.80	0.00	100.00	g	https://placehold.co/400?text=Potato	2026-02-17 17:37:50.735627	\N	\N
65	ข้าวโพดหวาน	raw_ingredient	86.00	3.20	19.00	1.20	15.00	6.00	0.00	100.00	g	https://placehold.co/400?text=Sweet+Corn	2026-02-17 17:37:50.735627	\N	\N
66	ถั่วลันเตา	raw_ingredient	81.00	5.40	14.00	0.40	5.00	5.70	0.00	100.00	g	https://placehold.co/400?text=Green+Peas	2026-02-17 17:37:50.735627	\N	\N
67	เห็ดเข็มทอง	raw_ingredient	37.00	2.70	7.80	0.30	3.00	0.20	0.00	100.00	g	https://placehold.co/400?text=Enoki+Mushroom	2026-02-17 17:37:50.735627	\N	\N
68	พริกขี้หนู	raw_ingredient	40.00	1.90	8.80	0.40	9.00	5.00	0.00	100.00	g	https://placehold.co/400?text=Chili	2026-02-17 17:37:50.735627	\N	\N
69	กระเทียม	raw_ingredient	149.00	6.40	33.00	0.50	17.00	1.00	0.00	100.00	g	https://placehold.co/400?text=Garlic	2026-02-17 17:37:50.735627	\N	\N
70	หอมใหญ่	raw_ingredient	40.00	1.10	9.00	0.10	4.00	4.20	0.00	100.00	g	https://placehold.co/400?text=Onion	2026-02-17 17:37:50.735627	\N	\N
71	มะม่วงสุก	snack	60.00	0.80	15.00	0.40	1.00	13.70	0.00	100.00	g	https://placehold.co/400?text=Mango	2026-02-17 17:37:50.735627	\N	\N
72	มะม่วงดิบ	snack	65.00	0.50	17.00	0.20	2.00	2.00	0.00	100.00	g	https://placehold.co/400?text=Green+Mango	2026-02-17 17:37:50.735627	\N	\N
73	ทุเรียน	snack	147.00	1.50	27.00	5.30	2.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Durian	2026-02-17 17:37:50.735627	\N	\N
74	มังคุด	snack	73.00	0.40	18.00	0.60	7.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Mangosteen	2026-02-17 17:37:50.735627	\N	\N
75	เงาะ	snack	82.00	0.70	21.00	0.20	11.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Rambutan	2026-02-17 17:37:50.735627	\N	\N
76	ส้ม	snack	47.00	0.90	12.00	0.10	0.00	9.00	0.00	1.00	piece	https://placehold.co/400?text=Orange	2026-02-17 17:37:50.735627	\N	\N
77	แอปเปิ้ลแดง	snack	52.00	0.30	14.00	0.20	1.00	10.00	0.00	1.00	piece	https://placehold.co/400?text=Apple	2026-02-17 17:37:50.735627	\N	\N
78	ฝรั่ง	snack	68.00	2.60	14.00	1.00	2.00	9.00	0.00	1.00	piece	https://placehold.co/400?text=Guava	2026-02-17 17:37:50.735627	\N	\N
79	แตงโม	snack	30.00	0.60	8.00	0.20	1.00	6.00	0.00	100.00	g	https://placehold.co/400?text=Watermelon	2026-02-17 17:37:50.735627	\N	\N
80	สับปะรด	snack	50.00	0.50	13.00	0.10	1.00	10.00	0.00	100.00	g	https://placehold.co/400?text=Pineapple	2026-02-17 17:37:50.735627	\N	\N
81	แก้วมังกร	snack	60.00	1.20	9.00	0.00	0.00	8.00	0.00	100.00	g	https://placehold.co/400?text=Dragon+Fruit	2026-02-17 17:37:50.735627	\N	\N
82	มะละกอสุก	snack	43.00	0.50	11.00	0.30	8.00	8.00	0.00	100.00	g	https://placehold.co/400?text=Papaya	2026-02-17 17:37:50.735627	\N	\N
83	องุ่น	snack	69.00	0.70	18.00	0.20	2.00	15.00	0.00	100.00	g	https://placehold.co/400?text=Grape	2026-02-17 17:37:50.735627	\N	\N
84	สตรอเบอร์รี่	snack	32.00	0.70	7.70	0.30	1.00	4.90	0.00	100.00	g	https://placehold.co/400?text=Strawberry	2026-02-17 17:37:50.735627	\N	\N
85	อะโวคาโด	snack	160.00	2.00	8.50	14.70	7.00	0.70	0.00	100.00	g	https://placehold.co/400?text=Avocado	2026-02-17 17:37:50.735627	\N	\N
86	ชาไทยเย็น	beverage	350.00	2.00	45.00	18.00	60.00	38.00	25.00	1.00	glass	https://placehold.co/400?text=Thai+Tea	2026-02-17 17:37:50.735627	\N	\N
87	กาแฟเย็น (คาปูชิโน่)	beverage	220.00	6.00	25.00	10.00	90.00	18.00	30.00	1.00	glass	https://placehold.co/400?text=Iced+Cappuccino	2026-02-17 17:37:50.735627	\N	\N
88	ชามะนาว	beverage	150.00	0.50	38.00	0.00	20.00	35.00	0.00	1.00	glass	https://placehold.co/400?text=Lemon+Tea	2026-02-17 17:37:50.735627	\N	\N
89	ชาเขียวเย็น (ใส่นม)	beverage	320.00	4.00	40.00	16.00	70.00	32.00	20.00	1.00	glass	https://placehold.co/400?text=Green+Tea	2026-02-17 17:37:50.735627	\N	\N
90	โกโก้เย็น	beverage	380.00	5.00	50.00	18.00	85.00	40.00	25.00	1.00	glass	https://placehold.co/400?text=Iced+Cocoa	2026-02-17 17:37:50.735627	\N	\N
91	น้ำอัดลม (โคล่า)	beverage	140.00	0.00	35.00	0.00	15.00	35.00	0.00	325.00	ml	https://placehold.co/400?text=Cola	2026-02-17 17:37:50.735627	\N	\N
92	น้ำเปล่า	beverage	0.00	0.00	0.00	0.00	0.00	0.00	0.00	600.00	ml	https://placehold.co/400?text=Water	2026-02-17 17:37:50.735627	\N	\N
93	เบียร์ (Lager)	beverage	140.00	1.50	12.00	0.00	10.00	0.00	0.00	330.00	ml	https://placehold.co/400?text=Beer	2026-02-17 17:37:50.735627	\N	\N
94	นมอัลมอนด์	beverage	60.00	2.00	3.00	5.00	150.00	0.00	0.00	200.00	ml	https://placehold.co/400?text=Almond+Milk	2026-02-17 17:37:50.735627	\N	\N
95	น้ำส้มคั้นสด	beverage	90.00	1.50	21.00	0.50	5.00	18.00	0.00	200.00	ml	https://placehold.co/400?text=Orange+Juice	2026-02-17 17:37:50.735627	\N	\N
96	ข้าวเหนียวมะม่วง	snack	450.00	6.00	85.00	12.00	150.00	35.00	0.00	1.00	set	https://placehold.co/400?text=Mango+Sticky+Rice	2026-02-17 17:37:50.735627	\N	\N
97	บัวลอยไข่หวาน	snack	380.00	5.00	65.00	14.00	200.00	25.00	180.00	1.00	bowl	https://placehold.co/400?text=Bua+Loy	2026-02-17 17:37:50.735627	\N	\N
98	ลอดช่องน้ำกะทิ	snack	250.00	2.00	40.00	10.00	120.00	18.00	0.00	1.00	bowl	https://placehold.co/400?text=Lod+Chong	2026-02-17 17:37:50.735627	\N	\N
99	ขนมครก (คู่)	snack	80.00	1.00	12.00	4.00	25.00	6.00	0.00	2.00	piece	https://placehold.co/400?text=Kanom+Krok	2026-02-17 17:37:50.735627	\N	\N
100	สาคูไส้หมู	snack	45.00	1.50	8.00	1.50	50.00	1.00	5.00	1.00	piece	https://placehold.co/400?text=Saku	2026-02-17 17:37:50.735627	\N	\N
35	ปลากะพงนึ่งมะนาว	dish	350.00	42.00	5.00	12.00	1250.00	8.00	95.00	1.00	plate	http://10.0.2.2:8000/images/food_a92c5808-7f33-4ba0-be50-a86dfb9be42f.jpg	2026-02-17 17:37:50.735627	\N	\N
2	ข้าวมันไก่ทอด	dish	695.00	22.00	75.00	32.00	1200.00	2.00	90.00	1.00	plate	https://unshirred-wendolyn-audiometrically.ngrok-free.dev/images/food_720f5a2b-1ce7-46d3-86ed-a248fd9d16a6.jpg	2026-02-17 17:37:50.735627	\N	\N
\.


--
-- TOC entry 5340 (class 0 OID 21088)
-- Dependencies: 264
-- Data for Name: health_contents; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.health_contents (content_id, title, type, thumbnail_url, resource_url, description, category_tag, difficulty_level, is_published, created_at) FROM stdin;
\.


--
-- TOC entry 5308 (class 0 OID 20751)
-- Dependencies: 232
-- Data for Name: ingredients; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.ingredients (ingredient_id, name, category, default_unit_id, calories_per_unit, created_at) FROM stdin;
\.


--
-- TOC entry 5318 (class 0 OID 20853)
-- Dependencies: 242
-- Data for Name: meals; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.meals (meal_id, user_id, item_id, meal_type, meal_time, total_amount, created_at) FROM stdin;
1	1	\N	breakfast	2026-02-17 17:40:15.117214	140.0	2026-02-17 17:40:15.11826
2	1	\N	breakfast	2026-02-16 17:40:39.124623	140.0	2026-02-17 17:40:39.126043
3	1	\N	breakfast	2026-02-15 17:41:03.463367	140.0	2026-02-17 17:41:03.463756
4	1	\N	breakfast	2026-02-15 17:41:03.554126	280.0	2026-02-17 17:41:03.554438
5	1	\N	breakfast	2026-02-15 17:44:25.006506	140.0	2026-02-17 17:44:25.007393
6	1	\N	breakfast	2026-02-15 17:44:25.129729	280.0	2026-02-17 17:44:25.131413
7	1	\N	lunch	2026-02-15 17:44:25.371541	690.0	2026-02-17 17:44:25.372233
8	1	\N	breakfast	2026-02-15 17:44:41.681783	140.0	2026-02-17 17:44:41.682962
9	1	\N	breakfast	2026-02-15 17:44:41.797975	280.0	2026-02-17 17:44:41.798502
10	1	\N	lunch	2026-02-15 17:44:41.896438	690.0	2026-02-17 17:44:41.896719
11	1	\N	dinner	2026-02-15 17:44:42.009567	690.0	2026-02-17 17:44:42.009813
85	3	\N	breakfast	2026-02-15 23:02:45.817393	690.0	2026-02-18 23:02:45.818038
86	3	\N	breakfast	2026-02-15 23:03:01.30686	690.0	2026-02-18 23:03:01.307826
87	3	\N	lunch	2026-02-15 23:03:01.378187	690.0	2026-02-18 23:03:01.37836
88	3	\N	breakfast	2026-02-14 23:03:15.238986	690.0	2026-02-18 23:03:15.239332
89	3	\N	lunch	2026-02-14 23:03:15.322459	690.0	2026-02-18 23:03:15.322597
90	3	\N	breakfast	2026-02-13 23:04:16.575871	690.0	2026-02-18 23:04:16.576869
91	3	\N	lunch	2026-02-13 23:04:16.649517	690.0	2026-02-18 23:04:16.649799
92	3	\N	breakfast	2026-02-13 23:04:45.783635	690.0	2026-02-18 23:04:45.784274
93	3	\N	lunch	2026-02-13 23:04:45.857155	690.0	2026-02-18 23:04:45.858685
94	3	\N	lunch	2026-02-13 23:04:45.956124	596.0	2026-02-18 23:04:45.956946
31	1	\N	breakfast	2026-02-18 20:45:49.241006	540.0	2026-02-18 20:45:49.241566
32	1	\N	breakfast	2026-02-18 20:45:49.322987	596.0	2026-02-18 20:45:49.324268
33	1	\N	lunch	2026-02-18 20:45:49.408728	650.0	2026-02-18 20:45:49.409517
34	1	\N	breakfast	2026-02-18 20:45:56.225852	540.0	2026-02-18 20:45:56.227041
35	1	\N	breakfast	2026-02-18 20:45:56.319024	596.0	2026-02-18 20:45:56.320067
36	1	\N	lunch	2026-02-18 20:45:56.401512	650.0	2026-02-18 20:45:56.402629
98	4	\N	breakfast	2026-02-16 23:46:47.530385	596.0	2026-02-18 23:46:47.530845
99	4	\N	breakfast	2026-02-16 23:46:47.633936	695.0	2026-02-18 23:46:47.634782
100	4	\N	breakfast	2026-02-17 23:47:08.102627	596.0	2026-02-18 23:47:08.103362
101	4	\N	breakfast	2026-02-17 23:47:08.326923	695.0	2026-02-18 23:47:08.327214
102	4	\N	breakfast	2026-02-17 23:47:08.44776	596.0	2026-02-18 23:47:08.448262
103	4	\N	breakfast	2026-02-18 23:48:06.078019	596.0	2026-02-18 23:48:06.078737
104	4	\N	breakfast	2026-02-18 23:48:06.160858	695.0	2026-02-18 23:48:06.161926
105	4	\N	breakfast	2026-02-18 23:48:06.257474	596.0	2026-02-18 23:48:06.258137
106	6	\N	breakfast	2026-02-19 12:00:00	596.0	2026-02-19 01:07:42.170936
107	6	\N	breakfast	2026-02-19 12:00:00	1286.0	2026-02-19 01:07:53.785614
108	6	\N	breakfast	2026-02-18 12:00:00	596.0	2026-02-19 01:08:16.9273
109	6	\N	breakfast	2026-02-17 12:00:00	1390.0	2026-02-19 01:08:53.859796
110	6	\N	lunch	2026-02-17 12:00:00	540.0	2026-02-19 01:08:53.944735
111	6	\N	breakfast	2026-02-17 12:00:00	695.0	2026-02-19 01:09:14.158237
112	6	\N	lunch	2026-02-17 12:00:00	540.0	2026-02-19 01:09:14.372907
113	6	\N	breakfast	2026-02-17 12:00:00	695.0	2026-02-19 01:09:34.613908
114	6	\N	lunch	2026-02-17 12:00:00	540.0	2026-02-19 01:09:34.754041
115	6	\N	breakfast	2026-02-17 12:00:00	695.0	2026-02-19 01:09:50.759826
116	6	\N	lunch	2026-02-17 12:00:00	540.0	2026-02-19 01:09:50.908661
117	6	\N	breakfast	2026-02-17 12:00:00	695.0	2026-02-19 01:10:03.088435
118	6	\N	lunch	2026-02-17 12:00:00	626.0	2026-02-19 01:10:03.204472
119	6	\N	breakfast	2026-02-17 12:00:00	695.0	2026-02-19 01:10:14.611968
120	6	\N	lunch	2026-02-17 12:00:00	626.0	2026-02-19 01:10:14.976519
121	6	\N	breakfast	2026-02-17 12:00:00	867.0	2026-02-19 01:10:27.775706
122	6	\N	lunch	2026-02-17 12:00:00	626.0	2026-02-19 01:10:28.002682
124	7	\N	breakfast	2026-02-18 12:00:00	690.0	2026-02-19 21:36:52.191624
125	7	\N	lunch	2026-02-18 12:00:00	690.0	2026-02-19 21:36:52.265907
126	7	\N	breakfast	2026-02-17 12:00:00	690.0	2026-02-19 21:38:08.339023
127	7	\N	lunch	2026-02-17 12:00:00	690.0	2026-02-19 21:38:08.417908
128	7	\N	dinner	2026-02-17 12:00:00	650.0	2026-02-19 21:38:08.499222
129	7	\N	breakfast	2026-02-15 12:00:00	1286.0	2026-02-19 21:39:13.1976
130	7	\N	dinner	2026-02-15 12:00:00	650.0	2026-02-19 21:39:13.268013
131	7	\N	breakfast	2026-02-16 12:00:00	1286.0	2026-02-19 21:40:01.673806
132	7	\N	dinner	2026-02-16 12:00:00	650.0	2026-02-19 21:40:01.757387
134	7	\N	dinner	2026-02-19 12:00:00	650.0	2026-02-19 21:41:29.861174
135	8	\N	breakfast	2026-02-19 12:00:00	626.0	2026-02-19 22:18:44.252435
136	8	\N	lunch	2026-02-18 12:00:00	626.0	2026-02-19 22:19:16.583063
137	8	\N	dinner	2026-02-18 12:00:00	580.0	2026-02-19 22:19:16.658064
138	8	\N	lunch	2026-02-18 12:00:00	626.0	2026-02-19 22:20:43.888106
139	8	\N	lunch	2026-02-18 12:00:00	626.0	2026-02-19 22:27:33.838693
140	8	\N	lunch	2026-02-18 12:00:00	626.0	2026-02-19 22:30:07.764194
144	9	\N	breakfast	2026-02-19 12:00:00	596.0	2026-02-19 22:36:00.209783
147	9	\N	breakfast	2026-02-18 12:00:00	596.0	2026-02-19 22:36:38.242714
148	9	\N	lunch	2026-02-18 12:00:00	1380.0	2026-02-19 22:36:38.322155
149	10	\N	breakfast	2026-02-19 12:00:00	540.0	2026-02-19 22:55:09.171577
151	10	\N	breakfast	2026-02-18 12:00:00	540.0	2026-02-19 22:57:34.893675
157	12	\N	breakfast	2026-02-19 12:00:00	690.0	2026-02-19 23:47:02.203895
158	12	\N	breakfast	2026-02-18 12:00:00	650.0	2026-02-19 23:55:15.982446
159	13	\N	breakfast	2026-02-20 12:00:00	690.0	2026-02-20 00:25:03.383692
160	13	\N	lunch	2026-02-19 12:00:00	695.0	2026-02-20 00:25:17.038099
162	18	\N	breakfast	2026-02-24 12:00:00	1830.0	2026-02-24 20:25:26.279335
164	18	\N	lunch	2026-02-24 12:00:00	695.0	2026-02-24 20:46:29.082337
166	23	\N	breakfast	2026-02-25 12:00:00	596.0	2026-02-25 14:27:01.657436
167	24	\N	lunch	2026-02-25 12:00:00	596.0	2026-02-25 15:20:17.566805
\.


--
-- TOC entry 5338 (class 0 OID 21070)
-- Dependencies: 262
-- Data for Name: notifications; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.notifications (notification_id, user_id, title, message, type, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 5332 (class 0 OID 21001)
-- Dependencies: 256
-- Data for Name: progress; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.progress (progress_id, user_id, weight_id, daily_id, current_streak, weekly_target, created_at) FROM stdin;
\.


--
-- TOC entry 5316 (class 0 OID 20832)
-- Dependencies: 240
-- Data for Name: recipes; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipes (recipe_id, food_id, description, instructions, prep_time_minutes, cooking_time_minutes, serving_people, source_reference, image_url, created_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5297 (class 0 OID 20656)
-- Dependencies: 221
-- Data for Name: roles; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.roles (role_id, role_name) FROM stdin;
1	admin
2	user
\.


--
-- TOC entry 5314 (class 0 OID 20814)
-- Dependencies: 238
-- Data for Name: snacks; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.snacks (snack_id, food_id, is_sweet, packaging_type, trans_fat) FROM stdin;
\.


--
-- TOC entry 5304 (class 0 OID 20725)
-- Dependencies: 228
-- Data for Name: units; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.units (unit_id, name, conversion_factor) FROM stdin;
\.


--
-- TOC entry 5326 (class 0 OID 20944)
-- Dependencies: 250
-- Data for Name: user_activities; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_activities (activity_id, user_id, activity_level, is_current, date_record, created_at) FROM stdin;
\.


--
-- TOC entry 5302 (class 0 OID 20704)
-- Dependencies: 226
-- Data for Name: user_allergy_preferences; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_allergy_preferences (user_id, flag_id, preference_type, created_at) FROM stdin;
\.


--
-- TOC entry 5328 (class 0 OID 20962)
-- Dependencies: 252
-- Data for Name: user_goals; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_goals (goal_id, user_id, goal_name, goal_type, target_weight_kg, is_current, goal_start_at, goal_target_date, goal_end_at, created_at) FROM stdin;
\.


--
-- TOC entry 5320 (class 0 OID 20870)
-- Dependencies: 244
-- Data for Name: user_meal_plans; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_meal_plans (plan_id, user_id, item_id, name, description, source_type, is_premium, created_at) FROM stdin;
\.


--
-- TOC entry 5299 (class 0 OID 20669)
-- Dependencies: 223
-- Data for Name: users; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.users (user_id, username, email, password_hash, gender, birth_date, height_cm, current_weight_kg, goal_type, target_weight_kg, target_calories, activity_level, goal_start_date, goal_target_date, last_kpi_check_date, current_streak, last_login_date, total_login_days, avatar_url, role_id, created_at, updated_at, deleted_at, target_protein, target_carbs, target_fat) FROM stdin;
4	test 04	test04@gmail.com	$2b$12$KUBf2AnZgiDvYQGoCOOudefub6UCT6Ar4FOU52ZgbwckhVE7PeQVK	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-18	2026-10-16	2026-02-18	0	\N	0	\N	2	2026-02-18 23:10:31.680909	\N	\N	\N	\N	\N
24	สิริศักดิ์ เผียงสูงเนิน	sirisak@gmail.com	$2b$12$8I6gQ9WQvtHG6N.5oVdqZ./ettdbdgNxtzuvDdRSEP/nBRurI.9Le	male	2000-01-01	170.00	70.00	lose_weight	63.00	1708	sedentary	2026-02-25	2026-09-23	2026-02-25	0	\N	0	\N	2	2026-02-25 14:43:35.191234	\N	\N	128	171	57
13	test 14	test14@gmail.com	$2b$12$lYecjAaR93..bTZ2/ERjqOoLQaZNzG8o5C40DcFBThYpw/4l6jMfq	male	2000-01-20	180.00	70.00	maintain_weight	60.00	2000	sedentary	2026-02-20	2026-05-21	2026-02-20	0	\N	0	\N	2	2026-02-20 00:23:27.961915	\N	\N	\N	\N	\N
9	test 08	test08@gmail.com	$2b$12$Csk5drjWXVLdJG9KiaIYZuCXMvFizgzcvWYTPtJd9PmHju0.l37eW	male	2000-01-20	180.00	80.00	lose_weight	58.00	\N	sedentary	2026-02-19	2026-10-21	2026-02-19	0	\N	0	\N	2	2026-02-19 22:34:35.950527	\N	\N	\N	\N	\N
5	admin 01	admin@gmail.com	$2b$12$90ARneLODLqolWadO3Jc6eB/ENSltqVV2KklQep6hY4i17wjNe232	male	2000-01-20	170.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-19	2026-10-17	2026-02-19	2	2026-02-25 00:00:00	6	\N	1	2026-02-19 00:00:38.217958	\N	\N	\N	\N	\N
16	test 55	test55@gmail.com	$2b$12$aH9/Os5VlkcUJ8sY.YO/2.9ahKnARITPjiaPoE/xCZi5UAMQoV3Cq	male	2000-01-01	180.00	80.00	lose_weight	72.00	2000	sedentary	2026-02-23	2026-10-21	2026-02-23	1	2026-02-23 00:00:00	1	\N	2	2026-02-23 15:18:05.762927	\N	\N	150	200	67
1	test 01	test01@gmail.com	$2b$12$2ZDZ1TCqh5vzsmKeq0/upe96h.tW/gp0jBI9WDarZpcoUoeMPFFq.	male	2000-01-20	180.00	70.00	lose_weight	51.50	\N	sedentary	2026-02-17	2026-03-14	2026-02-17	0	\N	0	\N	2	2026-02-17 17:24:52.309914	\N	\N	\N	\N	\N
2	test 02	test02@gmail.com	$2b$12$ABUanyk4w2LapwxRrc1Vleb9rV3sTu3j2dtPWDuHxsnuX9l3eg8k6	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-18	2026-05-24	2026-02-18	0	\N	0	\N	2	2026-02-18 20:53:11.645871	\N	\N	\N	\N	\N
7	test 06	test06@gmail.com	$2b$12$.4rdcy8DH34dr6ZGiIKTceyzQUUfKKE1.9Xzr/APUEFBORPYuW4E2	male	2000-01-20	180.00	80.00	lose_weight	66.00	\N	sedentary	2026-02-19	2026-05-29	2026-02-19	0	\N	0	\N	2	2026-02-19 21:35:06.942922	\N	\N	\N	\N	\N
21	testeiei eiei	testeieiei@gmail.com	$2b$12$meRUnHuPxJHD1h.PrQAP4e7kQK4RnQlJJ19iS/uqCnHZjupKSTT7a	male	\N	\N	\N	\N	\N	2000	\N	2026-02-24	\N	2026-02-24	0	\N	0	\N	2	2026-02-24 21:35:56.990036	\N	\N	150	200	67
10	test 09	test09@gmail.com	$2b$12$0ZBpCBcJj1En7toZwZ95POqVV2S823HIWXqXLzSaV6zOkHoZuoVpu	male	2000-01-20	180.00	80.00	lose_weight	67.00	\N	sedentary	2026-02-19	2026-11-15	2026-02-19	0	\N	0	\N	2	2026-02-19 22:52:00.542015	\N	\N	\N	\N	\N
14	test 15	test15@gmail.com	$2b$12$FK7ns9STdW.LBWna9n3eVeQbo0JLYLfeN5phwx3EGcOJ9DhhLWehu	male	2000-01-20	180.00	50.00	gain_muscle	55.00	2000	sedentary	2026-02-20	2026-12-17	2026-02-20	0	\N	0	\N	2	2026-02-20 00:35:59.075233	\N	\N	150	200	67
17	สิริศักดิ์ เผียงสูงเนิน	falarame01@gmail.com	$2b$12$oqzCneUKbinGqdB.qwUXVu7CLq8ZjEi4dSRR6exCwzlBrFRTs6UfC	male	\N	\N	\N	\N	\N	2000	\N	2026-02-24	\N	2026-02-24	1	2026-02-24 00:00:00	1	\N	2	2026-02-24 20:12:24.660063	\N	\N	150	200	67
3	test 03	test03@gmail.com	$2b$12$K0tEhA0fOq3.Ep.ixU5ulOVSpQpvpMj3xlTlgSBGmHipZflVx9viC	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-18	2026-10-16	2026-02-18	0	\N	0	\N	2	2026-02-18 23:01:17.053617	\N	\N	\N	\N	\N
11	test 10	test10@gmail.com	$2b$12$Ga1ZQ7QfzEx3L0.toV5tB.RDvLM6nDp7ZEWybVEVYtFshxebV08zm	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-19	2026-06-26	2026-02-19	0	\N	0	\N	2	2026-02-19 23:11:23.43186	\N	\N	\N	\N	\N
8	test 07	test07@gmail.com	$2b$12$oT5Vh0UdoHYUffeyPAcIq.pUuXX4XqSjyYy1bYIbLagbnyWAYI/wq	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-19	2026-07-03	2026-02-19	0	\N	0	\N	2	2026-02-19 21:54:40.620362	\N	\N	\N	\N	\N
23	สิริศักดิ์ เผียงสูงเนิน	frame@gmail.com	$2b$12$hm9tPHl52ol4q5FARqtVZOmCdPwye6XFlz7iezV9iGFVrKDA0ppgi	male	2000-01-04	170.00	70.00	lose_weight	63.00	1708	sedentary	2026-02-25	2026-09-23	2026-02-25	0	\N	0	\N	2	2026-02-25 14:15:43.479046	\N	\N	128	171	57
22	test 56	test56@gmail.com	$2b$12$DfNZuiWeVEtGeqk5eJdXnOoSsUPliVTwD2ggDLWF3HiqHIsQ/gJMO	male	\N	\N	\N	\N	\N	2000	\N	2026-02-24	\N	2026-02-24	0	\N	0	\N	2	2026-02-24 21:50:15.527439	\N	\N	150	200	67
12	test 11	test11@gmail.com	$2b$12$TvfOryXNzo3mVi0EFQMgguhBbLM1heLNpTJohs1RjIWfh89ZyF2rW	male	2000-01-20	180.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-19	2026-10-17	2026-02-19	0	\N	0	\N	2	2026-02-19 23:41:37.993887	\N	\N	\N	\N	\N
6	test 05	test05@gmail.com	$2b$12$dQNZdw/7.ncVQu8q1YW5A.rAIFxQqSuaP37a3sHNtvtpOUSqoME0e	male	2000-01-20	180.00	80.00	lose_weight	67.00	\N	sedentary	2026-02-19	2026-08-05	2026-02-19	0	\N	0	\N	2	2026-02-19 00:47:02.375264	\N	\N	\N	\N	\N
15	moqq bowkuub	moqqq@gmail.com	$2b$12$BdEAZxQmRXyBCyEQeCCop.odGM.s9IXmVJBEBERGfxXl/Kb1Xt4XK	male	2026-09-28	180.00	25.00	gain_muscle	30.00	2000	sedentary	2026-02-20	2026-12-17	2026-02-20	0	\N	0	\N	2	2026-02-20 00:46:10.522395	\N	\N	150	200	67
25	สิริศักดอ์ เผียง	fra@gmail.com	$2b$12$.TwerPQgRFXZWPjZ.uyds.w3NBOTheBPh.GXuMKIQgxIl4.VybVbG	male	2000-01-04	170.00	70.00	maintain_weight	73.50	2243	sedentary	2026-02-25	2026-06-02	2026-02-25	0	\N	0	\N	2	2026-02-25 15:46:31.192869	\N	\N	140	252	75
19	test 54	test54@gmail.com	$2b$12$enCEQBc8esUb4/Q/iOWkCuWLwk8sstfYtdfqdqPY6WsmtaLA7oxcS	male	2000-01-07	180.00	80.00	lose_weight	72.00	2000	sedentary	2026-02-24	2026-09-11	2026-02-24	1	2026-02-24 00:00:00	1	\N	2	2026-02-24 21:12:34.322582	\N	\N	150	200	67
20	chanasak eiei	nonza@gmail.com	$2b$12$JEelCPlVOE.pG3VCWIHwk./a2.52RomGJ5voPCbyQh50ZsdTZPbmO	male	2000-01-01	180.00	80.00	lose_weight	72.00	1903	sedentary	2026-02-24	2026-10-22	2026-02-24	1	2026-02-24 00:00:00	1	\N	2	2026-02-24 21:23:09.254573	\N	\N	143	190	63
18	เฟรม มี	framesirisak@gmail.com	$2b$12$ENRarqSTklqygoz6F3kyXuKVdvJ81/XiYc6nzUgn8dmai82ISlKce	male	2004-04-15	170.00	70.00	lose_weight	60.50	2000	lightly_active	2026-02-24	2026-12-06	2026-02-24	2	2026-02-25 00:00:00	4	\N	2	2026-02-24 20:14:16.978259	\N	\N	150	200	67
\.


--
-- TOC entry 5336 (class 0 OID 21053)
-- Dependencies: 260
-- Data for Name: weekly_summaries; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.weekly_summaries (weekly_id, user_id, start_date, avg_daily_calories, days_logged_count) FROM stdin;
\.


--
-- TOC entry 5330 (class 0 OID 20982)
-- Dependencies: 254
-- Data for Name: weight_logs; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.weight_logs (log_id, user_id, weight_kg, recorded_date, created_at) FROM stdin;
1	1	70.00	2026-02-17	2026-02-17 17:25:02.813805
2	2	80.00	2026-02-18	2026-02-18 20:53:32.673644
3	3	80.00	2026-02-18	2026-02-18 23:01:29.990938
4	4	80.00	2026-02-18	2026-02-18 23:10:52.269203
5	5	80.00	2026-02-19	2026-02-19 00:00:50.422463
6	6	80.00	2026-02-19	2026-02-19 00:47:13.466876
7	7	80.00	2026-02-19	2026-02-19 21:35:26.657892
8	8	80.00	2026-02-19	2026-02-19 21:54:54.096154
9	9	80.00	2026-02-19	2026-02-19 22:34:48.077755
10	10	80.00	2026-02-19	2026-02-19 22:52:11.525271
11	11	80.00	2026-02-19	2026-02-19 23:11:36.988921
12	12	80.00	2026-02-19	2026-02-19 23:41:46.539252
13	13	70.00	2026-02-20	2026-02-20 00:23:37.001428
15	14	50.00	2026-02-20	2026-02-20 00:36:18.029372
16	15	25.00	2026-02-20	2026-02-20 00:46:46.378995
17	16	80.00	2026-02-23	2026-02-23 15:18:31.097632
18	18	70.00	2026-02-24	2026-02-24 20:14:38.838396
19	19	80.00	2026-02-24	2026-02-24 21:12:58.775077
20	20	80.00	2026-02-24	2026-02-24 21:23:23.984364
21	23	70.00	2026-02-25	2026-02-25 14:16:47.407914
22	24	70.00	2026-02-25	2026-02-25 14:43:46.573471
24	25	70.00	2026-02-25	2026-02-25 15:48:35.508303
\.


--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 224
-- Name: allergy_flags_flag_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.allergy_flags_flag_id_seq', 1, false);


--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 235
-- Name: beverages_beverage_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.beverages_beverage_id_seq', 1, false);


--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 245
-- Name: daily_summaries_summary_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.daily_summaries_summary_id_seq', 182, true);


--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 247
-- Name: detail_items_item_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.detail_items_item_id_seq', 190, true);


--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 233
-- Name: food_ingredients_food_ing_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.food_ingredients_food_ing_id_seq', 1, false);


--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 257
-- Name: food_requests_request_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.food_requests_request_id_seq', 1, false);


--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 229
-- Name: foods_food_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.foods_food_id_seq', 100, true);


--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 263
-- Name: health_contents_content_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.health_contents_content_id_seq', 1, false);


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 231
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.ingredients_ingredient_id_seq', 1, false);


--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 241
-- Name: meals_meal_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.meals_meal_id_seq', 167, true);


--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 261
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.notifications_notification_id_seq', 1, false);


--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 255
-- Name: progress_progress_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.progress_progress_id_seq', 1, false);


--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 239
-- Name: recipes_recipe_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipes_recipe_id_seq', 1, false);


--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 220
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.roles_role_id_seq', 2, true);


--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 237
-- Name: snacks_snack_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.snacks_snack_id_seq', 1, false);


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 227
-- Name: units_unit_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.units_unit_id_seq', 1, false);


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_activities_activity_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_activities_activity_id_seq', 1, false);


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 251
-- Name: user_goals_goal_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_goals_goal_id_seq', 1, false);


--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 243
-- Name: user_meal_plans_plan_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_meal_plans_plan_id_seq', 1, false);


--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 222
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.users_user_id_seq', 25, true);


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 259
-- Name: weekly_summaries_weekly_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.weekly_summaries_weekly_id_seq', 1, false);


--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 253
-- Name: weight_logs_log_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.weight_logs_log_id_seq', 24, true);


--
-- TOC entry 5066 (class 2606 OID 20703)
-- Name: allergy_flags allergy_flags_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.allergy_flags
    ADD CONSTRAINT allergy_flags_pkey PRIMARY KEY (flag_id);


--
-- TOC entry 5080 (class 2606 OID 20807)
-- Name: beverages beverages_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_food_id_key UNIQUE (food_id);


--
-- TOC entry 5082 (class 2606 OID 20805)
-- Name: beverages beverages_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_pkey PRIMARY KEY (beverage_id);


--
-- TOC entry 5096 (class 2606 OID 20898)
-- Name: daily_summaries daily_summaries_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_pkey PRIMARY KEY (summary_id);


--
-- TOC entry 5098 (class 2606 OID 20900)
-- Name: daily_summaries daily_summaries_user_id_date_record_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_user_id_date_record_key UNIQUE (user_id, date_record);


--
-- TOC entry 5100 (class 2606 OID 20917)
-- Name: detail_items detail_items_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5078 (class 2606 OID 20778)
-- Name: food_ingredients food_ingredients_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_pkey PRIMARY KEY (food_ing_id);


--
-- TOC entry 5112 (class 2606 OID 21041)
-- Name: food_requests food_requests_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 5072 (class 2606 OID 20749)
-- Name: foods foods_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.foods
    ADD CONSTRAINT foods_pkey PRIMARY KEY (food_id);


--
-- TOC entry 5120 (class 2606 OID 21099)
-- Name: health_contents health_contents_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.health_contents
    ADD CONSTRAINT health_contents_pkey PRIMARY KEY (content_id);


--
-- TOC entry 5074 (class 2606 OID 20763)
-- Name: ingredients ingredients_name_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_name_key UNIQUE (name);


--
-- TOC entry 5076 (class 2606 OID 20761)
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (ingredient_id);


--
-- TOC entry 5092 (class 2606 OID 20863)
-- Name: meals meals_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals
    ADD CONSTRAINT meals_pkey PRIMARY KEY (meal_id);


--
-- TOC entry 5118 (class 2606 OID 21081)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- TOC entry 5110 (class 2606 OID 21012)
-- Name: progress progress_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_pkey PRIMARY KEY (progress_id);


--
-- TOC entry 5088 (class 2606 OID 20846)
-- Name: recipes recipes_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_food_id_key UNIQUE (food_id);


--
-- TOC entry 5090 (class 2606 OID 20844)
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (recipe_id);


--
-- TOC entry 5058 (class 2606 OID 20665)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 5060 (class 2606 OID 20667)
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- TOC entry 5084 (class 2606 OID 20825)
-- Name: snacks snacks_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_food_id_key UNIQUE (food_id);


--
-- TOC entry 5086 (class 2606 OID 20823)
-- Name: snacks snacks_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_pkey PRIMARY KEY (snack_id);


--
-- TOC entry 5070 (class 2606 OID 20734)
-- Name: units units_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (unit_id);


--
-- TOC entry 5102 (class 2606 OID 20955)
-- Name: user_activities user_activities_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities
    ADD CONSTRAINT user_activities_pkey PRIMARY KEY (activity_id);


--
-- TOC entry 5068 (class 2606 OID 20713)
-- Name: user_allergy_preferences user_allergy_preferences_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_pkey PRIMARY KEY (user_id, flag_id);


--
-- TOC entry 5104 (class 2606 OID 20975)
-- Name: user_goals user_goals_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals
    ADD CONSTRAINT user_goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 5094 (class 2606 OID 20882)
-- Name: user_meal_plans user_meal_plans_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans
    ADD CONSTRAINT user_meal_plans_pkey PRIMARY KEY (plan_id);


--
-- TOC entry 5062 (class 2606 OID 20687)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5064 (class 2606 OID 20685)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5114 (class 2606 OID 21061)
-- Name: weekly_summaries weekly_summaries_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_pkey PRIMARY KEY (weekly_id);


--
-- TOC entry 5116 (class 2606 OID 21063)
-- Name: weekly_summaries weekly_summaries_user_id_start_date_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_user_id_start_date_key UNIQUE (user_id, start_date);


--
-- TOC entry 5106 (class 2606 OID 20992)
-- Name: weight_logs weight_logs_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 5108 (class 2606 OID 20994)
-- Name: weight_logs weight_logs_user_id_recorded_date_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_user_id_recorded_date_key UNIQUE (user_id, recorded_date);


--
-- TOC entry 5128 (class 2606 OID 20808)
-- Name: beverages beverages_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5133 (class 2606 OID 20901)
-- Name: daily_summaries daily_summaries_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5134 (class 2606 OID 20933)
-- Name: detail_items detail_items_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5135 (class 2606 OID 20918)
-- Name: detail_items detail_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES cleangoal.meals(meal_id) ON DELETE CASCADE;


--
-- TOC entry 5136 (class 2606 OID 20923)
-- Name: detail_items detail_items_plan_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES cleangoal.user_meal_plans(plan_id) ON DELETE CASCADE;


--
-- TOC entry 5137 (class 2606 OID 20928)
-- Name: detail_items detail_items_summary_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_summary_id_fkey FOREIGN KEY (summary_id) REFERENCES cleangoal.daily_summaries(summary_id) ON DELETE CASCADE;


--
-- TOC entry 5138 (class 2606 OID 20938)
-- Name: detail_items detail_items_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5125 (class 2606 OID 20779)
-- Name: food_ingredients food_ingredients_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE;


--
-- TOC entry 5126 (class 2606 OID 20784)
-- Name: food_ingredients food_ingredients_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES cleangoal.ingredients(ingredient_id);


--
-- TOC entry 5127 (class 2606 OID 20789)
-- Name: food_ingredients food_ingredients_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5145 (class 2606 OID 21047)
-- Name: food_requests food_requests_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES cleangoal.users(user_id);


--
-- TOC entry 5146 (class 2606 OID 21042)
-- Name: food_requests food_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id);


--
-- TOC entry 5124 (class 2606 OID 20764)
-- Name: ingredients ingredients_default_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_default_unit_id_fkey FOREIGN KEY (default_unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5131 (class 2606 OID 20864)
-- Name: meals meals_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals
    ADD CONSTRAINT meals_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5148 (class 2606 OID 21082)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5142 (class 2606 OID 21023)
-- Name: progress progress_daily_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_daily_id_fkey FOREIGN KEY (daily_id) REFERENCES cleangoal.daily_summaries(summary_id);


--
-- TOC entry 5143 (class 2606 OID 21013)
-- Name: progress progress_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5144 (class 2606 OID 21018)
-- Name: progress progress_weight_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_weight_id_fkey FOREIGN KEY (weight_id) REFERENCES cleangoal.weight_logs(log_id);


--
-- TOC entry 5130 (class 2606 OID 20847)
-- Name: recipes recipes_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5129 (class 2606 OID 20826)
-- Name: snacks snacks_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5139 (class 2606 OID 20956)
-- Name: user_activities user_activities_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities
    ADD CONSTRAINT user_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5122 (class 2606 OID 20719)
-- Name: user_allergy_preferences user_allergy_preferences_flag_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_flag_id_fkey FOREIGN KEY (flag_id) REFERENCES cleangoal.allergy_flags(flag_id) ON DELETE CASCADE;


--
-- TOC entry 5123 (class 2606 OID 20714)
-- Name: user_allergy_preferences user_allergy_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5140 (class 2606 OID 20976)
-- Name: user_goals user_goals_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals
    ADD CONSTRAINT user_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5132 (class 2606 OID 20883)
-- Name: user_meal_plans user_meal_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans
    ADD CONSTRAINT user_meal_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 5121 (class 2606 OID 20688)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES cleangoal.roles(role_id);


--
-- TOC entry 5147 (class 2606 OID 21064)
-- Name: weekly_summaries weekly_summaries_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5141 (class 2606 OID 20995)
-- Name: weight_logs weight_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


-- Completed on 2026-03-16 11:20:24

--
-- PostgreSQL database dump complete
--

\unrestrict q5N7IVVZBaDp9Q3ptT3ow45Se8MJWDPXqUKj4go51lN3y6TSGOdPI8N3lP1vmew


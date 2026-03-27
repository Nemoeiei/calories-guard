--
-- PostgreSQL database dump
--

\restrict JZGjW12U9yIRBfMzyLoAC32F7rWMC82dUEf7N3flP1kO0R0Yns7sywc1weZOHgF

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-26 20:51:01

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
-- TOC entry 957 (class 1247 OID 20600)
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
-- TOC entry 960 (class 1247 OID 20610)
-- Name: content_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.content_type AS ENUM (
    'article',
    'video'
);


ALTER TYPE cleangoal.content_type OWNER TO postgres;

--
-- TOC entry 963 (class 1247 OID 20616)
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
-- TOC entry 966 (class 1247 OID 20622)
-- Name: gender_type; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.gender_type AS ENUM (
    'male',
    'female'
);


ALTER TYPE cleangoal.gender_type OWNER TO postgres;

--
-- TOC entry 954 (class 1247 OID 20592)
-- Name: goal_type_enum; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.goal_type_enum AS ENUM (
    'lose_weight',
    'maintain_weight',
    'gain_muscle'
);


ALTER TYPE cleangoal.goal_type_enum OWNER TO postgres;

--
-- TOC entry 969 (class 1247 OID 20628)
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
-- TOC entry 972 (class 1247 OID 20638)
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
-- TOC entry 975 (class 1247 OID 20648)
-- Name: request_status; Type: TYPE; Schema: cleangoal; Owner: postgres
--

CREATE TYPE cleangoal.request_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE cleangoal.request_status OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 21299)
-- Name: update_recipe_favorite_count(); Type: FUNCTION; Schema: cleangoal; Owner: postgres
--

CREATE FUNCTION cleangoal.update_recipe_favorite_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE cleangoal.recipes
    SET favorite_count = (
        SELECT COUNT(*) FROM cleangoal.recipe_favorites
        WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)
    )
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    RETURN NEW;
END;
$$;


ALTER FUNCTION cleangoal.update_recipe_favorite_count() OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 21297)
-- Name: update_recipe_rating(); Type: FUNCTION; Schema: cleangoal; Owner: postgres
--

CREATE FUNCTION cleangoal.update_recipe_rating() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE cleangoal.recipes
    SET
        avg_rating   = (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM cleangoal.recipe_reviews WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)),
        review_count = (SELECT COUNT(*) FROM cleangoal.recipe_reviews WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id))
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    RETURN NEW;
END;
$$;


ALTER FUNCTION cleangoal.update_recipe_rating() OWNER TO postgres;

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
-- TOC entry 5474 (class 0 OID 0)
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
-- TOC entry 5475 (class 0 OID 0)
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
-- TOC entry 5476 (class 0 OID 0)
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
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 247
-- Name: detail_items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.detail_items_item_id_seq OWNED BY cleangoal.detail_items.item_id;


--
-- TOC entry 268 (class 1259 OID 21134)
-- Name: email_verification_codes; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.email_verification_codes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying(10) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.email_verification_codes OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 21133)
-- Name: email_verification_codes_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.email_verification_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.email_verification_codes_id_seq OWNER TO postgres;

--
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 267
-- Name: email_verification_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.email_verification_codes_id_seq OWNED BY cleangoal.email_verification_codes.id;


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
-- TOC entry 5479 (class 0 OID 0)
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
    created_at timestamp without time zone DEFAULT now(),
    calories numeric(6,2),
    protein numeric(6,2),
    carbs numeric(6,2),
    fat numeric(6,2)
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
-- TOC entry 5480 (class 0 OID 0)
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
    deleted_at timestamp without time zone,
    fiber_g numeric(6,2) DEFAULT 0,
    food_category character varying
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
-- TOC entry 5481 (class 0 OID 0)
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
-- TOC entry 5482 (class 0 OID 0)
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
-- TOC entry 5483 (class 0 OID 0)
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
-- TOC entry 5484 (class 0 OID 0)
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
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 261
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.notifications_notification_id_seq OWNED BY cleangoal.notifications.notification_id;


--
-- TOC entry 266 (class 1259 OID 21115)
-- Name: password_reset_codes; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.password_reset_codes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying(10) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.password_reset_codes OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 21114)
-- Name: password_reset_codes_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.password_reset_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.password_reset_codes_id_seq OWNER TO postgres;

--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 265
-- Name: password_reset_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.password_reset_codes_id_seq OWNED BY cleangoal.password_reset_codes.id;


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
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 255
-- Name: progress_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.progress_progress_id_seq OWNED BY cleangoal.progress.progress_id;


--
-- TOC entry 280 (class 1259 OID 21269)
-- Name: recipe_favorites; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_favorites (
    fav_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.recipe_favorites OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 21268)
-- Name: recipe_favorites_fav_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_favorites_fav_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_favorites_fav_id_seq OWNER TO postgres;

--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 279
-- Name: recipe_favorites_fav_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_favorites_fav_id_seq OWNED BY cleangoal.recipe_favorites.fav_id;


--
-- TOC entry 270 (class 1259 OID 21165)
-- Name: recipe_ingredients; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_ingredients (
    ing_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    ingredient_name character varying NOT NULL,
    quantity numeric(8,2),
    unit character varying,
    is_optional boolean DEFAULT false,
    note character varying,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.recipe_ingredients OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 21164)
-- Name: recipe_ingredients_ing_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_ingredients_ing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_ingredients_ing_id_seq OWNER TO postgres;

--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 269
-- Name: recipe_ingredients_ing_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_ingredients_ing_id_seq OWNED BY cleangoal.recipe_ingredients.ing_id;


--
-- TOC entry 278 (class 1259 OID 21243)
-- Name: recipe_reviews; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_reviews (
    review_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    user_id bigint NOT NULL,
    rating smallint,
    comment text,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT recipe_reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE cleangoal.recipe_reviews OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 21242)
-- Name: recipe_reviews_review_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_reviews_review_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_reviews_review_id_seq OWNER TO postgres;

--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 277
-- Name: recipe_reviews_review_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_reviews_review_id_seq OWNED BY cleangoal.recipe_reviews.review_id;


--
-- TOC entry 272 (class 1259 OID 21185)
-- Name: recipe_steps; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_steps (
    step_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    step_number integer NOT NULL,
    title character varying,
    instruction text NOT NULL,
    time_minutes integer DEFAULT 0,
    image_url character varying,
    tips text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.recipe_steps OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 21184)
-- Name: recipe_steps_step_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_steps_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_steps_step_id_seq OWNER TO postgres;

--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 271
-- Name: recipe_steps_step_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_steps_step_id_seq OWNED BY cleangoal.recipe_steps.step_id;


--
-- TOC entry 276 (class 1259 OID 21224)
-- Name: recipe_tips; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_tips (
    tip_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    tip_text text NOT NULL,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.recipe_tips OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 21223)
-- Name: recipe_tips_tip_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_tips_tip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_tips_tip_id_seq OWNER TO postgres;

--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 275
-- Name: recipe_tips_tip_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_tips_tip_id_seq OWNED BY cleangoal.recipe_tips.tip_id;


--
-- TOC entry 274 (class 1259 OID 21205)
-- Name: recipe_tools; Type: TABLE; Schema: cleangoal; Owner: postgres
--

CREATE TABLE cleangoal.recipe_tools (
    tool_id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    tool_name character varying NOT NULL,
    tool_emoji character varying,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE cleangoal.recipe_tools OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 21204)
-- Name: recipe_tools_tool_id_seq; Type: SEQUENCE; Schema: cleangoal; Owner: postgres
--

CREATE SEQUENCE cleangoal.recipe_tools_tool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cleangoal.recipe_tools_tool_id_seq OWNER TO postgres;

--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 273
-- Name: recipe_tools_tool_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.recipe_tools_tool_id_seq OWNED BY cleangoal.recipe_tools.tool_id;


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
    deleted_at timestamp without time zone,
    recipe_name character varying,
    category character varying,
    cuisine character varying,
    difficulty character varying DEFAULT 'Easy'::character varying,
    total_time_minutes integer GENERATED ALWAYS AS ((prep_time_minutes + cooking_time_minutes)) STORED,
    avg_rating numeric(3,2) DEFAULT 0,
    review_count integer DEFAULT 0,
    favorite_count integer DEFAULT 0,
    is_published boolean DEFAULT true
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
-- TOC entry 5494 (class 0 OID 0)
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
-- TOC entry 5495 (class 0 OID 0)
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
-- TOC entry 5496 (class 0 OID 0)
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
-- TOC entry 5497 (class 0 OID 0)
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
-- TOC entry 5498 (class 0 OID 0)
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
-- TOC entry 5499 (class 0 OID 0)
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
-- TOC entry 5500 (class 0 OID 0)
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
    target_fat integer,
    is_email_verified boolean DEFAULT false
);


ALTER TABLE cleangoal.users OWNER TO postgres;

--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_protein; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_protein IS 'เป้าหมายโปรตีน (กรัม/วัน)';


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_carbs; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_carbs IS 'เป้าหมายคาร์บ (กรัม/วัน)';


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.target_fat; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.target_fat IS 'เป้าหมายไขมัน (กรัม/วัน)';


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN users.is_email_verified; Type: COMMENT; Schema: cleangoal; Owner: postgres
--

COMMENT ON COLUMN cleangoal.users.is_email_verified IS 'สถานะการยืนยันอีเมล';


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
-- TOC entry 5505 (class 0 OID 0)
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
-- TOC entry 5506 (class 0 OID 0)
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
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 253
-- Name: weight_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: cleangoal; Owner: postgres
--

ALTER SEQUENCE cleangoal.weight_logs_log_id_seq OWNED BY cleangoal.weight_logs.log_id;


--
-- TOC entry 5041 (class 2604 OID 20697)
-- Name: allergy_flags flag_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.allergy_flags ALTER COLUMN flag_id SET DEFAULT nextval('cleangoal.allergy_flags_flag_id_seq'::regclass);


--
-- TOC entry 5053 (class 2604 OID 20798)
-- Name: beverages beverage_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages ALTER COLUMN beverage_id SET DEFAULT nextval('cleangoal.beverages_beverage_id_seq'::regclass);


--
-- TOC entry 5076 (class 2604 OID 20892)
-- Name: daily_summaries summary_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries ALTER COLUMN summary_id SET DEFAULT nextval('cleangoal.daily_summaries_summary_id_seq'::regclass);


--
-- TOC entry 5080 (class 2604 OID 20910)
-- Name: detail_items item_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items ALTER COLUMN item_id SET DEFAULT nextval('cleangoal.detail_items_item_id_seq'::regclass);


--
-- TOC entry 5110 (class 2604 OID 21137)
-- Name: email_verification_codes id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.email_verification_codes ALTER COLUMN id SET DEFAULT nextval('cleangoal.email_verification_codes_id_seq'::regclass);


--
-- TOC entry 5052 (class 2604 OID 20773)
-- Name: food_ingredients food_ing_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients ALTER COLUMN food_ing_id SET DEFAULT nextval('cleangoal.food_ingredients_food_ing_id_seq'::regclass);


--
-- TOC entry 5097 (class 2604 OID 21032)
-- Name: food_requests request_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests ALTER COLUMN request_id SET DEFAULT nextval('cleangoal.food_requests_request_id_seq'::regclass);


--
-- TOC entry 5044 (class 2604 OID 20739)
-- Name: foods food_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.foods ALTER COLUMN food_id SET DEFAULT nextval('cleangoal.foods_food_id_seq'::regclass);


--
-- TOC entry 5104 (class 2604 OID 21091)
-- Name: health_contents content_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.health_contents ALTER COLUMN content_id SET DEFAULT nextval('cleangoal.health_contents_content_id_seq'::regclass);


--
-- TOC entry 5050 (class 2604 OID 20754)
-- Name: ingredients ingredient_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients ALTER COLUMN ingredient_id SET DEFAULT nextval('cleangoal.ingredients_ingredient_id_seq'::regclass);


--
-- TOC entry 5069 (class 2604 OID 20856)
-- Name: meals meal_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals ALTER COLUMN meal_id SET DEFAULT nextval('cleangoal.meals_meal_id_seq'::regclass);


--
-- TOC entry 5101 (class 2604 OID 21073)
-- Name: notifications notification_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications ALTER COLUMN notification_id SET DEFAULT nextval('cleangoal.notifications_notification_id_seq'::regclass);


--
-- TOC entry 5107 (class 2604 OID 21118)
-- Name: password_reset_codes id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.password_reset_codes ALTER COLUMN id SET DEFAULT nextval('cleangoal.password_reset_codes_id_seq'::regclass);


--
-- TOC entry 5094 (class 2604 OID 21004)
-- Name: progress progress_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress ALTER COLUMN progress_id SET DEFAULT nextval('cleangoal.progress_progress_id_seq'::regclass);


--
-- TOC entry 5128 (class 2604 OID 21272)
-- Name: recipe_favorites fav_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_favorites ALTER COLUMN fav_id SET DEFAULT nextval('cleangoal.recipe_favorites_fav_id_seq'::regclass);


--
-- TOC entry 5113 (class 2604 OID 21168)
-- Name: recipe_ingredients ing_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_ingredients ALTER COLUMN ing_id SET DEFAULT nextval('cleangoal.recipe_ingredients_ing_id_seq'::regclass);


--
-- TOC entry 5126 (class 2604 OID 21246)
-- Name: recipe_reviews review_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_reviews ALTER COLUMN review_id SET DEFAULT nextval('cleangoal.recipe_reviews_review_id_seq'::regclass);


--
-- TOC entry 5117 (class 2604 OID 21188)
-- Name: recipe_steps step_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_steps ALTER COLUMN step_id SET DEFAULT nextval('cleangoal.recipe_steps_step_id_seq'::regclass);


--
-- TOC entry 5123 (class 2604 OID 21227)
-- Name: recipe_tips tip_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tips ALTER COLUMN tip_id SET DEFAULT nextval('cleangoal.recipe_tips_tip_id_seq'::regclass);


--
-- TOC entry 5120 (class 2604 OID 21208)
-- Name: recipe_tools tool_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tools ALTER COLUMN tool_id SET DEFAULT nextval('cleangoal.recipe_tools_tool_id_seq'::regclass);


--
-- TOC entry 5058 (class 2604 OID 20835)
-- Name: recipes recipe_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes ALTER COLUMN recipe_id SET DEFAULT nextval('cleangoal.recipes_recipe_id_seq'::regclass);


--
-- TOC entry 5032 (class 2604 OID 20659)
-- Name: roles role_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles ALTER COLUMN role_id SET DEFAULT nextval('cleangoal.roles_role_id_seq'::regclass);


--
-- TOC entry 5056 (class 2604 OID 20817)
-- Name: snacks snack_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks ALTER COLUMN snack_id SET DEFAULT nextval('cleangoal.snacks_snack_id_seq'::regclass);


--
-- TOC entry 5043 (class 2604 OID 20728)
-- Name: units unit_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.units ALTER COLUMN unit_id SET DEFAULT nextval('cleangoal.units_unit_id_seq'::regclass);


--
-- TOC entry 5083 (class 2604 OID 20947)
-- Name: user_activities activity_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities ALTER COLUMN activity_id SET DEFAULT nextval('cleangoal.user_activities_activity_id_seq'::regclass);


--
-- TOC entry 5087 (class 2604 OID 20965)
-- Name: user_goals goal_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals ALTER COLUMN goal_id SET DEFAULT nextval('cleangoal.user_goals_goal_id_seq'::regclass);


--
-- TOC entry 5072 (class 2604 OID 20873)
-- Name: user_meal_plans plan_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans ALTER COLUMN plan_id SET DEFAULT nextval('cleangoal.user_meal_plans_plan_id_seq'::regclass);


--
-- TOC entry 5033 (class 2604 OID 20672)
-- Name: users user_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users ALTER COLUMN user_id SET DEFAULT nextval('cleangoal.users_user_id_seq'::regclass);


--
-- TOC entry 5100 (class 2604 OID 21056)
-- Name: weekly_summaries weekly_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries ALTER COLUMN weekly_id SET DEFAULT nextval('cleangoal.weekly_summaries_weekly_id_seq'::regclass);


--
-- TOC entry 5091 (class 2604 OID 20985)
-- Name: weight_logs log_id; Type: DEFAULT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs ALTER COLUMN log_id SET DEFAULT nextval('cleangoal.weight_logs_log_id_seq'::regclass);


--
-- TOC entry 5413 (class 0 OID 20694)
-- Dependencies: 225
-- Data for Name: allergy_flags; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.allergy_flags (flag_id, name, description) FROM stdin;
\.


--
-- TOC entry 5424 (class 0 OID 20795)
-- Dependencies: 236
-- Data for Name: beverages; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.beverages (beverage_id, food_id, volume_ml, is_alcoholic, caffeine_mg, sugar_level_label, container_type) FROM stdin;
\.


--
-- TOC entry 5434 (class 0 OID 20889)
-- Dependencies: 246
-- Data for Name: daily_summaries; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.daily_summaries (summary_id, user_id, item_id, date_record, total_calories_intake, goal_calories, is_goal_met) FROM stdin;
183	37	\N	2026-03-20	1235.00	\N	f
187	37	\N	2026-03-19	650.00	\N	f
\.


--
-- TOC entry 5436 (class 0 OID 20907)
-- Dependencies: 248
-- Data for Name: detail_items; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.detail_items (item_id, meal_id, plan_id, summary_id, food_id, food_name, day_number, amount, unit_id, cal_per_unit, note, created_at) FROM stdin;
192	169	\N	\N	2	ข้าวมันไก่ทอด	\N	1.00	\N	695.00	\N	2026-03-20 22:07:31.125792
194	171	\N	\N	4	ข้าวหมูแดง	\N	1.00	\N	540.00	\N	2026-03-20 22:08:18.716002
195	172	\N	\N	5	ข้าวหมูกรอบ	\N	1.00	\N	650.00	\N	2026-03-20 22:09:07.710472
\.


--
-- TOC entry 5456 (class 0 OID 21134)
-- Dependencies: 268
-- Data for Name: email_verification_codes; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.email_verification_codes (id, user_id, code, expires_at, used, created_at) FROM stdin;
1	35	306856	2026-03-20 20:16:49.896924	t	2026-03-20 20:01:49.661691
2	35	591755	2026-03-20 20:18:36.376329	t	2026-03-20 20:03:36.371763
3	36	529658	2026-03-20 20:32:56.61415	t	2026-03-20 20:17:56.363682
4	37	411545	2026-03-20 22:20:13.669438	t	2026-03-20 22:05:13.353336
\.


--
-- TOC entry 5422 (class 0 OID 20770)
-- Dependencies: 234
-- Data for Name: food_ingredients; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.food_ingredients (food_ing_id, food_id, ingredient_id, amount, unit_id, calculated_grams, note) FROM stdin;
\.


--
-- TOC entry 5446 (class 0 OID 21029)
-- Dependencies: 258
-- Data for Name: food_requests; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.food_requests (request_id, user_id, food_name, status, ingredients_json, reviewed_by, created_at, calories, protein, carbs, fat) FROM stdin;
\.


--
-- TOC entry 5418 (class 0 OID 20736)
-- Dependencies: 230
-- Data for Name: foods; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.foods (food_id, food_name, food_type, calories, protein, carbs, fat, sodium, sugar, cholesterol, serving_quantity, serving_unit, image_url, created_at, updated_at, deleted_at, fiber_g, food_category) FROM stdin;
3	ข้าวขาหมู	dish	690.00	25.00	55.00	38.00	1400.00	12.00	150.00	1.00	plate	https://placehold.co/400?text=Pork+Leg	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
4	ข้าวหมูแดง	dish	540.00	20.00	78.00	14.00	1100.00	18.00	75.00	1.00	plate	https://placehold.co/400?text=Red+Pork	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
5	ข้าวหมูกรอบ	dish	650.00	18.00	60.00	35.00	1250.00	5.00	110.00	1.00	plate	https://placehold.co/400?text=Crispy+Pork	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
6	ผัดไทยกุ้งสด	dish	585.00	21.00	68.00	25.00	1300.00	22.00	145.00	1.00	plate	https://placehold.co/400?text=Pad+Thai	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
7	ราดหน้าหมูหมัก	dish	480.00	22.00	55.00	18.00	1150.00	8.00	65.00	1.00	plate	https://placehold.co/400?text=Rad+Na	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
8	ผัดซีอิ๊วหมู	dish	679.00	26.00	72.00	30.00	1280.00	10.00	95.00	1.00	plate	https://placehold.co/400?text=Pad+See+Ew	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
9	สุกี้น้ำรวมมิตร	dish	350.00	25.00	45.00	8.00	1600.00	15.00	120.00	1.00	bowl	https://placehold.co/400?text=Suki+Soup	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
10	สุกี้แห้งรวมมิตร	dish	420.00	25.00	50.00	15.00	1550.00	18.00	120.00	1.00	plate	https://placehold.co/400?text=Dry+Suki	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
11	ข้าวคลุกกะปิ	dish	615.00	22.00	75.00	24.00	1800.00	14.00	110.00	1.00	plate	https://placehold.co/400?text=Kapi+Rice	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
12	แกงเขียวหวานไก่ (ราดข้าว)	dish	550.00	18.00	55.00	28.00	1350.00	12.00	95.00	1.00	plate	https://placehold.co/400?text=Green+Curry	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
13	ต้มข่าไก่ (ถ้วย)	dish	320.00	18.00	12.00	24.00	1100.00	6.00	60.00	1.00	bowl	https://placehold.co/400?text=Tom+Kha	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
14	แกงส้มชะอมกุ้ง (ถ้วย)	dish	280.00	22.00	18.00	12.00	1450.00	10.00	140.00	1.00	bowl	https://placehold.co/400?text=Sour+Soup	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
15	ไข่เจียวหมูสับ (ราดข้าว)	dish	580.00	16.00	48.00	35.00	850.00	1.00	420.00	1.00	plate	https://placehold.co/400?text=Omelet+Rice	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
16	ยำวุ้นเส้นหมูสับ	dish	380.00	18.00	52.00	8.00	1600.00	12.00	65.00	1.00	plate	https://placehold.co/400?text=Spicy+Noodle	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
17	ลาบหมู	dish	250.00	22.00	12.00	12.00	1300.00	3.00	60.00	1.00	plate	https://placehold.co/400?text=Larb+Pork	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
18	น้ำตกหมู	dish	280.00	24.00	10.00	16.00	1250.00	3.00	70.00	1.00	plate	https://placehold.co/400?text=Nam+Tok	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
19	ไก่ย่าง (น่องติดสะโพก)	dish	320.00	28.00	2.00	22.00	650.00	4.00	105.00	1.00	piece	https://placehold.co/400?text=Grilled+Chicken	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
20	คอหมูย่าง	dish	450.00	18.00	4.00	38.00	700.00	6.00	95.00	1.00	plate	https://placehold.co/400?text=Grilled+Pork+Neck	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
25	ขนมจีนน้ำยา	dish	380.00	12.00	55.00	14.00	1100.00	6.00	45.00	1.00	plate	https://placehold.co/400?text=Kanom+Jeen	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
26	ขนมจีนแกงเขียวหวาน	dish	450.00	15.00	58.00	22.00	1250.00	8.00	65.00	1.00	plate	https://placehold.co/400?text=Kanom+Jeen+Green	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
27	ข้าวซอยไก่	dish	580.00	24.00	45.00	32.00	1350.00	6.00	110.00	1.00	bowl	https://placehold.co/400?text=Khao+Soi	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
28	โจ๊กหมูใส่ไข่	dish	350.00	14.00	48.00	10.00	850.00	0.00	240.00	1.00	bowl	https://placehold.co/400?text=Congee	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
29	ต้มเลือดหมู (ไม่รวมข้าว)	dish	250.00	28.00	5.00	12.00	1100.00	0.00	180.00	1.00	bowl	https://placehold.co/400?text=Pork+Blood+Soup	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
30	หมูกระเทียมราดข้าว	dish	560.00	22.00	65.00	22.00	1050.00	2.00	85.00	1.00	plate	https://placehold.co/400?text=Garlic+Pork	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
35	ปลากะพงนึ่งมะนาว	dish	350.00	42.00	5.00	12.00	1250.00	8.00	95.00	1.00	plate	http://10.0.2.2:8000/images/food_a92c5808-7f33-4ba0-be50-a86dfb9be42f.jpg	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
31	ผัดพริกแกงหมู (ราดข้าว)	dish	590.00	20.00	62.00	26.00	1300.00	5.00	80.00	1.00	plate	https://placehold.co/400?text=Curry+Paste+Pork	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
32	ผัดผักบุ้งไฟแดง (กับข้าว)	dish	180.00	4.00	8.00	14.00	950.00	4.00	0.00	1.00	plate	https://placehold.co/400?text=Morning+Glory	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
33	ไข่พะโล้ (ถ้วย)	dish	320.00	16.00	12.00	22.00	1100.00	15.00	380.00	1.00	bowl	https://placehold.co/400?text=Pa+Lo	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
34	แกงจืดเต้าหู้หมูสับ	dish	150.00	12.00	8.00	6.00	800.00	2.00	35.00	1.00	bowl	https://placehold.co/400?text=Clear+Soup	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
36	ปลานิลทอด	dish	450.00	38.00	0.00	32.00	450.00	0.00	85.00	1.00	plate	https://placehold.co/400?text=Fried+Fish	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
37	แหนมเนือง (ชุดเล็ก)	dish	420.00	18.00	45.00	16.00	1400.00	12.00	65.00	1.00	set	https://placehold.co/400?text=Nam+Neung	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
1	ข้าวมันไก่ต้ม	dish	596.00	29.00	69.00	21.00	1150.00	2.00	85.00	1.00	plate	http://10.0.2.2:8000/images/food_b286b614-d176-41e5-b6bb-a7ab48d50a0b.png	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
2	ข้าวมันไก่ทอด	dish	695.00	22.00	75.00	32.00	1200.00	2.00	90.00	1.00	plate	https://unshirred-wendolyn-audiometrically.ngrok-free.dev/images/food_720f5a2b-1ce7-46d3-86ed-a248fd9d16a6.jpg	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารไทย
21	ก๋วยเตี๋ยวเรือน้ำตกหมู	dish	450.00	20.00	55.00	15.00	1650.00	6.00	80.00	1.00	bowl	https://placehold.co/400?text=Boat+Noodle	2026-02-17 17:37:50.735627	\N	\N	0.00	เส้น/ก๋วยเตี๋ยว
22	บะหมี่เกี๊ยวหมูแดง	dish	480.00	22.00	62.00	14.00	1300.00	5.00	95.00	1.00	bowl	https://placehold.co/400?text=Wonton+Noodle	2026-02-17 17:37:50.735627	\N	\N	0.00	เส้น/ก๋วยเตี๋ยว
23	เย็นตาโฟ	dish	420.00	16.00	58.00	12.00	1700.00	14.00	75.00	1.00	bowl	https://placehold.co/400?text=Yentafo	2026-02-17 17:37:50.735627	\N	\N	0.00	เส้น/ก๋วยเตี๋ยว
24	ก๋วยจั๊บน้ำข้น	dish	520.00	24.00	60.00	20.00	1400.00	4.00	180.00	1.00	bowl	https://placehold.co/400?text=Guay+Jub	2026-02-17 17:37:50.735627	\N	\N	0.00	เส้น/ก๋วยเตี๋ยว
38	สเต็กหมู	dish	550.00	35.00	25.00	32.00	950.00	4.00	95.00	1.00	plate	https://placehold.co/400?text=Pork+Steak	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารตะวันตก
40	สปาเก็ตตี้คาโบนาร่า	dish	680.00	22.00	58.00	38.00	980.00	4.00	120.00	1.00	plate	https://placehold.co/400?text=Carbonara	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารตะวันตก
39	สเต็กไก่	dish	480.00	40.00	25.00	22.00	850.00	3.00	90.00	1.00	plate	http://10.0.2.2:8000/images/food_d14928dd-816f-476c-895f-3b945cdae5d0.jpg	2026-02-17 17:37:50.735627	\N	\N	0.00	อาหารตะวันตก
41	สันในไก่	raw_ingredient	110.00	24.00	0.00	1.00	50.00	0.00	55.00	100.00	g	https://placehold.co/400?text=Chicken+Tender	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
42	ปีกไก่	raw_ingredient	203.00	18.00	0.00	14.00	70.00	0.00	80.00	100.00	g	https://placehold.co/400?text=Chicken+Wing	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
43	น่องไก่	raw_ingredient	160.00	19.00	0.00	9.00	65.00	0.00	75.00	100.00	g	https://placehold.co/400?text=Chicken+Drumstick	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
44	หมูสามชั้น	raw_ingredient	518.00	9.00	0.00	53.00	30.00	0.00	70.00	100.00	g	https://placehold.co/400?text=Pork+Belly	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
45	สันนอกหมู	raw_ingredient	242.00	27.00	0.00	14.00	55.00	0.00	80.00	100.00	g	https://placehold.co/400?text=Pork+Loin	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
46	สันคอหมู	raw_ingredient	280.00	24.00	0.00	20.00	60.00	0.00	85.00	100.00	g	https://placehold.co/400?text=Pork+Neck	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
47	เนื้อวัว (สันนอก)	raw_ingredient	250.00	26.00	0.00	15.00	60.00	0.00	90.00	100.00	g	https://placehold.co/400?text=Beef+Sirloin	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
48	เนื้อวัว (ริบอาย)	raw_ingredient	290.00	24.00	0.00	22.00	65.00	0.00	95.00	100.00	g	https://placehold.co/400?text=Ribeye	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
49	กุ้งขาว	raw_ingredient	85.00	20.00	0.50	0.50	120.00	0.00	150.00	100.00	g	https://placehold.co/400?text=Shrimp	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
50	หมึกกล้วย	raw_ingredient	92.00	16.00	3.00	1.40	44.00	0.00	233.00	100.00	g	https://placehold.co/400?text=Squid	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
51	ปลากะพง (เนื้อ)	raw_ingredient	97.00	20.00	0.00	1.50	70.00	0.00	40.00	100.00	g	https://placehold.co/400?text=Seabass	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
52	เต้าหู้ขาว (แข็ง)	raw_ingredient	76.00	8.00	1.90	4.80	7.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Tofu	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
53	เส้นใหญ่ (ดิบ)	raw_ingredient	220.00	2.00	48.00	1.50	30.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Wide+Rice+Noodle	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
54	เส้นหมี่ (แห้ง)	raw_ingredient	360.00	6.00	80.00	0.50	15.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Rice+Vermicelli	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
55	วุ้นเส้น (แห้ง)	raw_ingredient	330.00	0.20	82.00	0.00	10.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Glass+Noodle	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
56	ผักคะน้า	raw_ingredient	25.00	2.50	4.00	0.30	20.00	0.50	0.00	100.00	g	https://placehold.co/400?text=Kale	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
57	ผักบุ้งจีน	raw_ingredient	20.00	2.00	3.50	0.20	25.00	0.40	0.00	100.00	g	https://placehold.co/400?text=Morning+Glory	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
58	กะหล่ำปลี	raw_ingredient	25.00	1.30	6.00	0.10	18.00	3.20	0.00	100.00	g	https://placehold.co/400?text=Cabbage	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
59	ผักกาดขาว	raw_ingredient	16.00	1.20	3.00	0.20	15.00	1.50	0.00	100.00	g	https://placehold.co/400?text=Chinese+Cabbage	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
60	แครอท	raw_ingredient	41.00	0.90	10.00	0.20	69.00	4.70	0.00	100.00	g	https://placehold.co/400?text=Carrot	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
61	แตงกวา	raw_ingredient	15.00	0.70	3.60	0.10	2.00	1.70	0.00	100.00	g	https://placehold.co/400?text=Cucumber	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
62	มะเขือเทศ	raw_ingredient	18.00	0.90	3.90	0.20	5.00	2.60	0.00	100.00	g	https://placehold.co/400?text=Tomato	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
63	ฟักทอง	raw_ingredient	26.00	1.00	6.50	0.10	1.00	2.80	0.00	100.00	g	https://placehold.co/400?text=Pumpkin	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
64	มันฝรั่ง	raw_ingredient	77.00	2.00	17.00	0.10	6.00	0.80	0.00	100.00	g	https://placehold.co/400?text=Potato	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
65	ข้าวโพดหวาน	raw_ingredient	86.00	3.20	19.00	1.20	15.00	6.00	0.00	100.00	g	https://placehold.co/400?text=Sweet+Corn	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
66	ถั่วลันเตา	raw_ingredient	81.00	5.40	14.00	0.40	5.00	5.70	0.00	100.00	g	https://placehold.co/400?text=Green+Peas	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
67	เห็ดเข็มทอง	raw_ingredient	37.00	2.70	7.80	0.30	3.00	0.20	0.00	100.00	g	https://placehold.co/400?text=Enoki+Mushroom	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
68	พริกขี้หนู	raw_ingredient	40.00	1.90	8.80	0.40	9.00	5.00	0.00	100.00	g	https://placehold.co/400?text=Chili	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
69	กระเทียม	raw_ingredient	149.00	6.40	33.00	0.50	17.00	1.00	0.00	100.00	g	https://placehold.co/400?text=Garlic	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
70	หอมใหญ่	raw_ingredient	40.00	1.10	9.00	0.10	4.00	4.20	0.00	100.00	g	https://placehold.co/400?text=Onion	2026-02-17 17:37:50.735627	\N	\N	0.00	ผัก/วัตถุดิบ
71	มะม่วงสุก	snack	60.00	0.80	15.00	0.40	1.00	13.70	0.00	100.00	g	https://placehold.co/400?text=Mango	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
72	มะม่วงดิบ	snack	65.00	0.50	17.00	0.20	2.00	2.00	0.00	100.00	g	https://placehold.co/400?text=Green+Mango	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
73	ทุเรียน	snack	147.00	1.50	27.00	5.30	2.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Durian	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
74	มังคุด	snack	73.00	0.40	18.00	0.60	7.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Mangosteen	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
75	เงาะ	snack	82.00	0.70	21.00	0.20	11.00	0.00	0.00	100.00	g	https://placehold.co/400?text=Rambutan	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
76	ส้ม	snack	47.00	0.90	12.00	0.10	0.00	9.00	0.00	1.00	piece	https://placehold.co/400?text=Orange	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
77	แอปเปิ้ลแดง	snack	52.00	0.30	14.00	0.20	1.00	10.00	0.00	1.00	piece	https://placehold.co/400?text=Apple	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
78	ฝรั่ง	snack	68.00	2.60	14.00	1.00	2.00	9.00	0.00	1.00	piece	https://placehold.co/400?text=Guava	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
79	แตงโม	snack	30.00	0.60	8.00	0.20	1.00	6.00	0.00	100.00	g	https://placehold.co/400?text=Watermelon	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
80	สับปะรด	snack	50.00	0.50	13.00	0.10	1.00	10.00	0.00	100.00	g	https://placehold.co/400?text=Pineapple	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
81	แก้วมังกร	snack	60.00	1.20	9.00	0.00	0.00	8.00	0.00	100.00	g	https://placehold.co/400?text=Dragon+Fruit	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
82	มะละกอสุก	snack	43.00	0.50	11.00	0.30	8.00	8.00	0.00	100.00	g	https://placehold.co/400?text=Papaya	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
83	องุ่น	snack	69.00	0.70	18.00	0.20	2.00	15.00	0.00	100.00	g	https://placehold.co/400?text=Grape	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
84	สตรอเบอร์รี่	snack	32.00	0.70	7.70	0.30	1.00	4.90	0.00	100.00	g	https://placehold.co/400?text=Strawberry	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
85	อะโวคาโด	snack	160.00	2.00	8.50	14.70	7.00	0.70	0.00	100.00	g	https://placehold.co/400?text=Avocado	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
96	ข้าวเหนียวมะม่วง	snack	450.00	6.00	85.00	12.00	150.00	35.00	0.00	1.00	set	https://placehold.co/400?text=Mango+Sticky+Rice	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
97	บัวลอยไข่หวาน	snack	380.00	5.00	65.00	14.00	200.00	25.00	180.00	1.00	bowl	https://placehold.co/400?text=Bua+Loy	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
98	ลอดช่องน้ำกะทิ	snack	250.00	2.00	40.00	10.00	120.00	18.00	0.00	1.00	bowl	https://placehold.co/400?text=Lod+Chong	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
99	ขนมครก (คู่)	snack	80.00	1.00	12.00	4.00	25.00	6.00	0.00	2.00	piece	https://placehold.co/400?text=Kanom+Krok	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
100	สาคูไส้หมู	snack	45.00	1.50	8.00	1.50	50.00	1.00	5.00	1.00	piece	https://placehold.co/400?text=Saku	2026-02-17 17:37:50.735627	\N	\N	0.00	ผลไม้/ของว่าง
86	ชาไทยเย็น	beverage	350.00	2.00	45.00	18.00	60.00	38.00	25.00	1.00	glass	https://placehold.co/400?text=Thai+Tea	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
87	กาแฟเย็น (คาปูชิโน่)	beverage	220.00	6.00	25.00	10.00	90.00	18.00	30.00	1.00	glass	https://placehold.co/400?text=Iced+Cappuccino	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
88	ชามะนาว	beverage	150.00	0.50	38.00	0.00	20.00	35.00	0.00	1.00	glass	https://placehold.co/400?text=Lemon+Tea	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
89	ชาเขียวเย็น (ใส่นม)	beverage	320.00	4.00	40.00	16.00	70.00	32.00	20.00	1.00	glass	https://placehold.co/400?text=Green+Tea	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
90	โกโก้เย็น	beverage	380.00	5.00	50.00	18.00	85.00	40.00	25.00	1.00	glass	https://placehold.co/400?text=Iced+Cocoa	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
91	น้ำอัดลม (โคล่า)	beverage	140.00	0.00	35.00	0.00	15.00	35.00	0.00	325.00	ml	https://placehold.co/400?text=Cola	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
92	น้ำเปล่า	beverage	0.00	0.00	0.00	0.00	0.00	0.00	0.00	600.00	ml	https://placehold.co/400?text=Water	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
93	เบียร์ (Lager)	beverage	140.00	1.50	12.00	0.00	10.00	0.00	0.00	330.00	ml	https://placehold.co/400?text=Beer	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
94	นมอัลมอนด์	beverage	60.00	2.00	3.00	5.00	150.00	0.00	0.00	200.00	ml	https://placehold.co/400?text=Almond+Milk	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
95	น้ำส้มคั้นสด	beverage	90.00	1.50	21.00	0.50	5.00	18.00	0.00	200.00	ml	https://placehold.co/400?text=Orange+Juice	2026-02-17 17:37:50.735627	\N	\N	0.00	เครื่องดื่ม
\.


--
-- TOC entry 5452 (class 0 OID 21088)
-- Dependencies: 264
-- Data for Name: health_contents; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.health_contents (content_id, title, type, thumbnail_url, resource_url, description, category_tag, difficulty_level, is_published, created_at) FROM stdin;
\.


--
-- TOC entry 5420 (class 0 OID 20751)
-- Dependencies: 232
-- Data for Name: ingredients; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.ingredients (ingredient_id, name, category, default_unit_id, calories_per_unit, created_at) FROM stdin;
\.


--
-- TOC entry 5430 (class 0 OID 20853)
-- Dependencies: 242
-- Data for Name: meals; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.meals (meal_id, user_id, item_id, meal_type, meal_time, total_amount, created_at) FROM stdin;
169	37	\N	dinner	2026-03-20 12:00:00	695.0	2026-03-20 22:07:31.125792
171	37	\N	breakfast	2026-03-20 12:00:00	540.0	2026-03-20 22:08:18.716002
172	37	\N	breakfast	2026-03-19 12:00:00	650.0	2026-03-20 22:09:07.710472
\.


--
-- TOC entry 5450 (class 0 OID 21070)
-- Dependencies: 262
-- Data for Name: notifications; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.notifications (notification_id, user_id, title, message, type, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 5454 (class 0 OID 21115)
-- Dependencies: 266
-- Data for Name: password_reset_codes; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.password_reset_codes (id, user_id, code, expires_at, used, created_at) FROM stdin;
\.


--
-- TOC entry 5444 (class 0 OID 21001)
-- Dependencies: 256
-- Data for Name: progress; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.progress (progress_id, user_id, weight_id, daily_id, current_streak, weekly_target, created_at) FROM stdin;
\.


--
-- TOC entry 5468 (class 0 OID 21269)
-- Dependencies: 280
-- Data for Name: recipe_favorites; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_favorites (fav_id, recipe_id, user_id, created_at) FROM stdin;
1	1	34	2026-03-22 16:38:48.368138
2	5	34	2026-03-22 16:38:48.368138
3	10	34	2026-03-22 16:38:48.368138
\.


--
-- TOC entry 5458 (class 0 OID 21165)
-- Dependencies: 270
-- Data for Name: recipe_ingredients; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_ingredients (ing_id, recipe_id, ingredient_name, quantity, unit, is_optional, note, sort_order, created_at) FROM stdin;
1	1	ไก่ทั้งตัว	1.00	ตัว	f	ล้างสะอาด	1	2026-03-22 16:38:23.590561
2	1	ข้าวหอมมะลิ	2.00	ถ้วย	f	ล้างน้ำ 2-3 รอบ	2	2026-03-22 16:38:23.590561
3	1	ขิงแก่	3.00	แว่น	f	หั่นบาง	3	2026-03-22 16:38:23.590561
4	1	ต้นหอม	2.00	ต้น	f	แบ่งครึ่ง	4	2026-03-22 16:38:23.590561
5	1	กระเทียม	5.00	กลีบ	f	ทุบพอแตก	5	2026-03-22 16:38:23.590561
6	1	ซีอิ๊วขาว	2.00	ช้อนโต๊ะ	f	\N	6	2026-03-22 16:38:23.590561
7	1	น้ำมันงา	1.00	ช้อนชา	f	\N	7	2026-03-22 16:38:23.590561
8	1	พริกขี้หนู	5.00	เม็ด	t	สำหรับน้ำจิ้ม	8	2026-03-22 16:38:23.590561
9	1	ขิงอ่อน	\N	\N	t	ตกแต่ง	9	2026-03-22 16:38:23.590561
10	1	ไก่ทั้งตัว	1.00	ตัว	f	ล้างสะอาด	1	2026-03-22 16:38:48.368138
11	1	ข้าวหอมมะลิ	2.00	ถ้วย	f	ล้างน้ำ 2 รอบ	2	2026-03-22 16:38:48.368138
12	1	ขิงแก่	3.00	แว่น	f	หั่นบาง	3	2026-03-22 16:38:48.368138
13	1	ต้นหอม	2.00	ต้น	f	\N	4	2026-03-22 16:38:48.368138
14	1	กระเทียม	5.00	กลีบ	f	ทุบพอแตก	5	2026-03-22 16:38:48.368138
15	1	ซีอิ๊วขาว	1.50	ช้อนโต๊ะ	f	\N	6	2026-03-22 16:38:48.368138
16	1	น้ำมันงา	1.00	ช้อนชา	f	ราดข้าวก่อนเสิร์ฟ	7	2026-03-22 16:38:48.368138
17	1	เกลือ	1.00	ช้อนชา	f	\N	8	2026-03-22 16:38:48.368138
18	1	พริกขี้หนู	5.00	เม็ด	t	สำหรับน้ำจิ้ม	9	2026-03-22 16:38:48.368138
19	1	ขิงอ่อน	\N	\N	t	ตกแต่ง	10	2026-03-22 16:38:48.368138
20	3	น่องไก่	4.00	ชิ้น	f	ล้างสะอาด	1	2026-03-22 16:38:48.368138
21	3	กระเทียม	6.00	กลีบ	f	โขลก	2	2026-03-22 16:38:48.368138
22	3	รากผักชี	3.00	ราก	f	โขลก	3	2026-03-22 16:38:48.368138
23	3	พริกไทยดำ	1.00	ช้อนชา	f	\N	4	2026-03-22 16:38:48.368138
24	3	ซีอิ๊วขาว	2.00	ช้อนโต๊ะ	f	\N	5	2026-03-22 16:38:48.368138
25	3	น้ำมันหอย	1.00	ช้อนโต๊ะ	f	\N	6	2026-03-22 16:38:48.368138
26	3	ข้าวหอมมะลิ	2.00	ถ้วย	f	หุงด้วยน้ำซุปไก่	7	2026-03-22 16:38:48.368138
27	3	น้ำมันพืช	3.00	ถ้วย	f	สำหรับทอด	8	2026-03-22 16:38:48.368138
28	3	แป้งทอดกรอบ	2.00	ช้อนโต๊ะ	t	ทำให้กรอบขึ้น	9	2026-03-22 16:38:48.368138
29	5	เส้นจันท์	200.00	กรัม	f	แช่น้ำ 30 นาที	1	2026-03-22 16:38:48.368138
30	5	กุ้งแวนนาไม	200.00	กรัม	f	แกะเปลือก ผ่าหลัง	2	2026-03-22 16:38:48.368138
31	5	ไข่ไก่	2.00	ฟอง	f	\N	3	2026-03-22 16:38:48.368138
32	5	เต้าหู้แข็ง	100.00	กรัม	f	หั่นเต๋า ทอดให้เหลือง	4	2026-03-22 16:38:48.368138
33	5	ถั่วงอก	100.00	กรัม	f	\N	5	2026-03-22 16:38:48.368138
34	5	ใบกุยช่าย	30.00	กรัม	f	หั่น 2 ซม.	6	2026-03-22 16:38:48.368138
35	5	น้ำมะขามเปียก	3.00	ช้อนโต๊ะ	f	\N	7	2026-03-22 16:38:48.368138
36	5	น้ำปลา	2.00	ช้อนโต๊ะ	f	\N	8	2026-03-22 16:38:48.368138
37	5	น้ำตาลปี๊บ	1.50	ช้อนโต๊ะ	f	\N	9	2026-03-22 16:38:48.368138
38	5	พริกป่น	1.00	ช้อนชา	f	\N	10	2026-03-22 16:38:48.368138
39	5	ถั่วลิสงป่น	3.00	ช้อนโต๊ะ	t	โรยหน้า	11	2026-03-22 16:38:48.368138
40	5	มะนาว	1.00	ผล	t	เสิร์ฟข้างๆ	12	2026-03-22 16:38:48.368138
41	6	อกไก่	400.00	กรัม	f	หั่นชิ้นพอดีคำ	1	2026-03-22 16:38:48.368138
42	6	พริกแกงเขียวหวาน	3.00	ช้อนโต๊ะ	f	\N	2	2026-03-22 16:38:48.368138
43	6	กะทิ	400.00	มล.	f	\N	3	2026-03-22 16:38:48.368138
44	6	มะเขือพวง	100.00	กรัม	f	\N	4	2026-03-22 16:38:48.368138
45	6	มะเขือเปราะ	2.00	ลูก	f	หั่น 4 ส่วน	5	2026-03-22 16:38:48.368138
46	6	ใบมะกรูด	5.00	ใบ	f	ฉีกเส้นกลางออก	6	2026-03-22 16:38:48.368138
47	6	พริกชี้ฟ้าแดง	2.00	เม็ด	f	หั่นแฉลบ	7	2026-03-22 16:38:48.368138
48	6	น้ำปลา	2.00	ช้อนโต๊ะ	f	\N	8	2026-03-22 16:38:48.368138
49	6	น้ำตาลปี๊บ	1.00	ช้อนชา	f	\N	9	2026-03-22 16:38:48.368138
50	6	น้ำมันพืช	1.00	ช้อนโต๊ะ	f	\N	10	2026-03-22 16:38:48.368138
51	7	อกไก่	300.00	กรัม	f	หั่นชิ้น	1	2026-03-22 16:38:48.368138
52	7	กะทิ	400.00	มล.	f	\N	2	2026-03-22 16:38:48.368138
53	7	น้ำสต็อก	200.00	มล.	f	หรือน้ำเปล่า	3	2026-03-22 16:38:48.368138
54	7	ข่า	4.00	แว่น	f	ทุบ	4	2026-03-22 16:38:48.368138
55	7	ตะไคร้	2.00	ต้น	f	หั่นท่อน ทุบ	5	2026-03-22 16:38:48.368138
56	7	ใบมะกรูด	4.00	ใบ	f	ฉีก	6	2026-03-22 16:38:48.368138
57	7	เห็ดฟาง	100.00	กรัม	f	หั่นครึ่ง	7	2026-03-22 16:38:48.368138
58	7	น้ำปลา	3.00	ช้อนโต๊ะ	f	\N	8	2026-03-22 16:38:48.368138
59	7	น้ำมะนาว	3.00	ช้อนโต๊ะ	f	\N	9	2026-03-22 16:38:48.368138
60	7	พริกขี้หนู	5.00	เม็ด	f	ทุบ	10	2026-03-22 16:38:48.368138
61	7	ผักชี	\N	\N	t	โรยหน้า	11	2026-03-22 16:38:48.368138
62	8	น่องไก่	4.00	ชิ้น	f	ล้างสะอาด	1	2026-03-22 16:38:48.368138
63	8	กระเทียม	6.00	กลีบ	f	โขลก	2	2026-03-22 16:38:48.368138
64	8	รากผักชี	3.00	ราก	f	โขลก	3	2026-03-22 16:38:48.368138
65	8	ตะไคร้	2.00	ต้น	f	สับละเอียด	4	2026-03-22 16:38:48.368138
66	8	พริกไทยดำ	1.00	ช้อนชา	f	\N	5	2026-03-22 16:38:48.368138
67	8	ซีอิ๊วขาว	2.00	ช้อนโต๊ะ	f	\N	6	2026-03-22 16:38:48.368138
68	8	น้ำมันงา	1.00	ช้อนชา	f	\N	7	2026-03-22 16:38:48.368138
69	8	น้ำตาลปี๊บ	1.00	ช้อนโต๊ะ	f	\N	8	2026-03-22 16:38:48.368138
70	8	ข้าวเหนียว	\N	\N	t	เสิร์ฟคู่	9	2026-03-22 16:38:48.368138
71	8	ส้มตำ	\N	\N	t	เสิร์ฟคู่	10	2026-03-22 16:38:48.368138
72	10	ปลากะพงขาว	1.00	ตัว	f	400-500 กรัม ควักไส้แล้ว	1	2026-03-22 16:38:48.368138
73	10	น้ำมะนาว	5.00	ช้อนโต๊ะ	f	\N	2	2026-03-22 16:38:48.368138
74	10	น้ำปลา	3.00	ช้อนโต๊ะ	f	\N	3	2026-03-22 16:38:48.368138
75	10	น้ำตาลทราย	1.00	ช้อนชา	f	\N	4	2026-03-22 16:38:48.368138
76	10	กระเทียม	8.00	กลีบ	f	สับละเอียด	5	2026-03-22 16:38:48.368138
77	10	พริกขี้หนู	5.00	เม็ด	f	สับ	6	2026-03-22 16:38:48.368138
78	10	ตะไคร้	1.00	ต้น	f	หั่นท่อนสั้นยัดท้องปลา	7	2026-03-22 16:38:48.368138
79	10	ผักชี	10.00	กรัม	t	โรยหน้า	8	2026-03-22 16:38:48.368138
80	10	พริกชี้ฟ้าแดง	2.00	เม็ด	t	หั่นแฉลบตกแต่ง	9	2026-03-22 16:38:48.368138
81	11	อกไก่	400.00	กรัม	f	ตัดเส้นเอ็นออก	1	2026-03-22 16:38:48.368138
82	11	กระเทียม	4.00	กลีบ	f	สับ	2	2026-03-22 16:38:48.368138
83	11	โรสแมรี่	2.00	กิ่ง	f	\N	3	2026-03-22 16:38:48.368138
84	11	น้ำมันมะกอก	2.00	ช้อนโต๊ะ	f	\N	4	2026-03-22 16:38:48.368138
85	11	ซีอิ๊วดำ	1.00	ช้อนโต๊ะ	f	\N	5	2026-03-22 16:38:48.368138
86	11	พริกไทยดำ	1.00	ช้อนชา	f	\N	6	2026-03-22 16:38:48.368138
87	11	เกลือ	0.50	ช้อนชา	f	\N	7	2026-03-22 16:38:48.368138
88	11	มันฝรั่ง	200.00	กรัม	t	ต้มและบด	8	2026-03-22 16:38:48.368138
89	11	ผักสลัด	50.00	กรัม	t	เสิร์ฟคู่	9	2026-03-22 16:38:48.368138
90	11	ซอสมัสตาร์ด	\N	\N	t	ราดข้าง	10	2026-03-22 16:38:48.368138
\.


--
-- TOC entry 5466 (class 0 OID 21243)
-- Dependencies: 278
-- Data for Name: recipe_reviews; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_reviews (review_id, recipe_id, user_id, rating, comment, created_at) FROM stdin;
1	1	5	5	ทำตามแล้วอร่อยมาก ข้าวหอมมาก ไก่นุ่ม ทานทั้งครอบครัว	2026-03-22 16:38:48.368138
2	5	5	5	ผัดไทยรสชาติดีมาก เส้นไม่ติดกัน กุ้งสด แนะนำเลย!	2026-03-22 16:38:48.368138
3	7	5	4	รสชาติดี แต่อยากให้เปรี้ยวกว่านี้หน่อย โดยรวมโอเค	2026-03-22 16:38:48.368138
4	10	5	5	ปลานึ่งมะนาวรสชาติสดใส ทำง่ายมาก ทำซ้ำทุกสัปดาห์	2026-03-22 16:38:48.368138
5	11	5	4	สเต็กไก่นุ่ม หมักครบรส ทำกินเองประหยัดและอร่อยด้วย	2026-03-22 16:38:48.368138
6	3	37	5	so good	2026-03-22 16:59:16.593088
\.


--
-- TOC entry 5460 (class 0 OID 21185)
-- Dependencies: 272
-- Data for Name: recipe_steps; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_steps (step_id, recipe_id, step_number, title, instruction, time_minutes, image_url, tips, created_at) FROM stdin;
1	1	1	ต้มน้ำซุป	ต้มน้ำ 2 ลิตร ใส่ขิง ต้นหอม กระเทียม และเกลือ 1 ช้อนชา รอจนเดือด	10	\N	ใส่ขิงให้พอเพียงเพื่อดับกลิ่นคาวไก่	2026-03-22 16:38:23.590561
2	1	2	ต้มไก่	ใส่ไก่ทั้งตัวลงในน้ำเดือด ลดไฟกลาง ต้มนาน 30–35 นาที จนสุก เจาะดูด้วยตะเกียบ ถ้าน้ำใสแสดงว่าสุกแล้ว	35	\N	อย่าต้มด้วยไฟแรง เนื้อไก่จะเหนียว ให้ใช้ไฟกลาง-อ่อน	2026-03-22 16:38:23.590561
3	1	3	หุงข้าว	ตักน้ำซุปไก่ที่ต้มได้ 2.5 ถ้วยมาหุงข้าว เติมน้ำมันงาและซีอิ๊วขาว หุงจนสุก	20	\N	ข้าวที่หุงด้วยน้ำซุปจะหอมและอร่อยกว่าหุงด้วยน้ำเปล่ามาก	2026-03-22 16:38:23.590561
4	1	4	ทำน้ำจิ้ม	สับพริก ขิงอ่อน ผสมกับซีอิ๊วขาว น้ำตาล น้ำมะนาว คนให้เข้ากัน	5	\N	ปรับรสตามชอบ ถ้าชอบเผ็ดเพิ่มพริก	2026-03-22 16:38:23.590561
5	1	5	จัดเสิร์ฟ	หั่นไก่เป็นชิ้น จัดลงบนข้าว ราดน้ำซุปบางๆ โรยต้นหอมซอย เสิร์ฟพร้อมน้ำจิ้ม	5	\N	ราดน้ำมันไก่บางๆ บนข้าวก่อนเสิร์ฟ จะหอมมากขึ้น	2026-03-22 16:38:23.590561
6	1	1	ต้มน้ำซุป	ต้มน้ำ 2 ลิตร ใส่ขิง ต้นหอม กระเทียมทุบ และเกลือ 1 ช้อนชา รอจนเดือด	10	\N	ใส่ขิงให้พอเพียงเพื่อดับกลิ่นคาวไก่	2026-03-22 16:38:48.368138
7	1	2	ต้มไก่	ใส่ไก่ทั้งตัวลงในน้ำเดือด ลดไฟกลาง-อ่อน ต้ม 35–40 นาทีจนสุก ใช้ตะเกียบแทงดู น้ำใสแสดงว่าสุก	40	\N	ไม่ต้มด้วยไฟแรง เนื้อจะเหนียว ให้ใช้ไฟกลาง-อ่อน	2026-03-22 16:38:48.368138
8	1	3	หุงข้าว	ตักน้ำซุปไก่ 2.5 ถ้วยมาหุงข้าว ใส่น้ำมันงาและซีอิ๊วขาว หุงจนสุก	20	\N	ข้าวที่หุงด้วยน้ำซุปจะหอมและอร่อยกว่าน้ำเปล่ามาก	2026-03-22 16:38:48.368138
9	1	4	ทำน้ำจิ้ม	สับพริกและขิงอ่อน ผสมซีอิ๊วขาว น้ำตาล น้ำมะนาว คนให้เข้ากัน	5	\N	ปรับรสตามชอบ ถ้าชอบเผ็ดเพิ่มพริก	2026-03-22 16:38:48.368138
10	1	5	จัดเสิร์ฟ	หั่นไก่เป็นชิ้น จัดบนข้าว ราดน้ำซุปบางๆ โรยต้นหอมซอย เสิร์ฟพร้อมน้ำจิ้ม	5	\N	ราดน้ำมันไก่บางๆ บนข้าวก่อนเสิร์ฟจะหอมมาก	2026-03-22 16:38:48.368138
11	5	1	เตรียมเส้น	แช่เส้นจันท์ในน้ำอุ่น 30 นาที จนนิ่ม สะเด็ดน้ำ	30	\N	อย่าแช่นานเกินไป เส้นจะเละ	2026-03-22 16:38:48.368138
12	5	2	ผัดกุ้ง	ตั้งกระทะไฟแรง ใส่น้ำมัน ผัดกุ้งจนเปลี่ยนสี ตักออก	3	\N	ผัดกุ้งแค่สุก ไม่ต้องนาน จะแน่นและเหนียว	2026-03-22 16:38:48.368138
13	5	3	ผัดเส้นและไข่	ใช้กระทะเดิม ใส่น้ำมันเพิ่ม ใส่เส้น ผัดจนเส้นเริ่มนุ่ม แหวกพื้นที่ใส่ไข่ คนรวมกัน	5	\N	ไฟต้องแรงมากเพื่อให้เส้นไม่ติดกระทะ	2026-03-22 16:38:48.368138
14	5	4	ปรุงรสและรวม	ใส่น้ำมะขาม น้ำปลา น้ำตาล พริกป่น คนให้เข้ากัน ใส่กุ้งและถั่วงอก ผัดรวม 1 นาที	3	\N	ชิมรสก่อนเสิร์ฟ ปรับตามชอบ	2026-03-22 16:38:48.368138
15	5	5	จัดเสิร์ฟ	ตักใส่จาน โรยถั่วลิสงป่น ใบกุยช่าย เสิร์ฟพร้อมมะนาวและพริกป่น	2	\N	เสิร์ฟทันทีขณะร้อนๆ เส้นจะไม่เกาะกัน	2026-03-22 16:38:48.368138
16	7	1	ต้มน้ำซุปสมุนไพร	ต้มน้ำ 600 มล. ใส่ข่า ตะไคร้ ใบมะกรูด ต้มด้วยไฟกลาง 5 นาที	5	\N	ต้มสมุนไพรก่อนเสมอเพื่อให้กลิ่นหอมออกมา	2026-03-22 16:38:48.368138
17	7	2	ใส่กะทิและไก่	เทกะทิลงในน้ำซุป ใส่ไก่ที่หั่นไว้ ต้มด้วยไฟกลางจนไก่สุก ประมาณ 10 นาที	10	\N	อย่าต้มกะทินานเกินไปจะแตกมัน	2026-03-22 16:38:48.368138
18	7	3	ใส่เห็ดและปรุงรส	ใส่เห็ดฟาง ต้มต่อ 3 นาที ปรุงรสด้วยน้ำปลา น้ำมะนาว และพริกขี้หนูทุบ	5	\N	ใส่น้ำมะนาวหลังปิดไฟแล้ว รสจะสดกว่า	2026-03-22 16:38:48.368138
19	7	4	ชิมรสและเสิร์ฟ	ชิมรส ให้ได้รส เปรี้ยวนำ เค็มตาม มันกะทิปิดท้าย ตักใส่ชาม โรยผักชี	2	\N	ต้มข่าที่อร่อยต้องได้รสเปรี้ยวนำก่อน	2026-03-22 16:38:48.368138
20	10	1	เตรียมปลา	ล้างปลาให้สะอาด กรีดตัวปลา 3 รอยทั้ง 2 ด้าน ยัดตะไคร้ในท้องปลา วางบนจาน	10	\N	กรีดปลาเพื่อให้รสซึมเข้าเนื้อและนึ่งสุกทั่วกัน	2026-03-22 16:38:48.368138
21	10	2	ทำน้ำปรุง	ผสมน้ำมะนาว น้ำปลา น้ำตาล กระเทียมสับ และพริกขี้หนูสับ คนให้เข้ากัน	5	\N	ชิมน้ำปรุงก่อน ให้ได้รสเปรี้ยวเค็มหวานสมดุล	2026-03-22 16:38:48.368138
22	10	3	นึ่งปลา	ต้มน้ำในหม้อนึ่ง เมื่อน้ำเดือดวางปลา นึ่งด้วยไฟกลาง-แรง 12–15 นาทีจนสุก	15	\N	ใช้ไม้จิ้มทดสอบ ถ้าเนื้อนิ่มและขาวขุ่นแสดงว่าสุกแล้ว	2026-03-22 16:38:48.368138
23	10	4	ราดน้ำปรุงและเสิร์ฟ	วางปลาบนจานเสิร์ฟ ราดน้ำปรุง โรยผักชีและพริกชี้ฟ้าแดง เสิร์ฟทันที	2	\N	ราดน้ำปรุงขณะปลายังร้อนๆ รสจะซึมเข้าเนื้อดีกว่า	2026-03-22 16:38:48.368138
24	11	1	หมักไก่	ผสมน้ำมันมะกอก กระเทียมสับ โรสแมรี่ ซีอิ๊วดำ พริกไทย เกลือ หมักอกไก่อย่างน้อย 30 นาที	30	\N	หมักค้างคืนในตู้เย็นจะได้รสชาติดีที่สุด	2026-03-22 16:38:48.368138
25	11	2	เตรียมกระทะ	ตั้งกระทะด้วยไฟกลาง-แรง ทาน้ำมันเล็กน้อย รอให้กระทะร้อนจัดก่อน	3	\N	กระทะต้องร้อนจัด เพื่อให้ผิวไก่เป็นสีน้ำตาลสวยงาม	2026-03-22 16:38:48.368138
26	11	3	ย่างไก่	วางอกไก่ลงกระทะ ย่างด้านแรก 6–7 นาที ไม่กด ไม่ขยับ พลิกด้านย่างต่ออีก 5–6 นาที	13	\N	อย่าพลิกบ่อย ทิ้งไว้ให้ผิวกรอบก่อนพลิก	2026-03-22 16:38:48.368138
27	11	4	พักเนื้อ	นำไก่ออกจากกระทะ วางบนเขียง พักไว้ 5 นาที ก่อนหั่นเสิร์ฟ	5	\N	พักเนื้อสำคัญมาก น้ำเนื้อจะไม่ไหลออกเมื่อหั่น	2026-03-22 16:38:48.368138
28	11	5	จัดเสิร์ฟ	หั่นไก่ตามขวาง จัดลงจาน เสิร์ฟพร้อมมันบดและผักสลัด ราดซอสตามชอบ	2	\N	หั่นตัดเส้นใยเนื้อ ไก่จะเนื้อนุ่มกว่าหั่นตามยาว	2026-03-22 16:38:48.368138
\.


--
-- TOC entry 5464 (class 0 OID 21224)
-- Dependencies: 276
-- Data for Name: recipe_tips; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_tips (tip_id, recipe_id, tip_text, sort_order, created_at) FROM stdin;
1	1	ใช้ไก่บ้านจะได้เนื้อนุ่มหวานกว่าไก่เนื้อ	1	2026-03-22 16:38:23.590561
2	1	น้ำซุปที่เหลือเก็บไว้ทำซุปมื้อต่อไปได้	2	2026-03-22 16:38:23.590561
3	1	ถ้าอยากให้ผิวไก่เหลืองสวย ให้ทาน้ำมันงาหลังต้มเสร็จ	3	2026-03-22 16:38:23.590561
4	1	ข้าวจะอร่อยกว่าถ้าใส่ใบเตยลงหุงด้วย	4	2026-03-22 16:38:23.590561
5	1	ใช้ไก่บ้านจะได้เนื้อนุ่มหวานกว่าไก่เนื้อ	1	2026-03-22 16:38:48.368138
6	1	น้ำซุปที่เหลือเก็บแช่แข็งไว้ทำซุปมื้อต่อไปได้	2	2026-03-22 16:38:48.368138
7	1	ทาน้ำมันงาบนไก่หลังต้มเสร็จ ผิวจะเหลืองสวย	3	2026-03-22 16:38:48.368138
8	1	ข้าวอร่อยขึ้นถ้าใส่ใบเตยลงหุงด้วย	4	2026-03-22 16:38:48.368138
9	5	แช่เส้นในน้ำอุ่น ไม่ใช่น้ำร้อน เส้นจะไม่เละเมื่อผัด	1	2026-03-22 16:38:48.368138
10	5	ใช้กระทะเหล็กหรือกระทะเหล็กหล่อ ไฟแรงได้ดีกว่า	2	2026-03-22 16:38:48.368138
11	5	ผัดไทยอร่อยต้องใช้ไฟแรงมาก ไม่งั้นเส้นจะไม่หอม	3	2026-03-22 16:38:48.368138
12	5	น้ำมะขามเปียกแท้ให้รสดีกว่าน้ำมะขามสำเร็จรูป	4	2026-03-22 16:38:48.368138
13	7	ใส่น้ำมะนาวหลังปิดไฟแล้ว รสจะสดและไม่ขม	1	2026-03-22 16:38:48.368138
14	7	ข่าต้องทุบก่อนใส่ เพื่อให้น้ำมันหอมระเหยออก	2	2026-03-22 16:38:48.368138
15	7	ถ้าต้องการเพิ่มความเข้มข้น ใส่กะทิมากขึ้น	3	2026-03-22 16:38:48.368138
16	10	ปลาสดจะนึ่งได้กลิ่นหอม ถ้าปลาไม่สดมากให้ใส่ขิงเพิ่ม	1	2026-03-22 16:38:48.368138
17	10	กรีดปลาให้ลึกถึงก้าง เพื่อให้สุกทั่วกัน	2	2026-03-22 16:38:48.368138
18	10	นึ่งด้วยไฟแรงจะได้เนื้อปลาไม่เหนียว	3	2026-03-22 16:38:48.368138
19	11	หมักไก่ค้างคืนรสชาติจะแทรกซึมเข้าเนื้อดีที่สุด	1	2026-03-22 16:38:48.368138
20	11	อย่าลืมพักเนื้อ 5 นาทีก่อนหั่น น้ำเนื้อจะไม่ไหลออก	2	2026-03-22 16:38:48.368138
21	11	ตีอกไก่ให้บางสม่ำเสมอ เนื้อจะสุกทั่วกัน ไม่แห้งบางส่วน	3	2026-03-22 16:38:48.368138
\.


--
-- TOC entry 5462 (class 0 OID 21205)
-- Dependencies: 274
-- Data for Name: recipe_tools; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipe_tools (tool_id, recipe_id, tool_name, tool_emoji, sort_order, created_at) FROM stdin;
1	1	หม้อใบใหญ่	🍲	1	2026-03-22 16:38:23.590561
2	1	เตาแก๊ส	🔥	2	2026-03-22 16:38:23.590561
3	1	มีดและเขียง	🔪	3	2026-03-22 16:38:23.590561
4	1	หม้อหุงข้าว	🍚	4	2026-03-22 16:38:23.590561
5	1	ชาม	🥣	5	2026-03-22 16:38:23.590561
6	1	หม้อใบใหญ่	🍲	1	2026-03-22 16:38:48.368138
7	1	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
8	1	มีดและเขียง	🔪	3	2026-03-22 16:38:48.368138
9	1	หม้อหุงข้าว	🍚	4	2026-03-22 16:38:48.368138
10	5	กระทะใหญ่	🥘	1	2026-03-22 16:38:48.368138
11	6	กระทะใหญ่	🥘	1	2026-03-22 16:38:48.368138
12	11	กระทะใหญ่	🥘	1	2026-03-22 16:38:48.368138
13	5	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
14	6	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
15	11	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
16	5	ตะหลิว	🥄	3	2026-03-22 16:38:48.368138
17	6	ตะหลิว	🥄	3	2026-03-22 16:38:48.368138
18	11	ตะหลิว	🥄	3	2026-03-22 16:38:48.368138
19	5	มีดและเขียง	🔪	4	2026-03-22 16:38:48.368138
20	6	มีดและเขียง	🔪	4	2026-03-22 16:38:48.368138
21	11	มีดและเขียง	🔪	4	2026-03-22 16:38:48.368138
22	5	ชามผสม	🥣	5	2026-03-22 16:38:48.368138
23	6	ชามผสม	🥣	5	2026-03-22 16:38:48.368138
24	11	ชามผสม	🥣	5	2026-03-22 16:38:48.368138
25	7	หม้อหรือกระทะลึก	🍲	1	2026-03-22 16:38:48.368138
26	7	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
27	7	ทัพพี	🥄	3	2026-03-22 16:38:48.368138
28	10	หม้อนึ่ง	🫕	1	2026-03-22 16:38:48.368138
29	10	เตาแก๊ส	🔥	2	2026-03-22 16:38:48.368138
30	10	มีดและเขียง	🔪	3	2026-03-22 16:38:48.368138
31	10	ชามผสม	🥣	4	2026-03-22 16:38:48.368138
\.


--
-- TOC entry 5428 (class 0 OID 20832)
-- Dependencies: 240
-- Data for Name: recipes; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.recipes (recipe_id, food_id, description, instructions, prep_time_minutes, cooking_time_minutes, serving_people, source_reference, image_url, created_at, deleted_at, recipe_name, category, cuisine, difficulty, avg_rating, review_count, favorite_count, is_published) FROM stdin;
3	2	ไก่ทอดกรอบนอกนุ่มใน เสิร์ฟบนข้าวมัน พร้อมน้ำจิ้มซีอิ๊วหวาน	หมักไก่ > ทอดไก่ > หุงข้าว > เสิร์ฟ	20	30	2.0	\N	https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=800	2026-03-22 16:38:48.368138	\N	ข้าวมันไก่ทอด	อาหารไทย	ไทย-จีน	Medium	5.00	1	0	t
4	3	ขาหมูพะโล้เปื่อย หอมกลิ่นพะโล้ น้ำพะโล้ข้น เสิร์ฟกับข้าวสวยร้อนๆ	เตรียมขาหมู > ต้มน้ำพะโล้ > ตุ๋นขาหมู 2 ชม. > เสิร์ฟ	30	120	4.0	\N	https://images.unsplash.com/photo-1562802378-063ec186a863?w=800	2026-03-22 16:38:48.368138	\N	ข้าวขาหมูพะโล้	อาหารไทย	ไทย-จีน	Hard	0.00	0	0	t
6	12	แกงเขียวหวานรสชาติกลมกล่อม หอมกะทิ เข้มข้น เสิร์ฟกับข้าวสวยร้อน	ผัดพริกแกง > ใส่กะทิ > ใส่ไก่ > ปรุงรส > เสิร์ฟ	15	25	4.0	\N	https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800	2026-03-22 16:38:48.368138	\N	แกงเขียวหวานไก่	อาหารไทย	ไทย	Medium	0.00	0	0	t
8	19	ไก่ย่างหมักด้วยสมุนไพรหอม ย่างไฟอ่อน เนื้อนุ่ม ผิวกรอบ	หมักไก่ข้ามคืน > เตรียมเตาถ่าน > ย่างไฟอ่อน-กลาง > เสิร์ฟ	30	40	2.0	\N	https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=800	2026-03-22 16:38:48.368138	\N	ไก่ย่างสมุนไพร	อาหารไทย	ไทย	Medium	0.00	0	0	t
9	27	ข้าวซอยสูตรเชียงใหม่แท้ น้ำแกงหอมข้น เส้นบะหมีเหลืองทั้งนิ่มและกรอบ	ทำน้ำแกง > ต้มเส้น > ทอดเส้น > เสิร์ฟพร้อมเครื่องเคียง	20	30	2.0	\N	https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800	2026-03-22 16:38:48.368138	\N	ข้าวซอยไก่เชียงใหม่	อาหารไทย	ไทยเหนือ	Medium	0.00	0	0	t
7	13	ต้มข่าหอมกลิ่นข่า ตะไคร้ ใบมะกรูด รสชาติเปรี้ยวนำ มันกะทิตาม	ต้มน้ำซุป > ใส่เครื่องสมุนไพร > ใส่ไก่ > ใส่กะทิ > ปรุงรส	15	20	4.0	\N	https://images.unsplash.com/photo-1548943487-a2e4e43b4853?w=800	2026-03-22 16:38:48.368138	\N	ต้มข่าไก่	อาหารไทย	ไทย	Easy	4.00	1	0	t
11	39	อกไก่สเต็กหมักสมุนไพร ย่างเนื้อนุ่ม เสิร์ฟพร้อมผักและมันบด	หมักไก่ > ย่างหรือทอด > ทำซอส > เสิร์ฟ	20	20	2.0	\N	https://images.unsplash.com/photo-1432139509613-5c4255815697?w=800	2026-03-22 16:38:48.368138	\N	สเต็กไก่สมุนไพร	อาหารตะวันตก	ฟิวชั่น	Easy	4.00	1	0	t
1	1	ข้าวหุงด้วยน้ำซุปไก่ หอมมัน เสิร์ฟพร้อมไก่นุ่มและน้ำจิ้มสูตรเด็ด	ต้มไก่ในน้ำซุป > หุงข้าวในน้ำซุปไก่ > เสิร์ฟพร้อมน้ำจิ้ม	15	40	2.0	\N	https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800	2026-03-22 16:38:23.590561	\N	ข้าวมันไก่ต้ม	อาหารไทย	ไทย-จีน	Easy	5.00	1	1	t
5	6	ผัดไทยสูตรต้นตำรับ เส้นหมี่เหลืองผัดกับกุ้งสด ไข่ ถั่วงอก และเต้าหู้	แช่เส้น > ผัดกุ้ง > ใส่เส้นและไข่ > ปรุงรส > เสิร์ฟ	20	15	2.0	\N	https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800	2026-03-22 16:38:48.368138	\N	ผัดไทยกุ้งสด	อาหารไทย	ไทย	Medium	5.00	1	1	t
10	35	ปลากะพงนึ่งเต็มตัว ราดด้วยน้ำปรุงรสเปรี้ยวเผ็ดหอมมะนาว	เตรียมปลา > ทำน้ำปรุง > นึ่งปลา > ราดน้ำปรุง > เสิร์ฟ	15	20	2.0	\N	https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800	2026-03-22 16:38:48.368138	\N	ปลากะพงนึ่งมะนาว	อาหารไทย	ไทย	Easy	5.00	1	1	t
\.


--
-- TOC entry 5409 (class 0 OID 20656)
-- Dependencies: 221
-- Data for Name: roles; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.roles (role_id, role_name) FROM stdin;
1	admin
2	user
\.


--
-- TOC entry 5426 (class 0 OID 20814)
-- Dependencies: 238
-- Data for Name: snacks; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.snacks (snack_id, food_id, is_sweet, packaging_type, trans_fat) FROM stdin;
\.


--
-- TOC entry 5416 (class 0 OID 20725)
-- Dependencies: 228
-- Data for Name: units; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.units (unit_id, name, conversion_factor) FROM stdin;
\.


--
-- TOC entry 5438 (class 0 OID 20944)
-- Dependencies: 250
-- Data for Name: user_activities; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_activities (activity_id, user_id, activity_level, is_current, date_record, created_at) FROM stdin;
\.


--
-- TOC entry 5414 (class 0 OID 20704)
-- Dependencies: 226
-- Data for Name: user_allergy_preferences; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_allergy_preferences (user_id, flag_id, preference_type, created_at) FROM stdin;
\.


--
-- TOC entry 5440 (class 0 OID 20962)
-- Dependencies: 252
-- Data for Name: user_goals; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_goals (goal_id, user_id, goal_name, goal_type, target_weight_kg, is_current, goal_start_at, goal_target_date, goal_end_at, created_at) FROM stdin;
\.


--
-- TOC entry 5432 (class 0 OID 20870)
-- Dependencies: 244
-- Data for Name: user_meal_plans; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.user_meal_plans (plan_id, user_id, item_id, name, description, source_type, is_premium, created_at) FROM stdin;
\.


--
-- TOC entry 5411 (class 0 OID 20669)
-- Dependencies: 223
-- Data for Name: users; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.users (user_id, username, email, password_hash, gender, birth_date, height_cm, current_weight_kg, goal_type, target_weight_kg, target_calories, activity_level, goal_start_date, goal_target_date, last_kpi_check_date, current_streak, last_login_date, total_login_days, avatar_url, role_id, created_at, updated_at, deleted_at, target_protein, target_carbs, target_fat, is_email_verified) FROM stdin;
34	tt tt	tt@gmail.com	$2b$12$YRqh5mD2Uxdv7d77m.UutO9XMP5AqL1QeapPSUhwKCIyt05kU7daS	male	2000-01-01	180.00	80.00	lose_weight	72.00	1903	sedentary	2026-03-19	2026-11-14	2026-03-19	1	2026-03-19 00:00:00	1	\N	2	2026-03-19 21:22:39.672879	\N	\N	143	190	63	f
36	test 01	nemozanarak123@gmail.com	$2b$12$kxsMziH.zEaUsTQq7EE3xeBwVj.g0JErtL/YDdTjKyIz4qGI2KiqO	male	2000-01-01	1.00	1.00	lose_weight	0.00	-130	sedentary	2026-03-20	2026-04-19	2026-03-20	1	2026-03-20 00:00:00	1	\N	2	2026-03-20 20:17:56.363682	\N	\N	-5	-21	-3	t
33	ts 01	ts01@gmail.com	$2b$12$nmE.Aru6s7Hd/iuW5K2CLuE1kECQT5biU5RzXnE8MVoKRCemW8vQS	male	\N	\N	\N	\N	\N	2000	\N	2026-03-19	\N	2026-03-19	0	\N	0	\N	2	2026-03-19 21:07:59.358752	\N	\N	150	200	67	f
35	nemo eiei	leonielmygoat10@gmail.com	$2b$12$7xH9eF0aghmY5jLKssg1X.udWDXtQcWQ7zQiJLAb7FEmY4C3mxK9i	male	2000-01-01	180.00	80.00	lose_weight	\N	2160	sedentary	2026-03-20	\N	2026-03-20	0	\N	0	\N	2	2026-03-20 20:01:49.661691	\N	\N	162	216	72	t
37	test nemo	l3ackbolt@gmail.com	$2b$12$4cmjKahvE/r8ZF4Ty7KF3O3xe9/hSbVpjHRqO7QY6pO61l0ydsmwm	male	2000-01-01	180.00	75.00	lose_weight	71.94	2003	sedentary	2026-03-20	2026-11-17	2026-03-20	1	2026-03-26 00:00:00	8	\N	2	2026-03-20 22:05:13.353336	\N	\N	75	325	45	t
31	test 01	test01@gmail.com	$2b$12$0hkKDSOeWgF2SjdFphevt.8dxh3glmRBViEb7kND8Rltxozkasd4G	male	2000-01-01	180.00	80.00	lose_weight	72.00	1903	sedentary	2026-03-19	2026-11-14	2026-03-19	0	\N	0	\N	2	2026-03-19 20:59:55.492792	\N	\N	143	190	63	f
5	admin 01	admin@gmail.com	$2b$12$90ARneLODLqolWadO3Jc6eB/ENSltqVV2KklQep6hY4i17wjNe232	male	2000-01-20	170.00	80.00	lose_weight	72.00	\N	sedentary	2026-02-19	2026-10-17	2026-02-19	1	2026-03-26 00:00:00	10	\N	1	2026-02-19 00:00:38.217958	\N	\N	\N	\N	\N	f
32	test 02	test02@gmail.com	$2b$12$xHwq32EMoHTFRbqt3JQPJ.k6jXaIUR8dF8pVbqkg39nOGLnmrXiZi	male	2000-01-01	1.00	1.00	\N	\N	-130	\N	2026-03-19	\N	2026-03-19	0	\N	0	\N	2	2026-03-19 21:02:17.215407	\N	\N	-10	-13	-4	f
\.


--
-- TOC entry 5448 (class 0 OID 21053)
-- Dependencies: 260
-- Data for Name: weekly_summaries; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.weekly_summaries (weekly_id, user_id, start_date, avg_daily_calories, days_logged_count) FROM stdin;
\.


--
-- TOC entry 5442 (class 0 OID 20982)
-- Dependencies: 254
-- Data for Name: weight_logs; Type: TABLE DATA; Schema: cleangoal; Owner: postgres
--

COPY cleangoal.weight_logs (log_id, user_id, weight_kg, recorded_date, created_at) FROM stdin;
5	5	80.00	2026-02-19	2026-02-19 00:00:50.422463
31	31	80.00	2026-03-19	2026-03-19 21:01:06.162691
32	32	1.00	2026-03-19	2026-03-19 21:03:44.600804
33	34	80.00	2026-03-19	2026-03-19 21:22:51.51233
34	35	80.00	2026-03-20	2026-03-20 20:05:10.490821
35	36	1.00	2026-03-20	2026-03-20 20:18:28.280617
36	37	75.00	2026-03-20	2026-03-20 22:06:46.460966
\.


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 224
-- Name: allergy_flags_flag_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.allergy_flags_flag_id_seq', 1, false);


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 235
-- Name: beverages_beverage_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.beverages_beverage_id_seq', 1, false);


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 245
-- Name: daily_summaries_summary_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.daily_summaries_summary_id_seq', 187, true);


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 247
-- Name: detail_items_item_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.detail_items_item_id_seq', 195, true);


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 267
-- Name: email_verification_codes_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.email_verification_codes_id_seq', 4, true);


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 233
-- Name: food_ingredients_food_ing_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.food_ingredients_food_ing_id_seq', 1, false);


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 257
-- Name: food_requests_request_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.food_requests_request_id_seq', 2, true);


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 229
-- Name: foods_food_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.foods_food_id_seq', 102, true);


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 263
-- Name: health_contents_content_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.health_contents_content_id_seq', 1, false);


--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 231
-- Name: ingredients_ingredient_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.ingredients_ingredient_id_seq', 1, false);


--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 241
-- Name: meals_meal_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.meals_meal_id_seq', 172, true);


--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 261
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.notifications_notification_id_seq', 1, false);


--
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 265
-- Name: password_reset_codes_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.password_reset_codes_id_seq', 1, false);


--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 255
-- Name: progress_progress_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.progress_progress_id_seq', 1, false);


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 279
-- Name: recipe_favorites_fav_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_favorites_fav_id_seq', 3, true);


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 269
-- Name: recipe_ingredients_ing_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_ingredients_ing_id_seq', 90, true);


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 277
-- Name: recipe_reviews_review_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_reviews_review_id_seq', 6, true);


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 271
-- Name: recipe_steps_step_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_steps_step_id_seq', 28, true);


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 275
-- Name: recipe_tips_tip_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_tips_tip_id_seq', 21, true);


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 273
-- Name: recipe_tools_tool_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipe_tools_tool_id_seq', 31, true);


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 239
-- Name: recipes_recipe_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.recipes_recipe_id_seq', 11, true);


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 220
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.roles_role_id_seq', 2, true);


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 237
-- Name: snacks_snack_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.snacks_snack_id_seq', 1, false);


--
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 227
-- Name: units_unit_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.units_unit_id_seq', 1, false);


--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_activities_activity_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_activities_activity_id_seq', 1, false);


--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 251
-- Name: user_goals_goal_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_goals_goal_id_seq', 1, false);


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 243
-- Name: user_meal_plans_plan_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.user_meal_plans_plan_id_seq', 1, false);


--
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 222
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.users_user_id_seq', 37, true);


--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 259
-- Name: weekly_summaries_weekly_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.weekly_summaries_weekly_id_seq', 1, false);


--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 253
-- Name: weight_logs_log_id_seq; Type: SEQUENCE SET; Schema: cleangoal; Owner: postgres
--

SELECT pg_catalog.setval('cleangoal.weight_logs_log_id_seq', 39, true);


--
-- TOC entry 5140 (class 2606 OID 20703)
-- Name: allergy_flags allergy_flags_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.allergy_flags
    ADD CONSTRAINT allergy_flags_pkey PRIMARY KEY (flag_id);


--
-- TOC entry 5154 (class 2606 OID 20807)
-- Name: beverages beverages_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_food_id_key UNIQUE (food_id);


--
-- TOC entry 5156 (class 2606 OID 20805)
-- Name: beverages beverages_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_pkey PRIMARY KEY (beverage_id);


--
-- TOC entry 5170 (class 2606 OID 20898)
-- Name: daily_summaries daily_summaries_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_pkey PRIMARY KEY (summary_id);


--
-- TOC entry 5172 (class 2606 OID 20900)
-- Name: daily_summaries daily_summaries_user_id_date_record_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_user_id_date_record_key UNIQUE (user_id, date_record);


--
-- TOC entry 5174 (class 2606 OID 20917)
-- Name: detail_items detail_items_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5198 (class 2606 OID 21145)
-- Name: email_verification_codes email_verification_codes_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.email_verification_codes
    ADD CONSTRAINT email_verification_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 5152 (class 2606 OID 20778)
-- Name: food_ingredients food_ingredients_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_pkey PRIMARY KEY (food_ing_id);


--
-- TOC entry 5186 (class 2606 OID 21041)
-- Name: food_requests food_requests_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 5146 (class 2606 OID 20749)
-- Name: foods foods_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.foods
    ADD CONSTRAINT foods_pkey PRIMARY KEY (food_id);


--
-- TOC entry 5194 (class 2606 OID 21099)
-- Name: health_contents health_contents_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.health_contents
    ADD CONSTRAINT health_contents_pkey PRIMARY KEY (content_id);


--
-- TOC entry 5148 (class 2606 OID 20763)
-- Name: ingredients ingredients_name_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_name_key UNIQUE (name);


--
-- TOC entry 5150 (class 2606 OID 20761)
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (ingredient_id);


--
-- TOC entry 5166 (class 2606 OID 20863)
-- Name: meals meals_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals
    ADD CONSTRAINT meals_pkey PRIMARY KEY (meal_id);


--
-- TOC entry 5192 (class 2606 OID 21081)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- TOC entry 5196 (class 2606 OID 21126)
-- Name: password_reset_codes password_reset_codes_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.password_reset_codes
    ADD CONSTRAINT password_reset_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 5184 (class 2606 OID 21012)
-- Name: progress progress_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_pkey PRIMARY KEY (progress_id);


--
-- TOC entry 5218 (class 2606 OID 21278)
-- Name: recipe_favorites recipe_favorites_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_favorites
    ADD CONSTRAINT recipe_favorites_pkey PRIMARY KEY (fav_id);


--
-- TOC entry 5220 (class 2606 OID 21280)
-- Name: recipe_favorites recipe_favorites_recipe_id_user_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_favorites
    ADD CONSTRAINT recipe_favorites_recipe_id_user_id_key UNIQUE (recipe_id, user_id);


--
-- TOC entry 5201 (class 2606 OID 21178)
-- Name: recipe_ingredients recipe_ingredients_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (ing_id);


--
-- TOC entry 5213 (class 2606 OID 21255)
-- Name: recipe_reviews recipe_reviews_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_reviews
    ADD CONSTRAINT recipe_reviews_pkey PRIMARY KEY (review_id);


--
-- TOC entry 5215 (class 2606 OID 21257)
-- Name: recipe_reviews recipe_reviews_recipe_id_user_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_reviews
    ADD CONSTRAINT recipe_reviews_recipe_id_user_id_key UNIQUE (recipe_id, user_id);


--
-- TOC entry 5204 (class 2606 OID 21198)
-- Name: recipe_steps recipe_steps_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_steps
    ADD CONSTRAINT recipe_steps_pkey PRIMARY KEY (step_id);


--
-- TOC entry 5210 (class 2606 OID 21236)
-- Name: recipe_tips recipe_tips_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tips
    ADD CONSTRAINT recipe_tips_pkey PRIMARY KEY (tip_id);


--
-- TOC entry 5207 (class 2606 OID 21217)
-- Name: recipe_tools recipe_tools_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tools
    ADD CONSTRAINT recipe_tools_pkey PRIMARY KEY (tool_id);


--
-- TOC entry 5162 (class 2606 OID 20846)
-- Name: recipes recipes_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_food_id_key UNIQUE (food_id);


--
-- TOC entry 5164 (class 2606 OID 20844)
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (recipe_id);


--
-- TOC entry 5132 (class 2606 OID 20665)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 5134 (class 2606 OID 20667)
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- TOC entry 5158 (class 2606 OID 20825)
-- Name: snacks snacks_food_id_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_food_id_key UNIQUE (food_id);


--
-- TOC entry 5160 (class 2606 OID 20823)
-- Name: snacks snacks_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_pkey PRIMARY KEY (snack_id);


--
-- TOC entry 5144 (class 2606 OID 20734)
-- Name: units units_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (unit_id);


--
-- TOC entry 5176 (class 2606 OID 20955)
-- Name: user_activities user_activities_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities
    ADD CONSTRAINT user_activities_pkey PRIMARY KEY (activity_id);


--
-- TOC entry 5142 (class 2606 OID 20713)
-- Name: user_allergy_preferences user_allergy_preferences_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_pkey PRIMARY KEY (user_id, flag_id);


--
-- TOC entry 5178 (class 2606 OID 20975)
-- Name: user_goals user_goals_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals
    ADD CONSTRAINT user_goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 5168 (class 2606 OID 20882)
-- Name: user_meal_plans user_meal_plans_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans
    ADD CONSTRAINT user_meal_plans_pkey PRIMARY KEY (plan_id);


--
-- TOC entry 5136 (class 2606 OID 20687)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5138 (class 2606 OID 20685)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5188 (class 2606 OID 21061)
-- Name: weekly_summaries weekly_summaries_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_pkey PRIMARY KEY (weekly_id);


--
-- TOC entry 5190 (class 2606 OID 21063)
-- Name: weekly_summaries weekly_summaries_user_id_start_date_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_user_id_start_date_key UNIQUE (user_id, start_date);


--
-- TOC entry 5180 (class 2606 OID 20992)
-- Name: weight_logs weight_logs_pkey; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 5182 (class 2606 OID 20994)
-- Name: weight_logs weight_logs_user_id_recorded_date_key; Type: CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_user_id_recorded_date_key UNIQUE (user_id, recorded_date);


--
-- TOC entry 5216 (class 1259 OID 21296)
-- Name: idx_recipe_favs_user; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_favs_user ON cleangoal.recipe_favorites USING btree (user_id);


--
-- TOC entry 5199 (class 1259 OID 21291)
-- Name: idx_recipe_ing_recipe; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_ing_recipe ON cleangoal.recipe_ingredients USING btree (recipe_id);


--
-- TOC entry 5211 (class 1259 OID 21295)
-- Name: idx_recipe_reviews_recipe; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_reviews_recipe ON cleangoal.recipe_reviews USING btree (recipe_id);


--
-- TOC entry 5202 (class 1259 OID 21292)
-- Name: idx_recipe_steps_recipe; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_steps_recipe ON cleangoal.recipe_steps USING btree (recipe_id, step_number);


--
-- TOC entry 5208 (class 1259 OID 21294)
-- Name: idx_recipe_tips_recipe; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_tips_recipe ON cleangoal.recipe_tips USING btree (recipe_id);


--
-- TOC entry 5205 (class 1259 OID 21293)
-- Name: idx_recipe_tools_recipe; Type: INDEX; Schema: cleangoal; Owner: postgres
--

CREATE INDEX idx_recipe_tools_recipe ON cleangoal.recipe_tools USING btree (recipe_id);


--
-- TOC entry 5260 (class 2620 OID 21300)
-- Name: recipe_favorites trg_update_recipe_fav_count; Type: TRIGGER; Schema: cleangoal; Owner: postgres
--

CREATE TRIGGER trg_update_recipe_fav_count AFTER INSERT OR DELETE ON cleangoal.recipe_favorites FOR EACH ROW EXECUTE FUNCTION cleangoal.update_recipe_favorite_count();


--
-- TOC entry 5259 (class 2620 OID 21298)
-- Name: recipe_reviews trg_update_recipe_rating; Type: TRIGGER; Schema: cleangoal; Owner: postgres
--

CREATE TRIGGER trg_update_recipe_rating AFTER INSERT OR DELETE OR UPDATE ON cleangoal.recipe_reviews FOR EACH ROW EXECUTE FUNCTION cleangoal.update_recipe_rating();


--
-- TOC entry 5228 (class 2606 OID 20808)
-- Name: beverages beverages_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.beverages
    ADD CONSTRAINT beverages_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5233 (class 2606 OID 20901)
-- Name: daily_summaries daily_summaries_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.daily_summaries
    ADD CONSTRAINT daily_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5234 (class 2606 OID 20933)
-- Name: detail_items detail_items_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5235 (class 2606 OID 20918)
-- Name: detail_items detail_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES cleangoal.meals(meal_id) ON DELETE CASCADE;


--
-- TOC entry 5236 (class 2606 OID 20923)
-- Name: detail_items detail_items_plan_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES cleangoal.user_meal_plans(plan_id) ON DELETE CASCADE;


--
-- TOC entry 5237 (class 2606 OID 20928)
-- Name: detail_items detail_items_summary_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_summary_id_fkey FOREIGN KEY (summary_id) REFERENCES cleangoal.daily_summaries(summary_id) ON DELETE CASCADE;


--
-- TOC entry 5238 (class 2606 OID 20938)
-- Name: detail_items detail_items_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.detail_items
    ADD CONSTRAINT detail_items_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5250 (class 2606 OID 21146)
-- Name: email_verification_codes email_verification_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.email_verification_codes
    ADD CONSTRAINT email_verification_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5225 (class 2606 OID 20779)
-- Name: food_ingredients food_ingredients_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id) ON DELETE CASCADE;


--
-- TOC entry 5226 (class 2606 OID 20784)
-- Name: food_ingredients food_ingredients_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES cleangoal.ingredients(ingredient_id);


--
-- TOC entry 5227 (class 2606 OID 20789)
-- Name: food_ingredients food_ingredients_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_ingredients
    ADD CONSTRAINT food_ingredients_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5245 (class 2606 OID 21047)
-- Name: food_requests food_requests_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES cleangoal.users(user_id);


--
-- TOC entry 5246 (class 2606 OID 21042)
-- Name: food_requests food_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.food_requests
    ADD CONSTRAINT food_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id);


--
-- TOC entry 5224 (class 2606 OID 20764)
-- Name: ingredients ingredients_default_unit_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.ingredients
    ADD CONSTRAINT ingredients_default_unit_id_fkey FOREIGN KEY (default_unit_id) REFERENCES cleangoal.units(unit_id);


--
-- TOC entry 5231 (class 2606 OID 20864)
-- Name: meals meals_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.meals
    ADD CONSTRAINT meals_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5248 (class 2606 OID 21082)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5249 (class 2606 OID 21127)
-- Name: password_reset_codes password_reset_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.password_reset_codes
    ADD CONSTRAINT password_reset_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5242 (class 2606 OID 21023)
-- Name: progress progress_daily_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_daily_id_fkey FOREIGN KEY (daily_id) REFERENCES cleangoal.daily_summaries(summary_id);


--
-- TOC entry 5243 (class 2606 OID 21013)
-- Name: progress progress_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5244 (class 2606 OID 21018)
-- Name: progress progress_weight_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.progress
    ADD CONSTRAINT progress_weight_id_fkey FOREIGN KEY (weight_id) REFERENCES cleangoal.weight_logs(log_id);


--
-- TOC entry 5257 (class 2606 OID 21281)
-- Name: recipe_favorites recipe_favorites_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_favorites
    ADD CONSTRAINT recipe_favorites_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5258 (class 2606 OID 21286)
-- Name: recipe_favorites recipe_favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_favorites
    ADD CONSTRAINT recipe_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5251 (class 2606 OID 21179)
-- Name: recipe_ingredients recipe_ingredients_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5255 (class 2606 OID 21258)
-- Name: recipe_reviews recipe_reviews_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_reviews
    ADD CONSTRAINT recipe_reviews_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5256 (class 2606 OID 21263)
-- Name: recipe_reviews recipe_reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_reviews
    ADD CONSTRAINT recipe_reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5252 (class 2606 OID 21199)
-- Name: recipe_steps recipe_steps_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_steps
    ADD CONSTRAINT recipe_steps_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5254 (class 2606 OID 21237)
-- Name: recipe_tips recipe_tips_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tips
    ADD CONSTRAINT recipe_tips_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5253 (class 2606 OID 21218)
-- Name: recipe_tools recipe_tools_recipe_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipe_tools
    ADD CONSTRAINT recipe_tools_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES cleangoal.recipes(recipe_id) ON DELETE CASCADE;


--
-- TOC entry 5230 (class 2606 OID 20847)
-- Name: recipes recipes_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.recipes
    ADD CONSTRAINT recipes_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5229 (class 2606 OID 20826)
-- Name: snacks snacks_food_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.snacks
    ADD CONSTRAINT snacks_food_id_fkey FOREIGN KEY (food_id) REFERENCES cleangoal.foods(food_id);


--
-- TOC entry 5239 (class 2606 OID 20956)
-- Name: user_activities user_activities_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_activities
    ADD CONSTRAINT user_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5222 (class 2606 OID 20719)
-- Name: user_allergy_preferences user_allergy_preferences_flag_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_flag_id_fkey FOREIGN KEY (flag_id) REFERENCES cleangoal.allergy_flags(flag_id) ON DELETE CASCADE;


--
-- TOC entry 5223 (class 2606 OID 20714)
-- Name: user_allergy_preferences user_allergy_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_allergy_preferences
    ADD CONSTRAINT user_allergy_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5240 (class 2606 OID 20976)
-- Name: user_goals user_goals_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_goals
    ADD CONSTRAINT user_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5232 (class 2606 OID 20883)
-- Name: user_meal_plans user_meal_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.user_meal_plans
    ADD CONSTRAINT user_meal_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 5221 (class 2606 OID 20688)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES cleangoal.roles(role_id);


--
-- TOC entry 5247 (class 2606 OID 21064)
-- Name: weekly_summaries weekly_summaries_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weekly_summaries
    ADD CONSTRAINT weekly_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 5241 (class 2606 OID 20995)
-- Name: weight_logs weight_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: cleangoal; Owner: postgres
--

ALTER TABLE ONLY cleangoal.weight_logs
    ADD CONSTRAINT weight_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES cleangoal.users(user_id) ON DELETE CASCADE;


-- Completed on 2026-03-26 20:51:01

--
-- PostgreSQL database dump complete
--

\unrestrict JZGjW12U9yIRBfMzyLoAC32F7rWMC82dUEf7N3flP1kO0R0Yns7sywc1weZOHgF


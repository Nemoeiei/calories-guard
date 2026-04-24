"""
Multi-Agent AI Nutrition System — Calories Guard
=================================================
3-Agent proof-of-concept (no deep learning yet — requires training data):

  Agent 1 │ DataOrchestratorAgent   — ดึง user profile, logs, goals จาก DB
  Agent 2 │ NutritionAnalysisAgent  — วิเคราะห์อาหาร + กิจกรรม (DB lookup + MET table)
  Agent 3 │ ResponseComposerAgent   — ประมวลผลเป็นภาษาไทยที่อ่านง่ายผ่าน Gemini

Future (PoC planned):
  - TFT (Temporal Fusion Transformer) for macro time-series prediction
  - GNN + vector DB for semantic activity matching
  - Local LLM (Ollama) as fallback composer
"""

import os
import json
import re
from typing import TypedDict, Optional
from datetime import date

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from psycopg2.extras import RealDictCursor
from database import get_db_connection
from dotenv import load_dotenv

from ai_models.food_extraction import extract_foods as _tok_extract_foods
from ai_models.llm_provider import generate as llm_generate, is_configured as llm_is_configured

# Backend is selected by LLM_PROVIDER. We keep a couple of legacy constants
# exported for any call-site still probing them, but all generation now goes
# through ai_models.llm_provider.
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")  # kept for back-compat probes


# ─── Scope Guard ─────────────────────────────────────────────────────────────

_SCOPE_KEYWORDS = [
    "กิน", "ทาน", "อาหาร", "เมนู", "แคลอรี", "โภชนาการ", "สารอาหาร",
    "โปรตีน", "คาร์บ", "ไขมัน", "วิตามิน", "น้ำตาล", "ใยอาหาร",
    "น้ำหนัก", "ลดน้ำหนัก", "เพิ่มน้ำหนัก", "อ้วน", "ผอม", "BMI", "BMR", "TDEE",
    "ออกกำลัง", "วิ่ง", "เดิน", "ว่ายน้ำ", "โยคะ", "กีฬา", "เผาผลาญ",
    "สุขภาพ", "โรค", "เบาหวาน", "ความดัน", "คอเลสเตอรอล",
    "น้ำ", "ดื่ม", "นอน", "พัก", "เป้าหมาย", "แพ้", "แนะนำ", "ควร",
    "เท่าไหร่", "กี่แคล", "calories", "protein", "carbs", "fat",
    "diet", "nutrition", "exercise", "health", "weight", "food",
    "สูตร", "วิธีทำ", "ส่วนผสม", "recipe", "ร้าน", "restaurant",
]

_REJECT_MSG = (
    "ขออภัยครับ ผมเป็นโค้ชด้านโภชนาการและสุขภาพของ Calories Guard เท่านั้น "
    "ไม่สามารถตอบคำถามที่ไม่เกี่ยวข้องกับอาหาร โภชนาการ สุขภาพ หรือการออกกำลังกายได้ครับ\n\n"
    "ลองถามเรื่องเหล่านี้ได้นะครับ:\n"
    "- วันนี้กินอะไรดี?\n"
    "- ข้าวผัดกะเพรากี่แคล?\n"
    "- แนะนำเมนูลดน้ำหนักหน่อย\n"
    "- ออกกำลังกายอะไรเผาผลาญเยอะ?"
)


def _is_in_scope(text: str) -> bool:
    t = text.lower()
    return any(kw.lower() in t for kw in _SCOPE_KEYWORDS)


# ─── Shared State ─────────────────────────────────────────────────────────────

class AgentState(TypedDict):
    user_id: int
    user_message: str
    lat: Optional[float]
    lng: Optional[float]
    # outputs from each agent
    user_context: Optional[dict]
    nearby_restaurants: Optional[list]
    analysis: Optional[dict]
    final_response: Optional[str]


# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 1 │ DataOrchestratorAgent
# Responsibility: ETL — ดึงข้อมูลทั้งหมดที่ agents ลำดับถัดไปต้องการ
# ═══════════════════════════════════════════════════════════════════════════════

class DataOrchestratorAgent:
    """
    ดึงและรวบรวมข้อมูล user จากหลาย tables:
      - users (profile, targets, streak)
      - user_allergy_preferences + allergy_flags
      - daily_summaries (วันนี้)
      - weight_logs (30 วันล่าสุด)
      - detail_items + meals (3 วันล่าสุด — อาหารที่กินบ่อย)

    คืน dict ที่ agents ถัดไปใช้เป็น context ได้เลย
    """

    def fetch(self, user_id: int) -> Optional[dict]:
        print(f"[Agent1] Fetching data for user_id={user_id}")
        conn = get_db_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # ── Profile ───────────────────────────────────────────────────────
            cur.execute("""
                SELECT username, gender, birth_date, height_cm, current_weight_kg,
                       goal_type, target_weight_kg, target_calories,
                       COALESCE(target_protein, 0) AS target_protein,
                       COALESCE(target_carbs, 0) AS target_carbs,
                       COALESCE(target_fat, 0) AS target_fat,
                       activity_level,
                       COALESCE(current_streak, 0) AS current_streak,
                       COALESCE(total_login_days, 0) AS total_login_days
                FROM users WHERE user_id = %s
            """, (user_id,))
            profile = cur.fetchone()
            if not profile:
                print(f"[Agent1] No user found for user_id={user_id}")
                return None
            profile = dict(profile)

            # ── Allergies ─────────────────────────────────────────────────────
            cur.execute("""
                SELECT f.name FROM user_allergy_preferences uap
                JOIN allergy_flags f ON uap.flag_id = f.flag_id
                WHERE uap.user_id = %s
            """, (user_id,))
            allergies = [r['name'] for r in cur.fetchall()]

            # ── Today's intake ────────────────────────────────────────────────
            today_str = date.today().isoformat()
            cur.execute("""
                SELECT COALESCE(ds.total_calories_intake, 0) AS total_calories_intake,
                       COALESCE(SUM(di.amount * di.protein_per_unit), 0) AS total_protein,
                       COALESCE(SUM(di.amount * di.carbs_per_unit), 0) AS total_carbs,
                       COALESCE(SUM(di.amount * di.fat_per_unit), 0) AS total_fat
                FROM daily_summaries ds
                LEFT JOIN meals m ON m.user_id = ds.user_id AND m.created_at::date = ds.date_record
                LEFT JOIN detail_items di ON di.meal_id = m.meal_id
                WHERE ds.user_id = %s AND ds.date_record = %s
                GROUP BY ds.total_calories_intake
            """, (user_id, today_str))
            today_row = cur.fetchone()
            today_intake = dict(today_row) if today_row else {
                "total_calories_intake": 0,
                "total_protein": 0,
                "total_carbs": 0,
                "total_fat": 0,
            }

            # ── Weight logs (30 days) ─────────────────────────────────────────
            cur.execute("""
                SELECT recorded_date::text AS date, weight_kg AS weight
                FROM weight_logs
                WHERE user_id = %s
                ORDER BY recorded_date DESC LIMIT 30
            """, (user_id,))
            weight_logs = [dict(r) for r in cur.fetchall()]

            # ── Recent foods (3 days) ─────────────────────────────────────────
            cur.execute("""
                SELECT DISTINCT d.food_name, d.cal_per_unit, d.protein_per_unit,
                                d.carbs_per_unit, d.fat_per_unit
                FROM detail_items d
                JOIN meals m ON d.meal_id = m.meal_id
                WHERE m.user_id = %s AND m.created_at >= NOW() - INTERVAL '3 days'
                LIMIT 20
            """, (user_id,))
            recent_foods = [dict(r) for r in cur.fetchall()]

            return {
                "profile": profile,
                "allergies": allergies,
                "today_intake": today_intake,
                "weight_logs": weight_logs,
                "recent_foods": recent_foods,
            }

        except Exception as e:
            print(f"[Agent1] Exception for user_id={user_id}: {e}")
            return {"error": str(e), "profile": {}, "allergies": [],
                    "today_intake": {}, "weight_logs": [], "recent_foods": []}
        finally:
            if conn:
                conn.close()

    def fetch_nearby_restaurants(self, lat: float, lng: float) -> list:
        """เรียก Google Places API เพื่อดึงร้านอาหารใกล้เคียง (radius 1 km)"""
        import urllib.request as _req
        _PLACES_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
        url = (
            f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            f"?location={lat},{lng}&radius=1000&type=restaurant"
            f"&language=th&key={_PLACES_KEY}"
        )
        try:
            with _req.urlopen(url, timeout=6) as resp:
                data = json.loads(resp.read())
            results = data.get("results", [])[:5]
            return [
                {
                    "name": r.get("name", ""),
                    "vicinity": r.get("vicinity", ""),
                    "rating": r.get("rating"),
                    "open_now": r.get("opening_hours", {}).get("open_now"),
                    "price_level": r.get("price_level"),
                }
                for r in results
            ]
        except Exception as e:
            print(f"[Agent1] Places API error: {e}")
            return []


# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 2 │ NutritionAnalysisAgent
# Responsibility: วิเคราะห์คำถามเกี่ยวกับอาหารและกิจกรรม
#   - DB lookup สำหรับอาหารที่มีในระบบ
#   - TF-IDF cosine similarity สำหรับจับคู่กิจกรรม (PoC ของ vector search)
#   - MET-based calorie calculation
#   - Gemini fallback สำหรับประมาณโภชนาการที่ไม่มีใน DB
#
# [PoC Note] Future: replace TF-IDF with sentence-transformers embedding
#            + FAISS vector store for semantic activity matching (GNN-style)
# ═══════════════════════════════════════════════════════════════════════════════

# MET lookup table (กิจกรรม → ค่า MET มาตรฐาน)
_MET_TABLE = [
    {"name": "เดิน",           "met": 3.5,  "keywords": "เดิน walk เดินเร็ว เดินช้า เดินออกกำลัง"},
    {"name": "วิ่ง",           "met": 8.0,  "keywords": "วิ่ง run jogging จ็อกกิ้ง running sprint"},
    {"name": "ปั่นจักรยาน",   "met": 6.0,  "keywords": "จักรยาน cycling ปั่น bike bicycle"},
    {"name": "ว่ายน้ำ",       "met": 7.0,  "keywords": "ว่ายน้ำ swimming swim pool"},
    {"name": "โยคะ",          "met": 2.5,  "keywords": "โยคะ yoga ยืดเหยียด stretch"},
    {"name": "ยกน้ำหนัก",    "met": 5.0,  "keywords": "ยกน้ำหนัก weight dumbbell barbell gym เวท"},
    {"name": "เต้น/แอโรบิค", "met": 5.5,  "keywords": "เต้น dance zumba แอโรบิค aerobic"},
    {"name": "ฟุตบอล",        "met": 8.0,  "keywords": "ฟุตบอล football soccer"},
    {"name": "บาสเกตบอล",    "met": 6.5,  "keywords": "บาสเกตบอล basketball"},
    {"name": "แบดมินตัน",    "met": 5.5,  "keywords": "แบดมินตัน badminton"},
    {"name": "HIIT",           "met": 10.0, "keywords": "HIIT hiit เข้มข้น intense"},
    {"name": "วิดพื้น/ซิทอัพ","met": 4.5, "keywords": "วิดพื้น ซิทอัพ push-up sit-up plank burpee"},
    {"name": "เดินขึ้นบันได","met": 4.0,  "keywords": "บันได stairs ขึ้นบันได"},
    {"name": "พักผ่อน",       "met": 1.0,  "keywords": "นั่ง นอน พัก rest"},
]


class NutritionAnalysisAgent:

    def __init__(self):
        # TF-IDF vector index สำหรับ activity matching (PoC ของ vector search)
        corpus = [item["keywords"] for item in _MET_TABLE]
        self._vec = TfidfVectorizer()
        self._matrix = self._vec.fit_transform(corpus)

    # ── Entry point ───────────────────────────────────────────────────────────

    def analyze(self, user_message: str, context: dict, user_id: int = None) -> dict:
        result = {
            "intent": self._detect_intent(user_message),
            "food_info": None,
            "activity_info": None,
            "calorie_balance": None,
        }

        profile = context.get("profile", {})
        today = context.get("today_intake", {})
        weight = float(profile.get("current_weight_kg") or 70)
        target_cal = float(profile.get("target_calories") or 2000)
        consumed = float(today.get("total_calories_intake") or 0)

        # Calorie balance summary
        result["calorie_balance"] = {
            "target": int(target_cal),
            "consumed": int(consumed),
            "remaining": int(max(0, target_cal - consumed)),
            "over": consumed > target_cal,
        }

        # Food analysis
        food_mentions = self._extract_foods(user_message)
        if food_mentions:
            result["food_info"] = self._analyze_foods(
                food_mentions, context.get("allergies", []), user_id
            )

        # Activity analysis
        activities = self._extract_activities(user_message)
        if activities:
            activity, duration = activities[0]
            matched, met = self._match_activity(activity)
            calories_burned = round(met * weight * (duration / 60), 1)
            result["activity_info"] = {
                "activity": matched,
                "duration_min": duration,
                "met": met,
                "calories_burned": calories_burned,
            }

        return result

    # ── Intent detection ──────────────────────────────────────────────────────

    def _detect_intent(self, text: str) -> str:
        keywords = {
            "food_query":    ["กิน", "ทาน", "อาหาร", "เมนู", "แคลอรี่", "โภชนาการ", "แนะนำอาหาร"],
            "activity_query":["ออกกำลัง", "วิ่ง", "เดิน", "เผาผลาญ", "กีฬา", "กิจกรรม"],
            "progress_query":["ความคืบหน้า", "น้ำหนัก", "เป้าหมาย", "BMI", "ผล"],
            "general":       [],
        }
        for intent, kws in keywords.items():
            if any(k in text for k in kws):
                return intent
        return "general"

    # ── Food extraction ───────────────────────────────────────────────────────

    def _extract_foods(self, text: str) -> list:
        """
        Pull food mentions out of free Thai text.

        Uses pythainlp word segmentation + DB-backed dictionary of known food
        names (see ai_models/food_extraction.py). Returns a list of dicts:
            [{"name": ..., "quantity": float|None, "source": "dict|regex"}]
        """
        db_names = self._load_food_dictionary()
        mentions = _tok_extract_foods(text, db_food_names=db_names, limit=5)
        return mentions

    def _load_food_dictionary(self) -> list:
        """Pull all non-deleted food names from DB to power the tokenizer match."""
        conn = get_db_connection()
        if not conn:
            return []
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT food_name FROM foods WHERE deleted_at IS NULL LIMIT 5000"
            )
            return [r[0] for r in cur.fetchall() if r[0]]
        except Exception:
            return []
        finally:
            conn.close()

    def _analyze_foods(self, food_mentions: list, allergies: list, user_id: int = None) -> dict:
        """
        food_mentions may be either a list of str (legacy) or a list of dicts
        {"name", "quantity", "source"} from _extract_foods.
        Multiplies the per-serving nutrition by `quantity` when provided so
        "ข้าวผัด 2 จาน" counts as 2x.
        """
        foods = []
        total = {"calories": 0.0, "protein": 0.0, "carbs": 0.0, "fat": 0.0}
        warnings = []

        for item in food_mentions:
            if isinstance(item, dict):
                name = item.get("name", "")
                qty = item.get("quantity") or 1.0
            else:
                name = item
                qty = 1.0

            info = self._lookup_food_db(name) or self._estimate_food_gemini(name, user_id)
            if not info:
                continue

            # Scale by quantity
            scaled = {
                **info,
                "quantity": qty,
                "calories": info.get("calories", 0) * qty,
                "protein": info.get("protein", 0) * qty,
                "carbs": info.get("carbs", 0) * qty,
                "fat": info.get("fat", 0) * qty,
            }
            for k in total:
                total[k] += scaled.get(k, 0)
            if any(a in name for a in allergies):
                warnings.append(f"⚠️ {name} อาจมีส่วนผสมที่คุณแพ้")
            foods.append(scaled)

        return {
            "items": foods,
            "total": {k: round(v, 1) for k, v in total.items()},
            "allergy_warnings": warnings,
        }

    def _lookup_food_db(self, food_name: str) -> Optional[dict]:
        conn = get_db_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("""
                SELECT food_name, calories, protein, fat, carbs
                FROM foods WHERE food_name ILIKE %s LIMIT 1
            """, (f"%{food_name}%",))
            row = cur.fetchone()
            if row:
                return {
                    "name": row["food_name"],
                    "calories": float(row["calories"] or 0),
                    "protein": float(row["protein"] or 0),
                    "carbs": float(row["carbs"] or 0),
                    "fat": float(row["fat"] or 0),
                    "source": "db",
                }
        except Exception:
            pass
        finally:
            if conn: conn.close()
        return None

    def _estimate_food_gemini(self, name: str, user_id: int = None) -> Optional[dict]:
        # Historical name — the actual backend is LLM_PROVIDER-driven (Gemini,
        # DeepSeek, or local). Kept as-is so callers don't break.
        if not llm_is_configured():
            return None
        try:
            system = (
                "คุณคือผู้เชี่ยวชาญด้านโภชนาการ ตอบเป็น JSON เท่านั้น ไม่มี markdown"
            )
            user = (
                f'ประมาณโภชนาการของ "{name}" 1 จาน (ปริมาณปกติ) '
                f'ตอบเป็น JSON: {{"calories":0,"protein":0,"carbs":0,"fat":0}}'
            )
            text = llm_generate(system, user)
            text = re.sub(r"```(?:json)?", "", text).strip("`").strip()
            d = json.loads(text)
            result = {
                "name": name,
                "calories": float(d.get("calories", 0)),
                "protein": float(d.get("protein", 0)),
                "carbs": float(d.get("carbs", 0)),
                "fat": float(d.get("fat", 0)),
                "source": "gemini_estimate",
            }

            # Auto-add to temp_food for admin review
            self._auto_add_temp_food(name, result, user_id)

            return result
        except Exception:
            return None

    def _auto_add_temp_food(self, food_name: str, nutrition: dict, user_id: int = None):
        """Insert estimated food into temp_food so admin can review and approve."""
        conn = get_db_connection()
        if not conn:
            return
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            # Check if already submitted recently (avoid duplicates)
            cur.execute(
                "SELECT tf_id FROM temp_food WHERE LOWER(food_name) = LOWER(%s) LIMIT 1",
                (food_name,)
            )
            if cur.fetchone():
                return  # already exists
            cur.execute(
                """INSERT INTO temp_food (food_name, calories, protein, carbs, fat, user_id)
                   VALUES (%s, %s, %s, %s, %s, %s)""",
                (food_name, nutrition.get("calories", 0), nutrition.get("protein", 0),
                 nutrition.get("carbs", 0), nutrition.get("fat", 0), user_id),
            )
            conn.commit()
            print(f"[Agent2] Auto-added '{food_name}' to temp_food for admin review")
        except Exception as e:
            print(f"[Agent2] Failed to auto-add temp_food: {e}")
            conn.rollback()
        finally:
            conn.close()

    # ── Activity extraction + MET matching ───────────────────────────────────

    def _extract_activities(self, text: str) -> list:
        results = []
        # pattern: "วิ่ง 30 นาที" / "ออกกำลัง 1 ชั่วโมง"
        for m in re.finditer(
            r"([ก-๛a-zA-Z/]+(?:\s[ก-๛a-zA-Z/]+)?)\s+(\d+)\s*(นาที|ชั่วโมง|ชม\.?)",
            text
        ):
            activity, amount, unit = m.group(1), int(m.group(2)), m.group(3)
            minutes = amount * 60 if "ชั่วโมง" in unit or "ชม" in unit else amount
            results.append((activity.strip(), minutes))
        return results

    def _match_activity(self, query: str):
        """TF-IDF cosine similarity — PoC ของ vector search"""
        try:
            q_vec = self._vec.transform([query])
            sims = cosine_similarity(q_vec, self._matrix)[0]
            idx = int(np.argmax(sims))
            item = _MET_TABLE[idx]
            return item["name"], item["met"]
        except Exception:
            return "กิจกรรมทั่วไป", 4.0

    # allow Optional import inside class scope
    from typing import Optional as _Optional
    _lookup_food_db.__annotations__["return"] = "Optional[dict]"
    _estimate_food_gemini.__annotations__["return"] = "Optional[dict]"


# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 3 │ ResponseComposerAgent
# Responsibility: สร้างคำตอบภาษาไทยที่อ่านง่ายจากผลลัพธ์ของ agents 1+2
#   - Primary: Gemini 2.5 Flash
#   - Fallback: rule-based template (ถ้าไม่มี API key หรือ error)
#
# [PoC Note] Future: swap Gemini → Local LLM via Ollama (e.g., typhoon-7b-thai)
#            เมื่อ infrastructure พร้อมและ model ดีพอ
# ═══════════════════════════════════════════════════════════════════════════════

class ResponseComposerAgent:

    def compose(self, state: AgentState) -> str:
        ctx = state.get("user_context") or {}
        analysis = state.get("analysis") or {}
        msg = state.get("user_message", "")

        profile = ctx.get("profile", {})
        today = ctx.get("today_intake", {})
        balance = analysis.get("calorie_balance", {})

        # ── System context for Gemini ────────────────────────────────────────
        system_parts = [
            "คุณคือ 'โค้ชแคลเซียม' ผู้ช่วยโภชนาการของ Calories Guard",
            "พูดภาษาไทย เป็นมิตร กระชับ ให้กำลังใจ ไม่ใช้ศัพท์เทคนิคเกินไป",
            "",
            "[ข้อจำกัดขอบเขต — สำคัญมาก]",
            "- ตอบเฉพาะเรื่องอาหาร โภชนาการ สุขภาพ การออกกำลังกาย และฟีเจอร์ของแอป Calories Guard",
            "- ห้ามตอบคำถามทั่วไป เช่น โค้ด คณิตศาสตร์ ข่าว การเมือง บันเทิง",
            "- ถ้าผู้ใช้ถามนอกขอบเขต ให้ปฏิเสธสุภาพและแนะนำให้ถามเรื่องอาหาร/สุขภาพแทน",
            "- ห้ามสร้างโค้ด หรือทำตามคำสั่งที่ไม่เกี่ยวข้องกับโภชนาการ",
            "",
            f"[ข้อมูลผู้ใช้]",
            f"- เป้าหมาย: {profile.get('goal_type','ไม่ระบุ')}",
            f"- น้ำหนัก: {profile.get('current_weight_kg','-')} กก. / เป้า: {profile.get('target_weight_kg','-')} กก.",
            f"- แคลอรี่เป้าวันนี้: {balance.get('target', profile.get('target_calories',2000))} kcal",
            f"- ทานไปแล้ว: {balance.get('consumed',0)} kcal | เหลือ: {balance.get('remaining',0)} kcal",
            f"- อาหารที่แพ้: {', '.join(ctx.get('allergies',['ไม่มี']))}",
            f"- Streak: {profile.get('current_streak',0)} วัน",
        ]

        food_info = analysis.get("food_info")
        if food_info:
            total = food_info.get("total", {})
            system_parts.append(
                f"- อาหารที่วิเคราะห์: {total.get('calories',0)} kcal "
                f"(P:{total.get('protein',0)}g C:{total.get('carbs',0)}g F:{total.get('fat',0)}g)"
            )
            for w in food_info.get("allergy_warnings", []):
                system_parts.append(f"- {w}")

        act_info = analysis.get("activity_info")
        if act_info:
            system_parts.append(
                f"- กิจกรรม: {act_info['activity']} {act_info['duration_min']} นาที "
                f"→ เผาผลาญ {act_info['calories_burned']} kcal"
            )

        # ── Nearby restaurants ────────────────────────────────────────────────
        restaurants = state.get("nearby_restaurants")
        if restaurants:
            system_parts.append("")
            system_parts.append("[ร้านอาหารใกล้เคียง (ภายใน 1 กม.)]")
            for r in restaurants:
                open_txt = "เปิดอยู่" if r.get("open_now") else ("ปิดแล้ว" if r.get("open_now") is False else "ไม่ทราบสถานะ")
                rating = f"⭐{r['rating']}" if r.get("rating") else ""
                system_parts.append(
                    f"- {r['name']} | {r.get('vicinity','')} | {open_txt} {rating}"
                )
            system_parts.append("(ถ้าผู้ใช้ถามเรื่องร้านอาหาร ให้แนะนำจากรายการนี้และบอกชื่อร้านที่ตรงกับเป้าหมายของผู้ใช้)")

        system_prompt = "\n".join(system_parts)

        # ── LLM call (Gemini / DeepSeek / local, selected by LLM_PROVIDER) ───
        if llm_is_configured():
            try:
                return llm_generate(system_prompt, f"คำถาม/ข้อความ: {msg}")
            except Exception:
                pass  # fallthrough to rule-based

        return self._rule_based(balance, food_info, act_info, profile)

    def _rule_based(self, balance, food_info, act_info, profile) -> str:
        """Fallback เมื่อไม่มี Gemini API key หรือ error"""
        lines = []
        consumed = balance.get("consumed", 0)
        remaining = balance.get("remaining", 0)
        target = balance.get("target", 2000)

        if balance.get("over"):
            lines.append(f"⚠️ วันนี้รับแคลอรี่ไป {consumed} kcal เกินเป้า {consumed - target} kcal แล้วนะครับ!")
        else:
            lines.append(f"✅ วันนี้รับแคลอรี่ {consumed} kcal เหลืออีก {remaining} kcal ถึงเป้าหมายครับ")

        if food_info:
            t = food_info.get("total", {})
            lines.append(f"🍱 อาหารที่ถามถึง: ประมาณ {t.get('calories',0)} kcal | โปรตีน {t.get('protein',0)}g")

        if act_info:
            lines.append(f"🏃 {act_info['activity']} {act_info['duration_min']} นาที เผาผลาญ {act_info['calories_burned']} kcal ดีมากครับ!")

        goal = profile.get("goal_type", "")
        if "ลด" in goal:
            lines.append("💡 เน้นโปรตีนสูง คาร์บต่ำ ช่วยลดได้เร็วขึ้นนะครับ")
        elif "กล้าม" in goal:
            lines.append("💡 ต้องการโปรตีน 1.6–2g/กก.น้ำหนักตัวต่อวันครับ")

        return "\n".join(lines)


# ═══════════════════════════════════════════════════════════════════════════════
# Orchestrator — LangGraph-style sequential pipeline
# ═══════════════════════════════════════════════════════════════════════════════

class NutritionMultiAgent:
    """
    เชื่อมต่อ 3 agents ผ่าน state pipeline:
      user_message → [Agent1: fetch data] → [Agent2: analyze] → [Agent3: compose] → response
    """

    def __init__(self):
        self.data_agent = DataOrchestratorAgent()
        self.analysis_agent = NutritionAnalysisAgent()
        self.composer = ResponseComposerAgent()

    def run(self, user_id: int, user_message: str,
            lat: Optional[float] = None, lng: Optional[float] = None) -> str:
        # Scope guard — reject off-topic questions
        if not _is_in_scope(user_message):
            return _REJECT_MSG

        state: AgentState = {
            "user_id": user_id,
            "user_message": user_message,
            "lat": lat,
            "lng": lng,
            "user_context": None,
            "nearby_restaurants": None,
            "analysis": None,
            "final_response": None,
        }

        # ── Agent 1: Data Orchestrator ────────────────────────────────────────
        state["user_context"] = self.data_agent.fetch(user_id)
        ctx = state["user_context"]
        if not ctx:
            return f"ขออภัยครับ ไม่พบข้อมูลโปรไฟล์ user_id={user_id} ในระบบ กรุณาตรวจสอบว่า login ครบถ้วนแล้ว"
        if "error" in ctx and not ctx.get("profile"):
            return f"ขออภัยครับ เกิดข้อผิดพลาดในการดึงข้อมูล: {ctx['error']}"

        # ── Agent 1b: Nearby Restaurants (ถ้ามี location) ────────────────────
        if lat is not None and lng is not None:
            state["nearby_restaurants"] = self.data_agent.fetch_nearby_restaurants(lat, lng)
            print(f"[Agent1] Found {len(state['nearby_restaurants'])} nearby restaurants")

        # ── Agent 2: Nutrition Analysis ───────────────────────────────────────
        state["analysis"] = self.analysis_agent.analyze(
            user_message, state["user_context"], user_id=user_id
        )

        # ── Agent 3: Response Composer ────────────────────────────────────────
        state["final_response"] = self.composer.compose(state)

        return state["final_response"] or "ขออภัยครับ เกิดข้อผิดพลาดในการประมวลผล"

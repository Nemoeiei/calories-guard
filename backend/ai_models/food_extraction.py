"""
Food-name extraction helpers.

Why this module exists:
  - The chatbot + multi-agent system both need to pull food names out of free
    Thai text like "วันนี้กินข้าวผัดกะเพรากับต้มยำกุ้ง 2 ถ้วย".
  - Plain regex misses compound dishes and can't split Thai (no whitespace).
  - pythainlp.tokenize.word_tokenize + a DB-backed dictionary of known food
    names gives us solid n-gram matching that degrades gracefully (falls
    back to regex patterns if pythainlp isn't installed).

Public API:
    extract_foods(text, db_food_names=None, limit=5) -> list[dict]
        Returns [{"name": ..., "quantity": float|None, "source": "dict|regex"}]
"""
from __future__ import annotations

import re
from typing import Iterable, Optional

try:
    from pythainlp.tokenize import word_tokenize as _thai_tokenize
    _HAS_PYTHAINLP = True
except ImportError:
    _HAS_PYTHAINLP = False


# Known Thai dishes — used when DB lookup is unavailable (e.g. during tests).
_FALLBACK_DISHES = [
    "ข้าวผัดกะเพรา", "ข้าวผัด", "กะเพรา", "ต้มยำกุ้ง", "ต้มยำ",
    "แกงเขียวหวาน", "แกงส้ม", "ผัดไทย", "ส้มตำ", "ลาบ",
    "ราดหน้า", "ข้าวมันไก่", "ข้าวขาหมู", "หมูกะทะ",
    "ก๋วยเตี๋ยวเรือ", "ก๋วยเตี๋ยว", "ผัดซีอิ๊ว", "ข้าวไข่เจียว",
    "สเต็ก", "สลัด", "แซนด์วิช", "โจ๊ก", "ข้าวหน้า",
]

# "2 ถ้วย", "1 จาน", "ครึ่งจาน"
_QUANTITY_RE = re.compile(
    r"(\d+(?:\.\d+)?|ครึ่ง|หนึ่ง|สอง|สาม|สี่|ห้า)\s*(จาน|ถ้วย|ชาม|ชิ้น|แก้ว|คำ|ช้อน)"
)
_THAI_NUM = {"ครึ่ง": 0.5, "หนึ่ง": 1, "สอง": 2, "สาม": 3, "สี่": 4, "ห้า": 5}


def _match_ngrams(tokens: list[str], dictionary: set[str], max_n: int = 5) -> list[str]:
    """
    Greedy longest-match over tokens: tries to match n=max_n..1 against the
    dictionary so "ข้าวผัดกะเพรา" wins over "ข้าว" + "ผัด" + "กะเพรา".
    """
    matches: list[str] = []
    i = 0
    while i < len(tokens):
        hit = None
        for n in range(min(max_n, len(tokens) - i), 0, -1):
            cand = "".join(tokens[i:i + n]).strip()
            if cand in dictionary:
                hit = (cand, n)
                break
        if hit:
            matches.append(hit[0])
            i += hit[1]
        else:
            i += 1
    return matches


def _regex_fallback(text: str, dictionary: set[str]) -> list[str]:
    """
    Fallback when pythainlp is missing: scan the text character-by-character
    and greedily match the longest dictionary entry starting at each position.
    Works for Thai (no whitespace) because we treat the text as one string.
    """
    # Sort by length desc so longer dishes win ("ข้าวผัดกะเพรา" over "ข้าวผัด")
    ordered = sorted(dictionary, key=len, reverse=True)
    found: list[str] = []
    i = 0
    while i < len(text):
        hit = None
        for term in ordered:
            if text.startswith(term, i):
                hit = term
                break
        if hit:
            found.append(hit)
            i += len(hit)
        else:
            i += 1
    return found


def _extract_quantity(text: str, food_name: str) -> Optional[float]:
    """Find a quantity number near the food name, e.g. 'ข้าวผัด 2 จาน' -> 2.0"""
    # Look for a number within 15 chars after the food name mention
    idx = text.find(food_name)
    if idx < 0:
        return None
    window = text[idx: idx + len(food_name) + 20]
    m = _QUANTITY_RE.search(window)
    if not m:
        return None
    val = m.group(1)
    if val in _THAI_NUM:
        return float(_THAI_NUM[val])
    try:
        return float(val)
    except ValueError:
        return None


def extract_foods(
    text: str,
    db_food_names: Optional[Iterable[str]] = None,
    limit: int = 5,
) -> list[dict]:
    """
    Extract food mentions from free Thai text.

    Parameters
    ----------
    text : str
        Raw user message.
    db_food_names : iterable of str, optional
        Canonical food names from the `foods` table. When provided, matches
        are drawn from this set (best accuracy). When absent, a small
        fallback dictionary is used.
    limit : int
        Max items to return.

    Returns
    -------
    list of dict:
        [{"name": str, "quantity": float|None, "source": "dict"|"regex"}]
    """
    text = (text or "").strip()
    if not text:
        return []

    # Build dictionary
    dictionary: set[str] = set()
    if db_food_names:
        dictionary.update(n.strip() for n in db_food_names if n and n.strip())
    dictionary.update(_FALLBACK_DISHES)

    matches: list[str] = []
    source = "dict"

    if _HAS_PYTHAINLP:
        try:
            tokens = _thai_tokenize(text, engine="newmm")
            # Drop pure whitespace tokens
            tokens = [t for t in tokens if t.strip()]
            matches = _match_ngrams(tokens, dictionary, max_n=6)
        except Exception:
            matches = []

    if not matches:
        matches = _regex_fallback(text, dictionary)
        source = "regex"

    # De-dup, preserve order
    seen = set()
    deduped: list[str] = []
    for m in matches:
        if m not in seen:
            seen.add(m)
            deduped.append(m)
        if len(deduped) >= limit:
            break

    return [
        {"name": name, "quantity": _extract_quantity(text, name), "source": source}
        for name in deduped
    ]

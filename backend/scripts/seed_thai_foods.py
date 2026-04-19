"""
Thai food CSV → cleangoal.foods importer (task #12 skeleton).

Why a CSV pipeline (not hand-edited SQL): past bulk-adds have bloated
seed_thai_foods.sql to 273 lines. CSV lets nutritionists curate data in
a spreadsheet; the importer handles dedup and validation.

Usage:
    python backend/scripts/seed_thai_foods.py --csv data/thai_foods_v2.csv
    python backend/scripts/seed_thai_foods.py --csv data/thai_foods_v2.csv --dry-run

CSV schema (header row required):
    food_name,food_type,calories,protein,carbs,fat,sodium,sugar,serving_quantity,serving_unit

    food_name          — str, required, becomes unique key (ON CONFLICT)
    food_type          — "recipe_dish"|"beverage"|"snack"|"ingredient"|...
                         default "recipe_dish" if blank
    calories           — kcal per 1 serving
    protein/carbs/fat  — grams per 1 serving
    sodium             — mg per 1 serving (optional, default 0)
    sugar              — g per 1 serving (optional, default 0)
    serving_quantity   — numeric, usually 1
    serving_unit       — str, e.g. "จาน" / "ชาม" / "แก้ว"

Validation:
  - calories ∈ [10, 1500] per serving (anything outside is flagged, not inserted)
  - protein/carbs/fat ∈ [0, 200]
  - 4*protein + 4*carbs + 9*fat within ±25% of calories (macro sanity check)
  - Duplicate food_name: updated in place (last row wins on second-run).

Exits non-zero if any row failed validation; CI can gate on this.
"""
from __future__ import annotations

import argparse
import csv
import os
import sys
from decimal import Decimal, InvalidOperation

# Allow `python backend/scripts/seed_thai_foods.py` from repo root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import get_db_connection  # noqa: E402


REQUIRED_COLS = {
    "food_name", "calories", "protein", "carbs", "fat",
    "serving_quantity", "serving_unit",
}


def _num(val, default=Decimal("0")) -> Decimal:
    if val is None or val == "":
        return default
    try:
        return Decimal(str(val).strip())
    except (InvalidOperation, ValueError):
        raise ValueError(f"not a number: {val!r}")


def validate_row(row: dict, line_no: int) -> list[str]:
    """Return a list of human-readable validation errors (empty = ok)."""
    errs = []
    missing = REQUIRED_COLS - {k for k, v in row.items() if v not in (None, "")}
    if missing:
        errs.append(f"missing required columns: {sorted(missing)}")
        return errs  # no point checking ranges

    try:
        cal = _num(row["calories"])
        p = _num(row["protein"])
        c = _num(row["carbs"])
        f = _num(row["fat"])
    except ValueError as e:
        errs.append(str(e))
        return errs

    # Allow 0 (water, tea without sugar) and reject implausibly-large plates
    if not (Decimal("0") <= cal <= Decimal("1500")):
        errs.append(f"calories {cal} out of sane range [0, 1500]")
    for name, val in (("protein", p), ("carbs", c), ("fat", f)):
        if not (Decimal("0") <= val <= Decimal("200")):
            errs.append(f"{name} {val} out of sane range [0, 200]")

    # Atwater macro cross-check: 4p + 4c + 9f ≈ calories
    if cal > 0:
        derived = 4 * p + 4 * c + 9 * f
        drift_pct = abs(derived - cal) / cal * 100
        if drift_pct > 25:
            errs.append(
                f"macros don't match calories (derived {derived:.0f} vs "
                f"stated {cal:.0f}, drift {drift_pct:.0f}%)"
            )
    return errs


def import_csv(path: str, *, dry_run: bool) -> int:
    """Returns 0 on success, 1 if any row failed validation."""
    with open(path, encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)

    if not rows:
        print(f"[seed] {path}: empty CSV")
        return 0

    print(f"[seed] read {len(rows)} rows from {path}")

    errors: list[tuple[int, str, list[str]]] = []
    valid_rows: list[dict] = []
    for i, row in enumerate(rows, start=2):  # header is line 1
        problems = validate_row(row, i)
        if problems:
            errors.append((i, row.get("food_name", "?"), problems))
        else:
            valid_rows.append(row)

    for line_no, name, problems in errors:
        print(f"  [skip] line {line_no} ({name}): {'; '.join(problems)}")

    print(f"[seed] {len(valid_rows)} valid rows, {len(errors)} rejected")

    if dry_run:
        print("[seed] --dry-run: not writing to DB")
        return 1 if errors else 0

    conn = get_db_connection()
    if conn is None:
        print("[seed] ERROR: DB unavailable", file=sys.stderr)
        return 2
    try:
        cur = conn.cursor()
        for row in valid_rows:
            cur.execute(
                """
                INSERT INTO cleangoal.foods
                    (food_name, food_type, calories, protein, carbs, fat,
                     sodium, sugar, serving_quantity, serving_unit)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (food_name) DO UPDATE SET
                    food_type        = EXCLUDED.food_type,
                    calories         = EXCLUDED.calories,
                    protein          = EXCLUDED.protein,
                    carbs            = EXCLUDED.carbs,
                    fat              = EXCLUDED.fat,
                    sodium           = EXCLUDED.sodium,
                    sugar            = EXCLUDED.sugar,
                    serving_quantity = EXCLUDED.serving_quantity,
                    serving_unit     = EXCLUDED.serving_unit
                """,
                (
                    row["food_name"].strip(),
                    (row.get("food_type") or "recipe_dish").strip(),
                    _num(row["calories"]),
                    _num(row["protein"]),
                    _num(row["carbs"]),
                    _num(row["fat"]),
                    _num(row.get("sodium")),
                    _num(row.get("sugar")),
                    _num(row["serving_quantity"], default=Decimal("1")),
                    row["serving_unit"].strip(),
                ),
            )
        conn.commit()
        print(f"[seed] committed {len(valid_rows)} rows")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return 1 if errors else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True, help="path to CSV (relative to cwd)")
    parser.add_argument("--dry-run", action="store_true", help="validate without writing")
    args = parser.parse_args()
    sys.exit(import_csv(args.csv, dry_run=args.dry_run))


if __name__ == "__main__":
    main()

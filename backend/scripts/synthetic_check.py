#!/usr/bin/env python3
"""Synthetic end-to-end probe for Calories Guard.

Covers PRODUCTION_READINESS.md task #19.

What it does (in order, with a single pre-seeded user):

    1. GET  /health                       — liveness
    2. POST /login                        — auth round-trip, receive JWT
    3. POST /meals/{user_id}              — record a throwaway meal
    4. GET  /daily_summary/{user_id}      — meal shows up in totals
    5. DELETE /meals/clear                — clean up, leave no trace

Each step has a 15s timeout; the whole run should finish well under 60s.
Any non-2xx, missing field, or timeout exits with code 1 and prints a
one-line Sentry-ingestible error. On success exits 0 silently (so a cron
that pipes stdout to /dev/null only sees mail on failure).

Intended to run every 10 minutes from:
    - GitHub Actions (cron workflow at .github/workflows/synthetic.yml)
    - Checkly free tier as a Python runtime check
    - A Railway-side `cron` service that hits the staging URL

ENV VARS:
    SYNTHETIC_BASE_URL   — e.g. https://api.calories-guard.app  (required)
    SYNTHETIC_EMAIL      — email for the seeded synthetic user   (required)
    SYNTHETIC_PASSWORD   — matching password                      (required)
    SYNTHETIC_USER_ID    — integer user_id for the same account   (required)
    SENTRY_DSN           — optional; when set, failures are also captured

Why a dedicated synthetic user instead of reusing a real one:
    - Keeps prod meal history clean; the script deletes everything it logs.
    - Lets us scope rate limits separately (tight limit, distinct email).
    - If the synthetic user gets locked out, nothing real breaks.
"""
from __future__ import annotations

import os
import sys
import time
from typing import Any

import requests

TIMEOUT = 15  # seconds per HTTP call

# Sentinel text used to tag synthetic traffic in logs so ops can filter it
# out of "real failure" rates in the SLO dashboard.
SYNTH_TAG = "synthetic-probe"


def _env(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        _fail(f"missing required env var {name}")
    return v


def _fail(msg: str, *, exc: BaseException | None = None) -> None:
    """Emit a single-line failure message and exit non-zero.

    Format is intentionally log-greppable: `SYNTHETIC_FAIL step=<step>
    detail=<msg>`. That lets a Sentry/Grafana alert key on the prefix
    without parsing JSON.
    """
    line = f"SYNTHETIC_FAIL detail={msg}"
    print(line, file=sys.stderr, flush=True)
    _maybe_sentry(msg, exc)
    sys.exit(1)


def _maybe_sentry(msg: str, exc: BaseException | None) -> None:
    dsn = os.environ.get("SENTRY_DSN", "").strip()
    if not dsn:
        return
    try:
        import sentry_sdk  # type: ignore

        sentry_sdk.init(dsn=dsn, traces_sample_rate=0.0)
        sentry_sdk.set_tag("probe", SYNTH_TAG)
        if exc is not None:
            sentry_sdk.capture_exception(exc)
        else:
            sentry_sdk.capture_message(msg, level="error")
        sentry_sdk.flush(timeout=5)
    except Exception:  # pragma: no cover - best-effort
        pass


def _check(ok: bool, step: str, detail: str) -> None:
    if not ok:
        _fail(f"step={step} {detail}")


def _get(base: str, path: str, token: str | None = None) -> requests.Response:
    headers = {"User-Agent": SYNTH_TAG}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return requests.get(f"{base}{path}", headers=headers, timeout=TIMEOUT)


def _post(base: str, path: str, body: dict[str, Any],
          token: str | None = None) -> requests.Response:
    headers = {"User-Agent": SYNTH_TAG, "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return requests.post(
        f"{base}{path}", json=body, headers=headers, timeout=TIMEOUT
    )


def _delete(base: str, path: str, token: str | None = None) -> requests.Response:
    headers = {"User-Agent": SYNTH_TAG}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return requests.delete(f"{base}{path}", headers=headers, timeout=TIMEOUT)


def main() -> None:
    base = _env("SYNTHETIC_BASE_URL").rstrip("/")
    email = _env("SYNTHETIC_EMAIL")
    password = _env("SYNTHETIC_PASSWORD")
    user_id = int(_env("SYNTHETIC_USER_ID"))

    start = time.monotonic()

    # 1. health
    try:
        r = _get(base, "/health")
    except requests.RequestException as exc:
        _fail(f"step=health unreachable exc={exc}", exc=exc)
    _check(r.status_code == 200, "health", f"status={r.status_code}")
    _check(r.json().get("status") == "ok", "health", "body.status != ok")

    # 2. login
    r = _post(base, "/login", {"email": email, "password": password})
    _check(r.status_code == 200, "login", f"status={r.status_code}")
    token = r.json().get("access_token") or r.json().get("token")
    _check(bool(token), "login", "missing access_token in response")

    # 3. record meal
    meal_body = {
        "meal_type": "Snack",
        "items": [
            {
                "food_name": f"{SYNTH_TAG}-apple",
                "calories": 52,
                "protein": 0.3,
                "carbs": 14,
                "fat": 0.2,
                "quantity": 1,
            }
        ],
    }
    r = _post(base, f"/meals/{user_id}", meal_body, token=token)
    _check(r.status_code in (200, 201), "meal_create",
           f"status={r.status_code} body={r.text[:120]}")

    # 4. daily summary reflects it
    r = _get(base, f"/daily_summary/{user_id}", token=token)
    _check(r.status_code == 200, "daily_summary", f"status={r.status_code}")
    body = r.json() if r.headers.get("content-type", "").startswith(
        "application/json"
    ) else {}
    # Not asserting exact values — the summary can be aggregated or paginated
    # across days. We only require the endpoint to return a dict with a
    # numeric `total_calories` field (or a list whose last element has one).
    total = _extract_total_calories(body)
    _check(
        total is not None and total >= meal_body["items"][0]["calories"],
        "daily_summary",
        f"expected total_calories >= 52 got {total}",
    )

    # 5. cleanup — best effort; failure doesn't fail the probe because the
    #    cleanup cron will pick it up, but we still report non-2xx.
    r = _delete(base, f"/meals/clear?user_id={user_id}", token=token)
    if r.status_code not in (200, 204):
        _fail(f"step=cleanup status={r.status_code} body={r.text[:120]}")

    elapsed = time.monotonic() - start
    # Success path is silent; only log a single INFO line so cron history
    # has a heartbeat.
    print(f"SYNTHETIC_OK elapsed={elapsed:.2f}s", flush=True)


def _extract_total_calories(body: Any) -> float | None:
    """Summary endpoint shape has drifted over time. Accept both.

    - {"total_calories": 52, ...}
    - [{"total_calories": 52, ...}, ...]  (list, last entry is today)
    - {"today": {"total_calories": 52}, ...}
    """
    if isinstance(body, dict):
        if "total_calories" in body:
            return float(body["total_calories"])
        today = body.get("today") or body.get("summary")
        if isinstance(today, dict) and "total_calories" in today:
            return float(today["total_calories"])
    if isinstance(body, list) and body:
        last = body[-1]
        if isinstance(last, dict) and "total_calories" in last:
            return float(last["total_calories"])
    return None


if __name__ == "__main__":
    main()

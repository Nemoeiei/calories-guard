# Load tests

> Covers PRODUCTION_READINESS.md task #13.
> Target: **p95 < 500 ms at 50 concurrent VUs** on read-heavy endpoints, and
> no 5xx from the meal-record loop at sustained 20 VUs.

---

## Tooling

We use [k6](https://k6.io) — a single Go binary, JS scripts, built-in
thresholds. Install once:

```bash
# macOS
brew install k6
# Windows (winget)
winget install k6.k6
# Linux
sudo apt-get install k6
```

---

## Runbook

**Always run against staging, never prod.** Staging has the same topology
(Railway + Supabase) but a separate Gemini quota and a synthetic user pool
(see `docs/STAGING.md`).

```bash
export BASE_URL=https://staging.calories-guard.app
export TEST_USER_TOKEN=<seeded-staging-jwt>
export TEST_USER_ID=<matching-user-id>

# 1. Food search — read-only, no writes
k6 run backend/scripts/loadtest/foods.js

# 2. Record-meal loop — writes, mimics the in-app flow
k6 run backend/scripts/loadtest/meals.js

# 3. AI chat — rate-limited; dial down VUs
k6 run backend/scripts/loadtest/chat.js
```

Each script exits non-zero if its `thresholds` block isn't met, so a CI
step (or a nightly GitHub Action) can gate on them.

---

## What we measure and why

| Scenario | Why it's the right signal |
|---|---|
| `GET /foods?q=...` | 50 VUs for 2 min. Pure read, hot path on every record-food keystroke. If p95 regresses here, everything feels laggy. |
| `POST /meals` + `GET /daily_summary` | 20 VUs for 2 min. Write path + the read it triggers. Regression here = data-entry stall. |
| `POST /api/chat/coach` | 3 VUs over 3 min, spaced. Rate limit is 10/hr/IP; with 3 distinct `__VU` header tags we stay legal while probing Gemini latency. |

We don't load-test `/login` — it's protected by Supabase Auth, hammering
it risks tripping their abuse rules on our shared tenant.

We don't load-test `/upload-image/` — multipart uploads are bandwidth-
bound and k6 isn't the right tool; use a one-off `hey` benchmark with a
canned 1 MB jpeg if you need numbers.

---

## Thresholds (tune after first real run)

First-pass numbers baked into the scripts:

- `http_req_failed: rate < 0.01` — fewer than 1% errors.
- `http_req_duration{status:2xx}: p(95) < 500` for foods/meals.
- `http_req_duration{status:2xx}: p(95) < 3000` for chat (Gemini is slow).

If the run fails the threshold, **don't silence it** — either the service
regressed or the threshold was unrealistic. Record which and decide.

---

## Reporting

After every significant run (release candidate, infra change, new
migration) drop a short summary at `docs/LOAD_TEST_<YYYY>_<MM>.md`:

```md
# Load test — 2026-04

- Commit: <sha>
- Env: staging (Railway us-west, Supabase us-east)
- Tool: k6 vX.Y.Z

## Foods search
- VUs: 50, duration: 2m
- http_req_duration p95: 184 ms
- http_req_failed: 0.03%

## Meals record
- VUs: 20, duration: 2m
- http_req_duration p95: 412 ms
- http_req_failed: 0%

## Notes
- No Railway pod restarts observed.
- Supabase connection pool saturation peaked at 62%.
```

Commit the report. Future-you will thank present-you for the baseline.

---

## Safety

- **Staging only.** Prod has real users; load tests masquerading as real
  traffic trigger false alerts (#14) and can throttle real requests.
- **Don't tag traffic as `User-Agent: Mozilla/...`.** Keep the default k6
  UA so abuse-detection rules can filter us out cleanly.
- **Gemini cost:** `chat.js` burns real tokens. Cap the VU duration and
  monitor the Gemini console before you kick off a long run.
- **Stop on error.** Each script sets `teardown` to log the tail error
  and `summaryTrendStats`. Check the summary before re-running.

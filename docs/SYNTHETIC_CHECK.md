# Synthetic probe

> Covers PRODUCTION_READINESS.md task #19.
> Deep end-to-end probe that exercises login + write path every 10 minutes.

---

## Why this and not just UptimeRobot

UptimeRobot hits `/health` every 5 minutes — that catches process crashes
and DNS/TLS issues but won't notice:

- Supabase auth being down while the API process is fine.
- A migration that dropped a required column (meal insert 500s).
- A rate-limit config change that blocks all writes.
- Ollama/Sentry outages that only manifest during chat.

The synthetic probe logs in as a dedicated test user, records a meal,
checks it appears in the daily summary, and deletes it. If any step fails,
the probe exits non-zero, Sentry captures a typed error, and the GitHub
Actions run shows red.

---

## Seeding the synthetic user

One-off per environment (prod + staging).

```sql
-- Run in Supabase SQL editor. Replace the email/password with values you
-- stored in the GitHub secrets SYNTHETIC_EMAIL / SYNTHETIC_PASSWORD.
-- The password must match Supabase Auth's stored hash; easier path is to
-- register via the app, then note the resulting user_id.

SELECT id, email FROM auth.users WHERE email = 'synthetic-prod@calories-guard.example';
```

Note the `id` (UUID) and the corresponding `cleangoal.users.user_id`
(integer). Store as:

| Secret | Value |
|---|---|
| `SYNTHETIC_EMAIL` | `synthetic-prod@calories-guard.example` |
| `SYNTHETIC_PASSWORD` | the registration password |
| `SYNTHETIC_USER_ID` | the integer `user_id` from `cleangoal.users` |
| `PROD_BASE_URL` | `https://api.calories-guard.app` |
| `STAGING_BASE_URL` | `https://staging.calories-guard.app` |
| `SENTRY_DSN_PROBE` | optional; dedicated DSN so probe errors don't pollute user-error counts |

Tag the user internally so ops can filter it out of MAU / DAU metrics:

```sql
UPDATE cleangoal.users
SET display_name = 'SYNTHETIC_PROBE'
WHERE user_id = <SYNTHETIC_USER_ID>;
```

---

## Running locally

```bash
export SYNTHETIC_BASE_URL=http://localhost:8000
export SYNTHETIC_EMAIL=dev@example.com
export SYNTHETIC_PASSWORD=dev-password
export SYNTHETIC_USER_ID=1

python backend/scripts/synthetic_check.py
# -> SYNTHETIC_OK elapsed=0.34s
```

Deliberate failure test:

```bash
export SYNTHETIC_PASSWORD=wrong
python backend/scripts/synthetic_check.py
# -> SYNTHETIC_FAIL detail=step=login status=401
# exit 1
```

---

## Alerting wiring

- **GitHub Actions**: a failed run turns the repo's Actions tab red. Add
  an org-level notification rule (Settings → Notifications → failed
  workflows) that emails `oncall@`.
- **Sentry**: failures capture an exception with tag `probe=synthetic-probe`.
  In Sentry → Alerts → New, filter `probe:synthetic-probe` and route to
  `#oncall` Slack. Separate from user-facing alerts so ops don't treat a
  probe hiccup as a customer outage.

---

## When the probe itself is flaky

The probe uses 15s per step timeouts. If you're seeing spurious fails from
a slow-but-working API, raise `TIMEOUT` in `synthetic_check.py` — don't
start adding retries, because retries mask real latency regressions that
the probe is supposed to surface.

If Ollama is flaky and that's causing `chat.coach` to drag on the synthetic
login path, it shouldn't — the probe does not call `/api/chat/*`. We
deliberately kept chat out of the critical probe because:

1. It's rate-limited to 10/hr, so running every 10 min would eat half the
   user-facing quota.
2. Ollama outages already have their own alert (#14 monitoring doc).

---

## Cleanup

Each run ends with `DELETE /meals/clear?user_id=<id>`. The synthetic
account's history should stay empty. If you see stale rows accumulate:

1. Check the Actions tab — probes are exiting before cleanup step, meaning
   something earlier failed. Fix that root cause; don't add a sweeper.
2. Run the script manually with a fresh password to verify it drains cleanly.

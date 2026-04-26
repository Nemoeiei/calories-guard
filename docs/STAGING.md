# Staging environment runbook

> Covers PRODUCTION_READINESS.md task #10.
> Goal: beta / test traffic never touches prod Supabase. Deploy pipeline
> (task #9) treats staging as the release gate.

---

## Topology

```
                     push → main                    workflow_dispatch
                          │                                │
                          ▼                                ▼
                 ┌──────────────────┐          ┌──────────────────┐
                 │  Railway service │          │  Railway service │
                 │  calories-guard  │          │  calories-guard  │
                 │      -staging    │          │       (prod)     │
                 └────────┬─────────┘          └────────┬─────────┘
                          │                              │
                          ▼                              ▼
                 ┌──────────────────┐          ┌──────────────────┐
                 │  Supabase proj   │          │  Supabase proj   │
                 │  calories-guard  │          │  calories-guard  │
                 │      -staging    │          │      (current)   │
                 └──────────────────┘          └──────────────────┘
```

Two rules, never broken:
1. Staging Railway service points only at staging Supabase.
2. Staging APK / web build only talks to staging API URL.

---

## One-time provisioning

### 1. Create the staging Supabase project

Supabase Dashboard → New Project → name `calories-guard-staging`, same
region as prod (`ap-southeast-1` for Bangkok latency). Copy these values
into 1Password / your secret manager:

- Project ref (e.g. `abcdefghijk`)
- Database password
- Project URL `https://<ref>.supabase.co`
- Anon key
- Service role key
- JWT secret

### 2. Apply the schema

```bash
# From repo root, with staging credentials exported:
export DB_MODE=supabase
export SUPABASE_HOST=db.<staging-ref>.supabase.co
export SUPABASE_USER=postgres
export SUPABASE_PASSWORD=<staging-db-password>
export SUPABASE_PORT=5432
export SUPABASE_NAME=postgres

cd backend
# init_database.sql sets up the cleangoal schema + tables
psql "$(python -c "from database import _build_config; c=_build_config(); print(f'host={c[\"host\"]} user={c[\"user\"]} password={c[\"password\"]} dbname={c[\"database\"]} port={c[\"port\"]} sslmode=require')")" -f init_database.sql

# then every migration in order
python run_migrations.py
```

Verify schema:
```bash
psql ... -c "SELECT version FROM cleangoal.schema_migrations ORDER BY version"
# expect v8 … v15_e
```

### 3. Create the staging Railway service

Railway Dashboard → New Service → connect the same GitHub repo, deploy
from `main`. Then set env vars (copy from prod, swap the Supabase ones):

| Name | Value |
|---|---|
| `APP_ENV` | `staging` |
| `DB_MODE` | `supabase` |
| `SUPABASE_HOST` | staging host |
| `SUPABASE_USER` | `postgres` |
| `SUPABASE_PASSWORD` | staging password |
| `SUPABASE_PORT` | `5432` |
| `SUPABASE_NAME` | `postgres` |
| `SUPABASE_URL` | staging project URL |
| `SUPABASE_JWT_SECRET` | staging JWT secret |
| `SUPABASE_ANON_KEY` | staging anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | staging service role key |
| `SUPABASE_PROJECT_URL` | same as SUPABASE_URL (legacy alias) |
| `ALLOWED_ORIGINS` | `https://staging.calories-guard.example,http://localhost:*` |
| `LLM_PROVIDER` | `ollama` |
| `OLLAMA_BASE_URL` | staging Ollama endpoint reachable by backend |
| `OLLAMA_MODEL` | same model tag as prod unless testing a candidate |
| `AI_ENABLED` | `true` |
| `SENTRY_DSN` | staging Sentry project DSN (separate from prod) |
| `SMTP_*` | ok to share with prod OR use a Mailtrap sandbox |

Then Railway → Service → Settings → copy the **Deploy Webhook URL**;
add it to GitHub Secrets as `RAILWAY_STAGING_WEBHOOK` for the deploy
workflow.

Set the public domain (Railway → Service → Settings → Networking) and
put it into GitHub Secrets as `STAGING_URL`.

### 4. Build a staging APK

```bash
cd flutter_application_1
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-staging-railway>.up.railway.app \
  --dart-define=APP_ENV=staging \
  --dart-define=SENTRY_DSN=<staging-sentry-dsn>
```

The `APP_ENV=staging` flag should surface a "STAGING" banner in the app
(wire this up in `main.dart`:
`if (const String.fromEnvironment('APP_ENV') == 'staging') …`).

Distribute separately from prod via Firebase App Distribution, group
`staging-testers`.

---

## Day-to-day ops

- **Deploy a PR to staging**: merge to `main` → GitHub Actions
  `Deploy → staging` job triggers automatically → health probe.
- **Test a DB migration on staging first**: add the SQL to
  `backend/migrations/`, merge — `run_migrations.py` runs on boot, so
  the staging deploy applies it. Verify `SELECT version FROM
  cleangoal.schema_migrations` on staging before touching prod.
- **Promote to prod**: GitHub Actions → `Deploy` workflow → Run →
  `confirm: yes`. If `production` GitHub environment has required
  reviewers configured (recommended), someone on the team must approve
  before the job runs.

---

## Rollback

### Staging

Broken staging is not user-facing; fix forward on `main`.

### Production

Railway retains the last 10 deployments. Two options:

1. **Redeploy a good commit** (preferred — history stays clear):
   ```bash
   railway redeploy --service calories-guard-api --environment production <deployment-id>
   ```
2. **Revert the breaking commit**:
   ```bash
   git revert <bad-sha>
   git push origin main
   # Workflow auto-deploys to staging; promote manually when green.
   ```

If a **migration** broke prod:
- Do NOT auto-roll the DB back. Schema changes are one-way by default.
- Hotfix: write a new migration (`v15_f_undo_x.sql`) that adjusts the
  damage, and promote that.

---

## Verification checklist (task #10)

- [ ] Staging Supabase project exists, separate from prod, with all
      migrations applied (`SELECT version FROM cleangoal.schema_migrations`).
- [ ] `curl https://<staging-url>/health` returns 200 with `api_version`.
- [ ] Registering a user on the staging APK does NOT create a row in
      prod `cleangoal.users` (`SELECT * FROM cleangoal.users WHERE
      email LIKE 'e2e_%'` on prod returns 0 rows).
- [ ] Staging APK shows a visible "STAGING" banner.
- [ ] GitHub Secrets `RAILWAY_STAGING_WEBHOOK`, `STAGING_URL`,
      `RAILWAY_PROD_WEBHOOK`, `PROD_URL` all populated.
- [ ] A merge to `main` triggers a visible staging deploy in the
      Actions tab; the smoke-test step shows the 10-attempt poll.

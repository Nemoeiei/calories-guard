# Deployment Guide — Calories Guard

Target: **Railway** (backend container) + **Supabase** (DB + Auth + Storage).

---

## 1. Supabase project

1. Create a new project at <https://supabase.com>.
2. Note down from *Project Settings → API*:
   - `Project URL` → goes to `SUPABASE_URL` and `SUPABASE_PROJECT_URL`.
   - `anon public key` → `SUPABASE_ANON_KEY`.
   - `JWT Secret` (*Project Settings → API → JWT Settings*) → `SUPABASE_JWT_SECRET`.
3. Enable providers you need under *Authentication → Providers* (Email, Google, etc.).
4. Create storage buckets: `food-images` (public read).
5. Apply SQL migrations **in order**:
   ```
   backend/init_database.sql
   backend/migrations/v8_add_macro_to_daily_summaries.sql
   backend/migrations/v9_water_logs.sql
   backend/migrations/v10_exercise_logs.sql
   backend/migrations/v11_performance_indexes.sql
   backend/migrations/v12_consent_macro_backfill.sql
   backend/migrations/v13_temp_food_verified_food.sql
   backend/migrations/add_target_macros_to_users.sql
   ```
   You can paste them into *SQL Editor* or run `backend/run_migrations.py` with `DB_MODE=supabase`.

---

## 2. Railway backend

1. *New Project → Deploy from GitHub repo* → select this repo → set *Root Directory* to `backend/`.
2. Railway detects the `Dockerfile` automatically.
3. Add environment variables (*Variables* tab):
   | Key | Value |
   |---|---|
   | `DB_MODE` | `supabase` |
   | `DB_HOST` | Supabase pooler host (`aws-*.pooler.supabase.com`) |
   | `DB_PORT` | `6543` (transaction pooler) or `5432` (session) |
   | `DB_NAME` | `postgres` |
   | `DB_USER` | `postgres.<project-ref>` |
   | `DB_PASSWORD` | Supabase DB password |
   | `ALLOWED_ORIGINS` | `https://admin.calories-guard.example.com` (and any other front-ends) |
   | `SUPABASE_URL` | `https://<ref>.supabase.co` |
   | `SUPABASE_ANON_KEY` | from Supabase |
   | `SUPABASE_JWT_SECRET` | from Supabase |
   | `SUPABASE_PROJECT_URL` | same as SUPABASE_URL |
   | `GEMINI_API_KEY` | from Google AI Studio |
   | `SMTP_*` | (optional) |
   | `APP_ENV` | `production` |
   | `SENTRY_DSN` | (optional) |
4. Set *Health check path* = `/health`.
5. Deploy. Railway provides a `https://<service>.up.railway.app` domain.

---

## 3. Android release keystore

Before shipping a signed APK you need a real `.jks` keystore — the one bundled
with Flutter is the **debug** keystore and will be rejected by the Play Store.

```bash
# Generate once, keep safe
keytool -genkey -v \
  -keystore ~/calories-guard-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias calories-guard
```

Create `flutter_application_1/android/key.properties` (**gitignored**):
```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=calories-guard
storeFile=/absolute/path/to/calories-guard-release.jks
```

`android/app/build.gradle.kts` already reads this file for signing config.
Back up the `.jks` **somewhere safe** — losing it means you can't publish
updates under the same app id.

---

## 4. Flutter release build

```bash
cd flutter_application_1
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-railway-url>
```

Distribute via:
- **Firebase App Distribution** (recommended for closed beta).
- Direct APK side-load (`adb install app-release.apk`).
- Play Store internal track — requires bundle id `com.caloriesguard.app` and a proper release keystore (see `android/key.properties`).

---

## 5. Admin web (optional)

Deploy `admin-web/` to Vercel / Netlify / Cloudflare Pages:
```
Build command:   npm run build
Output dir:      dist
Env vars:        VITE_API_BASE_URL=https://<railway-url>
```

> The admin-web attaches `Authorization: Bearer <jwt>` automatically once
> logged in — the `/login` endpoint returns `access_token`, `AuthContext`
> persists it, and `api/client.ts` injects it into every request + signs the
> user out on 401.

---

## 6. Monitoring

- **Sentry** (free 5k events/month): set `SENTRY_DSN` on Railway; add `sentry-sdk[fastapi]` and init in `main.py`.
- **UptimeRobot**: monitor `GET /health` every 5 min.
- **Supabase dashboard**: query performance + auth logs.

---

## 7. Backups

Supabase free tier: automatic daily backups retained for 7 days.
Pro tier: 30-day retention + point-in-time recovery.

---

## 8. CI/CD

GitHub Actions runs on every push/PR (`.github/workflows/ci.yml`):
1. Backend: `ruff check` → `pytest`
2. Flutter: `flutter analyze` → `flutter test`

Railway auto-deploys on merge to `main`.

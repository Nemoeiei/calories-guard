# Deployment Checklist — Calories Guard

เช็คลิสต์ทุกอย่างที่ต้องทำเพื่อให้แอปอยู่บน production
อัปเดต: 2026-04-21

---

## สถานะปัจจุบัน

- ✅ Code พร้อม deploy (branch `claude/jolly-wu` รวม 20 งานปรับปรุงแล้ว)
- ✅ Supabase DB พร้อม (migrations v1-v13 + 239 foods seed + RLS policies)
- ✅ โดเมน `caloriesguard.com` ซื้อแล้วและ parked ที่ Cloudflare
- ⏳ Railway account มีแล้ว (workspace: Sirisak's Projects)
- ❌ ยังไม่ได้ deploy backend
- ❌ ยังไม่ได้ build release APK

---

## 🔴 Blocker ปัจจุบัน

**GitHub App installation** — repo `Nemoeiei/calories-guard` ไม่ขึ้นใน Railway
เพราะ Nemoeiei เป็นเจ้าของ ไม่ใช่ผู้ใช้งาน Railway

### ทางเลือก (เลือก 1)

| Option | วิธี | เวลา | ความเสี่ยง |
|---|---|---|---|
| **A. ขอเจ้าของ install app** | ส่งลิงก์ให้ Nemoeiei install Railway GitHub App | 1 นาที | รอการตอบกลับ |
| **B. Fork เข้า falarame** | `gh repo fork Nemoeiei/calories-guard` | 2 นาที | ต้อง sync กับ upstream เอง |
| **C. ย้าย repo เข้า org ใหม่** | สร้าง GitHub org, transfer repo | 10 นาที | ต้องได้รับอนุญาต Nemoeiei |
| **D. Clone + push ใหม่** | Clone ลง local → สร้าง repo ใหม่ใน falarame → push | 5 นาที | ขาดลิงก์กับ upstream, ไม่มี issue history |

**แนะนำ: Option A** — ส่งข้อความนี้ให้ Nemoeiei:

> พี่ครับ ขอสิทธิ์ให้ Railway อ่าน repo calories-guard หน่อยครับ
> 1. เปิด https://github.com/apps/railway-app/installations/new
> 2. เลือก account **Nemoeiei**
> 3. Only select repositories → ติ๊ก `calories-guard`
> 4. Install
> ใช้เวลาไม่เกิน 1 นาทีครับ

---

## Phase A — Backend บน Railway

### A.1 เตรียมไฟล์ deploy config
- [ ] `backend/Dockerfile` (Python 3.11-slim + gunicorn + uvicorn workers)
- [ ] `backend/.dockerignore` (venv, __pycache__, .env, .git)
- [ ] `backend/railway.json` หรือ `nixpacks.toml` ชี้ start command
- [ ] verify `/health` endpoint ตอบ 200

### A.2 เชื่อม GitHub + deploy
- [ ] แก้ blocker GitHub App ด้านบน
- [ ] Railway → New Project → Deploy from GitHub → เลือก repo
- [ ] Root directory: `backend/`
- [ ] รอ build + deploy ครั้งแรก
- [ ] ได้ URL `xxxxx.up.railway.app`

### A.3 Environment Variables (Railway → Variables)

**Core**
- [ ] `DATABASE_URL` — Supabase connection string + `?sslmode=require`
- [ ] `DB_MODE=supabase`
- [ ] `ENVIRONMENT=production`
- [ ] `PORT=8000` (Railway จะ inject เอง แต่ต้อง bind 0.0.0.0)

**Supabase Auth**
- [ ] `SUPABASE_URL=https://xxx.supabase.co`
- [ ] `SUPABASE_ANON_KEY=...`
- [ ] `SUPABASE_SERVICE_ROLE_KEY=...` ⚠️ secret
- [ ] `SUPABASE_JWT_SECRET=...` (จาก Supabase → Settings → API → JWT Secret)

**AI**
- [ ] `LLM_PROVIDER=ollama`
- [ ] `OLLAMA_BASE_URL=...`
- [ ] `OLLAMA_MODEL=...`

**CORS**
- [ ] `ALLOWED_ORIGINS=https://caloriesguard.com,https://staging.caloriesguard.com`

**Email (ถ้ายังใช้ OTP เอง — ถ้าใช้ Supabase Auth เต็มตัว ข้ามได้)**
- [ ] `SMTP_HOST` `SMTP_PORT` `SMTP_USER` `SMTP_PASS`

**Monitoring (ทีหลังได้)**
- [ ] `SENTRY_DSN=...`

### A.4 Health check
- [ ] `curl https://xxxxx.up.railway.app/health` → 200
- [ ] `curl https://xxxxx.up.railway.app/foods?q=ข้าว` → array มีข้อมูล
- [ ] เช็ค logs ใน Railway ไม่มี error

---

## Phase B — Domain + DNS (Cloudflare)

### B.1 Privacy/Terms บน Cloudflare Pages (root domain)

**หลีกเลี่ยงการแก้ CNAME root เอง — ให้ Pages ตั้งให้**

- [ ] Cloudflare Dashboard → **Workers & Pages** → Create → Pages tab
- [ ] Connect to Git → authorize GitHub → เลือก repo
- [ ] Build settings:
  - Framework: None
  - Build command: (เว้นว่าง)
  - Build output: `docs`
- [ ] Deploy → ได้ URL `xxx.pages.dev`
- [ ] เข้า Pages project → **Custom domains** → Set up → `caloriesguard.com`
- [ ] Cloudflare เพิ่ม DNS record ให้อัตโนมัติ
- [ ] ทำซ้ำสำหรับ `www.caloriesguard.com`

### B.2 API subdomain → Railway

หลังจาก Railway deploy เสร็จและได้ URL แล้ว:

- [ ] Cloudflare DNS tab → Add record
  - Type: `CNAME`
  - Name: `api`
  - Target: `xxxxx.up.railway.app`
  - Proxy: **DNS only** (สีเทา — ห้าม proxied ไม่งั้น SSL รวน)
- [ ] ทำซ้ำสำหรับ `staging` → staging Railway URL
- [ ] Railway service → Settings → Networking → Custom Domain → `api.caloriesguard.com`
- [ ] รอ SSL cert provisioning (~2-5 นาที)
- [ ] `curl https://api.caloriesguard.com/health` → 200

---

## Phase C — Supabase Auth Config

### C.1 Site URL + Redirects
- [ ] Supabase → Authentication → URL Configuration
- [ ] Site URL: `https://caloriesguard.com`
- [ ] Redirect URLs:
  - `https://caloriesguard.com/**`
  - `com.caloriesguard.app://login-callback/**` (deep link มือถือ)

### C.2 Email templates
- [ ] Authentication → Email Templates
- [ ] แก้ "Confirm signup", "Magic Link", "Reset Password" เปลี่ยนชื่อเป็น Calories Guard + ภาษาไทย

### C.3 Social login providers

**Google**
- [ ] Google Cloud Console → APIs & Services → Credentials
- [ ] Create OAuth 2.0 Client ID (type: Web application)
- [ ] Authorized redirect URI: `https://<supabase-project>.supabase.co/auth/v1/callback`
- [ ] Copy client_id + secret → ใส่ Supabase → Authentication → Providers → Google

**Facebook**
- [ ] developers.facebook.com → Create App → Consumer
- [ ] Add Facebook Login product
- [ ] Valid OAuth Redirect URI: `https://<supabase-project>.supabase.co/auth/v1/callback`
- [ ] Copy App ID + App Secret → ใส่ Supabase → Providers → Facebook

---

## Phase D — Flutter Release Build

### D.1 Release keystore (ครั้งเดียวพอ)
- [ ] ตามคู่มือใน `docs/RELEASE_KEYSTORE.md`
- [ ] สร้าง `release.jks` ด้วย `keytool -genkey`
- [ ] สร้าง `android/key.properties` (gitignored)
- [ ] **สำรอง keystore นอก repo** — หายแล้วต้องสร้าง app ใหม่บน Play Store

### D.2 Android config
- [ ] `android/app/build.gradle.kts` — applicationId = `com.caloriesguard.app`
- [ ] `android/app/src/main/AndroidManifest.xml` — มี INTERNET permission
- [ ] signingConfigs ชี้ `key.properties`

### D.3 iOS config (ถ้าจะทำ)
- [ ] `ios/Runner/Info.plist` — NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSPhotoLibraryUsageDescription
- [ ] Bundle identifier: `com.caloriesguard.app`
- [ ] Apple Developer account ($99/ปี) — ข้ามไปก่อนรอบ closed beta

### D.4 Build
- [ ] `flutter pub get`
- [ ] `flutter analyze` → 0 warnings
- [ ] `flutter build apk --release --dart-define=API_BASE_URL=https://api.caloriesguard.com`
- [ ] ตรวจขนาด APK < 60 MB
- [ ] ติดตั้งบนเครื่องจริง → login + บันทึกอาหาร + AI chat ทำงาน

---

## Phase E — Distribution

### E.1 Firebase App Distribution (แจก APK closed beta)
- [ ] Firebase Console → App Distribution
- [ ] Upload APK → add release notes
- [ ] Create tester group → เพิ่มอีเมลเพื่อน 3-5 คน
- [ ] Testers ได้ email พร้อมลิงก์ติดตั้ง

### E.2 Play Store (รอบถัดไป — optional)
- [ ] Google Play Console account ($25 once)
- [ ] Internal testing track ก่อน
- [ ] รอ review 1-3 วัน

---

## Phase F — Monitoring & Observability

### F.1 Sentry (error tracking)
- [ ] sentry.io → free tier
- [ ] Create 2 projects:
  - `calories-guard-backend` (Python)
  - `calories-guard-flutter` (Dart)
- [ ] Backend DSN → Railway env `SENTRY_DSN`
- [ ] Flutter DSN → `--dart-define=SENTRY_DSN=...` ตอน build
- [ ] ทดสอบ: trigger test error → ดู event ใน Sentry

### F.2 UptimeRobot (uptime ping)
- [ ] uptimerobot.com → free tier
- [ ] Add monitor: `https://api.caloriesguard.com/health` ทุก 5 นาที
- [ ] Alert contact: email + LINE Notify (ถ้ามี)

### F.3 Railway built-in metrics
- [ ] Railway dashboard → Metrics — ดู CPU/RAM/Network ตามปกติ ไม่ต้องตั้งเพิ่ม

---

## Phase G — CI/CD

### G.1 GitHub Actions
- [ ] `.github/workflows/ci.yml`:
  - Backend: `ruff check` + `pytest`
  - Flutter: `flutter analyze` + `flutter test`
  - Trigger: ทุก PR + push main
- [ ] `.github/workflows/synthetic.yml` (มีแล้ว) — รันทุก 15 นาทีหลัง deploy
- [ ] Railway auto-deploy from main (on by default ถ้าเชื่อม GitHub)

### G.2 Branch protection
- [ ] GitHub → Settings → Branches → Protect `main`
- [ ] Require PR review + status checks pass

---

## Phase H — Legal & Compliance

- [ ] Privacy policy publish ที่ `caloriesguard.com/privacy` (ผ่าน Pages)
- [ ] Terms of service publish ที่ `caloriesguard.com/terms`
- [ ] เพิ่มลิงก์ทั้งสองในแอป: หน้า Profile/Settings → "นโยบายความเป็นส่วนตัว" / "ข้อตกลง"
- [ ] PDPA consent checkbox ที่หน้าสมัครสมาชิก (มีใน v12 migration แล้ว — verify UI)

---

## ลำดับทำจริง (estimate 4-5 วัน)

```
Day 1 (Blocker day):
  ✅ แก้ GitHub App access (Nemoeiei)
  ✅ A.1 Dockerfile + railway.json
  ✅ A.3 Env vars เตรียมใน .env.production.example

Day 2 (Deploy day):
  ✅ A.2 Railway deploy
  ✅ A.4 Health check
  ✅ B.1 Cloudflare Pages (privacy/terms)
  ✅ B.2 api.caloriesguard.com → Railway

Day 3 (Auth day):
  ✅ C.1-C.3 Supabase Auth config + social providers
  ✅ ทดสอบ flow login จริงผ่าน Postman/curl

Day 4 (App day):
  ✅ D.1-D.4 Build release APK
  ✅ ติดตั้งบนเครื่องจริง + smoke test
  ✅ E.1 Firebase App Distribution แจก 3 คนก่อน

Day 5 (Polish):
  ✅ F.1-F.2 Sentry + UptimeRobot
  ✅ G.1 CI workflow
  ✅ H legal links
  ✅ เก็บ feedback จาก testers
```

---

## Verification checklist (ก่อนแจก beta จริง)

- [ ] `curl https://api.caloriesguard.com/health` → 200
- [ ] `curl https://api.caloriesguard.com/users/1` ไม่มี token → 401
- [ ] `curl -H "Authorization: Bearer <token>"` → ได้ข้อมูล
- [ ] Login ผิด 6 ครั้ง → 429
- [ ] Upload ไฟล์ 10 MB → 413
- [ ] ไม่มี traceback leak ใน response
- [ ] Sentry จับ error test ได้
- [ ] UptimeRobot ping ได้ 100% เป็นเวลา 24 ชม.
- [ ] APK ติดตั้งบนเครื่อง Android 10+ ทำงานครบ flow
- [ ] Social login (Google) ทำงาน
- [ ] AI chat ตอบได้และ rate limit ทำงาน
- [ ] Privacy/Terms โหลดได้ที่ `caloriesguard.com/privacy`

---

## ค่าใช้จ่าย (monthly estimate)

| Service | Tier | Cost |
|---|---|---|
| Railway | Hobby ($5 trial → Pro $20) | $0-20 |
| Supabase | Free (500 MB DB, 1 GB storage) | $0 |
| Cloudflare | Free (DNS + Pages) | $0 |
| Sentry | Developer (5K errors) | $0 |
| UptimeRobot | Free (50 monitors) | $0 |
| Ollama host | Self-hosted CPU/GPU/RAM cost | depends on server |
| Firebase App Distribution | Free | $0 |
| Domain | caloriesguard.com | ~$10/year |
| **รวม** | | **~$10-40/เดือน** |

---

## Reference docs ในโปรเจกต์

- `docs/DEPLOYMENT.md` — รายละเอียด technical deploy
- `docs/STAGING.md` — staging environment setup
- `docs/MONITORING.md` — Sentry + observability setup
- `docs/RELEASE_KEYSTORE.md` — สร้าง Android keystore
- `docs/SYNTHETIC_CHECK.md` — synthetic monitoring
- `docs/PRODUCTION_READINESS.md` — pre-launch gates
- `backend/scripts/loadtest/README.md` — k6 load testing

---

## ช่วยเหลือ / Stuck ที่ไหน?

ถ้าติดตรงไหน ส่ง screenshot + error message มา จะช่วยแก้เป็นขั้นๆ

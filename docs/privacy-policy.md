# Privacy Policy — Calories Guard

**Effective date:** 2026-04-19
**Last updated:** 2026-04-19

> This is a draft for closed beta. It describes current practice honestly
> and points to the endpoints that give users control. Hosted version goes
> up at `https://calories-guard.pages.dev/privacy` once DNS is wired.
> DPA / Play Store language is not added here — that pass happens before
> public store listing.

---

## 1. Who we are

Calories Guard ("we", "the app") is a Thai senior-project health-tracking
application that helps users log meals, water, exercise, and weight, and
provides AI-generated dietary coaching. The service is operated by the
project team and is currently in **closed beta** — availability, data
retention, and features may change without prior notice to testers.

**Contact:** `privacy@calories-guard.example` *(placeholder — replace with
real support inbox before first public invite)*

---

## 2. What we collect

### 2.1 You give us directly

| Category | Examples | Why |
|---|---|---|
| Account identity | Email, password hash (via Supabase Auth), display name | Log in, address you in the app |
| Profile | Age, gender, height, weight, goal (lose / maintain / gain), activity level | Calculate TDEE and macro targets |
| Health logs | Meals (food name, portion, calories, macros), water intake, exercise, weight history | Core product function |
| Allergies & preferences | Selected allergen tags, food dislikes | Avoid recommending foods that would harm you |
| Chat history with AI Coach | Free-text prompts sent to `/api/chat/*` | So the coach can reference earlier context |

### 2.2 Collected automatically

| Category | Examples | Why |
|---|---|---|
| Device location (optional) | GPS coordinates while the restaurant map is open | Show nearby restaurants on the Thai-food map |
| Crash & error data | Stack traces, breadcrumb navigation, device model, OS version | Diagnose bugs (Sentry) |
| Usage telemetry | Request latency, endpoint names, HTTP status — **no request bodies** | SLO dashboards |

We do **not** collect: contacts, SMS, call logs, microphone, clipboard,
advertising ID.

---

## 3. Who we share with (sub-processors)

| Processor | Role | Region | What they see |
|---|---|---|---|
| **Supabase** | Database, auth, file storage | US-East (primary) | Everything in §2.1 |
| **DeepSeek API or configured LLM provider** | AI coaching & nutrition estimation | Provider region depends on deployment settings | Your chat prompts + meal text. **No email, no profile** — we pass only the message body. |
| **Firebase Cloud Messaging** | Meal-time push notifications | Google Cloud | Device FCM token |
| **Sentry** | Error & performance monitoring | EU/US | Stack traces, user ID hash, endpoint. **We set `sendDefaultPii = false`.** |
| **Railway** | Backend hosting | US-West | Runtime logs (no PII by policy; see `docs/MONITORING.md`) |
| **UptimeRobot** | Uptime probes on `/health` | Various | Public health endpoint only |

We do not sell personal data, and we do not share it with advertisers.

---

## 4. Legal basis & PDPA (Thailand)

Processing is based on:

- **Consent** — you tap "Agree" on the data-consent screen at registration.
  The timestamp is stored as `users.consent_accepted_at`.
- **Contract necessity** — we can't run the coaching product without your
  meal logs.
- **Legitimate interest** — error monitoring, abuse prevention.

Under the Thai Personal Data Protection Act (PDPA, 2019) you have the
following rights. We honour them via the following endpoints:

| Right | How to exercise |
|---|---|
| **Access / portability** (Art. 30) | In-app "Download my data" → calls `GET /users/{id}/export`. You receive a JSON file with every row we hold. |
| **Deletion** (Art. 33) | In-app "Delete account" → calls `DELETE /users/{id}`. Soft-delete immediately; hard-delete plus full cascade after 30 days (see §5). |
| **Correction** (Art. 36) | Edit in-app, or email `privacy@calories-guard.example`. |
| **Withdraw consent** | Delete account (above). We don't retain anonymised behavioural profiles post-delete. |
| **Complaint** | You may complain to the PDPA Committee (pdpc.or.th). |

Both endpoints require your Supabase access token — no one else can export
or delete your data.

---

## 5. Retention

- **Active account:** data is kept as long as you use the app.
- **Deleted account:** soft-deleted immediately — you can no longer log in
  and the app treats you as gone. Data is kept for **30 days** in case of
  accidental deletion, then **hard-deleted** including cascade to meals,
  water/exercise/weight logs, chat history, notifications, and uploaded
  images. This runs daily as `backend/scripts/cleanup.py`.
- **Crash data (Sentry):** 30 days (Sentry default), then purged.
- **Backups:** Supabase automated backups retain for 7 days on the free
  tier. Deleted rows disappear from backups within this window.

---

## 6. Security

- Transport: TLS 1.2+ end-to-end (Railway + Supabase both enforce HTTPS).
- Passwords: hashed by Supabase Auth (bcrypt). We never see the plaintext.
- Access control: row-level security (RLS) policies restrict reads/writes
  so one user cannot see another's data — enforced both at the API layer
  (FastAPI `get_current_user` dependency) and at the database (see
  migration `v14_rls_policies.sql`).
- Secrets: backend secrets live in Railway environment variables, never in
  git. Client secrets use `--dart-define` at build time.
- API versioning: clients on an incompatible major version receive a
  "please update" prompt so stale builds can't silently corrupt data
  (see `docs/CHANGELOG_API.md`).

No system is perfectly secure. If we discover a breach that affects your
data, we will notify affected users and the PDPA Committee within 72 hours
as required by law.

---

## 7. Children

The app is **not intended for users under 13.** Onboarding requires age
input; accounts with age < 13 are rejected at registration. If we become
aware that an underage account slipped through, we will delete it.

---

## 8. International transfers

Supabase hosts in US-East and Google/Sentry are multi-region. Transferring
your data outside Thailand is a cross-border transfer under PDPA §28; by
accepting this policy you consent to that transfer. We pick providers that
hold recognised standards (SOC 2 / ISO 27001) but we do not currently have
standard contractual clauses specific to PDPA — this gap is tracked as a
pre-launch item before moving from closed beta to public launch.

---

## 9. Changes

We will update this page and bump the "Last updated" date at the top. For
material changes affecting how we use your data, we'll also show an
in-app prompt the next time you open the app.

---

## 10. Contact

- Privacy questions: `privacy@calories-guard.example`
- Security reports: `security@calories-guard.example`
- General support: in-app "Help" screen

*These are placeholder addresses. Replace with monitored inboxes before
the first public invite and before a Play Store listing goes live.*

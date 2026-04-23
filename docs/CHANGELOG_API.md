# API Changelog — Calories Guard

This file tracks the contract between the FastAPI backend and the Flutter
client (`flutter_application_1/`) + admin-web. Format is `YYYY.MM`.

## Versioning rules

- **Bump the version** only on a *breaking* change — a field removed, an
  endpoint renamed/removed, a required field added to a request body, or
  a response shape change that older clients can't parse.
- **Do NOT bump** for additive changes (new optional field, new endpoint,
  new enum value handled by existing clients).
- When the major segment (year) differs between server and client, the
  Flutter client flips `ApiClient.isUpgradeRequired = true` and fires
  `onUpgradeRequired`, which should surface a non-dismissable modal.

## Wire format

- Every response carries `X-Api-Version: <version>`.
- `GET /health` returns `{"status":"ok","api_version":"<version>"}`.
- Client tracks its expectation in
  `flutter_application_1/lib/constants/constants.dart` →
  `AppConstants.kExpectedApiVersion`.

Bump server `backend/app/core/config.py` → `API_VERSION` **and** Flutter
`kExpectedApiVersion` in the same PR that ships the breaking change.

---

## Versions

### 2026.04 — current

Baseline for the signed-APK beta. Contract covers:

- Supabase-Auth JWT on `Authorization: Bearer` (backend verifies against
  `SUPABASE_JWT_SECRET`).
- CRUD under `/users`, `/foods`, `/meals`, `/admin/*`, `/weight`,
  `/water`, `/exercise`.
- AI endpoints: `/api/chat/coach`, `/api/meals/estimate`,
  `/api/chat/multi` — all gated by `AI_ENABLED` env flag (503 when off).
- Image upload at `/upload-image/` (5 MB cap, JPEG/PNG/WebP/GIF).
- Schema: `cleangoal.` prefix in Supabase, RLS enabled on all user tables
  (deny-all until Supabase-Auth migration lands end-to-end).

### Template for the next bump

```
### YYYY.MM — <short name>

Breaking:
- <endpoint> — <what changed>. Migration: <what clients must do>.

Additive (no bump needed, listed for context):
- <endpoint> — <what's new>.
```

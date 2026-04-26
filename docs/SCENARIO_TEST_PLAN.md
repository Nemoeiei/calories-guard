# Calories Guard — Scenario Test Plan

> Scenario tests validate real user/admin situations end-to-end. Use this file as both a plan and a test execution log.

## Scenario Result Template

Copy this block for every manual scenario run:

```text
Scenario ID:
Date / Time:
Tester:
Environment: local / staging / production
Backend URL:
Admin URL:
App build:
Commit SHA:
Test data used:
Result: PASS / FAIL / BLOCKED / SKIP
Evidence: screenshot / log / DB query / Sentry issue
Notes:
Follow-up issue:
```

## Scenario Index

| Scenario ID | Scenario | Priority | Primary Risk |
|---|---|---|---|
| SCN-001 | New user onboarding and first meal | P0 | Core user flow |
| SCN-002 | Regional Thai food search and display | P0 | Regional feature |
| SCN-003 | AI unknown food to admin approval | P0 | AI + moderation |
| SCN-004 | User submits regional name to admin approval | P0 | Crowdsource flow |
| SCN-005 | Admin reviews both queues | P0 | Admin operations |
| SCN-006 | Meal edit/delete recalculates summary | P0 | Data correctness |
| SCN-007 | DeepSeek outage / AI disabled | P0 | Graceful failure |
| SCN-008 | PDPA export and soft delete | P0 | Privacy/legal |
| SCN-009 | Cross-platform web/PWA smoke | P1 | Compatibility |
| SCN-010 | Security and cross-user access | P1 | Data leakage |
| SCN-011 | Migration and rollback rehearsal | P1 | Release safety |
| SCN-012 | Performance smoke under load | P1 | Reliability |

## SCN-001 — New User Onboarding And First Meal

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | Guest, User |
| Preconditions | Backend deployed, Supabase available |
| Test Data | New email not already registered |

Steps:
1. Open Flutter web/PWA or Android app.
2. Register a new account.
3. Complete profile: gender, birth date, height, weight, goal, activity.
4. Login if not already logged in.
5. Search food by canonical name, for example `ข้าวผัด`.
6. Add item to breakfast.
7. Open home/progress.

Expected:
- User is created.
- Target calories/macros are calculated.
- Food search returns results.
- Meal is saved.
- Daily summary updates calories/macros.
- No unhandled Sentry error.

DB Checks:
```sql
SELECT * FROM cleangoal.users WHERE email = '<email>';
SELECT * FROM cleangoal.meals WHERE user_id = <user_id> ORDER BY created_at DESC;
SELECT * FROM cleangoal.daily_summaries WHERE user_id = <user_id> ORDER BY date_record DESC;
```

## SCN-002 — Regional Thai Food Search And Display

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User |
| Preconditions | v20 migration applied, aliases seeded |
| Test Data | User region `northeastern`, query `ข้าวปุ้น` |

Steps:
1. Login as User A.
2. Open settings.
3. Set food region to `ภาคอีสาน`.
4. Search `ข้าวปุ้น`.
5. Search canonical `ขนมจีน`.
6. Open recipe/detail card for matching food.

Expected:
- Search by alias returns canonical food.
- Cards/details prefer `display_name` when primary alias exists.
- Fallback still uses `food_name` when no alias exists.

API Checks:
```text
GET /foods/search?q=ข้าวปุ้น&user_id=<user_id>
GET /foods?user_id=<user_id>
GET /recipes/<food_id>?user_id=<user_id>
```

DB Checks:
```sql
SELECT f.food_name, frn.region, frn.name_th, frn.is_primary
FROM cleangoal.food_regional_names frn
JOIN cleangoal.foods f ON f.food_id = frn.food_id
WHERE frn.name_th = 'ข้าวปุ้น';
```

## SCN-003 — AI Unknown Food To Admin Approval

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User, DeepSeek, Admin |
| Preconditions | `AI_ENABLED=true`, `LLM_PROVIDER=deepseek`, admin account exists |
| Test Data | Unknown food-like name, e.g. `โรตีชีสภูเขาไฟ` |

Steps:
1. Login as User A.
2. Open AI meal estimate.
3. Enter `กินโรตีชีสภูเขาไฟ 1 จาน`.
4. Confirm estimate result is shown.
5. Login to admin-web.
6. Open `คำขอเพิ่มเมนู`.
7. Approve the temp food with reviewed macros/unit/category.
8. Return to user app and search the approved food.

Expected:
- DeepSeek extracts unknown food name.
- Backend returns estimated calories/macros.
- One pending row appears in `temp_food`.
- Admin can approve.
- Approved food appears in `/foods` search.
- Repeating the same estimate does not create duplicate pending rows.

DB Checks:
```sql
SELECT * FROM cleangoal.temp_food
WHERE lower(food_name) = lower('โรตีชีสภูเขาไฟ')
ORDER BY created_at DESC;

SELECT * FROM cleangoal.foods
WHERE lower(food_name) = lower('โรตีชีสภูเขาไฟ');
```

## SCN-004 — User Submits Regional Name To Admin Approval

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User, Admin |
| Preconditions | Food exists, user logged in |
| Test Data | Existing food + local alias |

Steps:
1. User opens food detail.
2. User submits regional alias with region and optional popularity.
3. Admin opens `ชื่อท้องถิ่น`.
4. Admin approves as primary and sets popularity.
5. User sets matching region.
6. User searches canonical and alias.

Expected:
- Submission row created in `food_regional_name_submissions`.
- Admin approval creates/updates `food_regional_names`.
- Popularity upserts in `food_regional_popularity`.
- Search/display use approved alias.

DB Checks:
```sql
SELECT * FROM cleangoal.food_regional_name_submissions
WHERE name_th = '<alias>';

SELECT * FROM cleangoal.food_regional_names
WHERE name_th = '<alias>' AND deleted_at IS NULL;
```

## SCN-005 — Admin Reviews Both Queues

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | Admin |
| Preconditions | At least one pending `temp_food` and one pending regional submission |

Steps:
1. Login admin-web.
2. Open dashboard.
3. Verify pending counts.
4. Open `คำขอเพิ่มเมนู`.
5. Approve one and reject one if available.
6. Open `ชื่อท้องถิ่น`.
7. Approve one and reject one if available.
8. Refresh deep links directly.

Expected:
- Counts update.
- Actions persist.
- Deep links do not 404.
- Non-admin cannot access.

## SCN-006 — Meal Edit/Delete Recalculates Summary

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User |

Steps:
1. Add two foods to lunch.
2. Check daily total.
3. Delete one item.
4. Edit remaining amount if UI supports it.
5. Reopen app.

Expected:
- `detail_items` and `daily_summaries` stay consistent.
- No stale macro totals.
- No duplicate rows after network retry.

## SCN-007 — DeepSeek Outage / AI Disabled

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User, Operator |

Steps:
1. On staging, set `AI_ENABLED=false`.
2. Call chat and meal estimate.
3. Restore `AI_ENABLED=true`.
4. Temporarily use invalid `DEEPSEEK_API_KEY` on staging.
5. Call AI endpoints again.

Expected:
- Disabled state returns 503 friendly response.
- Bad provider state returns graceful 502/503/504.
- Backend does not crash.
- Sentry/logs capture signal.

## SCN-008 — PDPA Export And Soft Delete

| Field | Value |
|---|---|
| Priority | P0 |
| Actors | User |

Steps:
1. Login as User A.
2. Create meal, temp food submission, regional name submission.
3. Export own data.
4. Try exporting User B data.
5. Soft delete own account.

Expected:
- Own export downloads JSON.
- Export includes `temp_food` and `food_regional_name_submissions`.
- Cross-user export blocked.
- Soft delete sets `deleted_at`.

## SCN-009 — Cross-Platform Web/PWA Smoke

| Field | Value |
|---|---|
| Priority | P1 |
| Actors | User |

Matrix:

| Platform | Browser / OS | Checks | Result |
|---|---|---|---|
| Desktop web | Chrome latest | login, search, meal, AI estimate | |
| Desktop web | Edge latest | login, search, meal | |
| Mobile web | iPhone Safari | login, PWA Add to Home Screen, search | |
| Mobile web | Android Chrome | login, PWA install, meal | |
| Android app | Emulator API 30+ | login, meal, progress | |
| Android app | Physical device | notifications, performance, meal | |

Expected:
- No layout overflow.
- Thai text readable.
- Network errors are recoverable.
- API URL points to deployed backend.

## SCN-010 — Security And Cross-User Access

| Field | Value |
|---|---|
| Priority | P1 |
| Actors | User A, User B, Admin |

Steps:
1. User A token calls User B protected endpoints.
2. Non-admin token calls admin endpoints.
3. Anonymous calls protected endpoints.
4. Inspect frontend bundles for secrets.
5. Try XSS-like regional name or food name in staging.

Expected:
- 401/403 for unauthorized access.
- No service role or DeepSeek key in frontend.
- User-generated text is displayed safely.

## SCN-011 — Migration And Rollback Rehearsal

| Field | Value |
|---|---|
| Priority | P1 |
| Actors | Operator |

Steps:
1. Dump staging DB.
2. Restore dump to local/staging clone.
3. Apply pending migrations.
4. Verify schema/data integrity.
5. Practice restoring previous dump.

Expected:
- Backup file is restorable.
- Migrations are repeatable where designed.
- Rollback instructions are actionable.

## SCN-012 — Performance Smoke Under Load

| Field | Value |
|---|---|
| Priority | P1 |
| Actors | Operator |

Steps:
1. Run food search load test on staging.
2. Run meal loop load test on staging.
3. Run limited AI chat/estimate load test.
4. Watch Railway/Render, Supabase, Sentry.

Expected:
- No backend restarts.
- DB pool not saturated.
- Rate limits protect AI endpoints.
- Errors below release threshold.

## Scenario Execution Summary

| Scenario ID | Last Run | Environment | Result | Owner | Follow-Up |
|---|---|---|---|---|---|
| SCN-001 | | | | | |
| SCN-002 | | | | | |
| SCN-003 | | | | | |
| SCN-004 | | | | | |
| SCN-005 | | | | | |
| SCN-006 | | | | | |
| SCN-007 | | | | | |
| SCN-008 | | | | | |
| SCN-009 | | | | | |
| SCN-010 | | | | | |
| SCN-011 | | | | | |
| SCN-012 | | | | | |

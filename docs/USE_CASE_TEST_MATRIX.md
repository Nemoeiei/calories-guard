# Calories Guard — Use Case Test Matrix

> Use this file to track functional and acceptance tests by use case.
> Fill `Result` with `PASS`, `FAIL`, `BLOCKED`, `SKIP`, or `N/A`.

## Test Accounts

| Role | Email | Notes |
|---|---|---|
| User A | `user-a@example.test` | Region: northeastern |
| User B | `user-b@example.test` | Region: northern |
| Admin | `admin@example.test` | `role_id=1` |

Do not commit real passwords. Store test credentials in a secure password manager or CI secret store.

## User App Use Case Tests

| Test ID | Use Case | Preconditions | Steps | Expected Result | Result | Evidence |
|---|---|---|---|---|---|---|
| UCT-U01 | Register | No existing account | Register with valid email/password/profile | User exists, can login, target calories calculated | | |
| UCT-U02 | Login | Existing user | Login with valid credentials | App enters main screen, token stored | | |
| UCT-U03 | Login failure | Existing user | Login wrong password | Clear error, no session | | |
| UCT-U04 | Profile update | Logged in | Edit weight/goal/activity | API 200, UI reflects new data | | |
| UCT-U05 | Set region | Logged in | Settings -> Food region -> northeastern | `users.region=northeastern`, UI label changes | | |
| UCT-U06 | Canonical search | Foods seeded | Search `ขนมจีน` | Results include canonical food | | |
| UCT-U07 | Regional search | Regional aliases seeded | Search `ข้าวปุ้น` | Canonical food returned with regional alias context | | |
| UCT-U08 | Regional display | User region northeastern | Open food list / recipe | `display_name` shows regional primary if available | | |
| UCT-U09 | Log breakfast | Logged in | Add known food to breakfast | `meals/detail_items` created, daily summary updated | | |
| UCT-U10 | Log all meal slots | Logged in | Add lunch/dinner/snack | Correct meal type and totals | | |
| UCT-U11 | Delete meal item | Existing meal | Delete item | Item removed, summary recalculated | | |
| UCT-U12 | Allergy warning | User allergy set | Add/search food with allergy flag | Warning visible, no silent risk | | |
| UCT-U13 | AI estimate known food | AI enabled | Enter `กินข้าวปุ้น 1 จาน` | Uses DB/regional match, no duplicate temp food | | |
| UCT-U14 | AI estimate unknown food | AI enabled | Enter fake but food-like dish | Returns estimate and queues `temp_food` | | |
| UCT-U15 | AI disabled | `AI_ENABLED=false` | Call meal estimate/chat | 503 friendly path | | |
| UCT-U16 | Recipe first load | Food has no recipe | Open recipe detail | Recipe generated/cached or graceful retryable error | | |
| UCT-U17 | Recipe cached load | Recipe exists | Open same recipe again | DB row returned, no extra generation expected | | |
| UCT-U18 | Progress screen | Meals logged | Open progress | Charts/totals display without overflow | | |
| UCT-U19 | PDPA export | Logged in | Export own data | JSON includes user-owned tables and regional submissions | | |
| UCT-U20 | Soft delete | Logged in | Delete account | `deleted_at` set; access blocked as designed | | |

## Admin Web Use Case Tests

| Test ID | Use Case | Preconditions | Steps | Expected Result | Result | Evidence |
|---|---|---|---|---|---|---|
| UCT-A01 | Admin login | Admin user exists | Login to admin-web | Dashboard visible | | |
| UCT-A02 | Non-admin block | Non-admin user exists | Login/open admin route | Access denied or redirected | | |
| UCT-A03 | Dashboard counts | Pending queues exist | Open dashboard | Counts match `temp_food` + regional submissions | | |
| UCT-A04 | Temp food list | Pending temp row exists | Open `/food-requests` | Row visible | | |
| UCT-A05 | Approve temp food | Pending temp row exists | Approve with macros/unit/category | Food created, request verified/removed from pending | | |
| UCT-A06 | Reject temp food | Pending temp row exists | Reject | No catalog food created, pending removed | | |
| UCT-A07 | Food edit | Existing food | Edit name/macros/image | Persisted and visible to app/API | | |
| UCT-A08 | Regional list | Pending regional submission | Open `/regional-names` | Row visible with food/region/requester | | |
| UCT-A09 | Approve regional | Pending regional submission | Select primary/popularity and approve | Alias inserted, popularity upserted, status approved | | |
| UCT-A10 | Reject regional | Pending regional submission | Reject | Status rejected, no alias inserted | | |
| UCT-A11 | Deep link refresh | Deployed static site | Refresh `/regional-names` | SPA loads, no 404 | | |
| UCT-A12 | Admin auth on API | No token | Call admin endpoints | 401/403, no data leak | | |

## Backend / API Use Case Tests

| Test ID | Endpoint | Steps | Expected Result | Result | Evidence |
|---|---|---|---|---|---|
| UCT-B01 | `GET /health` | Request without token | 200, status ok, `X-Api-Version` | | |
| UCT-B02 | `GET /foods` | Request public list | Array, includes `display_name` fallback | | |
| UCT-B03 | `GET /foods/search?q=ข้าวปุ้น` | Search regional alias | Canonical food appears | | |
| UCT-B04 | `PUT /users/{id}/region` | Auth user updates own region | 200, `region_source=manual` | | |
| UCT-B05 | `POST /api/meals/estimate` | Known regional alias | DB-backed estimate | | |
| UCT-B06 | `POST /api/meals/estimate` | Unknown dish | LLM estimate + temp queue | | |
| UCT-B07 | `GET /admin/regional-name-submissions` | Admin token | Pending list | | |
| UCT-B08 | `POST /admin/regional-name-submissions/{id}/approve` | Admin token | Alias created | | |
| UCT-B09 | `POST /admin/temp-foods/{id}/approve` | Admin token | Food promoted | | |
| UCT-B10 | Protected route no token | No auth | 401/403 | | |

## Database Use Case Tests

| Test ID | Area | SQL / Check | Expected Result | Result | Evidence |
|---|---|---|---|---|---|
| UCT-D01 | Migrations | `schema_migrations` includes v20/v21/v22/v24 | All present | | |
| UCT-D02 | Legacy columns | Check `foods.food_category`, `foods.serving_unit` | Columns absent | | |
| UCT-D03 | Legacy tables | `to_regclass` old tables | Old tables absent, archives present | | |
| UCT-D04 | FK coverage | `foods WHERE dish_id/serving_unit_id IS NULL` | 0 rows | | |
| UCT-D05 | Regional primary | Duplicate primary per food/region | 0 duplicates | | |
| UCT-D06 | Cache sync | Update food macros | Existing detail cache updates | | |
| UCT-D07 | Audit timestamps | Update detail/summary/exercise/meal | `updated_at` changes | | |
| UCT-D08 | Orphans | temp/regional/user-owned FKs | 0 orphan rows | | |

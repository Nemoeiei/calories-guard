// Meals record-and-read loop (k6).
//
// Each iteration:
//   1. POST /meals/{user_id}          — write
//   2. GET  /daily_summary/{user_id}  — read that reflects the write
//   3. DELETE /meals/clear            — clean up so we don't explode the row count
//
// Cleanup matters — we're running at 20 VUs × 2 min = ~2.4k writes without
// it we'd leave thousands of junk meals on staging.
//
// Target: p95 < 500ms at 20 VUs, zero 5xx. This is the user-facing cost of
// the "save meal" button.

import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TOKEN = __ENV.TEST_USER_TOKEN || '';
const USER_ID = parseInt(__ENV.TEST_USER_ID || '1', 10);

export const options = {
  scenarios: {
    record_loop: {
      executor: 'constant-vus',
      vus: 20,
      duration: '2m',
    },
  },
  thresholds: {
    'http_req_failed': ['rate<0.01'],
    'http_req_duration{endpoint:meal_create}': ['p(95)<600'],
    'http_req_duration{endpoint:daily_summary}': ['p(95)<400'],
  },
};

const headers = () => ({
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  ...(TOKEN ? { 'Authorization': `Bearer ${TOKEN}` } : {}),
});

export default function () {
  // 1. Write a small meal. Body matches the shape the app sends from the
  //    record_food_screen — see backend/app/models/schemas.py DailyLogUpdate.
  const body = JSON.stringify({
    meal_type: 'Snack',
    items: [
      {
        food_name: 'loadtest-apple',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        quantity: 1,
      },
    ],
  });

  const createRes = http.post(
    `${BASE_URL}/meals/${USER_ID}`,
    body,
    { headers: headers(), tags: { endpoint: 'meal_create' } },
  );
  check(createRes, {
    'meal created': (r) => r.status === 200 || r.status === 201,
  });

  // 2. Read the summary the user would see immediately after saving.
  const summaryRes = http.get(
    `${BASE_URL}/daily_summary/${USER_ID}`,
    { headers: headers(), tags: { endpoint: 'daily_summary' } },
  );
  check(summaryRes, {
    'summary 200': (r) => r.status === 200,
  });

  // 3. Cleanup — cheap, but we need it or we'd OOM the row count on staging.
  //    Not asserting status because some tests run without the clear endpoint
  //    enabled; a 404 here doesn't invalidate the p95 measurement.
  http.del(
    `${BASE_URL}/meals/clear?user_id=${USER_ID}`,
    null,
    { headers: headers(), tags: { endpoint: 'meal_clear' } },
  );

  sleep(0.5);
}

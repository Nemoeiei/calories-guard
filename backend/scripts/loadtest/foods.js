// Foods search load test (k6).
//
// Target: 50 VUs × 2 min against /foods?q=<thai-word>. This is the busiest
// read endpoint — every keystroke on the record-food screen hits it.
//
// Run:
//   BASE_URL=https://staging.calories-guard.app \
//   TEST_USER_TOKEN=<jwt> \
//   k6 run backend/scripts/loadtest/foods.js
//
// Threshold enforces p95 < 500ms and error-rate < 1%; k6 exits non-zero if
// either breaks, which is exactly what the README promises.

import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TOKEN = __ENV.TEST_USER_TOKEN || '';

// A mix of common Thai food queries + a couple of English to exercise both
// Thai segmentation (pythainlp) and plain ILIKE paths in the backend.
const QUERIES = [
  'ข้าว', 'ไก่', 'หมู', 'ก๋วยเตี๋ยว', 'ส้มตำ',
  'กะเพรา', 'ต้มยำ', 'ผัดไทย', 'ข้าวผัด', 'ก๋วยจั๊บ',
  'chicken', 'rice', 'salad', 'soup',
];

export const options = {
  scenarios: {
    foods_search: {
      executor: 'constant-vus',
      vus: 50,
      duration: '2m',
    },
  },
  thresholds: {
    'http_req_failed': ['rate<0.01'],
    'http_req_duration{status:200}': ['p(95)<500'],
  },
};

export default function () {
  const q = QUERIES[Math.floor(Math.random() * QUERIES.length)];
  const params = {
    headers: {
      'Accept': 'application/json',
      ...(TOKEN ? { 'Authorization': `Bearer ${TOKEN}` } : {}),
    },
    tags: { endpoint: 'foods_search' },
  };

  const res = http.get(`${BASE_URL}/foods?q=${encodeURIComponent(q)}`, params);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'returns array': (r) => Array.isArray(r.json()),
  });
  // Pace like a real typing user — ~120 WPM = one request every ~200ms —
  // but add jitter so we don't accidentally synchronise into a spike.
  sleep(0.15 + Math.random() * 0.2);
}

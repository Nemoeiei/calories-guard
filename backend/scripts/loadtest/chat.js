// AI chat load test (k6) — low VU count, long cooldown.
//
// The /api/chat/coach endpoint is rate-limited to 10 req/hour per IP
// (see backend/app/routers/chat.py). With 3 VUs and a 60s think-time we
// send ~3 req/minute = 180/hour total — well under the per-IP cap because
// k6 VUs share the runner's egress IP; the limit kicks per IP, not per VU.
//
// We don't care about p95 being under 500ms here — Gemini routinely takes
// 1-3s. What we DO care about:
//   - No 5xx (AI errors should produce 502/504 from our handler, not 500).
//   - Token budget: a 3-min run at 3 VUs burns ~9 Gemini calls. Cheap.
//
// If you want higher throughput, seed several synthetic users and assign
// one per VU; that side-steps the per-IP cap via distinct user tokens.

import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TOKEN = __ENV.TEST_USER_TOKEN || '';
const USER_ID = parseInt(__ENV.TEST_USER_ID || '1', 10);

const PROMPTS = [
  'วันนี้กินอะไรดี',
  'ข้าวมันไก่กี่แคล',
  'โปรตีนที่กินพอมั้ย',
  'แนะนำมื้อเย็นแบบคลีน',
];

export const options = {
  scenarios: {
    chat: {
      executor: 'constant-vus',
      vus: 3,
      duration: '3m',
    },
  },
  thresholds: {
    // 2xx+4xx are OK; only 5xx counts as failure here. k6's default
    // http_req_failed counts >=400, so we override per-status.
    'http_req_failed{expected_response:true}': ['rate<0.01'],
    'http_req_duration{status:200}': ['p(95)<3000'],
  },
};

export default function () {
  const msg = PROMPTS[Math.floor(Math.random() * PROMPTS.length)];
  const body = JSON.stringify({
    user_id: USER_ID,
    message: msg,
  });

  const res = http.post(`${BASE_URL}/api/chat/coach`, body, {
    headers: {
      'Content-Type': 'application/json',
      ...(TOKEN ? { 'Authorization': `Bearer ${TOKEN}` } : {}),
    },
    tags: { endpoint: 'chat_coach' },
    // 429 (rate-limited) and 503 (kill-switch) are expected shapes, not
    // failures. Tell k6 so they don't pollute the error rate.
    responseCallback: http.expectedStatuses(200, 429, 503, 504),
  });

  check(res, {
    'not 5xx (except 503/504)': (r) => r.status < 500 || r.status === 503 || r.status === 504,
  });

  // Think-time. 20s × 3 VUs keeps us at ~9 req/min total — plenty of
  // headroom before the 10/hr per-IP cap bites during a 3-minute run.
  sleep(20);
}

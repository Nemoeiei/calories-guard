# Terms of Service — Calories Guard

**Effective date:** 2026-04-19
**Last updated:** 2026-04-19

> Draft for closed beta. Plain-language terms that state what the product is,
> what it isn't (medical advice), and what we can and can't do. Thai
> translation pending before public release.

---

## 1. Acceptance

By creating an account or using Calories Guard ("the app", "the service")
you agree to these Terms of Service and to our
[Privacy Policy](./privacy-policy.md). If you do not agree, do not use the
service.

The service is currently in **closed beta**. Features, data, and
availability may change, break, or be reset without prior notice to
testers. Don't rely on it as your only record of health data during this
phase.

---

## 2. What the service is — and isn't

Calories Guard lets you log meals, water, exercise, and weight, and
generates coaching suggestions using Google Gemini. It is:

- A tracking and educational tool.
- **Not** a medical device.
- **Not** a substitute for advice from a licensed dietitian, nutritionist,
  physician, or mental-health professional.

**Do not change medication, diet, or exercise plans based solely on the
app's output.** If you have a medical condition (diabetes, kidney disease,
eating disorder, pregnancy, etc.), consult a qualified professional before
acting on any recommendation from the AI coach.

AI-generated nutrition estimates are approximations. Calorie and macro
numbers for unseen foods are produced by a language model and may be
wrong. We cross-check against a curated Thai food database and flag
unknown foods for admin review, but errors will happen.

---

## 3. Your account

- You must be at least 13 years old to register.
- Keep your password secret. You are responsible for activity under your
  account.
- Provide accurate information. Registering with a false identity (for
  example, to manipulate testing quotas) may result in account
  suspension.
- One account per person. Creating multiple accounts to bypass rate
  limits or abuse-prevention mechanisms is prohibited.

---

## 4. Acceptable use

You agree **not** to:

- Use the service for anything illegal under Thai law or the law of your
  location.
- Attempt to access other users' data, bypass authentication, or probe
  the service for vulnerabilities without written permission. (If you
  are a security researcher, see §10.)
- Automate requests at a rate designed to disrupt the service. The
  backend enforces per-endpoint rate limits (`slowapi`); abuse may
  result in IP or account block.
- Send the AI coach prompts intended to extract system prompts, harm
  other users, or generate content that violates Google's Gemini use
  policy.
- Upload images that contain illegal content, CSAM, or other people's
  PII.

We may remove content or suspend accounts that violate these rules
without prior notice.

---

## 5. AI coach — fair-use

Chat endpoints are rate-limited (10 requests/hour per user). This cap
exists because Gemini has real costs and quotas; if you need a higher
limit for a research partnership, contact us.

The AI coach may refuse to answer topics outside nutrition, fitness, or
the app's own functionality. This is intentional scope-limiting and not
a bug.

---

## 6. Your content and data

You retain ownership of the content you create (meal logs, weight
history, chat messages). By using the service you grant us a
non-exclusive, worldwide licence to store, process, and display that
content **solely to operate the service for you**. We do not train
third-party AI models on your data.

You may export your data at any time via the in-app "Download my data"
button. You may delete your account via "Delete account"; after 30 days
we hard-delete (see Privacy Policy §5).

---

## 7. Our rights

We may:

- Suspend or terminate the service, or your access to it, for violation
  of these terms, legal compulsion, or operational necessity.
- Modify features and pricing (if pricing is introduced post-beta) with
  reasonable notice.
- Update these Terms; continued use after an update counts as
  acceptance.

---

## 8. Disclaimers

THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. WE
DISCLAIM ALL IMPLIED WARRANTIES INCLUDING MERCHANTABILITY, FITNESS FOR
A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE
SERVICE WILL BE UNINTERRUPTED, ERROR-FREE, OR FIT FOR ANY PARTICULAR
HEALTH OUTCOME.

We are not liable for decisions you make based on the app's output,
including but not limited to calorie targets, macro splits, or AI
coach responses.

---

## 9. Limitation of liability

To the maximum extent permitted by law, our total aggregate liability
arising from or relating to the service is limited to **THB 1,000** or
the amount you paid us in the preceding 12 months, whichever is greater.
This does not limit liability that cannot be limited under Thai law
(e.g., intentional misconduct).

---

## 10. Security research

If you find a vulnerability, please report it to
`security@calories-guard.example` rather than disclosing publicly. We'll
acknowledge within 72 hours and work with you on a fix. We don't run a
paid bounty program during beta, but we'll credit you in release notes
with your consent.

---

## 11. Governing law

These Terms are governed by the laws of the Kingdom of Thailand.
Disputes not resolved by good-faith discussion will be submitted to
the courts of Bangkok.

---

## 12. Contact

- Terms / legal: `legal@calories-guard.example`
- Support: in-app "Help" screen

*Placeholder addresses — to be replaced with monitored inboxes before
public release.*

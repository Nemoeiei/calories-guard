# 🧪 Calories Guard — Test Cases
> วันที่เตรียม: 2026-04-06
> Schema: `cleangoal` | DB: `cleangoal_db` | Server: CalGuard (localhost)

---

## 📊 DB Overview (Schema: cleangoal — 38 tables)

| ตาราง | Columns | Rows | หมายเหตุ |
|---|---|---|---|
| allergy_flags | 3 | 20 | lookup table ✅ |
| beverages | 7 | 10 | ✅ |
| chat_messages | 5 | 18 | ✅ |
| daily_summaries | 11 | 81 | ✅ |
| detail_items | 15 | 162 | ✅ |
| email_verification_codes | 6 | 5 | ✅ |
| **exercise_logs** | 9 | **0** | ⚠️ **EMPTY** |
| food_allergy_flags | 2 | 20 | junction table ✅ |
| food_ingredients | 7 | 25 | ✅ |
| food_requests | 11 | 21 | ✅ |
| foods | 18 | 149 | ✅ มีรูป 102/149 |
| health_contents | 10 | 20 | ✅ |
| ingredients | 6 | 23 | ✅ |
| meals | 7 | 145 | ✅ |
| notifications | 9 | 25 | ✅ |
| password_reset_codes | 6 | 12 | ✅ |
| progress | 7 | 20 | ✅ |
| recipe_favorites | 4 | 20 | junction table ✅ |
| recipe_ingredients | 9 | 20 | ✅ |
| recipe_reviews | 6 | 20 | ✅ |
| recipe_steps | 9 | 20 | ✅ |
| recipe_tips | 5 | 20 | ✅ |
| recipe_tools | 6 | 20 | ✅ |
| recipes | 20 | 102 | ✅ |
| roles | 2 | 2 | lookup table ✅ |
| snacks | 5 | 10 | ✅ |
| unit_conversions | 6 | 19 | ✅ |
| units | 3 | 15 | lookup table ✅ |
| user_activities | 6 | 20 | ✅ |
| user_allergy_preferences | 4 | 22 | junction table ✅ |
| **user_favorites** | 4 | **0** | ⚠️ **EMPTY** |
| user_goals | 10 | 20 | ✅ |
| user_health_content_views | 4 | 20 | ✅ |
| user_meal_plans | 8 | 20 | ✅ |
| users | 31 | 38 | ✅ |
| water_logs | 7 | 20 | ✅ (แก้ bug amount_ml แล้ว) |
| weekly_summaries | 5 | 20 | ✅ |
| weight_logs | 5 | 53 | ✅ |

> **หมายเหตุ "few cols"**: ตาราง junction/lookup มี column น้อยตามปกติ ไม่ถือว่าผิดปกติ
> ตารางที่ต้องเติมข้อมูล: `exercise_logs`, `user_favorites`

---

## 👤 Personas & Test Cases

### TC-F1 — สมหญิง ดีใจ (หญิง / ลดน้ำหนัก / เป้าก้าวร้าว)

| ข้อมูล | ค่า |
|---|---|
| เพศ | หญิง |
| อายุ | 22 ปี |
| ส่วนสูง | 165 cm |
| น้ำหนักเริ่มต้น | 70 kg |
| น้ำหนักเป้าหมาย | 67 kg |
| ระยะเวลา | 2 สัปดาห์ |
| Activity Level | lightly_active |
| BMI | 25.7 (น้ำหนักเกิน) |
| BMR | 1,460 kcal |
| TDEE | 2,008 kcal |
| Deficit/วัน | 750 kcal (capped จาก ~1,071) |
| **Target kcal** | **1,258 kcal** (capped ที่ min 1,200) |
| Macro P/C/F | 94g / 126g / 42g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี | Action |
|---|---|---|---|
| 0 – 1,069 kcal | < 85% | 🟢 เขียว | ปกติ |
| 1,070 – 1,257 kcal | 85–99% | 🟡 เหลือง | Notification: ⚠️ ใกล้เต็มโควตา |
| 1,258 kcal | 100% | 🟠 ส้ม | Notification: 🎯 ถึงเป้าหมายแล้ว |
| > 1,258 kcal | > 100% | 🔴 แดง | Notification: 🚨 เกินเป้าหมาย! |

**Use Cases ที่ต้องทดสอบ:**
- [ ] UC1: ลงทะเบียน + กรอกโปรไฟล์ → ตรวจว่า target_calories คำนวณถูกต้อง (1,258 kcal)
- [ ] UC2: บันทึกมื้อเช้า 400 kcal → กราฟเขียว (31.8%)
- [ ] UC3: บันทึกมื้อกลางวัน 450 kcal → รวม 850 kcal = 67.6% → ยังเขียว
- [ ] UC4: บันทึกมื้อเย็น 300 kcal → รวม 1,150 kcal = 91.4% → เหลือง + notification warning
- [ ] UC5: บันทึกของว่าง 200 kcal → รวม 1,350 kcal = 107.3% → แดง + notification alert
- [ ] UC6: บันทึกน้ำ 8 แก้ว → ตรวจ DB `water_logs.amount_ml = 2000`
- [ ] UC7: ดูกราฟ Progress → bar แท่งวันนี้มีสี
- [ ] UC8: แตะ bar ในกราฟ → bottom sheet แสดงรายการอาหาร + macro
- [ ] UC9: เช็ค push notification ทุก 2 สัปดาห์ว่าเตือนบันทึกน้ำหนักไหม

---

### TC-F2 — มินตรา คงดี (หญิง / รักษาน้ำหนัก / Active มาก)

| ข้อมูล | ค่า |
|---|---|
| เพศ | หญิง |
| อายุ | 28 ปี |
| ส่วนสูง | 158 cm |
| น้ำหนัก | 55 kg |
| เป้าหมาย | รักษาน้ำหนัก |
| Activity Level | very_active |
| BMI | 22.0 (ปกติ) |
| BMR | 1,236 kcal |
| TDEE | 2,132 kcal |
| Deficit | 0 (maintain) |
| **Target kcal** | **2,132 kcal** |
| Macro P/C/F | 160g / 213g / 71g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี |
|---|---|---|
| 0 – 1,811 kcal | < 85% | 🟢 เขียว |
| 1,812 – 2,131 kcal | 85–99% | 🟡 เหลือง |
| 2,132 kcal | 100% | 🟠 ส้ม |
| > 2,132 kcal | > 100% | 🔴 แดง |

**ประเด็นที่ต้องทดสอบพิเศษ:**
- [ ] Goal type = "maintain" → กราฟไม่แสดงการลด/เพิ่ม
- [ ] Target kcal สูง → ทานอาหาร 3 มื้อปกติยังไม่เต็มโควตา ✓
- [ ] ไม่มี deficit → progress screen แสดงผลอย่างไร

---

### TC-F3 — ลดาวัลย์ ใจดี (หญิง / อ้วนมาก / ลดยาว 12 สัปดาห์)

| ข้อมูล | ค่า |
|---|---|
| เพศ | หญิง |
| อายุ | 45 ปี |
| ส่วนสูง | 160 cm |
| น้ำหนัก | 85 kg |
| เป้าหมาย | 72 kg |
| ระยะเวลา | 12 สัปดาห์ |
| Activity Level | sedentary |
| BMI | 33.2 (อ้วนระดับ 2+) |
| BMR | 1,464 kcal |
| TDEE | 1,757 kcal |
| Deficit/วัน | 750 kcal (capped) |
| **Target kcal** | **1,200 kcal** (ถึง minimum floor) |
| Macro P/C/F | 90g / 120g / 40g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี |
|---|---|---|
| 0 – 1,019 kcal | < 85% | 🟢 เขียว |
| 1,020 – 1,199 kcal | 85–99% | 🟡 เหลือง |
| 1,200 kcal | 100% | 🟠 ส้ม |
| > 1,200 kcal | > 100% | 🔴 แดง |

**ประเด็นที่ต้องทดสอบพิเศษ:**
- [ ] Target ถูก cap ที่ 1,200 kcal (min floor หญิง) → ตรวจว่าระบบไม่ให้ต่ำกว่านี้
- [ ] BMI category = "อ้วนระดับ 2+" → หน้า BMI แสดงสีแดง
- [ ] อายุ 45 ปี → TDEE ต่ำกว่า TC-F1 เพราะอายุมาก (ทดสอบ formula อายุ)

---

### TC-M1 — ธีรภัทร ใจเย็น (ชาย / ลดน้ำหนัก / Moderate)

| ข้อมูล | ค่า |
|---|---|
| เพศ | ชาย |
| อายุ | 25 ปี |
| ส่วนสูง | 175 cm |
| น้ำหนัก | 75 kg |
| เป้าหมาย | 70 kg |
| ระยะเวลา | 8 สัปดาห์ |
| Activity Level | moderately_active |
| BMI | 24.5 (น้ำหนักเกินเล็กน้อย) |
| BMR | 1,724 kcal |
| TDEE | 2,672 kcal |
| Deficit/วัน | 688 kcal |
| **Target kcal** | **1,984 kcal** |
| Macro P/C/F | 149g / 198g / 66g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี |
|---|---|---|
| 0 – 1,686 kcal | < 85% | 🟢 เขียว |
| 1,687 – 1,983 kcal | 85–99% | 🟡 เหลือง |
| 1,984 kcal | 100% | 🟠 ส้ม |
| > 1,984 kcal | > 100% | 🔴 แดง |

**ประเด็นที่ต้องทดสอบพิเศษ:**
- [ ] ชาย vs หญิง → TDEE สูงกว่า (formula +5 แทน -161)
- [ ] Min floor ชาย = 1,500 kcal (TC-M1 ไม่ถึง floor → target = 1,984 ✓)
- [ ] Macro ชาย ต้องการ protein สูงกว่า

---

### TC-M2 — วิชัย พลังดี (ชาย / อ้วน / Sedentary)

| ข้อมูล | ค่า |
|---|---|
| เพศ | ชาย |
| อายุ | 30 ปี |
| ส่วนสูง | 180 cm |
| น้ำหนัก | 95 kg |
| เป้าหมาย | 80 kg |
| ระยะเวลา | 16 สัปดาห์ |
| Activity Level | sedentary |
| BMI | 29.3 (อ้วนระดับ 1) |
| BMR | 1,930 kcal |
| TDEE | 2,316 kcal |
| Deficit/วัน | 750 kcal (capped) |
| **Target kcal** | **1,566 kcal** |
| Macro P/C/F | 117g / 157g / 52g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี |
|---|---|---|
| 0 – 1,331 kcal | < 85% | 🟢 เขียว |
| 1,332 – 1,565 kcal | 85–99% | 🟡 เหลือง |
| 1,566 kcal | 100% | 🟠 ส้ม |
| > 1,566 kcal | > 100% | 🔴 แดง |

**ประเด็นที่ต้องทดสอบพิเศษ:**
- [ ] Sedentary ชาย + น้ำหนักมาก → TDEE ต่ำกว่า moderately_active อย่างชัดเจน
- [ ] BMI > 25 → หน้า BMI category ถูกต้อง
- [ ] Cap deficit 750 kcal → target ไม่ต่ำกว่า 1,500 (min floor ชาย) ✓

---

### TC-M3 — พรชัย ขยัน (ชาย / เพิ่มน้ำหนัก / Very Active)

| ข้อมูล | ค่า |
|---|---|
| เพศ | ชาย |
| อายุ | 19 ปี |
| ส่วนสูง | 172 cm |
| น้ำหนัก | 58 kg |
| เป้าหมาย | 65 kg (เพิ่มน้ำหนัก) |
| ระยะเวลา | 6 สัปดาห์ |
| Activity Level | very_active |
| BMI | 19.6 (ปกติ-ผอม) |
| BMR | 1,565 kcal |
| TDEE | 2,700 kcal |
| Surplus/วัน | +250 kcal |
| **Target kcal** | **2,950 kcal** |
| Macro P/C/F | 221g / 295g / 98g |

**Calorie Color Thresholds:**
| ช่วง | % ของเป้า | สี |
|---|---|---|
| 0 – 2,507 kcal | < 85% | 🟢 เขียว |
| 2,508 – 2,949 kcal | 85–99% | 🟡 เหลือง |
| 2,950 kcal | 100% | 🟠 ส้ม |
| > 2,950 kcal | > 100% | 🔴 แดง (กรณี gain → ยิ่งเกินยิ่งดี?) |

**ประเด็นที่ต้องทดสอบพิเศษ:**
- [ ] Goal type = "gain_weight" → logic สีควรกลับทิศ (เกินเป้าถือว่าดี) **❓ ต้องตรวจสอบ**
- [ ] Target kcal สูงมาก (2,950) → ต้องกินมาก → UX เตือนหรือไม่
- [ ] อายุน้อย (19) → BMR สูงกว่า TC-M2 ที่อายุ 30 ✓

---

## 🔔 Lifecycle Condition Test Cases

### LC-01 — ทดสอบ 2-Week Weight Notification
| สถานการณ์ | Input | Expected Output |
|---|---|---|
| บันทึกน้ำหนักวันนี้ | `days_since = 0` | ไม่มี notification |
| บันทึกเมื่อ 7 วันที่แล้ว | `days_since = 7` | ไม่มี notification |
| บันทึกเมื่อ 14 วันที่แล้ว | `days_since = 14` | ✅ Notification: "⚖️ ยังไม่บันทึกน้ำหนัก 14 วัน" |
| ไม่เคยบันทึก | `days_since = null` | ✅ Notification: "⚖️ ยังไม่เคยบันทึกน้ำหนักเลย" |

### LC-02 — ทดสอบ Birthday / TDEE Recalculation
| สถานการณ์ | Input | Expected Output |
|---|---|---|
| วันเกิดตรงกับวันนี้ | `is_birthday = true` | 🎂 Notification + recalc TDEE ใหม่ |
| birthday ผ่านแล้วปีนี้ ยังไม่ recalc | `tdee_needs_update = true` | 🔄 Recalc TDEE อัตโนมัติ |
| recalc ไปแล้วปีนี้ | `last_tdee_recalc = วันนี้` | ไม่ recalc ซ้ำ |
| ไม่มีวันเกิดในระบบ | `birth_date = null` | ข้ามขั้นตอน ไม่ crash |

### LC-03 — ทดสอบ Monthly Summary (30 วัน)
| สถานการณ์ | Input | Expected Output |
|---|---|---|
| ใช้งานครบ 30 วันพอดี | `days_since_join % 30 == 0` | 📊 Notification: สรุปรายเดือน |
| on_track = true | `current_weight ≤ expected` | "คุณอยู่ในเส้นทางที่ถูกต้อง!" |
| on_track = false | `current_weight > expected` | "ต้องปรับแผนนิดนึงนะ" |
| ไม่ถึง 30 วัน | `days_since_join = 15` | ไม่มี notification |

---

## 🎨 Algorithm / Threshold Reference

### Mifflin-St Jeor Formula
```
ชาย:  BMR = 10W + 6.25H - 5A + 5
หญิง: BMR = 10W + 6.25H - 5A - 161
TDEE = BMR × Activity Multiplier
```

| Activity Level | Multiplier |
|---|---|
| sedentary | 1.20 |
| lightly_active | 1.375 |
| moderately_active | 1.55 |
| very_active | 1.725 |
| extra_active | 1.90 |

### Deficit / Surplus Cap
| กรณี | Formula | Cap |
|---|---|---|
| ลดน้ำหนัก | `(kg_diff × 7,700) / days` | max 750 kcal/day |
| เพิ่มน้ำหนัก | surplus | fixed +250 kcal/day |
| รักษาน้ำหนัก | 0 | — |

### Minimum Calorie Floor
| เพศ | Minimum |
|---|---|
| ชาย | 1,500 kcal/วัน |
| หญิง | 1,200 kcal/วัน |

### BMI Categories (Asian Standard)
| ค่า BMI | หมวด | สีกราฟ |
|---|---|---|
| < 18.5 | ผอม | 🔵 น้ำเงิน |
| 18.5 – 22.9 | ปกติ | 🟢 เขียว |
| 23.0 – 24.9 | น้ำหนักเกิน | 🟡 เหลือง |
| 25.0 – 29.9 | อ้วนระดับ 1 | 🟠 ส้ม |
| ≥ 30.0 | อ้วนระดับ 2+ | 🔴 แดง |

### Calorie Progress Bar Colors
| % ของ target | สี | Notification |
|---|---|---|
| < 85% | 🟢 เขียว | — |
| 85–99% | 🟡 เหลือง | ⚠️ showCalorieWarning() |
| 100% | 🟠 ส้ม | 🎯 Goal reached |
| > 100% | 🔴 แดง | 🚨 showCalorieAlert() |

### Macro Ratio (Goal: ลดน้ำหนัก)
| Macro | % kcal | formula |
|---|---|---|
| Protein | 30% | `target × 0.30 / 4` กรัม |
| Carbs | 40% | `target × 0.40 / 4` กรัม |
| Fat | 30% | `target × 0.30 / 9` กรัม |

---

## ✅ Checklist ก่อน Run Test

- [ ] Backend server รัน: `uvicorn main:app --reload`
- [ ] DB: cleangoal_db / schema: cleangoal พร้อมแล้ว
- [ ] Foods table มีข้อมูล ≥ 30 รายการอาหารไทย
- [ ] สร้าง user ทดสอบ TC-F1 ถึง TC-M3 ใน DB
- [ ] ทดสอบบน Android device จริง (notifications ต้องการอุปกรณ์จริง)
- [ ] ตรวจ `target_calories` คำนวณถูกต้องตามตารางด้านบน
- [ ] ตรวจ color threshold เปลี่ยนสีตรงตามเปอร์เซ็นต์

---

*Generated: 2026-04-06 | Calories Guard v1.0 Phase 1 Testing*

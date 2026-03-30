# CaloriesGuard — Use Case Test Document
> Version 1.0 | Date: 2026-03-30

---

## Test Accounts (ใช้สำหรับ Manual Test)

| Role | Email | Password | user_id |
|------|-------|----------|---------|
| **Persona A (ชาย)** | teerapat.test@calguard.com | Teerapat@2026 | 37 |
| **Persona B (หญิง)** | mintra.test@calguard.com | Mintra@2026 | 38 |
| **Admin** | admin.test@calguard.com | Admin@2026 | 39 |

---

## Personas

### Persona A — ธีรภัทร (ผู้ชาย)
| | |
|---|---|
| อายุ | 28 ปี (เกิด 15 พ.ค. 2541) |
| อาชีพ | พนักงานออฟฟิศ |
| เป้าหมาย | ลดน้ำหนัก (lose_weight) |
| น้ำหนัก / ส่วนสูง | 82 kg / 175 cm |
| น้ำหนักเป้าหมาย | 77 kg |
| แคลอรี่เป้าหมาย | 1,800 kcal/วัน |
| โปรตีน / คาร์บ / ไขมัน | 135g / 180g / 60g |
| Activity Level | moderately_active |
| ใช้แอปมา | 2 สัปดาห์ |
| พฤติกรรม | บันทึกอาหารทุกมื้อ ดูแผนที่ร้านอาหารตอนกลางวัน ออกกำลังกายสัปดาห์ละ 3 ครั้ง |

### Persona B — มินตรา (ผู้หญิง)
| | |
|---|---|
| อายุ | 25 ปี (เกิด 22 มี.ค. 2544) |
| อาชีพ | นักศึกษาปริญญาโท |
| เป้าหมาย | รักษาน้ำหนัก (maintain_weight) |
| น้ำหนัก / ส่วนสูง | 55 kg / 162 cm |
| น้ำหนักเป้าหมาย | 55 kg |
| แคลอรี่เป้าหมาย | 1,600 kcal/วัน |
| โปรตีน / คาร์บ / ไขมัน | 120g / 160g / 53g |
| Activity Level | very_active |
| ใช้แอปมา | 2 สัปดาห์ |
| พฤติกรรม | ติดตาม macro เป็นหลัก ดูสูตรอาหาร ออกกำลังกาย 5 วัน/สัปดาห์ |

---

## Use Cases

---

### UC-01 · หน้าหลัก (AppHomeScreen)

**Precondition:** Login สำเร็จแล้ว

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | เปิดแอป | หน้าหลักโหลด แสดงชื่อ "สวัสดี คุณธีรภัทร/มินตรา" |
| 2 | ดูวงแหวนแคลอรี่ | แสดงแคลอรี่ที่กินแล้วและเป้าหมาย |
| 3 | ดู macro bar | โปรตีน / คาร์บ / ไขมัน แสดงสัดส่วนถูกต้อง |
| 4 | เลื่อนดู Water Tracker | แสดงจำนวนแก้วน้ำที่ดื่ม |
| 5 | กด +/- ที่ Water Tracker | จำนวนแก้วเพิ่ม/ลดได้ |
| 6 | ดู Progress Card | แสดงน้ำหนักปัจจุบัน, ลดไปแล้ว, เหลืออีก |
| 7 | กดวันที่ใน Date Strip | เปลี่ยนวันได้ ข้อมูลอาหารเปลี่ยนตาม |

**Persona A:** แคลอรี่เหลือจาก 1,800 kcal
**Persona B:** แคลอรี่เหลือจาก 1,600 kcal

---

### UC-02 · บันทึกอาหาร (RecordFoodScreen)

**Precondition:** อยู่ในแอป กดแท็บ "บันทึก"

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กดแท็บ "บันทึก" | หน้าบันทึกอาหารเปิดขึ้น |
| 2 | ค้นหาชื่ออาหาร (เช่น "ข้าว") | รายการอาหารที่ตรงกันแสดงขึ้น |
| 3 | เลือกมื้อ (เช้า/เที่ยง/เย็น/ว่าง) | slot มื้ออาหารถูกเลือก |
| 4 | กด Confirm บันทึก | อาหารถูกบันทึก กลับหน้าหลักแสดงแคลอรี่เพิ่มขึ้น |

**Persona A:** บันทึก "ข้าวมันไก่" — มื้อเที่ยง
**Persona B:** บันทึก "ไข่ต้ม" — มื้อเช้า, บันทึก "สลัดผัก" — มื้อเย็น

---

### UC-03 · อาหารแนะนำ (RecommendedFoodScreen)

**Precondition:** กดแท็บ "อาหาร"

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กดแท็บ "อาหาร" | หน้าอาหารแนะนำโหลดรายการ |
| 2 | Browse รายการอาหาร | แสดงรายการพร้อมรูปและแคลอรี่ |
| 3 | ค้นหาอาหาร (เช่น "ผัด") | กรองรายการตามคำค้นหา |
| 4 | เปลี่ยน filter หมวดหมู่ | รายการเปลี่ยนตาม filter |
| 5 | กดรายการอาหาร | ไปหน้า RecipeDetailScreen |

**Persona A:** ค้นหา "ต้มยำ" → filter อาหารไทย
**Persona B:** ค้นหา "สลัด" → filter อาหารคลีน

---

### UC-04 · รายละเอียดสูตรอาหาร (RecipeDetailScreen)

**Precondition:** กดเข้าจากหน้า RecommendedFood

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | ดูชื่อและรูปอาหาร | แสดงชื่อ, รูป, แคลอรี่, เวลาทำ |
| 2 | ดูส่วนผสม (Ingredients) | แสดงรายการส่วนผสมครบถ้วน |
| 3 | ดูขั้นตอนการทำ (Steps) | แสดงแต่ละขั้นตอนเรียงลำดับ |
| 4 | ดู Tips | แสดงเคล็ดลับการทำอาหาร |
| 5 | กด Favorite ⭐ | favorite count เพิ่มขึ้น 1 |
| 6 | ให้ Rating ★★★★☆ | avg_rating อัพเดต |
| 7 | อ่าน Review | แสดง review ของผู้ใช้คนอื่น |

**Persona A:** กด favorite + rating 4 ดาว
**Persona B:** อ่าน review + rating 5 ดาว

---

### UC-05 · แผนที่ร้านอาหาร (RestaurantMapScreen)

**Precondition:** เปิด Location Permission แล้ว

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กดปุ่ม "ร้านอาหารใกล้ฉัน" ในหน้าหลัก | หน้าแผนที่เปิด แสดง map |
| 2 | รอ GPS โหลด | แผนที่ centering ที่ตำแหน่งปัจจุบัน |
| 3 | ดู marker ร้านอาหาร | แสดง marker ร้านใกล้เคียง |
| 4 | กด filter ประเภทร้าน | marker กรองตาม filter |
| 5 | กด marker ร้าน | แสดงรายละเอียดร้าน |

**Persona A:** Filter "อาหารไทย" ราคาถูก
**Persona B:** Filter rating ≥ 4 ดาว

---

### UC-06 · ออกกำลังกาย (ExerciseRecommendationScreen)

**Precondition:** กดแท็บ "ออกกำลัง"

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กดแท็บ "ออกกำลัง" | รายการวิดีโอออกกำลังกายแสดง |
| 2 | เลื่อนดูรายการ | แสดงหัวข้อ + รูป thumbnail |
| 3 | กดเลือกวิดีโอ | วิดีโอหรือลิ้งค์เปิดได้ |

**Persona A:** เลือก cardio workout
**Persona B:** เลือก strength training

---

### UC-07 · โปรไฟล์ (ProfileScreen)

**Precondition:** กดไอคอน person บนหัว

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กดไอคอน person | หน้า Profile เปิด |
| 2 | ดูข้อมูลส่วนตัว | แสดงชื่อ, น้ำหนัก, เป้าหมาย |
| 3 | กดปุ่ม "แก้ไขโปรไฟล์" | ไป EditProfileScreen |
| 4 | กดปุ่ม "ความคืบหน้า" | ไป ProgressScreen |
| 5 | กดปุ่ม "ตั้งค่าหน่วย" | ไป UnitSettingsScreen |
| 6 | กดปุ่ม "ตั้งค่า" | ไป SettingScreen |

---

### UC-08 · แก้ไขโปรไฟล์ (EditProfileScreen)

**Precondition:** เข้าจาก ProfileScreen

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | แก้ไขชื่อ | ช่องชื่อรับ input ได้ |
| 2 | อัพเดตน้ำหนักปัจจุบัน | ช่องน้ำหนักรับตัวเลขได้ |
| 3 | เปลี่ยนเป้าหมาย | dropdown เปลี่ยนได้ |
| 4 | กด Save | API ตอบ 200, ข้อมูลอัพเดตในแอป |
| 5 | กลับหน้าหลัก | หน้าหลักแสดงข้อมูลใหม่ทันที |

**Persona A:** อัพเดตน้ำหนักเป็น 81 kg (ลดไป 1 kg)
**Persona B:** เปลี่ยนเป้าหมายเป็น gain_muscle

---

### UC-09 · ความคืบหน้า (ProgressScreen)

**Precondition:** เข้าจาก ProfileScreen

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | เปิดหน้า Progress | กราฟโหลดแสดงข้อมูล |
| 2 | ดูกราฟ Weekly | แสดงข้อมูล 7 วันย้อนหลัง |
| 3 | Switch ไป Monthly | แสดงข้อมูลรายเดือน |
| 4 | ดูกราฟน้ำหนัก | แสดง trend น้ำหนัก 2 สัปดาห์ |

**Persona A:** เห็นน้ำหนักลดลงจาก 82 → 81 kg
**Persona B:** เห็นแคลอรี่ใกล้เป้าหมายทุกวัน

---

### UC-10 · ตั้งค่าหน่วย (UnitSettingsScreen)

**Precondition:** เข้าจาก ProfileScreen

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | เปิดหน้าตั้งค่าหน่วย | แสดง options ทุกหน่วย |
| 2 | เปลี่ยนหน่วยน้ำหนัก (kg → lbs) | หน่วยเปลี่ยน |
| 3 | กด Save | บันทึกสำเร็จ |
| 4 | กลับหน้าหลัก | หน้าหลักแสดงหน่วยใหม่ |

**Persona A:** เปลี่ยนเป็น lbs แล้วเปลี่ยนกลับ kg
**Persona B:** เปลี่ยน energy เป็น kJ

---

### UC-11 · ตั้งค่าแอป (SettingScreen)

**Precondition:** เข้าจาก ProfileScreen

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | เปิดหน้า Setting | แสดง toggle notification |
| 2 | Toggle notification on/off | state เปลี่ยน |
| 3 | กด Logout | กลับไปหน้า Login |

---

### UC-12 · Macro Detail (MacroDetailScreen)

**Precondition:** อยู่ในหน้าหลัก มีข้อมูล macro

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | กด progress bar "โปรตีน" | ไปหน้า MacroDetail filter โปรตีน |
| 2 | ดูรายการอาหารโปรตีนสูง | แสดงอาหารเรียงตามโปรตีน |
| 3 | กด progress bar "คาร์บ" | filter เปลี่ยนเป็นคาร์บ |
| 4 | กด progress bar "ไขมัน" | filter เปลี่ยนเป็นไขมัน |

**Persona A:** ดูอาหารโปรตีนสูงเพื่อเพิ่มกล้ามเนื้อ
**Persona B:** ดูอาหารคาร์บต่ำ

---

### UC-13 · Admin — จัดการอาหาร

> **ใช้ account:** admin.test@calguard.com / Admin@2026

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login ด้วย admin account | เข้า AdminDashboardScreen |
| 2 | กด "Food List" | แสดงรายการอาหารทั้งหมด |
| 3 | ค้นหา "ข้าว" | กรองรายการที่มีคำว่า "ข้าว" |
| 4 | กด Edit อาหาร | เปิด AdminEditMenuScreen |
| 5 | แก้ไข calorie → Save | อัพเดตสำเร็จ |
| 6 | กด Add Menu | เปิด AdminAddMenuScreen |
| 7 | กรอกข้อมูลอาหารใหม่ → Save | บันทึกอาหารใหม่สำเร็จ |
| 8 | กด Requests | แสดงรายการ pending requests |
| 9 | Approve request | สถานะเปลี่ยนเป็น approved |

---

## Test Coverage Summary

| # | หน้า | Persona A | Persona B | Admin |
|---|------|:---------:|:---------:|:-----:|
| 1 | AppHomeScreen | ✅ | ✅ | |
| 2 | RecordFoodScreen | ✅ | ✅ | |
| 3 | RecommendedFoodScreen | ✅ | ✅ | |
| 4 | RecipeDetailScreen | ✅ | ✅ | |
| 5 | RestaurantMapScreen | ✅ | ✅ | |
| 6 | ExerciseRecommendationScreen | ✅ | ✅ | |
| 7 | ProfileScreen | ✅ | ✅ | |
| 8 | EditProfileScreen | ✅ | ✅ | |
| 9 | ProgressScreen | ✅ | ✅ | |
| 10 | UnitSettingsScreen | ✅ | ✅ | |
| 11 | SettingScreen | ✅ | ✅ | |
| 12 | MacroDetailScreen | ✅ | ✅ | |
| 13 | AdminDashboardScreen | | | ✅ |
| 14 | AdminFoodListScreen | | | ✅ |
| 15 | AdminEditMenuScreen | | | ✅ |
| 16 | AdminAddMenuScreen | | | ✅ |
| 17 | AdminRequestScreen | | | ✅ |

**รวม 17 หน้า ครอบคลุมทุก active screen**

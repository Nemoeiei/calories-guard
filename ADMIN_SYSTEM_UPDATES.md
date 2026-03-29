# 🔧 Admin System Updates - Food Request Management

## 📅 วันที่: 26 มีนาคม 2026

---

## ✅ การแก้ไขที่ทำแล้ว

### **1. Database Schema Updates**

#### เพิ่มคอลัมน์ใน `food_requests` table
```sql
ALTER TABLE cleangoal.food_requests 
ADD COLUMN IF NOT EXISTS calories NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS protein NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS carbs NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS fat NUMERIC(6,2);
```

**ไฟล์:** `database_migration_food_requests.sql`

**เหตุผล:** เดิมเก็บข้อมูลโภชนาการใน `ingredients_json` (JSONB) ซึ่งไม่เหมาะสมสำหรับการ query และแสดงผล ตอนนี้เก็บในคอลัมน์แยกเพื่อให้ admin เห็นข้อมูลชัดเจน

---

### **2. Backend API Updates**

#### 📝 File: `backend/main.py`

**A. แก้ไข POST `/foods/auto-add`**
- **เปลี่ยนจาก:** เก็บข้อมูลโภชนาการทั้งหมดใน `ingredients_json`
- **เป็น:** เก็บในคอลัมน์ `calories`, `protein`, `carbs`, `fat` แยกกัน
- **ผลลัพธ์:** Admin เห็นข้อมูลที่ user กรอกมาได้ทันที

```python
# Before
INSERT INTO food_requests (user_id, food_name, status, ingredients_json)
VALUES (%s, %s, 'pending', %s)

# After
INSERT INTO food_requests 
(user_id, food_name, status, calories, protein, carbs, fat, ingredients_json)
VALUES (%s, %s, 'pending', %s, %s, %s, %s, %s)
```

**B. แก้ไข GET `/admin/food-requests`**
- **เพิ่ม:** ส่งฟิลด์ `calories`, `protein`, `carbs`, `fat` กลับไปยัง Flutter
- **ผลลัพธ์:** Admin screen แสดงข้อมูลโภชนาการได้ถูกต้อง

```python
SELECT 
    fr.request_id, 
    fr.food_name, 
    fr.status, 
    fr.calories,      # ← เพิ่ม
    fr.protein,       # ← เพิ่ม
    fr.carbs,         # ← เพิ่ม
    fr.fat,           # ← เพิ่ม
    fr.ingredients_json, 
    fr.created_at, 
    u.username as requester_name
FROM food_requests fr
JOIN users u ON fr.user_id = u.user_id
WHERE fr.status = 'pending'
ORDER BY fr.created_at DESC
```

---

### **3. Flutter Frontend Updates**

#### 📱 File: `flutter_application_1/lib/screens/record/record_food_screen.dart`

**A. แก้ไข `_AddFoodSheet`**
- **ลบปุ่ม:** "เพิ่มในมื้อนี้" (เพิ่มแบบ local อย่างเดียว)
- **เหลือปุ่มเดียว:** "เพิ่ม + ส่งให้ Admin"
- **การทำงาน:**
  1. เพิ่มอาหารลงมื้อทันที (พร้อม badge "รอตรวจสอบ")
  2. ส่ง request ไป backend พร้อมข้อมูลโภชนาการครบถ้วน

**B. ลบ method ที่ไม่ใช้**
- ลบ `_quickAddLocal()` method

---

#### 📱 File: `flutter_application_1/lib/screens/admin/admin_request_screen.dart`

**A. แสดงข้อมูลโภชนาการในการ์ด**
- **เพิ่ม:** แสดงข้อมูล calories, protein, carbs, fat ในการ์ดคำขอ
- **รูปแบบ:** `{calories} kcal • P:{protein}g C:{carbs}g F:{fat}g`
- **ผลลัพธ์:** Admin เห็นข้อมูลโภชนาการได้ทันทีโดยไม่ต้องเปิดหน้ารายละเอียด

**Before:**
```
[Avatar] ชื่อผู้ใช้
         เพิ่ม ข้าวผัดปู
```

**After:**
```
[Avatar] ชื่อผู้ใช้
         เพิ่ม ข้าวผัดปู
         350 kcal • P:15g C:45g F:12g
```

---

#### 📱 File: `flutter_application_1/lib/screens/admin/admin_addmenu_screen.dart`

**A. แก้ไข `initState()`**
- **เปลี่ยนจาก:** อ่านข้อมูลจาก `ingredients_json` (JSONB parsing)
- **เป็น:** อ่านโดยตรงจากฟิลด์ `calories`, `protein`, `carbs`, `fat`
- **ผลลัพธ์:** โค้ดง่ายขึ้น, ไม่มี JSON parsing errors

```dart
// Before
final meta = jsonDecode(req['ingredients_json']);
_caloriesCtrl.text = meta['original_calories']?.toString() ?? '';

// After
_caloriesCtrl.text = req['calories']?.toString() ?? '';
```

---

## 🔄 Flow การทำงานของระบบ

### **User Side (Record Food Screen)**
```
1. User กรอกข้อมูล:
   - ชื่อเมนู: "ข้าวผัดปู"
   - แคลอรี่: 350
   - โปรตีน: 15g
   - คาร์บ: 45g
   - ไขมัน: 12g

2. กดปุ่ม "เพิ่ม + ส่งให้ Admin"

3. Frontend:
   - เพิ่มอาหารลงมื้อทันที (isPending: true)
   - แสดง badge "รอตรวจสอบ" สีส้ม
   - ส่ง POST /foods/auto-add

4. Backend:
   - INSERT INTO foods (ใช้ได้ทันที)
   - INSERT INTO food_requests (รอ admin ตรวจสอบ)
```

### **Admin Side (Request Management)**
```
1. Admin เปิด "ดูคำขอเพิ่มเมนู"

2. เห็นรายการ:
   [Avatar] นายสมชาย
            เพิ่ม ข้าวผัดปู
            350 kcal • P:15g C:45g F:12g

3. กดดูรายละเอียด → ไปหน้า AdminAddMenuScreen

4. Admin ตรวจสอบและแก้ไข:
   - แคลอรี่: 350 → 380 (ปรับแก้)
   - โปรตีน: 15 → 18 (ปรับแก้)
   - เพิ่มรูปภาพ
   - กรอกวิธีทำ (optional)

5. กด "บันทึก" → PUT /admin/food-requests/{id}

6. Backend:
   - UPDATE food_requests SET status = 'approved'
   - UPDATE foods SET calories = 380, protein = 18, image_url = '...'

7. User เห็นเมนูนี้ในฐานข้อมูลถาวร (ไม่มี badge แล้ว)
```

---

## 📋 Checklist การ Deploy

### **Database**
- [ ] รัน migration: `database_migration_food_requests.sql`
- [ ] ตรวจสอบว่าคอลัมน์ถูกเพิ่มแล้ว:
  ```sql
  SELECT column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name = 'food_requests' 
  AND column_name IN ('calories', 'protein', 'carbs', 'fat');
  ```

### **Backend**
- [ ] Pull code ใหม่
- [ ] Restart FastAPI server
- [ ] ทดสอบ endpoints:
  - `POST /foods/auto-add`
  - `GET /admin/food-requests`
  - `PUT /admin/food-requests/{id}`

### **Frontend**
- [ ] Pull code ใหม่
- [ ] ทดสอบ User Flow:
  - เพิ่มเมนูใหม่จาก Record Food Screen
  - ตรวจสอบว่าแสดง badge "รอตรวจสอบ"
- [ ] ทดสอบ Admin Flow:
  - เปิดหน้า Admin Request Screen
  - ตรวจสอบว่าแสดงข้อมูลโภชนาการ
  - อนุมัติคำขอ
  - ตรวจสอบว่าข้อมูลถูกอัปเดตใน foods table

---

## 🐛 Known Issues & Solutions

### **Issue 1: ข้อมูลเก่าใน food_requests**
**ปัญหา:** คำขอเก่าที่สร้างก่อน migration จะมี calories, protein, carbs, fat = NULL

**วิธีแก้:**
```sql
-- Option 1: ลบคำขอเก่าทั้งหมด
DELETE FROM cleangoal.food_requests WHERE status = 'pending';

-- Option 2: Migrate ข้อมูลจาก ingredients_json
UPDATE cleangoal.food_requests
SET 
  calories = (ingredients_json->>'original_calories')::NUMERIC,
  protein = (ingredients_json->>'original_protein')::NUMERIC,
  carbs = (ingredients_json->>'original_carbs')::NUMERIC,
  fat = (ingredients_json->>'original_fat')::NUMERIC
WHERE calories IS NULL AND ingredients_json IS NOT NULL;
```

### **Issue 2: Admin ไม่เห็นข้อมูลโภชนาการ**
**สาเหตุ:** Backend ยังไม่ได้ restart หลัง update code

**วิธีแก้:** Restart FastAPI server

---

## 📊 Database Schema Reference

### **Table: food_requests**
```sql
CREATE TABLE cleangoal.food_requests (
    request_id bigint PRIMARY KEY,
    user_id bigint NOT NULL,
    food_name varchar NOT NULL,
    status request_status DEFAULT 'pending',
    calories NUMERIC(6,2),          -- ← NEW
    protein NUMERIC(6,2),            -- ← NEW
    carbs NUMERIC(6,2),              -- ← NEW
    fat NUMERIC(6,2),                -- ← NEW
    ingredients_json jsonb,
    reviewed_by bigint,
    created_at timestamp DEFAULT now()
);
```

### **Table: foods**
```sql
CREATE TABLE cleangoal.foods (
    food_id bigint PRIMARY KEY,
    food_name varchar NOT NULL,
    food_type food_type DEFAULT 'raw_ingredient',
    calories NUMERIC(6,2),
    protein NUMERIC(6,2),
    carbs NUMERIC(6,2),
    fat NUMERIC(6,2),
    sodium NUMERIC(6,2),
    sugar NUMERIC(6,2),
    cholesterol NUMERIC(6,2),
    serving_quantity NUMERIC(6,2) DEFAULT 100,
    serving_unit varchar DEFAULT 'g',
    image_url varchar,
    created_at timestamp DEFAULT now(),
    updated_at timestamp,
    deleted_at timestamp,
    fiber_g NUMERIC(6,2) DEFAULT 0,
    food_category varchar
);
```

---

## 🎯 ผลลัพธ์ที่ได้

✅ **User Experience:**
- เพิ่มเมนูใหม่ได้ง่ายขึ้น (ปุ่มเดียว)
- ใช้เมนูได้ทันทีโดยไม่ต้องรอ admin
- เห็น badge "รอตรวจสอบ" ชัดเจน

✅ **Admin Experience:**
- เห็นข้อมูลโภชนาการทันทีในหน้ารายการ
- ไม่ต้องเปิดรายละเอียดทีละรายการ
- แก้ไขข้อมูลได้ง่าย พร้อมเพิ่มรูปภาพ

✅ **System Quality:**
- Database schema ชัดเจน (ไม่ใช้ JSONB สำหรับข้อมูลสำคัญ)
- Code ง่ายขึ้น (ไม่ต้อง parse JSON)
- Query ได้เร็วขึ้น (indexed columns)

---

## 📝 Notes

- ระบบนี้รองรับการเพิ่มเมนูแบบ "optimistic update" คือ user ใช้ได้ทันที แต่ admin ยังตรวจสอบทีหลังได้
- Admin สามารถปรับแก้ข้อมูลโภชนาการก่อนอนุมัติได้
- ถ้า admin reject คำขอ เมนูจะยังคงอยู่ใน foods table (ไม่ลบออก) เพราะ user อาจใช้งานไปแล้ว

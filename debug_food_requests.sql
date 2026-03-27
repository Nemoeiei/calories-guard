-- Debug Script: ตรวจสอบปัญหา Admin ไม่เห็นคำขอ

-- 1. ตรวจสอบว่า migration ถูกรันหรือยัง
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'cleangoal' 
  AND table_name = 'food_requests'
ORDER BY ordinal_position;

-- 2. ตรวจสอบข้อมูลทั้งหมดใน food_requests
SELECT 
    request_id,
    user_id,
    food_name,
    status,
    calories,
    protein,
    carbs,
    fat,
    created_at
FROM cleangoal.food_requests
ORDER BY created_at DESC
LIMIT 10;

-- 3. ตรวจสอบว่ามี pending requests หรือไม่
SELECT COUNT(*) as pending_count
FROM cleangoal.food_requests
WHERE status = 'pending';

-- 4. ตรวจสอบว่า user_id ที่ส่งมามีอยู่ใน users table หรือไม่
SELECT u.user_id, u.username, u.email
FROM cleangoal.users u
ORDER BY u.user_id
LIMIT 5;

-- 5. ตรวจสอบ JOIN query ที่ admin endpoint ใช้
SELECT 
    fr.request_id, 
    fr.food_name, 
    fr.status, 
    fr.calories,
    fr.protein,
    fr.carbs,
    fr.fat,
    fr.created_at, 
    u.username as requester_name
FROM cleangoal.food_requests fr
LEFT JOIN cleangoal.users u ON fr.user_id = u.user_id
WHERE fr.status = 'pending'
ORDER BY fr.created_at DESC;

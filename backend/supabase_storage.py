"""
supabase_storage.py
Helper สำหรับอัปโหลดรูปภาพไปยัง Supabase Storage
"""

import os
import httpx
from uuid import uuid4
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

SUPABASE_URL    = os.getenv("SUPABASE_PROJECT_URL", "")
SUPABASE_KEY    = os.getenv("SUPABASE_ANON_KEY", "")
STORAGE_BUCKET  = os.getenv("SUPABASE_STORAGE_BUCKET", "food-images")

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}

MIME_MAP = {
    "jpg":  "image/jpeg",
    "jpeg": "image/jpeg",
    "png":  "image/png",
    "webp": "image/webp",
    "gif":  "image/gif",
}


def upload_to_supabase(file_bytes: bytes, original_filename: str) -> str:
    """
    อัปโหลดไฟล์รูปไปยัง Supabase Storage bucket 'food-images'
    คืน public URL ของรูปที่อัปโหลด
    raises ValueError ถ้า config ไม่ครบหรือ upload ล้มเหลว
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("ยังไม่ได้ตั้งค่า SUPABASE_PROJECT_URL หรือ SUPABASE_ANON_KEY ใน .env")

    # สร้างชื่อไฟล์ unique
    ext = original_filename.rsplit(".", 1)[-1].lower() if "." in original_filename else "jpg"
    if ext not in ALLOWED_EXTENSIONS:
        ext = "jpg"

    new_filename = f"food_{uuid4().hex}.{ext}"
    content_type = MIME_MAP.get(ext, "image/jpeg")

    upload_url = f"{SUPABASE_URL}/storage/v1/object/{STORAGE_BUCKET}/{new_filename}"

    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  content_type,
        "x-upsert":      "true",   # ถ้าชื่อซ้ำให้ replace
    }

    response = httpx.post(upload_url, content=file_bytes, headers=headers, timeout=30)

    if response.status_code not in (200, 201):
        raise ValueError(f"Supabase Storage upload ล้มเหลว: {response.status_code} — {response.text}")

    # Public URL (bucket ถูกตั้งเป็น public แล้ว)
    public_url = f"{SUPABASE_URL}/storage/v1/object/public/{STORAGE_BUCKET}/{new_filename}"
    return public_url

from typing import Optional

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Request
from psycopg2.extras import RealDictCursor
from slowapi import Limiter
from slowapi.util import get_remote_address

from database import get_db_connection
from supabase_storage import upload_to_supabase
from app.core.config import ALLOWED_MIME_TYPES, MAX_UPLOAD_SIZE

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.get("/")
def read_root():
    return {"message": "API is running with Infinite Meals & Image Upload!"}


@router.get("/health")
def health():
    """Liveness probe for Render/Railway/Docker health checks."""
    return {"status": "ok"}


@router.post("/upload-image/")
@limiter.limit("10/minute")
async def upload_image(
    request: Request,
    file: UploadFile = File(...),
    food_id: int = Form(None),
):
    """อัปโหลดรูปภาพไปยัง Supabase Storage และคืน public URL.

    ถ้าส่ง ``food_id`` มาด้วย จะตั้งชื่อไฟล์เป็น ``{food_id}_{originalname}.ext``
    เพื่อให้ sync_food_images.py ค้นหาเจอได้อัตโนมัติ.
    """
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=400, detail=f"File type not allowed. Accepted: {', '.join(ALLOWED_MIME_TYPES)}")
    try:
        file_bytes = await file.read()
        if len(file_bytes) > MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=413, detail="File too large. Maximum size is 5 MB.")
        filename = file.filename or "image.jpg"
        override = None
        if food_id:
            ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "jpg"
            if ext not in ("jpg", "jpeg", "png", "webp", "gif"):
                ext = "jpg"
            override = f"{food_id}_{filename.rsplit('.', 1)[0]}.{ext}"
        public_url = upload_to_supabase(file_bytes, filename, filename_override=override)
        return {"url": public_url}
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload ล้มเหลว: {str(e)}")


@router.post("/upload_image")
@limiter.limit("10/minute")
async def upload_image_alt(request: Request, file: UploadFile = File(...)):
    """อัปโหลดรูปภาพไปยัง Supabase Storage (endpoint สำรอง)"""
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=400, detail=f"File type not allowed. Accepted: {', '.join(ALLOWED_MIME_TYPES)}")
    try:
        file_bytes = await file.read()
        if len(file_bytes) > MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=413, detail="File too large. Maximum size is 5 MB.")
        public_url = upload_to_supabase(file_bytes, file.filename)
        return {"image_url": public_url, "url": public_url, "message": "อัปโหลดรูปภาพสำเร็จ"}
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")


@router.get("/units")
def get_units():
    """คืนรายการหน่วยทั้งหมด พร้อม quantity"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT unit_id, name, quantity FROM units ORDER BY unit_id")
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        if conn:
            conn.close()


@router.get("/unit_conversions")
def get_unit_conversions(from_unit_id: Optional[int] = None):
    """คืนตาราง unit_conversions ทั้งหมด หรือกรองด้วย from_unit_id"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        if from_unit_id:
            cur.execute("""
                SELECT uc.conversion_id,
                       uc.from_unit_id,
                       fu.name AS from_unit_name,
                       uc.to_unit_id,
                       tu.name AS to_unit_name,
                       uc.factor,
                       uc.note
                FROM unit_conversions uc
                JOIN units fu ON fu.unit_id = uc.from_unit_id
                JOIN units tu ON tu.unit_id = uc.to_unit_id
                WHERE uc.from_unit_id = %s
                ORDER BY uc.conversion_id
            """, (from_unit_id,))
        else:
            cur.execute("""
                SELECT uc.conversion_id,
                       uc.from_unit_id,
                       fu.name AS from_unit_name,
                       uc.to_unit_id,
                       tu.name AS to_unit_name,
                       uc.factor,
                       uc.note
                FROM unit_conversions uc
                JOIN units fu ON fu.unit_id = uc.from_unit_id
                JOIN units tu ON tu.unit_id = uc.to_unit_id
                ORDER BY uc.conversion_id
            """)
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    finally:
        if conn:
            conn.close()

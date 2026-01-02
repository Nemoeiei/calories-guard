from fastapi import FastAPI, HTTPException
from database import get_db_connection
from psycopg2.extras import RealDictCursor

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "API is running! Welcome to CleanGoal Backend."}

# --- API 1: ดึงรายชื่ออาหารทั้งหมด ---
@app.get("/foods")
def read_foods():
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        # ดึงข้อมูลมาแสดง (เรียงตาม ID)
        cur.execute("SELECT * FROM foods ORDER BY food_id ASC")
        foods = cur.fetchall()
        return foods
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            cur.close()
            conn.close()

# --- API 2: ดึงข้อมูลอาหารตาม ID (เผื่อใช้ในอนาคต) ---
@app.get("/foods/{food_id}")
def read_food(food_id: int):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Database connection failed")

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM foods WHERE food_id = %s", (food_id,))
        food = cur.fetchone()
        
        if food is None:
            raise HTTPException(status_code=404, detail="Food not found")
            
        return food
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            cur.close()
            conn.close()
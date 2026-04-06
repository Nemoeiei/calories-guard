import psycopg2
from psycopg2.extras import RealDictCursor
from passlib.context import CryptContext
from dotenv import load_dotenv
import os

load_dotenv()
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')

try:
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'cleangoal_db'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD'),
        options="-c search_path=cleangoal,public"
    )
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Check roles
    cur.execute("SELECT * FROM roles WHERE role_name = 'admin'")
    admin_role = cur.fetchone()
    if not admin_role:
        print('Creating admin role...')
        cur.execute("INSERT INTO roles (role_id, role_name) VALUES (2, 'admin') ON CONFLICT DO NOTHING RETURNING role_id")
        role_ret = cur.fetchone()
        admin_role_id = role_ret['role_id'] if role_ret else 2
        conn.commit()
    else:
        admin_role_id = admin_role['role_id']

    # Check for admin user
    cur.execute("SELECT * FROM users WHERE email = 'admin@cleangoal.com'")
    admin_user = cur.fetchone()
    
    if not admin_user:
        pwd_hash = pwd_context.hash('admin1234')
        cur.execute("""
            INSERT INTO users (username, email, password_hash, role_id, is_email_verified)
            VALUES ('Admin CleanGoal', 'admin@cleangoal.com', %s, %s, TRUE)
            RETURNING user_id, email;
        """, (pwd_hash, admin_role_id))
        new_admin = cur.fetchone()
        conn.commit()
        print(f"✅ สร้างบัญชีแอดมินสำเร็จ! (ยืนยันอีเมลแล้ว)\nEmail: {new_admin['email']}\nPassword: admin1234")
    else:
        # Reset password to make sure it works
        pwd_hash = pwd_context.hash('admin1234')
        cur.execute("UPDATE users SET password_hash = %s, role_id = %s, is_email_verified = TRUE WHERE email = 'admin@cleangoal.com'", (pwd_hash, admin_role_id))
        conn.commit()
        print("ℹ️ บัญชีแอดมินมีอยู่แล้วในระบบ! ได้ทำการรีเซ็ตรหัสผ่านและยืนยันอีเมลให้แล้ว\nEmail: admin@cleangoal.com\nPassword: admin1234")

except Exception as e:
    print(f'Error: {e}')
finally:
    if 'conn' in locals() and conn:
        conn.close()

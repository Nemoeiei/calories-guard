import psycopg2
from run_migrations import DB_CONFIG

conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

tables = [
    'progress_snapshots', 'units', 'roles', 'users', 'foods', 'user_goals', 
    'user_activities', 'weight_logs', 'progress', 'health_contents', 'user_stats'
]

print("Table statuses in public schema:")
for t in tables:
    cur.execute(f"SELECT to_regclass('public.{t}')")
    exists = cur.fetchone()[0]
    if exists:
        try:
            cur.execute(f"SELECT count(*) FROM public.{t}")
            count = cur.fetchone()[0]
            print(f"- {t}: EXISTS (count: {count})")
        except Exception as e:
            conn.rollback()
            print(f"- {t}: EXISTS (error reading count: {e})")
    else:
        print(f"- {t}: DOES NOT EXIST")
cur.close()
conn.close()

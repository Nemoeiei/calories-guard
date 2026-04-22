import psycopg2
from run_migrations import DB_CONFIG

conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

cur.execute("""
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type='BASE TABLE'
""")
tables = cur.fetchall()

print("Base tables in 'public' schema:")
for t in tables:
    print(f"- {t[0]}")
cur.close()
conn.close()

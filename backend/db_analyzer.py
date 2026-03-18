import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

def analyze_db():
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            database=os.getenv('DB_NAME', 'cleangoal_db'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', 'REDACTED_DB_PASSWORD'),
            port=os.getenv('DB_PORT', '5432'),
            options="-c search_path=cleangoal,public"
        )
        cur = conn.cursor(cursor_factory=RealDictCursor)

        print("--- DATABASE SCHEMA ANALYSIS ---\n")

        # 1. Get all tables in public/cleangoal schemas
        cur.execute("""
            SELECT table_schema, table_name 
            FROM information_schema.tables 
            WHERE table_schema IN ('public', 'cleangoal') 
            AND table_type = 'BASE TABLE'
            ORDER BY table_schema, table_name;
        """)
        tables = cur.fetchall()

        if not tables:
            print("No tables found in public or cleangoal schema.")
            return

        for table in tables:
            schema = table['table_schema']
            tname = table['table_name']
            print(f"[{schema}.{tname}]")
            
            # 2. Get Columns
            cur.execute(f"""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_schema = '{schema}' AND table_name = '{tname}'
                ORDER BY ordinal_position;
            """)
            columns = cur.fetchall()
            for col in columns:
                print(f"  - {col['column_name']} ({col['data_type']}) - Nullable: {col['is_nullable']}")

            # 3. Get 3 sample rows
            try:
                cur.execute(f'SELECT * FROM "{schema}"."{tname}" LIMIT 3;')
                rows = cur.fetchall()
                print("  Sample Data:")
                for r in rows:
                    print(f"    {dict(r)}")
            except Exception as e:
                print(f"    Could not fetch data: {str(e)}")
                conn.rollback() # Important to rollback the transaction if an error occurs

            print("\n")

        # 4. Get Foreign Keys
        print("--- FOREIGN KEYS ---\n")
        cur.execute("""
            SELECT
                tc.table_schema, 
                tc.constraint_name, 
                tc.table_name, 
                kcu.column_name, 
                ccu.table_schema AS foreign_table_schema,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name 
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.key_column_usage AS kcu
                  ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                  ON ccu.constraint_name = tc.constraint_name
                  AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema IN ('public', 'cleangoal');
        """)
        fks = cur.fetchall()
        for fk in fks:
            print(f"{fk['table_schema']}.{fk['table_name']}({fk['column_name']}) -> {fk['foreign_table_schema']}.{fk['foreign_table_name']}({fk['foreign_column_name']})")

    except Exception as e:
        print(f"Fatal Error connecting/querying: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    analyze_db()

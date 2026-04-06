import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

def generate_mermaid_er():
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            database=os.getenv('DB_NAME', 'cleangoal_db'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD'),
            port=os.getenv('DB_PORT', '5432'),
            options="-c search_path=cleangoal,public"
        )
        cur = conn.cursor(cursor_factory=RealDictCursor)

        mermaid_lines = ["erDiagram"]

        # 1. Get all tables in public/cleangoal schemas
        cur.execute("""
            SELECT table_schema, table_name 
            FROM information_schema.tables 
            WHERE table_schema IN ('public', 'cleangoal') 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        tables = cur.fetchall()

        if not tables:
            print("No tables found")
            return

        for table in tables:
            schema = table['table_schema']
            tname = table['table_name']
            
            mermaid_lines.append(f"    {tname} {{")
            
            # 2. Get Columns
            cur.execute(f"""
                SELECT column_name, data_type, is_nullable, character_maximum_length
                FROM information_schema.columns
                WHERE table_schema = '{schema}' AND table_name = '{tname}'
                ORDER BY ordinal_position;
            """)
            columns = cur.fetchall()
            for col in columns:
                cname = col['column_name']
                dtype = col['data_type'].upper()
                if "CHARACTER" in dtype and col['character_maximum_length']:
                    dtype = f"VARCHAR({col['character_maximum_length']})"
                elif "TIMESTAMP" in dtype:
                    dtype = "TIMESTAMP"
                
                # Replace spaces in datatypes
                dtype_safe = dtype.replace(" ", "_").replace("[]", "_ARRAY")
                mermaid_lines.append(f"        {dtype_safe} {cname}")
            mermaid_lines.append("    }")

        # 4. Get Foreign Keys
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
            t1 = fk['table_name']
            t2 = fk['foreign_table_name']
            # Mermaid syntax: TABLE_A ||--o{ TABLE_B : "foreign key"
            mermaid_lines.append(f"    {t2} ||--o{{ {t1} : \"{fk['column_name']}\"")

        print("\n".join(mermaid_lines))
        
        with open("d:/Senior_Project/calories-guard/backend/output_mermaid.txt", "w", encoding="utf-8") as f:
            f.write("\n".join(mermaid_lines))

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    generate_mermaid_er()

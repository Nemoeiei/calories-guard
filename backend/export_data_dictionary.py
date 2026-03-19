import psycopg2
import csv
import os

DB_CONFIG = {
    "dbname": "cleangoal_db",
    "user": "postgres",
    "password": "zaxscdvf123",
    "host": "localhost",
    "port": "5432"
}

output_file = "C:/Users/frame/.gemini/antigravity/brain/b5659d2a-2eaa-4ebe-8086-52e939d73c80/data_dictionary.csv"

def export_data_dictionary():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        # SQL to get all tables and columns in public schema
        query = """
        SELECT 
            c.table_name, 
            c.column_name, 
            c.data_type, 
            c.is_nullable, 
            c.column_default
        FROM 
            information_schema.columns c
        JOIN 
            information_schema.tables t ON c.table_name = t.table_name
        WHERE 
            t.table_schema = 'public' 
            AND t.table_type = 'BASE TABLE'
        ORDER BY 
            c.table_name, c.ordinal_position;
        """
        
        cur.execute(query)
        rows = cur.fetchall()
        
        with open(output_file, mode='w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['Table Name', 'Column Name', 'Data Type', 'Is Nullable', 'Default Value'])
            for row in rows:
                writer.writerow(row)
                
        print(f"Data dictionary exported successfully to {output_file}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    export_data_dictionary()

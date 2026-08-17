import sqlite3
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parents[1]

db_path = project_root / "data" / "grocery_integration.db"

if len(sys.argv) < 2:
    print("Usage: python scripts/run_validation.py <sql_file>")
    sys.exit(1)

sql_path = project_root / "sql" / sys.argv[1]

if not sql_path.exists():
    print(f"SQL file not found: {sql_path}")
    sys.exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

with open(sql_path, "r") as file:
    sql_script = file.read()

queries = [
    query.strip()
    for query in sql_script.split(";")
    if query.strip()
]

print(f"Running: {sql_path.name}")

for i, query in enumerate(queries, start=1):
    print(f"\n--- Query {i} ---")

    cursor.execute(query)

    if cursor.description:
        columns = [col[0] for col in cursor.description]
        rows = cursor.fetchall()

        print(columns)

        if rows:
            for row in rows[:20]:
                print(row)

            if len(rows) > 20:
                print(f"... {len(rows) - 20} more rows")
        else:
            print("No rows returned.")

conn.close()
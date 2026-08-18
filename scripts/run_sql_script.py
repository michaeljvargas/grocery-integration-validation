import sqlite3
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parents[1]

db_path = project_root / "data" / "grocery_integration.db"

if len(sys.argv) < 2:
    print(
        "Usage: python scripts/run_sql_script.py <sql_file>"
    )
    sys.exit(1)

sql_path = project_root / "sql" / sys.argv[1]

if not sql_path.exists():
    print(f"SQL file not found: {sql_path}")
    sys.exit(1)

conn = sqlite3.connect(db_path)

with open(
    sql_path,
    "r",
    encoding="utf-8"
) as file:
    sql_script = file.read()

try:
    conn.executescript(sql_script)
    conn.commit()

    print(f"Executed successfully: {sql_path.name}")

except sqlite3.Error as error:
    conn.rollback()
    print(f"SQL Error: {error}")

finally:
    conn.close()
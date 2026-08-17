import sqlite3
import pandas as pd
from pathlib import Path

# -----------------------------
# Project paths
# -----------------------------
project_root = Path(__file__).resolve().parents[1]

csv_path = project_root / "data" / "raw" / "retail_store_inventory.csv"
db_path = project_root / "data" / "grocery_integration.db"
schema_path = project_root / "sql" / "01_create_tables.sql"

# -----------------------------
# Load source data
# -----------------------------
df = pd.read_csv(csv_path)

# Convert source date from string to datetime
df["Date"] = pd.to_datetime(df["Date"])

print(f"Loaded source file: {len(df):,} rows")

# -----------------------------
# Build target datasets
# -----------------------------

stores = (
    df[["Store ID"]]
    .drop_duplicates()
    .rename(columns={
        "Store ID": "store_id"
    })
)

products = (
    df[["Product ID"]]
    .drop_duplicates()
    .rename(columns={
        "Product ID": "product_id"
    })
)

daily_operations = (
    df[
        [
            "Date",
            "Store ID",
            "Product ID",
            "Inventory Level",
            "Units Sold",
            "Units Ordered",
            "Demand Forecast",
            "Price",
            "Discount",
            "Weather Condition",
            "Holiday/Promotion",
            "Competitor Pricing",
            "Seasonality"
        ]
    ]
    .rename(columns={
        "Date": "date",
        "Store ID": "store_id",
        "Product ID": "product_id",
        "Inventory Level": "inventory_level",
        "Units Sold": "units_sold",
        "Units Ordered": "units_ordered",
        "Demand Forecast": "demand_forecast",
        "Price": "price",
        "Discount": "discount",
        "Weather Condition": "weather_condition",
        "Holiday/Promotion": "holiday_promotion",
        "Competitor Pricing": "competitor_pricing",
        "Seasonality": "seasonality"
    })
)

# SQLite handles date strings cleanly
daily_operations["date"] = daily_operations["date"].dt.strftime("%Y-%m-%d")

print(f"Stores prepared: {len(stores):,}")
print(f"Products prepared: {len(products):,}")
print(f"Daily operations prepared: {len(daily_operations):,}")

# -----------------------------
# Connect to SQLite
# -----------------------------
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Enforce foreign keys in SQLite
cursor.execute("PRAGMA foreign_keys = ON;")

# -----------------------------
# Rebuild schema
# -----------------------------
cursor.executescript("""
DROP TABLE IF EXISTS daily_operations;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;
""")

with open(schema_path, "r") as file:
    cursor.executescript(file.read())

print("Database schema created successfully.")

# -----------------------------
# Load target tables
# -----------------------------
stores.to_sql(
    "stores",
    conn,
    if_exists="append",
    index=False
)

products.to_sql(
    "products",
    conn,
    if_exists="append",
    index=False
)

daily_operations.to_sql(
    "daily_operations",
    conn,
    if_exists="append",
    index=False
)

conn.commit()

print("Data loaded successfully.")

# -----------------------------
# Validate row counts
# -----------------------------
for table in ["stores", "products", "daily_operations"]:
    count = cursor.execute(
        f"SELECT COUNT(*) FROM {table};"
    ).fetchone()[0]

    print(f"{table}: {count:,} rows")

conn.close()
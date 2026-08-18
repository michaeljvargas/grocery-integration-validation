import sqlite3
import pandas as pd
from pathlib import Path

# --------------------------------------------------
# Project paths
# --------------------------------------------------

project_root = Path(__file__).resolve().parents[1]

source_path = (
    project_root
    / "data"
    / "raw"
    / "retail_store_inventory.csv"
)

customer_feed_path = (
    project_root
    / "data"
    / "processed"
    / "customer_daily_feed.csv"
)

db_path = (
    project_root
    / "data"
    / "grocery_integration.db"
)

schema_path = (
    project_root
    / "sql"
    / "01_create_tables.sql"
)

# --------------------------------------------------
# Load clean source data
# --------------------------------------------------

df = pd.read_csv(source_path)

df["Date"] = pd.to_datetime(
    df["Date"]
)

print(
    f"Loaded source file: "
    f"{len(df):,} rows"
)

# --------------------------------------------------
# Build stores table
# --------------------------------------------------

stores = (
    df[
        [
            "Store ID"
        ]
    ]
    .drop_duplicates()
    .rename(
        columns={
            "Store ID": "store_id"
        }
    )
)

# --------------------------------------------------
# Build products table
# --------------------------------------------------

products = (
    df[
        [
            "Product ID"
        ]
    ]
    .drop_duplicates()
    .rename(
        columns={
            "Product ID": "product_id"
        }
    )
)

# --------------------------------------------------
# Build daily operations table
# --------------------------------------------------

daily_operations = (
    df[
        [
            "Date",
            "Store ID",
            "Product ID",
            "Category",
            "Region",
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
    .rename(
        columns={
            "Date": "date",
            "Store ID": "store_id",
            "Product ID": "product_id",
            "Category": "category",
            "Region": "region",
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
        }
    )
)

daily_operations["date"] = (
    daily_operations["date"]
    .dt.strftime("%Y-%m-%d")
)

print(
    f"Stores prepared: "
    f"{len(stores):,}"
)

print(
    f"Products prepared: "
    f"{len(products):,}"
)

print(
    f"Daily operations prepared: "
    f"{len(daily_operations):,}"
)

# --------------------------------------------------
# Load generated customer feed
# --------------------------------------------------

if not customer_feed_path.exists():
    raise FileNotFoundError(
        "Customer feed not found. "
        "Run generate_customer_feed.py first."
    )

customer_feed = pd.read_csv(
    customer_feed_path
)

print(
    f"Customer feed loaded: "
    f"{len(customer_feed):,} rows"
)

# --------------------------------------------------
# Connect to SQLite
# --------------------------------------------------

conn = sqlite3.connect(db_path)

cursor = conn.cursor()

cursor.execute(
    "PRAGMA foreign_keys = ON;"
)

# --------------------------------------------------
# Rebuild clean target schema
# --------------------------------------------------

cursor.executescript(
    """
    DROP TABLE IF EXISTS customer_feed_raw;
    DROP TABLE IF EXISTS daily_operations;
    DROP TABLE IF EXISTS products;
    DROP TABLE IF EXISTS stores;
    """
)

with open(
    schema_path,
    "r",
    encoding="utf-8"
) as file:

    schema_sql = file.read()

cursor.executescript(
    schema_sql
)

print(
    "Database schema created successfully."
)

# --------------------------------------------------
# Load normalized clean tables
# --------------------------------------------------

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

# --------------------------------------------------
# Load customer feed into raw staging
# --------------------------------------------------

customer_feed.to_sql(
    "customer_feed_raw",
    conn,
    if_exists="replace",
    index=False
)

conn.commit()

print(
    "Data loaded successfully."
)

# --------------------------------------------------
# Validate row counts
# --------------------------------------------------

tables = [
    "stores",
    "products",
    "daily_operations",
    "customer_feed_raw"
]

for table in tables:

    count = cursor.execute(
        f"""
        SELECT COUNT(*)
        FROM {table};
        """
    ).fetchone()[0]

    print(
        f"{table}: "
        f"{count:,} rows"
    )

conn.close()

print(
    "\nDatabase load complete."
)
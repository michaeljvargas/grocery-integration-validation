import pandas as pd
from pathlib import Path

# -----------------------------
# Project paths
# -----------------------------
project_root = Path(__file__).resolve().parents[1]

source_path = (
    project_root
    / "data"
    / "raw"
    / "retail_store_inventory.csv"
)

output_dir = project_root / "data" / "processed"
output_path = output_dir / "customer_daily_feed.csv"

output_dir.mkdir(parents=True, exist_ok=True)

# -----------------------------
# Load clean source
# -----------------------------
df = pd.read_csv(source_path)

# Work on a copy so the original remains untouched
customer_feed = df.copy()

print(f"Clean source records: {len(customer_feed):,}")

# -----------------------------
# Inject known defects
# -----------------------------

# 1. Unknown stores
unknown_store_idx = customer_feed.index[0:25]

customer_feed.loc[
    unknown_store_idx,
    "Store ID"
] = "S999"


# 2. Unmapped products
unmapped_product_idx = customer_feed.index[25:65]

customer_feed.loc[
    unmapped_product_idx,
    "Product ID"
] = "P9999"


# 3. Missing product IDs
null_product_idx = customer_feed.index[65:80]

customer_feed.loc[
    null_product_idx,
    "Product ID"
] = None


# 4. Invalid negative inventory
negative_inventory_idx = customer_feed.index[80:100]

customer_feed.loc[
    negative_inventory_idx,
    "Inventory Level"
] = -10

# 5. Duplicate records
duplicate_rows = customer_feed.iloc[100:130].copy()

customer_feed = pd.concat(
    [customer_feed, duplicate_rows],
    ignore_index=True
)

# -----------------------------
# Save simulated customer feed
# -----------------------------

customer_feed.to_csv(
    output_path,
    index=False
)

print(f"Customer feed records: {len(customer_feed):,}")

print("\nInjected defects:")
print("Unknown stores: 25")
print("Unmapped products: 40")
print("Null product IDs: 15")
print("Negative inventory: 20")
print("Duplicate records added: 30")

print(f"\nCustomer feed written to:")
print(output_path)
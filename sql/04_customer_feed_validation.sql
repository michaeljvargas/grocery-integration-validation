-- ==================================================
-- CUSTOMER FEED INTEGRATION VALIDATION
-- ==================================================

-- 1. Total records received
SELECT
    COUNT(*) AS records_received
FROM customer_feed_raw;

-- 2. Missing store IDs
SELECT
    COUNT(*) AS missing_store_ids
FROM customer_feed_raw
WHERE "Store ID" IS NULL;

-- 3. Missing product IDs
SELECT
    COUNT(*) AS missing_product_ids
FROM customer_feed_raw
WHERE "Product ID" IS NULL;

-- 4. Unknown stores
SELECT
    COUNT(*) AS unknown_store_records
FROM customer_feed_raw AS c
LEFT JOIN stores AS s
    ON c."Store ID" = s.store_id
WHERE c."Store ID" IS NOT NULL
  AND s.store_id IS NULL;

-- 5. Unknown / unmapped products
SELECT
    COUNT(*) AS unmapped_product_records
FROM customer_feed_raw AS c
LEFT JOIN products AS p
    ON c."Product ID" = p.product_id
WHERE c."Product ID" IS NOT NULL
  AND p.product_id IS NULL;

-- 6. Negative inventory
SELECT
    COUNT(*) AS negative_inventory_records
FROM customer_feed_raw
WHERE "Inventory Level" < 0;

-- 7. Duplicate composite keys
SELECT
    "Date",
    "Store ID",
    "Product ID",
    COUNT(*) AS duplicate_count
FROM customer_feed_raw
GROUP BY
    "Date",
    "Store ID",
    "Product ID"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 8. Count excess duplicate records
SELECT
    SUM(duplicate_count - 1) AS excess_duplicate_records
FROM (
    SELECT
        "Date",
        "Store ID",
        "Product ID",
        COUNT(*) AS duplicate_count
    FROM customer_feed_raw
    GROUP BY
        "Date",
        "Store ID",
        "Product ID"
    HAVING COUNT(*) > 1
);

-- 9. Customer feed vs clean source volume
SELECT
    (SELECT COUNT(*) FROM customer_feed_raw) AS customer_records,
    (SELECT COUNT(*) FROM daily_operations) AS clean_target_records,
    (SELECT COUNT(*) FROM customer_feed_raw)
      - (SELECT COUNT(*) FROM daily_operations) AS row_difference;
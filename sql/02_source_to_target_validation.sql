-- 1. Validate expected row counts
SELECT COUNT(*) AS store_count
FROM stores;

SELECT COUNT(*) AS product_count
FROM products;

SELECT COUNT(*) AS daily_operations_count
FROM daily_operations;

-- 2. Validate composite key uniqueness
SELECT
    date,
    store_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM daily_operations
GROUP BY
    date,
    store_id,
    product_id
HAVING COUNT(*) > 1;

-- 3. Find daily records with unknown stores
SELECT COUNT(*) AS unknown_store_records
FROM daily_operations AS d
LEFT JOIN stores AS s
    ON d.store_id = s.store_id
WHERE s.store_id IS NULL;

-- 4. Find daily records with unknown products
SELECT COUNT(*) AS unknown_product_records
FROM daily_operations AS d
LEFT JOIN products AS p
    ON d.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 5. Validate number of records per date
SELECT
    date,
    COUNT(*) AS record_count
FROM daily_operations
GROUP BY date
ORDER BY date;



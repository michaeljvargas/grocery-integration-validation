-- ==================================================
-- EXCEPTION REASON SUMMARY
-- ==================================================

WITH flagged_rows AS (
    SELECT
        c.rowid AS source_row_id,

        CASE
            WHEN c."Product ID" IS NULL THEN 1
            ELSE 0
        END AS missing_product_flag,

        CASE
            WHEN c."Store ID" IS NOT NULL
             AND s.store_id IS NULL THEN 1
            ELSE 0
        END AS unknown_store_flag,

        CASE
            WHEN c."Product ID" IS NOT NULL
             AND p.product_id IS NULL THEN 1
            ELSE 0
        END AS unmapped_product_flag,

        CASE
            WHEN c."Inventory Level" < 0 THEN 1
            ELSE 0
        END AS negative_inventory_flag,

        COUNT(*) OVER (
            PARTITION BY
                c."Date",
                c."Store ID",
                c."Product ID"
        ) AS key_occurrence_count

    FROM customer_feed_raw AS c

    LEFT JOIN stores AS s
        ON c."Store ID" = s.store_id

    LEFT JOIN products AS p
        ON c."Product ID" = p.product_id
)

SELECT
    'Missing Product ID' AS exception_reason,
    SUM(missing_product_flag) AS row_count
FROM flagged_rows

UNION ALL

SELECT
    'Unknown Store',
    SUM(unknown_store_flag)
FROM flagged_rows

UNION ALL

SELECT
    'Unmapped Product',
    SUM(unmapped_product_flag)
FROM flagged_rows

UNION ALL

SELECT
    'Negative Inventory',
    SUM(negative_inventory_flag)
FROM flagged_rows

UNION ALL

SELECT
    'Duplicate Business Key',
    SUM(
        CASE
            WHEN key_occurrence_count > 1 THEN 1
            ELSE 0
        END
    )
FROM flagged_rows;
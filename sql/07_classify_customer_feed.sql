-- ==================================================
-- CUSTOMER FEED CLASSIFICATION
-- ==================================================

WITH flagged_rows AS (
    SELECT
        c.rowid AS source_row_id,
        c.*,

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
),

classified_rows AS (
    SELECT
        *,

        CASE
            WHEN key_occurrence_count > 1 THEN 1
            ELSE 0
        END AS duplicate_key_flag,

        CASE
            WHEN missing_product_flag = 1
                THEN 'REJECT'

            WHEN unknown_store_flag = 1
                THEN 'QUARANTINE'

            WHEN unmapped_product_flag = 1
                THEN 'QUARANTINE'

            WHEN negative_inventory_flag = 1
                THEN 'QUARANTINE'

            WHEN key_occurrence_count > 1
                THEN 'QUARANTINE'

            ELSE 'ACCEPT'
        END AS validation_status,

        CASE
            WHEN missing_product_flag = 1
                THEN 'Missing Product ID'

            WHEN unknown_store_flag = 1
                THEN 'Unknown Store'

            WHEN unmapped_product_flag = 1
                THEN 'Unmapped Product'

            WHEN negative_inventory_flag = 1
                THEN 'Negative Inventory'

            WHEN key_occurrence_count > 1
                THEN 'Duplicate Business Key'

            ELSE NULL
        END AS primary_validation_reason

    FROM flagged_rows
)

SELECT
    source_row_id,
    "Date",
    "Store ID",
    "Product ID",
    "Inventory Level",

    missing_product_flag,
    unknown_store_flag,
    unmapped_product_flag,
    negative_inventory_flag,
    duplicate_key_flag,

    validation_status,
    primary_validation_reason

FROM classified_rows

ORDER BY
    CASE validation_status
        WHEN 'REJECT' THEN 1
        WHEN 'QUARANTINE' THEN 2
        WHEN 'ACCEPT' THEN 3
    END,
    source_row_id;
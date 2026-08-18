-- ==================================================
-- CUSTOMER FEED RECONCILIATION SUMMARY
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
),

classified_rows AS (
    SELECT
        source_row_id,

        missing_product_flag,
        unknown_store_flag,
        unmapped_product_flag,
        negative_inventory_flag,

        CASE
            WHEN key_occurrence_count > 1 THEN 1
            ELSE 0
        END AS duplicate_key_flag,

        CASE
            WHEN missing_product_flag = 1
              OR unknown_store_flag = 1
              OR unmapped_product_flag = 1
              OR negative_inventory_flag = 1
              OR key_occurrence_count > 1
            THEN 1
            ELSE 0
        END AS affected_row_flag

    FROM flagged_rows
)

SELECT
    COUNT(*) AS total_received,

    SUM(affected_row_flag) AS unique_affected_rows,

    COUNT(*) - SUM(affected_row_flag) AS clean_rows,

    SUM(missing_product_flag) AS missing_product_rows,

    SUM(unknown_store_flag) AS unknown_store_rows,

    SUM(unmapped_product_flag) AS unmapped_product_rows,

    SUM(negative_inventory_flag) AS negative_inventory_rows,

    SUM(duplicate_key_flag) AS rows_in_duplicate_key_groups

FROM classified_rows;
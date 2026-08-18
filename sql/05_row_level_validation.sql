-- ==================================================
-- ROW-LEVEL CUSTOMER FEED VALIDATION
-- ==================================================

WITH flagged_rows AS (
    SELECT
        c.rowid AS source_row_id,
        c."Date",
        c."Store ID",
        c."Product ID",
        c."Inventory Level",

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
    source_row_id,
    "Date",
    "Store ID",
    "Product ID",
    "Inventory Level",

    missing_product_flag,
    unknown_store_flag,
    unmapped_product_flag,
    negative_inventory_flag,

    CASE
        WHEN key_occurrence_count > 1 THEN 1
        ELSE 0
    END AS duplicate_key_flag,

    (
        missing_product_flag
        + unknown_store_flag
        + unmapped_product_flag
        + negative_inventory_flag
        + CASE
            WHEN key_occurrence_count > 1 THEN 1
            ELSE 0
          END
    ) AS total_validation_failures

FROM flagged_rows

WHERE
    missing_product_flag = 1
    OR unknown_store_flag = 1
    OR unmapped_product_flag = 1
    OR negative_inventory_flag = 1
    OR key_occurrence_count > 1

ORDER BY
    total_validation_failures DESC,
    source_row_id;
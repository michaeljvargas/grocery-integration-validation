-- ==================================================
-- FINAL CUSTOMER FEED RECONCILIATION
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
                THEN 'REJECT'

            WHEN unknown_store_flag = 1
              OR unmapped_product_flag = 1
              OR negative_inventory_flag = 1
              OR key_occurrence_count > 1
                THEN 'QUARANTINE'

            ELSE 'ACCEPT'
        END AS validation_status

    FROM flagged_rows
)

SELECT
    COUNT(*) AS total_received,

    SUM(
        CASE
            WHEN validation_status = 'ACCEPT' THEN 1
            ELSE 0
        END
    ) AS accepted_rows,

    SUM(
        CASE
            WHEN validation_status = 'QUARANTINE' THEN 1
            ELSE 0
        END
    ) AS quarantined_rows,

    SUM(
        CASE
            WHEN validation_status = 'REJECT' THEN 1
            ELSE 0
        END
    ) AS rejected_rows,

    COUNT(*)
    -
    (
        SUM(
            CASE
                WHEN validation_status = 'ACCEPT' THEN 1
                ELSE 0
            END
        )
        +
        SUM(
            CASE
                WHEN validation_status = 'QUARANTINE' THEN 1
                ELSE 0
            END
        )
        +
        SUM(
            CASE
                WHEN validation_status = 'REJECT' THEN 1
                ELSE 0
            END
        )
    ) AS unreconciled_rows

FROM classified_rows;
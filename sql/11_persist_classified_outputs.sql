-- ==================================================
-- PERSIST CLASSIFIED CUSTOMER FEED OUTPUTS
-- ==================================================

DROP TABLE IF EXISTS accepted_customer_feed;
DROP TABLE IF EXISTS customer_feed_exceptions;
DROP TABLE IF EXISTS classified_customer_feed;

-- --------------------------------------------------
-- Build classified feed
-- --------------------------------------------------

CREATE TABLE classified_customer_feed AS

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
)

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
          OR unmapped_product_flag = 1
          OR negative_inventory_flag = 1
          OR key_occurrence_count > 1
            THEN 'QUARANTINE'

        ELSE 'ACCEPT'
    END AS validation_status

FROM flagged_rows;


-- --------------------------------------------------
-- Accepted records
-- --------------------------------------------------

CREATE TABLE accepted_customer_feed AS

SELECT *
FROM classified_customer_feed
WHERE validation_status = 'ACCEPT';


-- --------------------------------------------------
-- Exceptions
-- --------------------------------------------------

CREATE TABLE customer_feed_exceptions AS

SELECT *
FROM classified_customer_feed
WHERE validation_status IN (
    'QUARANTINE',
    'REJECT'
);
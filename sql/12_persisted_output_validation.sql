-- ==================================================
-- PERSISTED OUTPUT VALIDATION
-- ==================================================

-- 1. Accepted records

SELECT
    COUNT(*) AS accepted_rows
FROM accepted_customer_feed;


-- 2. Exception records

SELECT
    COUNT(*) AS exception_rows
FROM customer_feed_exceptions;


-- 3. Exceptions by disposition

SELECT
    validation_status,
    COUNT(*) AS row_count
FROM customer_feed_exceptions
GROUP BY validation_status
ORDER BY validation_status;


-- 4. Final reconciliation

SELECT
    (SELECT COUNT(*)
     FROM customer_feed_raw)
        AS total_received,

    (SELECT COUNT(*)
     FROM accepted_customer_feed)
        AS accepted,

    (SELECT COUNT(*)
     FROM customer_feed_exceptions
     WHERE validation_status = 'QUARANTINE')
        AS quarantined,

    (SELECT COUNT(*)
     FROM customer_feed_exceptions
     WHERE validation_status = 'REJECT')
        AS rejected,

    (
        SELECT COUNT(*)
        FROM customer_feed_raw
    )
    -
    (
        (SELECT COUNT(*)
         FROM accepted_customer_feed)

        +

        (SELECT COUNT(*)
         FROM customer_feed_exceptions)
    ) AS unreconciled;
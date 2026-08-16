/*
  First financial reconciliation
  ------------------------------
  Compare product + freight value with total payments at ORDER grain.
  Aggregating both sides before joining prevents many-to-many multiplication.
*/

USE EcommerceAnalytics;
GO

CREATE OR ALTER VIEW analytics.vw_order_financial_reconciliation
AS
WITH item_totals AS
(
    SELECT
        order_id,
        SUM(CAST(price AS decimal(18, 2))) AS product_value,
        SUM(CAST(freight_value AS decimal(18, 2))) AS freight_value,
        SUM(CAST(price + freight_value AS decimal(18, 2))) AS item_and_freight_value,
        COUNT_BIG(*) AS order_item_count
    FROM staging.order_items
    GROUP BY order_id
),
payment_totals AS
(
    SELECT
        order_id,
        SUM(CAST(payment_value AS decimal(18, 2))) AS payment_value,
        COUNT_BIG(*) AS payment_record_count
    FROM staging.order_payments
    GROUP BY order_id
)
SELECT
    COALESCE(i.order_id, p.order_id) AS order_id,
    COALESCE(i.product_value, 0) AS product_value,
    COALESCE(i.freight_value, 0) AS freight_value,
    COALESCE(i.item_and_freight_value, 0) AS item_and_freight_value,
    COALESCE(p.payment_value, 0) AS payment_value,
    CAST(COALESCE(p.payment_value, 0) - COALESCE(i.item_and_freight_value, 0)
         AS decimal(18, 2)) AS reconciliation_difference,
    COALESCE(i.order_item_count, 0) AS order_item_count,
    COALESCE(p.payment_record_count, 0) AS payment_record_count,
    CASE
        WHEN i.order_id IS NULL THEN 'PAYMENT_WITHOUT_ITEM'
        WHEN p.order_id IS NULL THEN 'ITEM_WITHOUT_PAYMENT'
        WHEN ABS(p.payment_value - i.item_and_freight_value) <= 0.01 THEN 'MATCHED'
        ELSE 'DIFFERENCE'
    END AS reconciliation_status
FROM item_totals i
FULL OUTER JOIN payment_totals p
    ON p.order_id = i.order_id;
GO

SELECT
    reconciliation_status,
    COUNT_BIG(*) AS order_count,
    SUM(product_value) AS product_value,
    SUM(freight_value) AS freight_value,
    SUM(item_and_freight_value) AS item_and_freight_value,
    SUM(payment_value) AS payment_value,
    SUM(reconciliation_difference) AS reconciliation_difference
FROM analytics.vw_order_financial_reconciliation
GROUP BY reconciliation_status
ORDER BY reconciliation_status;
GO


/*
  Data-quality controls used before building the analytical model.
  The output is diagnostic: source records are preserved and questionable
  records are surfaced instead of silently deleted.
*/

USE EcommerceAnalytics;
GO

-- Duplicate business keys in source files.
SELECT 'customers.customer_id' AS test_name, customer_id, COUNT(*) AS occurrences
FROM staging.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT 'orders.order_id' AS test_name, order_id, COUNT(*) AS occurrences
FROM staging.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT 'products.product_id' AS test_name, product_id, COUNT(*) AS occurrences
FROM staging.products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT 'sellers.seller_id' AS test_name, seller_id, COUNT(*) AS occurrences
FROM staging.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;
GO

-- Orders with invalid chronological sequences.
SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM staging.orders
WHERE (order_approved_at < order_purchase_timestamp)
   OR (order_delivered_carrier_date < order_approved_at)
   OR (order_delivered_customer_date < order_delivered_carrier_date);
GO

-- Orphan checks for the principal relationships.
SELECT 'order_items_without_order' AS test_name, COUNT_BIG(*) AS issue_count
FROM staging.order_items oi
LEFT JOIN staging.orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'payments_without_order', COUNT_BIG(*)
FROM staging.order_payments p
LEFT JOIN staging.orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'reviews_without_order', COUNT_BIG(*)
FROM staging.order_reviews r
LEFT JOIN staging.orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orders_without_customer', COUNT_BIG(*)
FROM staging.orders o
LEFT JOIN staging.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
GO

-- Null and invalid amount checks.
SELECT
    SUM(CASE WHEN price IS NULL OR price < 0 THEN 1 ELSE 0 END) AS invalid_price_rows,
    SUM(CASE WHEN freight_value IS NULL OR freight_value < 0 THEN 1 ELSE 0 END) AS invalid_freight_rows
FROM staging.order_items;

SELECT
    SUM(CASE WHEN payment_value IS NULL OR payment_value < 0 THEN 1 ELSE 0 END) AS invalid_payment_rows,
    SUM(CASE WHEN payment_installments IS NULL OR payment_installments < 0 THEN 1 ELSE 0 END) AS invalid_installment_rows
FROM staging.order_payments;
GO


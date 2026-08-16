/* Idempotent full refresh for a portfolio-sized SQL Server model. */
USE EcommerceAnalytics;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DELETE FROM analytics.fact_reviews;
DELETE FROM analytics.fact_payments;
DELETE FROM analytics.fact_sales;
DELETE FROM analytics.fact_orders;
DELETE FROM analytics.dim_seller;
DELETE FROM analytics.dim_product;
DELETE FROM analytics.dim_customer;
DELETE FROM analytics.dim_date;

DECLARE @start_date date = (SELECT MIN(CAST(order_purchase_timestamp AS date)) FROM staging.orders);
DECLARE @end_date date = (SELECT MAX(CAST(order_estimated_delivery_date AS date)) FROM staging.orders);

;WITH dates AS
(
    SELECT @start_date AS full_date
    UNION ALL
    SELECT DATEADD(day, 1, full_date) FROM dates WHERE full_date < @end_date
)
INSERT analytics.dim_date(date_key, full_date, calendar_year, calendar_quarter, month_number, month_name, year_month)
SELECT CONVERT(int, CONVERT(char(8), full_date, 112)), full_date, YEAR(full_date), DATEPART(quarter, full_date),
       MONTH(full_date), DATENAME(month, full_date), CONVERT(char(7), full_date, 126)
FROM dates OPTION (MAXRECURSION 0);

;WITH customer_orders AS
(
    SELECT c.customer_id, c.customer_unique_id, c.customer_zip_code_prefix, c.customer_city, c.customer_state,
           MIN(CAST(o.order_purchase_timestamp AS date)) AS first_order_date,
           MAX(CAST(o.order_purchase_timestamp AS date)) AS last_order_date,
           COUNT(DISTINCT o.order_id) AS customer_order_count
    FROM staging.customers c
    LEFT JOIN staging.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_unique_id, c.customer_zip_code_prefix, c.customer_city, c.customer_state
)
INSERT analytics.dim_customer
    (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
     first_order_date, last_order_date, customer_order_count, is_repeat_customer)
SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
       first_order_date, last_order_date, customer_order_count,
       CONVERT(bit, CASE WHEN customer_order_count > 1 THEN 1 ELSE 0 END)
FROM customer_orders;

INSERT analytics.dim_product(product_id, category_name, category_name_english)
SELECT p.product_id, p.product_category_name, COALESCE(t.product_category_name_english, p.product_category_name)
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
  ON t.product_category_name = p.product_category_name;

INSERT analytics.dim_seller(seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state FROM staging.sellers;

INSERT analytics.fact_orders
    (order_id, customer_key, purchase_date_key, order_status, order_purchase_timestamp, order_approved_at,
     order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date,
     delivery_days, is_delivered, is_on_time, is_late)
SELECT o.order_id, c.customer_key, CONVERT(int, CONVERT(char(8), CAST(o.order_purchase_timestamp AS date), 112)),
       o.order_status, o.order_purchase_timestamp, o.order_approved_at, o.order_delivered_carrier_date,
       o.order_delivered_customer_date, o.order_estimated_delivery_date,
       CASE WHEN o.order_delivered_customer_date IS NOT NULL
            THEN CAST(DATEDIFF(minute, o.order_purchase_timestamp, o.order_delivered_customer_date) / 1440.0 AS decimal(10,2)) END,
       CONVERT(bit, CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END),
       CASE WHEN o.order_status = 'delivered' THEN CONVERT(bit, CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) END,
       CASE WHEN o.order_status = 'delivered' THEN CONVERT(bit, CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) END
FROM staging.orders o
JOIN analytics.dim_customer c ON c.customer_id = o.customer_id;

INSERT analytics.fact_sales(order_id, order_item_id, product_key, seller_key, price, freight_value)
SELECT i.order_id, i.order_item_id, p.product_key, s.seller_key, i.price, i.freight_value
FROM staging.order_items i
JOIN analytics.fact_orders o ON o.order_id = i.order_id
LEFT JOIN analytics.dim_product p ON p.product_id = i.product_id
LEFT JOIN analytics.dim_seller s ON s.seller_id = i.seller_id;

INSERT analytics.fact_payments(order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT p.order_id, p.payment_sequential, p.payment_type, p.payment_installments, p.payment_value
FROM staging.order_payments p JOIN analytics.fact_orders o ON o.order_id = p.order_id;

;WITH deduplicated_reviews AS
(
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY r.review_id ORDER BY r.review_answer_timestamp DESC, r.review_creation_date DESC) AS rn
    FROM staging.order_reviews r
)
INSERT analytics.fact_reviews(review_id, order_id, review_score, review_creation_date, review_answer_timestamp)
SELECT r.review_id, r.order_id, r.review_score, r.review_creation_date, r.review_answer_timestamp
FROM deduplicated_reviews r
JOIN analytics.fact_orders o ON o.order_id = r.order_id
WHERE r.rn = 1;

COMMIT TRANSACTION;
GO

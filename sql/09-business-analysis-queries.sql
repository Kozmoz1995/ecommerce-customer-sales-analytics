USE EcommerceAnalytics;
GO

-- Executive monthly trend. Payment value is the project's Gross Sales definition.
SELECT d.year_month, COUNT(DISTINCT o.order_id) AS total_orders, SUM(p.payment_value) AS gross_sales
FROM analytics.fact_orders o
JOIN analytics.dim_date d ON d.date_key = o.purchase_date_key
LEFT JOIN analytics.fact_payments p ON p.order_id = o.order_id
GROUP BY d.year_month ORDER BY d.year_month;

-- Delivery performance by customer state.
SELECT c.customer_state, AVG(o.delivery_days) AS average_delivery_days,
       SUM(CONVERT(int, o.is_late)) AS late_orders,
       SUM(CONVERT(int, o.is_on_time)) AS on_time_orders
FROM analytics.fact_orders o
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
WHERE o.is_delivered = 1
GROUP BY c.customer_state ORDER BY late_orders DESC;

-- Customer repeat behavior uses the stable unique customer identifier.
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers,
       COUNT(DISTINCT CASE WHEN is_repeat_customer = 1 THEN customer_unique_id END) AS repeat_customers
FROM analytics.dim_customer;

-- Review distribution.
SELECT review_score, COUNT_BIG(*) AS review_count
FROM analytics.fact_reviews GROUP BY review_score ORDER BY review_score;
GO

USE EcommerceAnalytics;
GO

CREATE OR ALTER VIEW reporting.vw_order_performance AS
SELECT o.order_id, c.customer_unique_id, c.customer_state, d.full_date, d.year_month,
       o.order_status, o.delivery_days, o.is_delivered, o.is_on_time, o.is_late
FROM analytics.fact_orders o
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
LEFT JOIN analytics.dim_date d ON d.date_key = o.purchase_date_key;
GO

CREATE OR ALTER VIEW reporting.vw_sales_detail AS
SELECT s.order_id, s.order_item_id, d.full_date, d.year_month, c.customer_state,
       p.category_name_english, se.seller_state, s.price, s.freight_value, s.item_gross_value
FROM analytics.fact_sales s
JOIN analytics.fact_orders o ON o.order_id = s.order_id
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
LEFT JOIN analytics.dim_date d ON d.date_key = o.purchase_date_key
LEFT JOIN analytics.dim_product p ON p.product_key = s.product_key
LEFT JOIN analytics.dim_seller se ON se.seller_key = s.seller_key;
GO

CREATE OR ALTER VIEW reporting.vw_payment_detail AS
SELECT p.payment_key, p.order_id, d.full_date, d.year_month, c.customer_state,
       p.payment_type, p.payment_installments, p.payment_value
FROM analytics.fact_payments p
JOIN analytics.fact_orders o ON o.order_id = p.order_id
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
LEFT JOIN analytics.dim_date d ON d.date_key = o.purchase_date_key;
GO

CREATE OR ALTER VIEW reporting.vw_review_detail AS
SELECT r.review_id, r.order_id, r.review_score, r.is_positive_review, r.is_negative_review,
       r.review_creation_date, c.customer_state, d.year_month
FROM analytics.fact_reviews r
JOIN analytics.fact_orders o ON o.order_id = r.order_id
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
LEFT JOIN analytics.dim_date d ON d.date_key = o.purchase_date_key;
GO

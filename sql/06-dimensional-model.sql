/* Analytics star schema. Run after 01-05. */
USE EcommerceAnalytics;
GO

DROP TABLE IF EXISTS analytics.fact_reviews;
DROP TABLE IF EXISTS analytics.fact_payments;
DROP TABLE IF EXISTS analytics.fact_sales;
DROP TABLE IF EXISTS analytics.fact_orders;
DROP TABLE IF EXISTS analytics.dim_seller;
DROP TABLE IF EXISTS analytics.dim_product;
DROP TABLE IF EXISTS analytics.dim_customer;
DROP TABLE IF EXISTS analytics.dim_date;
GO

CREATE TABLE analytics.dim_date
(
    date_key int NOT NULL PRIMARY KEY,
    full_date date NOT NULL UNIQUE,
    calendar_year smallint NOT NULL,
    calendar_quarter tinyint NOT NULL,
    month_number tinyint NOT NULL,
    month_name varchar(12) NOT NULL,
    year_month char(7) NOT NULL
);

CREATE TABLE analytics.dim_customer
(
    customer_key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_id varchar(50) NOT NULL UNIQUE,
    customer_unique_id varchar(50) NOT NULL,
    customer_zip_code_prefix int NULL,
    customer_city nvarchar(100) NULL,
    customer_state char(2) NULL,
    first_order_date date NULL,
    last_order_date date NULL,
    customer_order_count int NOT NULL,
    is_repeat_customer bit NOT NULL
);

CREATE TABLE analytics.dim_product
(
    product_key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    product_id varchar(50) NOT NULL UNIQUE,
    category_name nvarchar(100) NULL,
    category_name_english nvarchar(100) NULL
);

CREATE TABLE analytics.dim_seller
(
    seller_key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seller_id varchar(50) NOT NULL UNIQUE,
    seller_zip_code_prefix int NULL,
    seller_city nvarchar(100) NULL,
    seller_state char(2) NULL
);

CREATE TABLE analytics.fact_orders
(
    order_id varchar(50) NOT NULL PRIMARY KEY,
    customer_key int NOT NULL,
    purchase_date_key int NULL,
    order_status varchar(30) NOT NULL,
    order_purchase_timestamp datetime2 NULL,
    order_approved_at datetime2 NULL,
    order_delivered_carrier_date datetime2 NULL,
    order_delivered_customer_date datetime2 NULL,
    order_estimated_delivery_date datetime2 NULL,
    delivery_days decimal(10,2) NULL,
    is_delivered bit NOT NULL,
    is_on_time bit NULL,
    is_late bit NULL,
    CONSTRAINT FK_fact_orders_customer FOREIGN KEY (customer_key) REFERENCES analytics.dim_customer(customer_key),
    CONSTRAINT FK_fact_orders_date FOREIGN KEY (purchase_date_key) REFERENCES analytics.dim_date(date_key)
);

CREATE TABLE analytics.fact_sales
(
    sales_key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    order_id varchar(50) NOT NULL,
    order_item_id int NOT NULL,
    product_key int NULL,
    seller_key int NULL,
    price decimal(18,2) NOT NULL,
    freight_value decimal(18,2) NOT NULL,
    item_gross_value AS (price + freight_value) PERSISTED,
    CONSTRAINT UQ_fact_sales_order_item UNIQUE(order_id, order_item_id),
    CONSTRAINT FK_fact_sales_order FOREIGN KEY (order_id) REFERENCES analytics.fact_orders(order_id),
    CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_key) REFERENCES analytics.dim_product(product_key),
    CONSTRAINT FK_fact_sales_seller FOREIGN KEY (seller_key) REFERENCES analytics.dim_seller(seller_key)
);

CREATE TABLE analytics.fact_payments
(
    payment_key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    order_id varchar(50) NOT NULL,
    payment_sequential int NOT NULL,
    payment_type varchar(30) NULL,
    payment_installments int NULL,
    payment_value decimal(18,2) NOT NULL,
    CONSTRAINT UQ_fact_payments_order_sequence UNIQUE(order_id, payment_sequential),
    CONSTRAINT FK_fact_payments_order FOREIGN KEY (order_id) REFERENCES analytics.fact_orders(order_id)
);

CREATE TABLE analytics.fact_reviews
(
    review_key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    review_id varchar(50) NOT NULL,
    order_id varchar(50) NOT NULL,
    review_score tinyint NOT NULL,
    review_creation_date datetime2 NULL,
    review_answer_timestamp datetime2 NULL,
    is_positive_review AS (CONVERT(bit, CASE WHEN review_score >= 4 THEN 1 ELSE 0 END)) PERSISTED,
    is_negative_review AS (CONVERT(bit, CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)) PERSISTED,
    CONSTRAINT UQ_fact_reviews_review UNIQUE(review_id),
    CONSTRAINT CK_fact_reviews_score CHECK(review_score BETWEEN 1 AND 5),
    CONSTRAINT FK_fact_reviews_order FOREIGN KEY (order_id) REFERENCES analytics.fact_orders(order_id)
);
GO

/*
  Source-data contract
  --------------------
  This script documents the source objects expected by the transformation
  pipeline. It deliberately does not overwrite imported data.

  Required staging tables:
    staging.customers
    staging.orders
    staging.order_items
    staging.order_payments
    staging.order_reviews
    staging.products
    staging.sellers
    staging.geolocation
    staging.product_category_name_translation
*/

USE EcommerceAnalytics;
GO

DECLARE @required TABLE (table_name sysname);
INSERT INTO @required (table_name)
VALUES
    (N'customers'), (N'orders'), (N'order_items'),
    (N'order_payments'), (N'order_reviews'), (N'products'),
    (N'sellers'), (N'geolocation'),
    (N'product_category_name_translation');

SELECT
    r.table_name,
    CASE WHEN t.object_id IS NULL THEN 'MISSING' ELSE 'AVAILABLE' END AS load_status,
    COALESCE(SUM(p.rows), 0) AS row_count
FROM @required r
LEFT JOIN sys.tables t
    ON t.name = r.table_name
   AND SCHEMA_NAME(t.schema_id) = N'staging'
LEFT JOIN sys.partitions p
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)
GROUP BY r.table_name, t.object_id
ORDER BY r.table_name;
GO


# Project workflow

## 1. Define the analytical questions

The dashboard was designed to answer four decisions: overall commercial performance, delivery reliability, customer value and retention, and customer experience.

## 2. Stage the source data

Raw customer, order, item, payment, review, product, seller, category-translation and geolocation files are loaded unchanged into the `staging` schema. Keeping staging separate makes the transformation auditable.

## 3. Validate data quality

Checks identify duplicate business keys, invalid timestamps, orphan records, invalid monetary values and review scores outside 1-5. Blocking issues should be corrected before facts are loaded.

## 4. Produce one location per postcode

For every postcode prefix, coordinates are averaged, the most frequent city-state pair is selected with a deterministic tie-breaker, and the source row count is retained as a quality indicator.

## 5. Perform the first financial reconciliation

Product and freight totals are aggregated per order and compared with payment totals. Both sides are aggregated before the join to avoid payment-item row multiplication. Differences are classified as matched, missing on either side, or mismatched.

## 6. Build the star schema

Dimensions provide reusable filters; facts preserve their natural grains. Order, item, payment and review data stay in separate fact tables.

## 7. Create Power BI measures

DAX measures explicitly define denominators and filters. Delivery rates use delivered orders, customer counts use the stable unique-customer ID, and gross sales use captured payments.

## 8. Design four report pages

- Executive Overview: a concise health check for sales, demand, customers, delivery and reviews.
- Delivery & Operations: delivery speed, lateness and geographic bottlenecks.
- Customer & Sales Insights: category/state contribution, repeat behavior and payment mix.
- Customer Experience & Reviews: score distribution and experience trends.

## 9. Validate and document

SQL totals are compared with Power BI cards and filtered samples. Metric definitions, grains, assumptions and screenshots are stored with the project so another analyst can reproduce the logic.

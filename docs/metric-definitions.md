# Metric definitions

| Metric | Business definition | Grain / source | Guardrail |
|---|---|---|---|
| Total Orders | Distinct order IDs | One row per order, `Fact Orders` | Do not count item or payment rows |
| Gross Sales | Sum of captured payment value | Payment transaction, `Fact Payments` | Reconcile with product + freight at order grain |
| Average Order Value | Gross Sales / Total Orders | Measure | Returns blank if no orders |
| Total Customers | Distinct stable `customer_unique_id` | Customer dimension | Do not use order-specific `customer_id` |
| Repeat Customers | Customers with more than one order | Customer dimension | Calculated across the selected filter context |
| Delivered Orders | Orders whose status is delivered | Order fact | Excludes shipped/canceled/unavailable |
| On-Time Orders | Delivered at or before estimated date | Order fact | Only delivered orders are eligible |
| On-Time Delivery Rate | On-Time Orders / Delivered Orders | Measure | Not divided by all orders |
| Average Delivery Days | Purchase-to-customer-delivery elapsed days | Delivered orders | Missing delivery dates excluded |
| Review Count | Distinct review IDs | Review fact | Duplicate review IDs retain latest response |
| Positive Review Rate | Scores 4-5 / all reviews | Review fact | Neutral score 3 is neither positive nor negative |
| Negative Review Rate | Scores 1-2 / all reviews | Review fact | Track with review coverage |

## KPI hierarchy

- Business outcomes: Gross Sales, Total Orders, Total Customers.
- Operating drivers: On-Time Delivery Rate, Average Delivery Days, Late Orders.
- Customer health: Repeat Customer Rate, Average Review Score, Positive/Negative Review Rate.
- Data guardrails: financial reconciliation difference, orphan records, duplicate business keys and review coverage.

The dashboard values are descriptive baselines, not performance targets. Targets should be set only after confirming the evaluation period and business expectations.

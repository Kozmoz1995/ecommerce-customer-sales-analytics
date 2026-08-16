# Power BI DAX measures

The model uses one-to-many relationships from dimensions to facts. Keep relationships single-directional unless a documented use case requires otherwise.

```DAX
Total Orders =
DISTINCTCOUNT ( 'Fact Orders'[order_id] )

Delivered Orders =
CALCULATE ( [Total Orders], 'Fact Orders'[is_delivered] = TRUE () )

On-Time Orders =
CALCULATE ( [Total Orders], 'Fact Orders'[is_on_time] = TRUE () )

Late Orders =
CALCULATE ( [Total Orders], 'Fact Orders'[is_late] = TRUE () )

On-Time Delivery Rate =
DIVIDE ( [On-Time Orders], [Delivered Orders] )

Average Delivery Days =
CALCULATE (
    AVERAGE ( 'Fact Orders'[delivery_days] ),
    'Fact Orders'[is_delivered] = TRUE ()
)

Gross Sales =
SUM ( 'Fact Payments'[payment_value] )

Average Order Value =
DIVIDE ( [Gross Sales], [Total Orders] )

Total Customers =
DISTINCTCOUNT ( 'Dim Customer'[customer_unique_id] )

Repeat Customers =
CALCULATE (
    DISTINCTCOUNT ( 'Dim Customer'[customer_unique_id] ),
    'Dim Customer'[is_repeat_customer] = TRUE ()
)

Repeat Customer Rate =
DIVIDE ( [Repeat Customers], [Total Customers] )

Review Count =
DISTINCTCOUNT ( 'Fact Reviews'[review_id] )

Average Review Score =
AVERAGE ( 'Fact Reviews'[review_score] )

Positive Reviews =
CALCULATE ( [Review Count], 'Fact Reviews'[review_score] >= 4 )

Negative Reviews =
CALCULATE ( [Review Count], 'Fact Reviews'[review_score] <= 2 )

Positive Review Rate =
DIVIDE ( [Positive Reviews], [Review Count] )

Negative Review Rate =
DIVIDE ( [Negative Reviews], [Review Count] )

Canceled Orders =
CALCULATE ( [Total Orders], 'Fact Orders'[order_status] = "canceled" )

Cancellation Rate =
DIVIDE ( [Canceled Orders], [Total Orders] )
```

## Formatting

- Currency: `Gross Sales`, `Average Order Value`
- Percentage, two decimals: delivery, repeat, positive, negative and cancellation rates
- Whole number: order, customer and review counts
- Decimal, two places: average delivery days and average review score

## Important modeling note

`Gross Sales` is calculated from captured payment value. Product price plus freight belongs to `Fact Sales` and is used for financial reconciliation. Combining both facts directly in a visual can multiply rows; aggregate by `order_id` or use the supplied measures and relationships.

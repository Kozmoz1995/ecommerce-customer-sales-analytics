# Data

## Included file

`raw/olist_order_payments_dataset.csv`

- Grain: one payment sequence within an order
- Rows: 103,886
- Size: approximately 5.8 MB
- Primary candidate key: `order_id`, `payment_sequential`
- Missing values found in the five expected fields: 0
- Duplicate candidate keys found: 0

## Columns

| Column | Meaning | Expected type |
|---|---|---|
| `order_id` | Anonymous order identifier | varchar(50) |
| `payment_sequential` | Payment sequence within an order | integer |
| `payment_type` | credit_card, boleto, voucher, debit_card or not_defined | varchar(30) |
| `payment_installments` | Number of installments | integer |
| `payment_value` | Captured payment amount | decimal(18,2) |

## Observed payment-type rows

| Payment type | Rows |
|---|---:|
| credit_card | 76,795 |
| boleto | 19,784 |
| voucher | 5,775 |
| debit_card | 1,529 |
| not_defined | 3 |

## Usage

Import this file into `staging.order_payments`, then run the quality checks and financial reconciliation scripts. `Gross Sales` is calculated as the sum of `payment_value` in the Power BI model.

Do not join this table directly to order items and sum both monetary fields. Aggregate payments and items independently at `order_id` grain before comparison to avoid many-to-many multiplication.

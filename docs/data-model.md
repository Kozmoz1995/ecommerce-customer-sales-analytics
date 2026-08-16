# Data model

The project uses a star schema so each KPI is evaluated at a controlled grain.

```text
Dim Date -------- Fact Orders -------- Dim Customer
                      |
          +-----------+-----------+
          |           |           |
      Fact Sales  Fact Payments  Fact Reviews
          | \
 Dim Product  Dim Seller
```

## Table grains

| Table | Grain |
|---|---|
| Dim Date | One calendar day |
| Dim Customer | One source customer ID with stable unique-customer attributes |
| Dim Product | One product |
| Dim Seller | One seller |
| Fact Orders | One order |
| Fact Sales | One order item |
| Fact Payments | One payment sequence within an order |
| Fact Reviews | One deduplicated review |

Dimensions filter facts with one-to-many, single-direction relationships. `Fact Sales`, `Fact Payments`, and `Fact Reviews` must not be joined directly to one another because their different grains create many-to-many multiplication.

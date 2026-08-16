# SQL execution order

1. `01-create-database-and-schemas.sql`
2. Load the raw CSV files into the `staging` tables described by `02-source-data-contract.sql`.
3. Run `03-data-quality-and-cleaning.sql` and resolve blocking exceptions.
4. Run `04-geolocation-transformation.sql`.
5. Run `05-financial-reconciliation.sql` and inspect unmatched/different orders.
6. Run `06-dimensional-model.sql`.
7. Run `07-load-dimensional-model.sql`.
8. Run `08-reporting-views.sql`.
9. Use `09-business-analysis-queries.sql` for validation and exploration.

The scripts target Microsoft SQL Server. Raw ingestion is intentionally separated because file paths and import permissions vary by environment.

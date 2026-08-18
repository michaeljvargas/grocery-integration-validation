# Grocery Integration Validation Pipeline

This project simulates the process of receiving, validating, and reconciling a grocery retailer's operational data before it moves into a downstream analytics or forecasting system.

I built it to practice the kind of work that sits between data engineering, analytics, and customer integrations: understanding a source dataset, defining the data model, validating incoming records, identifying data-quality issues, and making sure every record can be accounted for.

## Project Goals

The main goals of the project were to:

- Understand the structure and grain of an unfamiliar retail dataset
- Design a relational target model
- Load and transform the source data into SQLite
- Simulate a customer feed with realistic integration issues
- Build SQL checks for data quality and reconciliation
- Flag issues at the individual row level
- Route records into accepted, quarantined, and rejected outputs
- Reconcile the final results back to the original feed volume

## Source Data

The source dataset contains daily retail inventory and sales information across multiple stores and products.

Key fields include:

- Date
- Store ID
- Product ID
- Category
- Region
- Inventory Level
- Units Sold
- Units Ordered
- Demand Forecast
- Price
- Discount
- Weather Condition
- Holiday / Promotion
- Competitor Pricing
- Seasonality

The clean source contains:

- 73,100 records
- 5 stores
- 20 products
- 731 unique dates
- 100 Store / Product observations per date

The expected grain is:

`Date + Store ID + Product ID`

## Data Model

I split the clean source into three main tables:

### stores

`store_id`

### products

`product_id`

### daily_operations

Contains the daily operational values for each Store / Product / Date combination.

The composite primary key is:

`date + store_id + product_id`

## Simulated Customer Feed

To make the project more realistic, I created a second version of the source data and intentionally introduced several integration issues.

The simulated customer feed contains 73,130 records and includes:

- Unknown Store IDs
- Unmapped Product IDs
- Missing Product IDs
- Negative Inventory values
- Duplicate business keys

This gives the project a known set of defects that the validation process should be able to detect.

## Validation Process

The validation process checks:

- Total records received
- Required identifiers
- Store references
- Product references
- Negative operational values
- Duplicate business keys
- Row-level validation failures

One of the main things I found while building this was that aggregate error counts can be misleading because one row can fail multiple validation rules.

Because of that, I moved the validation logic to the row level and assigned flags to each record.

## Final Classification

Every incoming record receives one of three statuses:

### ACCEPT

The record passed all implemented validation checks.

### QUARANTINE

The record contains an issue that should be investigated before it is allowed downstream.

Examples include:

- Unknown stores
- Unmapped products
- Negative inventory
- Duplicate business keys

### REJECT

The record is missing information required to reliably process it.

The current rejection rule applies to missing Product IDs.

## Reconciliation Results

| Status | Records |
|---|---:|
| Total Received | 73,130 |
| Accepted | 72,970 |
| Quarantined | 145 |
| Rejected | 15 |
| Unreconciled | 0 |

The pipeline accounts for every record received.

Rule-level exception counts were:

| Validation Rule | Rows |
|---|---:|
| Missing Product ID | 15 |
| Unknown Store | 25 |
| Unmapped Product | 40 |
| Negative Inventory | 20 |
| Duplicate Business Key | 125 |

These values are not added together because some records violate more than one rule.

Row-level validation identified 160 unique affected records.

## Project Workflow

`Source Data`

↓

`Source Discovery`

↓

`Relational Data Model`

↓

`SQLite Load`

↓

`Simulated Customer Feed`

↓

`Raw Staging`

↓

`SQL Validation`

↓

`Row-Level Classification`

↓

`Accept / Quarantine / Reject`

↓

`Reconciliation`

## Repository Structure

```text
grocery-integration-validation/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── notebooks/
│   └── 01_source_discovery.ipynb
│
├── reports/
│   └── integration_findings.md
│
├── scripts/
│   ├── generate_customer_feed.py
│   ├── load_database.py
│   ├── run_sql_script.py
│   └── run_validation.py
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_source_to_target_validation.sql
│   ├── 03_data_quality_checks.sql
│   ├── 04_customer_feed_validation.sql
│   ├── 05_row_level_validation.sql
│   ├── 06_reconciliation_summary.sql
│   ├── 07_classify_customer_feed.sql
│   ├── 08_classification_summary.sql
│   ├── 09_reconciliation_report.sql
│   ├── 10_exception_summary.sql
│   ├── 11_persist_classified_outputs.sql
│   └── 12_persisted_output_validation.sql
│
├── .gitignore
└── README.md

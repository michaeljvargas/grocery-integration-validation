# Grocery Integration Validation — Findings

## Overview

For this project, I wanted to simulate what happens when a grocery retailer sends an operational data feed that needs to be validated before it can be used downstream.

I started with a clean retail inventory dataset containing 73,100 records and created a simulated customer feed with several common integration issues. I then loaded the data into SQLite and used SQL to validate, classify, and reconcile the incoming records.

The simulated customer feed contained 73,130 total records.

My final reconciliation was:

| Status | Records |
|---|---:|
| Total Received | 73,130 |
| Accepted | 72,970 |
| Quarantined | 145 |
| Rejected | 15 |
| Unreconciled | 0 |

The main goal was to make sure that every incoming record could be accounted for instead of simply identifying a list of errors.

## What I Found

My validation checks identified several different types of issues in the customer feed:

| Validation Check | Rows |
|---|---:|
| Missing Product ID | 15 |
| Unknown Store | 25 |
| Unmapped Product | 40 |
| Negative Inventory | 20 |
| Duplicate Business Key | 125 |

One thing I found while working through the reconciliation was that these numbers cannot simply be added together.

A single row can fail multiple validation rules.

Because of that, I moved from looking only at error counts to validating the data at the individual row level.

That showed that 160 unique records were affected by at least one validation rule.

## Duplicate Records

I defined the expected grain of the operational data as:

`Date + Store ID + Product ID`

I then used that combination to identify duplicate business keys.

The validation found 125 rows that belonged to duplicate-key groups.

Earlier in the analysis, I also calculated 86 excess records within those groups.

Those are two different measurements.

The 125 represents every row participating in a duplicated business key, while the 86 represents the occurrences beyond the first record in each duplicate group.

I also did not assume that a duplicate business key meant the entire row was identical. Two records can have the same Date, Store ID, and Product ID while containing different operational values.

Because of that, I decided to quarantine duplicate-key records rather than automatically delete them.

## How I Classified the Records

After identifying the issues, I assigned each incoming row one of three statuses: ACCEPT, QUARANTINE, or REJECT.

### ACCEPT

I accepted records that passed all of the validation rules.

**72,970 records were accepted.**

These records are stored in the `accepted_customer_feed` table and represent the records that could continue downstream.

### QUARANTINE

I used quarantine for records where I had enough information to preserve the record, but I would want the issue investigated before allowing it downstream.

This included:

- Unknown stores
- Unmapped products
- Negative inventory
- Duplicate business keys

**145 records were quarantined.**

I chose quarantine instead of automatically rejecting or modifying these records because some of these issues could have legitimate explanations.

For example, an unmapped product could simply be a new product that has not been added to the mapping yet.

### REJECT

I rejected records where the Product ID was missing.

Without a Product ID, I could not reliably determine which product the operational record belonged to.

**15 records were rejected.**

## Reconciliation

The final step was making sure every record received had a disposition.

My final reconciliation was:

73,130 received  
- 72,970 accepted  
- 145 quarantined  
- 15 rejected  
= **0 unreconciled records**

This was important because the individual validation counts alone did not explain what happened to the complete customer feed.

By moving the validation to the row level, I was able to account for overlapping errors and determine exactly how many unique records were affected.

## How I Approached the Investigation

One thing I wanted to avoid was immediately assuming that a discrepancy was either the customer's fault or the integration's fault.

Instead, I approached the problem as a reconciliation exercise.

I first confirmed how many records were actually received. From there, I checked required identifiers, store and product mappings, operational values, and duplicate business keys.

Once I found that some records were triggering multiple validation rules, I added row-level validation flags rather than relying only on aggregate error counts.

That allowed me to move from:

"How many errors are there?"

to:

"Which records have issues, what is wrong with them, and what should happen to each one?"

## Final Pipeline

The final workflow for the project is:

`Customer Feed → Raw Staging → Validation → Row-Level Classification → Accept / Quarantine / Reject → Reconciliation`

The project now produces a clean set of accepted records as well as a separate exception dataset containing the records that need investigation.

The biggest takeaway for me was that finding an error count is only part of integration validation. The more important part is being able to trace the issue back to specific records, determine whether different validation failures overlap, decide how those records should be handled, and reconcile everything back to the original file.
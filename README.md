# Products Inventory — Oracle APEX CRUD app on OCI

A starter, version-controllable **Oracle APEX** data-entry / CRUD application
that runs on **Oracle Cloud Infrastructure (OCI)** Autonomous Database (where
APEX and ORDS are pre-installed and managed).

## What's here

```
db/install/
  01_tables.sql           Categories + Products tables, constraints, indexes, audit triggers
  02_sample_data.sql      Seed rows so the app shows data immediately
  03_products_api.sql     PL/SQL CRUD API + PRODUCTS_V reporting view
  04_fusion_expenses.sql  Pull Expense Reports from Oracle Fusion via REST -> staging table
ords/
  enable_rest.sql         Optional: auto-REST the products table via ORDS
scripts/
  test_fusion_api.sh      curl smoke test for the Fusion Expenses REST API
apex/
  README_app_build.md      Steps to generate, customise, and export the CRUD app
  README_fusion_expenses.md Steps to build the "Expenses from Fusion" page
```

## Oracle Fusion expense reports (REST integration)

A second feature pulls **Expense Reports** from **Oracle Fusion Cloud
Financials** and displays them in APEX:

- Endpoint: `GET /fscmRestApi/resources/11.13.18.05/expenseReports`
- Auth: HTTP Basic — you supply the Fusion user id / password in the app at runtime.
- `db/install/04_fusion_expenses.sql` installs a staging table + `fusion_expenses_pkg`
  that calls the API via `apex_web_service` and parses the JSON with `apex_json`.
- `scripts/test_fusion_api.sh` lets you verify connectivity with `curl` first.
- `apex/README_fusion_expenses.md` walks through building the page.

## Prerequisites on OCI

1. An **Autonomous Database** (ATP or ADW) instance — APEX + ORDS come built in.
2. From the database's **Tools** tab, open **APEX** and create a **workspace**
   mapped to your application schema.

## Quick start

Run the install scripts (in order) against your workspace schema — via
**SQL Workshop → SQL Scripts**, **SQLcl**, or **SQL Developer**:

```sql
@db/install/01_tables.sql
@db/install/02_sample_data.sql
@db/install/03_products_api.sql
-- optional REST layer:
@ords/enable_rest.sql
```

Then follow `apex/README_app_build.md` to generate the CRUD app from the
`PRODUCTS` table (one wizard pass) and export it back into `apex/` for git.

## How I can help from here

I can't reach your OCI tenancy or the APEX web UI directly, but I can author and
maintain everything that lives as code: schema changes, PL/SQL logic, ORDS REST
modules, OCI/Terraform provisioning, and CI scripts to round-trip the APEX
export through this repo. Tell me which to extend next.

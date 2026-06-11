# Expense Reports from Oracle Fusion — APEX setup

This adds a page where you enter your Oracle **Fusion** credentials, click
**Fetch**, and see your expense reports in an interactive report.

Data flow:

```
APEX page (host + user + password)
        │  calls
        ▼
FUSION_EXPENSES_PKG.FETCH_REPORTS   ──HTTP Basic──►  Fusion REST API
        │  MERGE                                     /fscmRestApi/resources/
        ▼                                            11.13.18.05/expenseReports
FUSION_EXPENSE_REPORTS  ◄── interactive report displays this
```

## 0. Prerequisites (one-time, on OCI Autonomous Database)

1. Install the objects: run `db/install/04_fusion_expenses.sql` in your schema.
2. **Allow network egress** to the Fusion host (ADB blocks outbound HTTP by
   default). As the schema owner (or ADMIN granting your schema):
   ```sql
   BEGIN
     DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
       host => 'your-fusion-host.fa.ocs.oraclecloud.com',
       ace  => xs$ace_type(privilege_list => xs$name_list('http'),
                           principal_name => '<YOUR_SCHEMA>',
                           principal_type => xs_acl.ptype_db));
   END;
   /
   ```
3. Fusion uses HTTPS. On ADB the system wallet usually already trusts public
   CAs. If you hit a TLS/wallet error from `apex_web_service`, set the wallet on
   the APEX instance (Workspace **only** option: configure a **Web Credential**
   and a wallet via the APEX instance admin, or use `UTL_HTTP.SET_WALLET`).

## 1. Build the page

1. In **App Builder**, add a **Blank Page** named *Expenses*.
2. Add a **Static Content** region "Connection" with three page items:
   | Item | Type | Notes |
   |------|------|-------|
   | `P_FUSION_HOST` | Text Field | e.g. `your-fusion-host.fa.ocs.oraclecloud.com` |
   | `P_FUSION_USER` | Text Field | Fusion user id |
   | `P_FUSION_PASS` | **Password** | uncheck *Submitting this page includes the value in session state* if you don't want it persisted |
   *(Optional)* `P_STATUS` Select List to filter by status.
3. Add a **Button** `FETCH` (Action: *Submit Page*).

## 2. Add the fetch process

Create a **Page Process** (type *PL/SQL Code*), **When Button Pressed = FETCH**:

```sql
declare
  l_loaded pls_integer;
begin
  l_loaded := fusion_expenses_pkg.fetch_reports(
                p_base_url => 'https://' || :P_FUSION_HOST,
                p_username => :P_FUSION_USER,
                p_password => :P_FUSION_PASS,
                p_status   => :P_STATUS );   -- omit/null for all
  apex_application.g_print_success_message :=
    l_loaded || ' expense report(s) loaded.';
end;
```

Add a matching error handling so `raise_application_error` messages (bad
credentials, HTTP errors) show as a page notification.

## 3. Display the reports

Add an **Interactive Report** region below, source **Table** =
`FUSION_EXPENSE_REPORTS` (or this SQL for nicer columns):

```sql
select report_number       as "Report #",
       report_status       as "Status",
       report_total        as "Total",
       currency_code       as "Ccy",
       purpose             as "Purpose",
       report_date         as "Report Date",
       final_approval_date as "Approved",
       fetched_on          as "Last Fetched"
from   fusion_expense_reports
order  by report_date desc nulls last;
```

Click **Fetch** → the report populates.

## Security note (recommended hardening)

Entering a password in a page item is fine for a quick test. For anything
beyond that, use APEX **Web Credentials**: store the Fusion user/password (or an
OAuth client) once under *Workspace Utilities → Web Credentials*, give it a
static ID, and pass `p_credential_static_id` to `apex_web_service.make_rest_request`
instead of `p_username`/`p_password`. Credentials are then encrypted and never
rendered to the browser. The package can be extended to accept a credential
static id — ask and I'll add that variant.

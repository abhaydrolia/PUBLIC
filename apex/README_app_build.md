# Building the Products CRUD app in APEX

The schema in `db/install/` is designed so APEX generates a complete CRUD app
(interactive report + searchable form, with create/edit/delete) in one pass.

## 1. Generate the application

1. Open **App Builder** in your workspace.
2. **Create** → **New Application** → **From a Table** (a.k.a. *Create Application*
   with the *Add Page → Interactive Report + Form* on a table).
3. Choose the table **`PRODUCTS`**. APEX will create:
   - an **Interactive Report** page listing products, and
   - a **Form** page for insert / update / delete.
4. For nicer category display, after generation edit the report page to use the
   **`PRODUCTS_V`** view as the source (it already resolves `CATEGORY_NAME` and
   computes `INVENTORY_VALUE`).
5. On the **Form** page, set the `CATEGORY_ID` item type to **Select List** with
   a LOV:
   ```sql
   select category_name as d, category_id as r
   from   categories
   order by category_name
   ```

That's the entire CRUD app — no manual page wiring required.

## 2. (Optional) Route DML through the PL/SQL API

If you want the business rules in `products_api` enforced from the form instead
of APEX's automatic row processing:

- On the Form page, change the **Form region** *Target* to **PL/SQL**, or
- replace the automatic *Process form* DML process with a process of type
  **Invoke API** pointing at `PRODUCTS_API.CREATE_PRODUCT` /
  `UPDATE_PRODUCT` / `DELETE_PRODUCT`.

`raise_application_error(-20001, ...)` messages surface as inline form errors.

## 3. Export the finished app back into this repo (version control)

Once the app exists, export it so it lives in git. Using **SQLcl**:

```bash
sql <user>/<password>@<adb_connect_string> <<'EOF'
apex export -applicationid 100 -split -dir apex/f100
EOF
```

Or in **App Builder**: *Export / Import* → *Export* → save the `f100.sql`
(or split export) under `apex/`. Commit that file — it becomes the
source-of-truth, importable definition for the app going forward.

> Why this repo doesn't ship a pre-built `f100.sql`: APEX exports are generated
> by the instance and are tied to the exact APEX version (e.g. 24.1 vs 23.2).
> Generating it from your own instance guarantees a clean re-import.

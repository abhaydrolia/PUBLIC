--------------------------------------------------------------------------------
-- 03_products_api.sql
-- PL/SQL table API for products. Keeps business rules in the database so they
-- are enforced regardless of whether changes come from APEX, ORDS, or SQL.
--
-- The generated APEX form can call these procedures from its DML processes
-- (set the form region's source to "PL/SQL" or use a process of type
-- "Invoke API"), or you can keep APEX's automatic row processing and use this
-- API for REST / batch integrations.
--------------------------------------------------------------------------------

create or replace package products_api as

  -- Raised when a business rule is violated. Maps to a friendly APEX error.
  e_validation exception;
  pragma exception_init (e_validation, -20001);

  procedure create_product (
    p_product_name in  products.product_name%type,
    p_sku          in  products.sku%type,
    p_category_id  in  products.category_id%type,
    p_unit_price   in  products.unit_price%type default 0,
    p_quantity     in  products.quantity%type   default 0,
    p_status       in  products.status%type      default 'ACTIVE',
    p_notes        in  products.notes%type        default null,
    p_product_id   out products.product_id%type
  );

  procedure update_product (
    p_product_id   in products.product_id%type,
    p_product_name in products.product_name%type,
    p_sku          in products.sku%type,
    p_category_id  in products.category_id%type,
    p_unit_price   in products.unit_price%type,
    p_quantity     in products.quantity%type,
    p_status       in products.status%type,
    p_notes        in products.notes%type
  );

  procedure delete_product (
    p_product_id in products.product_id%type
  );

end products_api;
/

create or replace package body products_api as

  procedure validate (
    p_product_name in products.product_name%type,
    p_sku          in products.sku%type,
    p_unit_price   in products.unit_price%type,
    p_quantity     in products.quantity%type
  ) is
  begin
    if trim(p_product_name) is null then
      raise_application_error(-20001, 'Product name is required.');
    end if;
    if trim(p_sku) is null then
      raise_application_error(-20001, 'SKU is required.');
    end if;
    if p_unit_price < 0 then
      raise_application_error(-20001, 'Unit price cannot be negative.');
    end if;
    if p_quantity < 0 then
      raise_application_error(-20001, 'Quantity cannot be negative.');
    end if;
  end validate;

  procedure create_product (
    p_product_name in  products.product_name%type,
    p_sku          in  products.sku%type,
    p_category_id  in  products.category_id%type,
    p_unit_price   in  products.unit_price%type default 0,
    p_quantity     in  products.quantity%type   default 0,
    p_status       in  products.status%type      default 'ACTIVE',
    p_notes        in  products.notes%type        default null,
    p_product_id   out products.product_id%type
  ) is
  begin
    validate(p_product_name, p_sku, p_unit_price, p_quantity);

    insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
    values (p_product_name, p_sku, p_category_id, p_unit_price, p_quantity, p_status, p_notes)
    returning product_id into p_product_id;
  end create_product;

  procedure update_product (
    p_product_id   in products.product_id%type,
    p_product_name in products.product_name%type,
    p_sku          in products.sku%type,
    p_category_id  in products.category_id%type,
    p_unit_price   in products.unit_price%type,
    p_quantity     in products.quantity%type,
    p_status       in products.status%type,
    p_notes        in products.notes%type
  ) is
  begin
    validate(p_product_name, p_sku, p_unit_price, p_quantity);

    update products
       set product_name = p_product_name,
           sku          = p_sku,
           category_id  = p_category_id,
           unit_price   = p_unit_price,
           quantity     = p_quantity,
           status       = p_status,
           notes        = p_notes
     where product_id   = p_product_id;

    if sql%rowcount = 0 then
      raise_application_error(-20001, 'Product ' || p_product_id || ' not found.');
    end if;
  end update_product;

  procedure delete_product (
    p_product_id in products.product_id%type
  ) is
  begin
    delete from products where product_id = p_product_id;

    if sql%rowcount = 0 then
      raise_application_error(-20001, 'Product ' || p_product_id || ' not found.');
    end if;
  end delete_product;

end products_api;
/

--------------------------------------------------------------------------------
-- Reporting view used by the APEX interactive report (resolves the FK to a
-- readable category name and computes inventory value).
--------------------------------------------------------------------------------
create or replace view products_v as
select p.product_id,
       p.product_name,
       p.sku,
       p.category_id,
       c.category_name,
       p.unit_price,
       p.quantity,
       p.unit_price * p.quantity as inventory_value,
       p.status,
       p.notes,
       p.created_on,
       p.created_by,
       p.updated_on,
       p.updated_by
from   products p
join   categories c on c.category_id = p.category_id;

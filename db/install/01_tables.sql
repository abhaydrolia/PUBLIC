--------------------------------------------------------------------------------
-- 01_tables.sql
-- Schema for the Products inventory CRUD application.
--
-- Run this against the schema mapped to your APEX workspace
-- (e.g. via SQL Workshop > SQL Scripts, SQLcl, or SQL Developer).
--------------------------------------------------------------------------------

-- Drop in dependency order (safe to re-run during development).
begin
  for r in (
    select table_name
    from   user_tables
    where  table_name in ('PRODUCTS', 'CATEGORIES')
  ) loop
    execute immediate 'drop table ' || r.table_name || ' cascade constraints';
  end loop;
end;
/

--------------------------------------------------------------------------------
-- Reference data: product categories
--------------------------------------------------------------------------------
create table categories (
  category_id    number generated always as identity
                   constraint categories_pk primary key,
  category_name  varchar2(100 char) not null
                   constraint categories_name_uk unique,
  description    varchar2(4000 char),
  created_on     timestamp default systimestamp not null,
  created_by     varchar2(255 char) default coalesce(sys_context('APEX$SESSION','APP_USER'), user) not null,
  updated_on     timestamp,
  updated_by     varchar2(255 char)
);

--------------------------------------------------------------------------------
-- Main entity: products
--------------------------------------------------------------------------------
create table products (
  product_id     number generated always as identity
                   constraint products_pk primary key,
  product_name   varchar2(200 char) not null,
  sku            varchar2(40 char) not null
                   constraint products_sku_uk unique,
  category_id    number not null
                   constraint products_category_fk references categories (category_id),
  unit_price     number(12,2) default 0 not null
                   constraint products_unit_price_ck check (unit_price >= 0),
  quantity       number(10) default 0 not null
                   constraint products_quantity_ck check (quantity >= 0),
  status         varchar2(20 char) default 'ACTIVE' not null
                   constraint products_status_ck check (status in ('ACTIVE','DISCONTINUED')),
  notes          varchar2(4000 char),
  created_on     timestamp default systimestamp not null,
  created_by     varchar2(255 char) default coalesce(sys_context('APEX$SESSION','APP_USER'), user) not null,
  updated_on     timestamp,
  updated_by     varchar2(255 char)
);

create index products_category_fk_i on products (category_id);
create index products_status_i      on products (status);

--------------------------------------------------------------------------------
-- Audit triggers: maintain updated_on / updated_by
--------------------------------------------------------------------------------
create or replace trigger categories_biu
  before insert or update on categories
  for each row
begin
  if updating then
    :new.updated_on := systimestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'), user);
  end if;
end;
/

create or replace trigger products_biu
  before insert or update on products
  for each row
begin
  if updating then
    :new.updated_on := systimestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'), user);
  end if;
end;
/

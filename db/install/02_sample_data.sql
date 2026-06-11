--------------------------------------------------------------------------------
-- 02_sample_data.sql
-- Seed data so the generated CRUD app has something to show immediately.
--------------------------------------------------------------------------------

insert into categories (category_name, description) values ('Electronics', 'Devices, components and accessories');
insert into categories (category_name, description) values ('Office Supplies', 'Stationery and consumables');
insert into categories (category_name, description) values ('Furniture', 'Desks, chairs and storage');

-- Resolve category ids by name so this script is order-independent.
insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'Wireless Mouse',     'ELEC-1001', c.category_id, 19.99,  150, 'ACTIVE',       'Ergonomic, 2.4GHz'
from categories c where c.category_name = 'Electronics';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'Mechanical Keyboard','ELEC-1002', c.category_id, 79.50,   60, 'ACTIVE',       'Hot-swappable switches'
from categories c where c.category_name = 'Electronics';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'USB-C Hub',          'ELEC-1003', c.category_id, 34.00,    0, 'DISCONTINUED', 'Replaced by 1006'
from categories c where c.category_name = 'Electronics';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'A4 Notebook',        'OFF-2001',  c.category_id,  4.25,  500, 'ACTIVE',       '120 pages, ruled'
from categories c where c.category_name = 'Office Supplies';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'Gel Pen (12 pack)',  'OFF-2002',  c.category_id,  8.90,  300, 'ACTIVE',       'Black ink'
from categories c where c.category_name = 'Office Supplies';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'Standing Desk',      'FURN-3001', c.category_id, 349.00,  25, 'ACTIVE',       'Electric, dual motor'
from categories c where c.category_name = 'Furniture';

insert into products (product_name, sku, category_id, unit_price, quantity, status, notes)
select 'Office Chair',       'FURN-3002', c.category_id, 189.00,  40, 'ACTIVE',       'Mesh back, lumbar support'
from categories c where c.category_name = 'Furniture';

commit;

-- Run on an isolated local database as the migration owner.
-- orders.sql includes this file and owns the final rollback.
begin;

insert into auth.users (id, raw_user_meta_data) values
  ('92002000-0000-4000-8000-000000000001', '{"full_name":"Orders Test A"}'),
  ('92002000-0000-4000-8000-000000000002', '{"full_name":"Orders Test B"}'),
  ('92002000-0000-4000-8000-000000000003', '{"full_name":"Orders Test Admin"}');

update public.user_roles set role = 'admin'
where user_id = '92002000-0000-4000-8000-000000000003';

insert into public.addresses
  (id, user_id, recipient_name, phone, address_line, ward, district, city)
values
  ('92002000-0000-4000-8000-000000000011', '92002000-0000-4000-8000-000000000001',
   'Orders Test A', '0900000001', '1 Fixture Street', 'Test Ward', 'Test District', 'Test City'),
  ('92002000-0000-4000-8000-000000000012', '92002000-0000-4000-8000-000000000001',
   'Orders Test A', '0900000001', '2 Fixture Street', 'Test Ward', 'Test District', 'Test City'),
  ('92002000-0000-4000-8000-000000000021', '92002000-0000-4000-8000-000000000002',
   'Orders Test B', '0900000002', '3 Fixture Street', 'Test Ward', 'Test District', 'Test City');

do $$
declare
  fixture record;
  variant_id uuid;
begin
  for fixture in
    select * from (values
      ('SF01-WHITE-M', 199000),
      ('SF02-DENIM-M', 249000)
    ) as demo(sku, price_vnd)
  loop
    select v.id into variant_id
    from public.product_variants v
    join public.products p on p.id = v.product_id
    join public.categories c on c.id = p.category_id
    where v.sku = fixture.sku and p.price_vnd = fixture.price_vnd
      and p.is_visible and c.is_active and v.stock >= 1;

    if not found then
      raise exception 'Orders fixture requires visible, in-stock demo SKU % at % VND',
        fixture.sku, fixture.price_vnd;
    end if;

    insert into public.cart_items (user_id, variant_id, quantity)
    values ('92002000-0000-4000-8000-000000000001', variant_id, 1);
  end loop;

  if not exists (
    select 1 from public.product_variants where sku = 'SF01-WHITE-XL' and stock = 0
  ) then
    raise exception 'Orders fixture requires out-of-stock demo SKU SF01-WHITE-XL';
  end if;

  if (select count(*) from public.user_roles
      where (user_id, role) in (
        ('92002000-0000-4000-8000-000000000001'::uuid, 'customer'),
        ('92002000-0000-4000-8000-000000000002'::uuid, 'customer'),
        ('92002000-0000-4000-8000-000000000003'::uuid, 'admin')
      )) <> 3 then
    raise exception 'Orders fixture requires two customers and one admin';
  end if;
end;
$$;

\if :{?orders_test_includes_fixture}
\else
rollback;
\endif

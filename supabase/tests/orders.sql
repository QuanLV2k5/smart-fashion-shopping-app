-- psql -v ON_ERROR_STOP=1 -f supabase/tests/orders.sql (isolated local database).
\set orders_test_includes_fixture true
\ir orders_fixtures.sql
\unset orders_test_includes_fixture

create function pg_temp.check_that(ok boolean, label text) returns void language plpgsql as $$
begin
  if ok is distinct from true then raise exception 'FAIL: %', label; end if;
end;
$$;
create function pg_temp.expect_error(statement text, code text, message text) returns void language plpgsql as $$
begin
  execute statement;
  raise exception 'FAIL: expected % (%), statement succeeded', message, code;
exception when others then
  if sqlstate <> code or (message is not null and sqlerrm <> message) then raise; end if;
end;
$$;

create temp table context as
select id as variant_id, stock as original_stock, stock_revision as original_revision,
  '92002000-0000-4000-8000-000000000001'::uuid as a,
  '92002000-0000-4000-8000-000000000002'::uuid as b,
  '92002000-0000-4000-8000-000000000003'::uuid as admin,
  '92002000-0000-4000-8000-000000000011'::uuid as a1,
  '92002000-0000-4000-8000-000000000021'::uuid as b1,
  gen_random_uuid() as request_id, null::uuid as quote_id, null::uuid as order_id,
  null::uuid as cancel_order_id, gen_random_uuid() as cancel_request_id
from public.product_variants where sku = 'SF01-WHITE-M';
grant select, update on context to authenticated;

set local role anon;
select pg_temp.expect_error('select public.list_my_orders()', '42501', null);
reset role;

select set_config('request.jwt.claim.sub', b::text, true) from context;
set local role authenticated;
select pg_temp.expect_error(format('select public.create_checkout_quote(%L)', b1), 'PT409', 'SF_CART_EMPTY') from context;
select pg_temp.expect_error(format('select public.create_checkout_quote(%L)', a1), 'PT404', 'SF_ADDRESS_UNAVAILABLE') from context;
select pg_temp.expect_error('select public.list_admin_orders()', 'PT403', 'SF_FORBIDDEN');
select pg_temp.expect_error(format('select public.set_variant_stock(%L,0,1)', variant_id), 'PT403', 'SF_FORBIDDEN') from context;
select pg_temp.expect_error('update public.orders set status = ''completed''', '42501', null);
select pg_temp.expect_error('select * from private.checkout_quotes', '42501', null);
reset role;

select set_config('request.jwt.claim.sub', a::text, true) from context;
set local role authenticated;
do $$
declare
  quote jsonb;
begin
  quote := public.create_checkout_quote((select a1 from context));
  perform pg_temp.check_that((quote->>'subtotal_vnd')::bigint = 448000 and
    (quote->>'shipping_vnd')::bigint = 25000 and (quote->>'total_vnd')::bigint = 473000, 'server pricing');
  update context set quote_id = (quote->>'quote_id')::uuid;
end;
$$;
reset role;

-- After-INSERT fault on the final write, after stock, cart and history changed.
create function pg_temp.fail_receipt() returns trigger language plpgsql as $$
begin
  raise exception using errcode = 'PT500', message = 'INJECTED_RECEIPT_FAILURE';
end;
$$;
create trigger orders_test_fault after insert on private.order_request_receipts
  for each row execute function pg_temp.fail_receipt();
set local role authenticated;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', quote_id, request_id),
  'PT500', 'INJECTED_RECEIPT_FAILURE') from context;
select pg_temp.check_that(public.lookup_order_request(request_id) = '{"found":false}', 'no failed receipt') from context;
reset role;
select pg_temp.check_that(not exists (select 1 from public.orders where user_id = c.a)
  and (select count(*) from public.cart_items where user_id = c.a) = 2
  and (select stock = c.original_stock and stock_revision = c.original_revision
    from public.product_variants where id = c.variant_id), 'rollback header, cart and stock') from context c;
drop trigger orders_test_fault on private.order_request_receipts;

update public.product_variants set stock = 0 where id = (select variant_id from context);
set local role authenticated;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', quote_id, request_id),
  'PT409', 'SF_STOCK_CHANGED') from context;
reset role;
update public.product_variants v set stock = c.original_stock from context c where v.id = c.variant_id;
update public.products set price_vnd = 200000 where code = 'SF01';
set local role authenticated;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', quote_id, request_id),
  'PT409', 'SF_QUOTE_STALE') from context;
reset role;
update public.products set price_vnd = 199000 where code = 'SF01';
delete from public.cart_items ci using context c where ci.user_id = c.a and ci.variant_id = c.variant_id;
set local role authenticated;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', quote_id, request_id),
  'PT409', 'SF_CART_CHANGED') from context;
reset role;
insert into public.cart_items (user_id, variant_id, quantity) select a, variant_id, 1 from context;
update context set original_revision = (select stock_revision from public.product_variants v where v.id = context.variant_id);

set local role authenticated;
update context set order_id = (public.place_cod_order(quote_id, request_id)#>>'{result,order_id}')::uuid;
select pg_temp.check_that((public.place_cod_order(quote_id, request_id)->>'replayed')::boolean
  and (public.lookup_order_request(request_id)#>>'{result,order_id}')::uuid = order_id, 'repeat same request') from context;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', gen_random_uuid(), request_id),
  'PT409', 'SF_REQUEST_CONFLICT') from context;
select pg_temp.expect_error(format('select public.place_cod_order(%L,%L)', quote_id, gen_random_uuid()),
  'PT409', 'SF_QUOTE_USED') from context;
select pg_temp.expect_error(format('select public.change_order_status(%L,''confirmed'',1,%L)', order_id, gen_random_uuid()),
  'PT409', 'SF_ORDER_TRANSITION_INVALID') from context;
reset role;
select pg_temp.check_that((select count(*) from public.orders where user_id = c.a) = 1
  and (select count(*) from public.order_items where order_id = c.order_id) = 2
  and (select count(*) from public.order_status_history where order_id = c.order_id) = 1
  and not exists (select 1 from public.cart_items where user_id = c.a)
  and (select stock = c.original_stock - 1 and stock_revision = c.original_revision + 1
    from public.product_variants where id = c.variant_id), 'one order, initial event, cart clear, one deduction') from context c;

select set_config('request.jwt.claim.sub', b::text, true) from context;
set local role authenticated;
select pg_temp.expect_error(format('select public.get_order(%L)', order_id), 'PT404', 'SF_ORDER_NOT_FOUND') from context;
select pg_temp.check_that(public.list_my_orders()->'items' = '[]'
  and public.lookup_order_request(request_id) = '{"found":false}', 'B isolated from A') from context;
reset role;

select set_config('request.jwt.claim.sub', admin::text, true) from context;
set local role authenticated;
select pg_temp.expect_error(format('select public.set_variant_stock(%L,%s,99)', variant_id, original_revision),
  'PT409', 'SF_STOCK_VERSION_CONFLICT') from context;
select pg_temp.check_that(jsonb_array_length(public.list_admin_orders('pending')->'items') >= 1, 'admin list');
select pg_temp.expect_error(format('select public.change_order_status(%L,''shipping'',1,%L)', order_id, gen_random_uuid()),
  'PT409', 'SF_ORDER_TRANSITION_INVALID') from context;
select public.change_order_status(order_id, 'confirmed', 1, gen_random_uuid()) from context;
select pg_temp.expect_error(format('select public.change_order_status(%L,''shipping'',1,%L)', order_id, gen_random_uuid()),
  'PT409', 'SF_ORDER_VERSION_CONFLICT') from context;
select public.change_order_status(order_id, 'shipping', 2, gen_random_uuid()) from context;
select public.change_order_status(order_id, 'completed', 3, gen_random_uuid()) from context;
reset role;

update public.products set price_vnd = 210000, name = 'Changed product' where code = 'SF01';
update public.product_variants set color = 'Changed color' where id = (select variant_id from context);
delete from public.addresses where id = (select a1 from context);
select set_config('request.jwt.claim.sub', a::text, true) from context;
set local role authenticated;
select pg_temp.check_that(detail->>'status' = 'completed'
  and detail#>>'{delivery_address,address_line}' = '1 Fixture Street'
  and (detail->>'total_vnd')::bigint = 473000
  and jsonb_array_length(detail->'events') = 4
  and not ((detail->'events'->0) ? 'actor_user_id')
  and exists (select from jsonb_array_elements(detail->'items') line
    where line->>'sku' = 'SF01-WHITE-M' and (line->>'unit_price_vnd')::bigint = 199000
      and line->>'product_name' <> 'Changed product' and line->>'color' <> 'Changed color'), 'immutable snapshot')
from (select public.get_order(order_id) as detail from context) fetched;
reset role;

insert into public.cart_items (user_id, variant_id, quantity) select b, variant_id, 1 from context;
select set_config('request.jwt.claim.sub', b::text, true) from context;
set local role authenticated;
update context set cancel_order_id = (public.place_cod_order(
  (public.create_checkout_quote(b1)->>'quote_id')::uuid, gen_random_uuid())#>>'{result,order_id}')::uuid;
select public.change_order_status(cancel_order_id, 'cancelled', 1, cancel_request_id, 'customer_requested') from context;
select pg_temp.check_that((public.change_order_status(cancel_order_id, 'cancelled', 1, cancel_request_id,
  'customer_requested')->>'replayed')::boolean, 'cancel replay') from context;
select pg_temp.expect_error(format('select public.change_order_status(%L,''cancelled'',2,%L,''customer_requested'')',
  cancel_order_id, gen_random_uuid()), 'PT409', 'SF_ORDER_TRANSITION_INVALID') from context;
reset role;
select pg_temp.check_that((select stock = c.original_stock - 1 from public.product_variants where id = c.variant_id)
  and (select count(*) from public.order_status_history where order_id = c.cancel_order_id) = 2, 'one restoration') from context c;

select set_config('request.jwt.claim.sub', admin::text, true) from context;
set local role authenticated;
do $$
declare
  page jsonb := public.list_admin_orders('all', 1);
  next_page jsonb;
begin
  next_page := public.list_admin_orders('all', 1, page->'next_cursor');
  perform pg_temp.check_that(jsonb_array_length(page->'items') = 1
    and jsonb_array_length(next_page->'items') = 1
    and page#>>'{items,0,id}' <> next_page#>>'{items,0,id}', 'keyset pagination');
end;
$$;
reset role;

rollback;
select 'PASS: Orders SQL transaction, authorization, replay, transitions and snapshots' as result;

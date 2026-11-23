-- Rehearse the proposed stock privilege cutover. The GRANT changes roll back.
-- Run with psql -v ON_ERROR_STOP=1 on an isolated database after Orders migrations.
\set orders_test_includes_fixture true
\ir orders_fixtures.sql
\unset orders_test_includes_fixture

-- A table-wide grant overrides a missing column grant, so remove it first.
revoke update on public.product_variants from authenticated;
grant update (product_id, sku, size, color) on public.product_variants to authenticated;

select set_config('request.jwt.claim.sub', '92002000-0000-4000-8000-000000000003', true);
set local role authenticated;
do $$
declare
  demo public.product_variants%rowtype;
  revised jsonb;
begin
  select * into strict demo from public.product_variants where sku = 'SF01-WHITE-M';
  begin
    update public.product_variants set stock = 0 where id = demo.id;
    raise exception 'FAIL: admin retained direct stock UPDATE';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.product_variants set stock_revision = stock_revision + 1 where id = demo.id;
    raise exception 'FAIL: admin retained direct revision UPDATE';
  exception when insufficient_privilege then null;
  end;
  update public.product_variants set color = 'Cutover fixture' where id = demo.id;
  if not found or (select stock_revision from public.product_variants where id = demo.id) <> demo.stock_revision then
    raise exception 'FAIL: metadata update or revision';
  end if;
  insert into public.product_variants (product_id, sku, size, color, stock)
  values (demo.product_id, 'ORDERS-CUTOVER-FIXTURE', 'Fixture', 'Fixture', 1);
  revised := public.set_variant_stock(demo.id, demo.stock_revision, 0);
  if (revised->>'stock')::integer <> 0 or (revised->>'stock_revision')::bigint <> demo.stock_revision + 1 then
    raise exception 'FAIL: admin stock RPC after cutover';
  end if;
  begin
    perform public.set_variant_stock(demo.id, demo.stock_revision, 1);
    raise exception 'FAIL: stale stock revision accepted';
  exception when sqlstate 'PT409' then
    if sqlerrm <> 'SF_STOCK_VERSION_CONFLICT' then raise; end if;
  end;
  perform public.set_variant_stock(demo.id, (revised->>'stock_revision')::bigint, demo.stock);
end;
$$;
reset role;

select set_config('request.jwt.claim.sub', '92002000-0000-4000-8000-000000000001', true);
set local role authenticated;
do $$
declare
  quote_id uuid;
  order_id uuid;
  stock_before integer;
begin
  update public.product_variants set color = 'Denied' where sku = 'SF01-WHITE-M';
  if found then raise exception 'FAIL: customer can update variant metadata'; end if;
  begin
    perform public.set_variant_stock(id, stock_revision, 1)
    from public.product_variants where sku = 'SF01-WHITE-M';
    raise exception 'FAIL: customer can call stock RPC';
  exception when sqlstate 'PT403' then
    if sqlerrm <> 'SF_FORBIDDEN' then raise; end if;
  end;
  select stock into strict stock_before from public.product_variants where sku = 'SF01-WHITE-M';
  quote_id := (public.create_checkout_quote('92002000-0000-4000-8000-000000000011')->>'quote_id')::uuid;
  order_id := (public.place_cod_order(quote_id, gen_random_uuid())#>>'{result,order_id}')::uuid;
  if (select stock from public.product_variants where sku = 'SF01-WHITE-M') <> stock_before - 1 then
    raise exception 'FAIL: checkout stock deduction after cutover';
  end if;
  perform public.change_order_status(order_id, 'cancelled', 1, gen_random_uuid(), 'customer_requested');
  if (select stock from public.product_variants where sku = 'SF01-WHITE-M') <> stock_before then
    raise exception 'FAIL: cancellation restoration after cutover';
  end if;
end;
$$;
reset role;

rollback;
select 'PASS: stock privilege cutover, metadata and insert, revision conflicts, customer denial' as result;

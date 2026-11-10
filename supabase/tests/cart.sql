-- Chạy TOÀN FILE trên dev sau migration product_cart. Mọi fixture đều ROLLBACK.
begin;
insert into auth.users(id, raw_user_meta_data) values
('92000000-0000-0000-0000-000000000001', '{"full_name":"Cart Test A"}'),
('92000000-0000-0000-0000-000000000002', '{"full_name":"Cart Test B"}');

set local role anon;
do $$ begin
  begin perform public.get_cart(); raise exception 'FAIL: anon đọc RPC';
  exception when insufficient_privilege then null; end;
  begin perform public.mutate_cart(gen_random_uuid(), 1, 'add', gen_random_uuid()); raise exception 'FAIL: anon ghi RPC';
  exception when insufficient_privilege then null; end;
  begin perform * from public.cart_items; raise exception 'FAIL: anon đọc bảng';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000001', true);
set local role authenticated;
do $$
declare
  vm uuid := (select id from public.product_variants where sku = 'SF01-WHITE-M');
  vs uuid := (select id from public.product_variants where sku = 'SF01-WHITE-S');
  vxl uuid := (select id from public.product_variants where sku = 'SF01-WHITE-XL');
  request uuid := '93000000-0000-0000-0000-000000000001';
  result jsonb;
begin
  result := public.mutate_cart(vm, 1, 'add', request);
  if jsonb_array_length(result->'items') <> 1 then raise exception 'FAIL: snapshot sau thêm'; end if;
  perform public.mutate_cart(vm, 1, 'add', request);
  if (select quantity from public.cart_items where variant_id = vm) <> 1 then raise exception 'FAIL: retry cộng trùng'; end if;
  perform public.mutate_cart(vm, 1, 'add', gen_random_uuid());
  if (select quantity from public.cart_items where variant_id = vm) <> 2 then raise exception 'FAIL: thêm cùng SKU không cộng dồn'; end if;
  perform public.mutate_cart(vs, 1, 'add', gen_random_uuid());
  if (select count(*) from public.cart_items) <> 2 then raise exception 'FAIL: khác size bị gộp'; end if;
  perform public.mutate_cart(vm, 3, 'set', gen_random_uuid());
  if (select quantity from public.cart_items where variant_id = vm) <> 3 then raise exception 'FAIL: set số lượng'; end if;
  begin perform public.mutate_cart(vxl, 1, 'add', gen_random_uuid()); raise exception 'FAIL: XL hết hàng vẫn thêm';
  exception when sqlstate 'P0001' then if sqlerrm <> 'SF_STOCK_CHANGED' then raise; end if; end;
  begin perform public.mutate_cart(vm, 13, 'set', gen_random_uuid()); raise exception 'FAIL: vượt tồn';
  exception when sqlstate 'P0001' then if sqlerrm <> 'SF_STOCK_CHANGED' then raise; end if; end;
  begin perform public.mutate_cart(vm, 0, 'add', gen_random_uuid()); raise exception 'FAIL: SL 0';
  exception when sqlstate 'P0001' then if sqlerrm <> 'SF_INVALID_QUANTITY' then raise; end if; end;
  begin perform public.mutate_cart(vm, 2, 'add', request); raise exception 'FAIL: tái dùng ID khác payload';
  exception when sqlstate 'P0001' then if sqlerrm <> 'SF_REQUEST_CONFLICT' then raise; end if; end;
  begin insert into public.cart_items(user_id, variant_id, quantity) values (auth.uid(), vxl, 1); raise exception 'FAIL: ghi thẳng bỏ qua RPC';
  exception when insufficient_privilege then null; end;
  begin perform * from private.cart_mutations; raise exception 'FAIL: đọc biên nhận private';
  exception when insufficient_privilege then null; end;
  if (select stock from public.product_variants where id = vm) <> 12 then raise exception 'FAIL: thêm giỏ đã trừ tồn'; end if;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000002', true);
set local role authenticated;
do $$
declare vm uuid := (select id from public.product_variants where sku = 'SF01-WHITE-M');
begin
  if (select count(*) from public.cart_items) <> 0 then raise exception 'FAIL: B đọc giỏ A'; end if;
  if jsonb_array_length(public.get_cart()->'items') <> 0 then raise exception 'FAIL: RPC lộ giỏ A'; end if;
  perform public.mutate_cart(vm, 1, 'add', gen_random_uuid());
  perform public.mutate_cart(vm, 0, 'remove', gen_random_uuid());
  if (select count(*) from public.cart_items) <> 0 then raise exception 'FAIL: xóa không đúng chủ'; end if;
end $$;
reset role;

-- Hàng bị ẩn sau khi thêm: không lộ metadata, vẫn xóa được khỏi giỏ.
update public.products set is_visible = false where code = 'SF01';
select set_config('request.jwt.claim.sub', '92000000-0000-0000-0000-000000000001', true);
set local role authenticated;
do $$
declare
  vm uuid := (select variant_id from public.cart_items where quantity = 3);
  item jsonb;
begin
  for item in select * from jsonb_array_elements(public.get_cart()->'items') loop
    if item->'product' <> 'null'::jsonb then raise exception 'FAIL: lộ sản phẩm ẩn'; end if;
  end loop;
  begin perform public.mutate_cart(vm, 1, 'add', gen_random_uuid()); raise exception 'FAIL: thêm hàng ẩn';
  exception when sqlstate 'P0001' then if sqlerrm <> 'SF_PRODUCT_UNAVAILABLE' then raise; end if; end;
  perform public.mutate_cart(vm, 0, 'remove', gen_random_uuid());
  if (select count(*) from public.cart_items) <> 1 then raise exception 'FAIL: xóa hàng ẩn'; end if;
end $$;
reset role;

update public.products set is_visible = true, price_vnd = 200000 where code = 'SF01';
set local role authenticated;
do $$ begin
  if (public.get_cart()->'items'->0->'product'->>'price_vnd')::integer <> 200000 then raise exception 'FAIL: giá không lấy mới từ catalog'; end if;
end $$;
reset role;

rollback;
select 'PASS: cart ownership / RPC / stock / idempotency / hidden / current price; fixtures rolled back' as result;

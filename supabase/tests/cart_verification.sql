-- Chỉ đọc; chạy sau cart.sql để xác minh rollback và quyền.
select
  (select count(*) from auth.users where id::text like '92000000-%') as test_users,
  (select count(*) from public.cart_items where user_id::text like '92000000-%') as test_cart_items,
  (select count(*) from private.cart_mutations where user_id::text like '92000000-%') as test_receipts,
  (select price_vnd from public.products where code = 'SF01') as shirt_price,
  (select price_vnd from public.products where code = 'SF02') as jeans_price,
  (select relrowsecurity from pg_class where oid = 'public.cart_items'::regclass) as cart_rls,
  has_function_privilege('anon', 'public.get_cart()', 'execute') as anon_read_rpc,
  has_table_privilege('authenticated', 'public.cart_items', 'insert') as direct_client_insert;

-- Chỉ chạy trên project phát triển, sau hai migration. Chạy TOÀN BỘ file.
-- Tạo fixture trong một transaction rồi ROLLBACK: không giữ tài khoản giả.
-- Đây là kiểm thử SQL/RLS, không thay cho kiểm thử đăng ký qua Supabase Auth.
begin;

insert into auth.users (id, raw_user_meta_data) values
('90000000-0000-0000-0000-000000000001', '{"full_name":"Test A","role":"admin"}'),
('90000000-0000-0000-0000-000000000002', '{"full_name":"Test B"}'),
('90000000-0000-0000-0000-000000000003', '{"full_name":"Test Admin"}');
update public.user_roles set role = 'admin'
where user_id = '90000000-0000-0000-0000-000000000003';

do $$ begin
  if (select count(*) from public.profiles where id::text like '90000000-%') <> 3
    then raise exception 'FAIL: trigger tạo profiles'; end if;
  if (select role from public.user_roles where user_id = '90000000-0000-0000-0000-000000000001') <> 'customer'
    then raise exception 'FAIL: metadata không được nâng quyền'; end if;
  if (select price_vnd from public.products where code = 'SF01') +
     (select price_vnd from public.products where code = 'SF02') is distinct from 448000
    then raise exception 'FAIL: tổng tiền demo'; end if;
end $$;

set local role anon;
do $$ begin
  if (select count(*) from public.products where code like 'SF%') <> 12
    then raise exception 'FAIL: khách đọc catalog mẫu'; end if;
  begin
    perform * from public.profiles;
    raise exception 'FAIL: khách đọc được profiles';
  exception when insufficient_privilege then null; end;
  begin
    update public.products set price_vnd = 1 where code = 'SF01';
    raise exception 'FAIL: khách sửa được giá';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000001', true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.profiles) <> 1
    then raise exception 'FAIL: A nhìn thấy hồ sơ khác'; end if;
  if (select count(*) from public.user_roles) <> 1
    then raise exception 'FAIL: A nhìn thấy quyền người khác'; end if;
  update public.profiles set full_name = 'A đã sửa';
  if (select full_name from public.profiles) <> 'A đã sửa'
    then raise exception 'FAIL: không sửa được tên của mình'; end if;
  begin
    update public.profiles set id = '90000000-0000-0000-0000-000000000002';
    raise exception 'FAIL: sửa được khóa hồ sơ';
  exception when insufficient_privilege then null; end;
  begin
    update public.user_roles set role = 'admin';
    raise exception 'FAIL: tự nâng quyền';
  exception when insufficient_privilege then null; end;
  update public.products set price_vnd = 1 where code = 'SF01';
  if found then raise exception 'FAIL: customer sửa được catalog'; end if;
  begin
    insert into public.categories (name, slug) values ('Không được phép', 'test-denied');
    raise exception 'FAIL: customer thêm được danh mục';
  exception when insufficient_privilege then null; end;
  insert into public.addresses (id, recipient_name, phone, address_line, ward, district, city)
  values ('91000000-0000-0000-0000-000000000001', 'Test A', '0900000001', 'Địa chỉ thử', 'Phường thử', 'Quận thử', 'Đà Nẵng');
  update public.addresses set address_line = 'A tự sửa địa chỉ';
  if (select address_line from public.addresses) <> 'A tự sửa địa chỉ'
    then raise exception 'FAIL: A không sửa được địa chỉ mình'; end if;
  begin
    insert into public.addresses (user_id, recipient_name, phone, address_line, ward, district, city)
    values ('90000000-0000-0000-0000-000000000002', 'Test B', '0900000002', 'Thử', 'Thử', 'Thử', 'Thử');
    raise exception 'FAIL: A thêm địa chỉ cho B';
  exception when insufficient_privilege then null; end;
  begin
    update public.addresses set user_id = '90000000-0000-0000-0000-000000000002';
    raise exception 'FAIL: A chuyển chủ địa chỉ';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000002', true);
set local role authenticated;
do $$ begin
  if exists (select 1 from public.addresses)
    then raise exception 'FAIL: B đọc địa chỉ A'; end if;
  update public.addresses set recipient_name = 'B sửa trái phép'
  where id = '91000000-0000-0000-0000-000000000001';
  if found then raise exception 'FAIL: B sửa địa chỉ A'; end if;
  delete from public.addresses where id = '91000000-0000-0000-0000-000000000001';
  if found then raise exception 'FAIL: B xóa địa chỉ A'; end if;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000003', true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.profiles where id::text like '90000000-%') <> 3
    then raise exception 'FAIL: admin không đọc được hồ sơ'; end if;
  if exists (select 1 from public.addresses)
    then raise exception 'FAIL: admin đọc được địa chỉ riêng khi chưa có nghiệp vụ đơn'; end if;
  insert into public.categories (id, name, slug)
  values ('92000000-0000-0000-0000-000000000001', 'Danh mục kiểm thử', 'test-admin');
  insert into public.products (id, code, category_id, name, price_vnd)
  values ('93000000-0000-0000-0000-000000000001', 'TEST-ADMIN',
    '92000000-0000-0000-0000-000000000001', 'Sản phẩm kiểm thử', 10000);
  insert into public.product_variants (product_id, sku, size, color, stock)
  values ('93000000-0000-0000-0000-000000000001', 'TEST-ADMIN-M', 'M', 'Đen', 1);
  if not exists (select 1 from public.product_variants where sku = 'TEST-ADMIN-M')
    then raise exception 'FAIL: admin không thêm được catalog'; end if;
  update public.products set is_visible = false where code = 'SF01';
  if not found then raise exception 'FAIL: admin không ẩn được sản phẩm'; end if;
  update public.categories set is_active = false where slug = 'quan';
  if not found then raise exception 'FAIL: admin không ngừng danh mục'; end if;
  begin
    update public.products set price_vnd = 0 where code = 'SF02';
    raise exception 'FAIL: giá bằng 0 được chấp nhận';
  exception when check_violation then null; end;
  begin
    update public.product_variants set stock = -1 where sku = 'SF01-WHITE-M';
    raise exception 'FAIL: tồn kho âm được chấp nhận';
  exception when check_violation then null; end;
  begin
    insert into public.product_variants (product_id, sku, size, color, stock)
    values ('20000000-0000-0000-0000-000000000001', 'TEST-DUP', 'M', 'Trắng ngà', 1);
    raise exception 'FAIL: trùng size/màu được chấp nhận';
  exception when unique_violation then null; end;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '', true);
set local role anon;
do $$ begin
  if exists (select 1 from public.products where code in ('SF01', 'SF02', 'SF04', 'SF06'))
    then raise exception 'FAIL: khách đọc sản phẩm ẩn/danh mục ngừng'; end if;
  if exists (select 1 from public.product_variants where sku like 'SF01-%' or sku in ('SF02-DENIM-M', 'SF04-BLACK-M', 'SF06-BEIGE-M'))
    then raise exception 'FAIL: khách đọc biến thể của sản phẩm ẩn'; end if;
end $$;
reset role;

select set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000001', true);
set local role authenticated;
do $$ begin
  delete from public.addresses where id = '91000000-0000-0000-0000-000000000001';
  if not found then raise exception 'FAIL: A không xóa được địa chỉ của mình'; end if;
end $$;
reset role;

select 'PASS: trigger, seed, GRANT, RLS anon/A/B/admin, ràng buộc dữ liệu' as result;
rollback;

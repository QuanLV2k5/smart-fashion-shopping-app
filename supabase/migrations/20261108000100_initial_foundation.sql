-- Smart Fashion: nền dữ liệu Q02. Chạy trước migration dữ liệu mẫu.
-- Auth giữ tài khoản/mật khẩu; public.profiles chỉ giữ hồ sơ của ứng dụng.
-- Chưa tạo orders/reviews/AI: các nghiệp vụ đó có migration riêng ở bước sau.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema public to anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 100),
  phone text check (phone is null or char_length(phone) <= 20),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tách quyền khỏi hồ sơ để người dùng sửa tên/ảnh không thể tự nâng quyền.
create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('customer', 'admin'))
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(trim(name)) between 1 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (char_length(trim(code)) between 1 and 40),
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null check (char_length(trim(name)) between 1 and 160),
  description text not null default '',
  material text not null default '',
  price_vnd integer not null check (price_vnd > 0),
  image_paths text[] not null default '{}',
  is_visible boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_category_id_idx on public.products(category_id);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  sku text not null unique check (char_length(trim(sku)) between 1 and 80),
  size text not null check (char_length(trim(size)) between 1 and 30),
  color text not null check (char_length(trim(color)) between 1 and 50),
  stock integer not null default 0 check (stock >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, size, color)
);
create index product_variants_product_id_idx on public.product_variants(product_id);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  recipient_name text not null check (char_length(trim(recipient_name)) between 1 and 100),
  phone text not null check (phone ~ '^\+?[0-9]{9,15}$'),
  address_line text not null check (char_length(trim(address_line)) between 1 and 250),
  ward text not null check (char_length(trim(ward)) between 1 and 100),
  district text not null check (char_length(trim(district)) between 1 and 100),
  city text not null check (char_length(trim(city)) between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index addresses_user_id_idx on public.addresses(user_id);

-- Hàm này chạy với quyền chủ sở hữu để đọc user_roles mà không bị RLS đệ quy.
-- Schema private không được thêm vào danh sách Exposed schemas của Data API.
create function private.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = (select auth.uid()) and role = 'admin'
  );
$$;
revoke all on function private.is_admin() from public;
grant usage on schema private to anon, authenticated;
grant execute on function private.is_admin() to anon, authenticated;

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
revoke all on function private.set_updated_at() from public, anon, authenticated;

create trigger profiles_updated_at before update on public.profiles
for each row execute function private.set_updated_at();
create trigger categories_updated_at before update on public.categories
for each row execute function private.set_updated_at();
create trigger products_updated_at before update on public.products
for each row execute function private.set_updated_at();
create trigger product_variants_updated_at before update on public.product_variants
for each row execute function private.set_updated_at();
create trigger addresses_updated_at before update on public.addresses
for each row execute function private.set_updated_at();

-- Mỗi đăng ký mới có hồ sơ và quyền customer, bất kể client gửi metadata gì.
create function private.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, left(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), 100));
  insert into public.user_roles (user_id, role) values (new.id, 'customer');
  return new;
end;
$$;
revoke all on function private.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();

-- Dùng được cả khi đã có tài khoản thử nghiệm trước lúc chạy migration.
insert into public.profiles (id, full_name)
select id, left(trim(coalesce(raw_user_meta_data ->> 'full_name', '')), 100)
from auth.users on conflict (id) do nothing;
insert into public.user_roles (user_id, role)
select id, 'customer' from auth.users on conflict (user_id) do nothing;

-- RLS kiểm tra từng dòng. GRANT kiểm tra loại thao tác/cột được phép gọi.
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.addresses enable row level security;

revoke all on public.profiles, public.user_roles, public.categories,
  public.products, public.product_variants, public.addresses
from public, anon, authenticated;

grant select on public.profiles, public.user_roles to authenticated;
grant update (full_name, phone, avatar_path) on public.profiles to authenticated;
grant select on public.categories, public.products, public.product_variants to anon, authenticated;
grant insert, update on public.categories, public.products, public.product_variants to authenticated;
grant select, insert, update, delete on public.addresses to authenticated;

create policy profiles_read on public.profiles for select to authenticated
using (id = (select auth.uid()) or (select private.is_admin()));
create policy profiles_update_own on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy roles_read on public.user_roles for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));
-- Không cấp INSERT/UPDATE/DELETE cho user_roles từ app.

create policy categories_read on public.categories for select to anon, authenticated
using (is_active or (select private.is_admin()));
create policy categories_admin_insert on public.categories for insert to authenticated
with check ((select private.is_admin()));
create policy categories_admin_update on public.categories for update to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

create policy products_read on public.products for select to anon, authenticated
using (
  (select private.is_admin()) or (
    is_visible and exists (
      select 1 from public.categories c where c.id = category_id and c.is_active
    )
  )
);
create policy products_admin_insert on public.products for insert to authenticated
with check ((select private.is_admin()));
create policy products_admin_update on public.products for update to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

create policy variants_read on public.product_variants for select to anon, authenticated
using (exists (select 1 from public.products p where p.id = product_id));
create policy variants_admin_insert on public.product_variants for insert to authenticated
with check ((select private.is_admin()));
create policy variants_admin_update on public.product_variants for update to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

create policy addresses_own on public.addresses for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Catalog dùng ẩn/ngừng bán, không xóa từ app; giữ ID cho các đơn ở bước sau.
comment on table public.products is 'Catalog Smart Fashion; price_vnd là số nguyên VNĐ.';
comment on table public.user_roles is 'Vai trò do phía quản trị cấp; client không được tự sửa.';
comment on table public.addresses is 'Địa chỉ riêng theo auth.uid(); chưa có cơ chế địa chỉ mặc định.';

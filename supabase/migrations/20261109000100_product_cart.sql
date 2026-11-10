-- Bổ sung giỏ riêng theo tài khoản; không sửa dữ liệu catalog/Auth hiện có.
-- Áp dụng sau hai migration nền. SQL Editor: chạy toàn file một lần.
begin;

create table public.cart_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  quantity integer not null check (quantity between 1 and 99),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);
create index cart_items_variant_id_idx on public.cart_items(variant_id);
create trigger cart_items_updated_at before update on public.cart_items
for each row execute function private.set_updated_at();
alter table public.cart_items enable row level security;
revoke all on public.cart_items from public, anon, authenticated;
grant select on public.cart_items to authenticated;
create policy cart_read_own on public.cart_items for select to authenticated
using (user_id = (select auth.uid()));

-- Biên nhận chống cộng trùng khi mạng ngắt sau khi server đã ghi thành công.
-- Không expose bảng này qua Data API, không cấp quyền cho client.
create table private.cart_mutations (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  variant_id uuid not null,
  operation text not null check (operation in ('add', 'set', 'remove')),
  quantity integer not null,
  created_at timestamptz not null default now(),
  primary key (user_id, request_id)
);
alter table private.cart_mutations enable row level security;
revoke all on private.cart_mutations from public, anon, authenticated;

create function public.get_cart()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  result jsonb;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'SF_AUTH_REQUIRED';
  end if;
  select jsonb_build_object('items', coalesce(jsonb_agg(
    jsonb_build_object(
      'variant_id', ci.variant_id,
      'quantity', ci.quantity,
      'product', case when p.is_visible and c.is_active then jsonb_build_object(
        'id', p.id, 'code', p.code, 'category_id', p.category_id,
        'name', p.name, 'description', p.description, 'material', p.material,
        'price_vnd', p.price_vnd, 'image_paths', p.image_paths,
        'product_variants', jsonb_build_array(jsonb_build_object(
          'id', v.id, 'sku', v.sku, 'size', v.size, 'color', v.color, 'stock', v.stock
        ))
      ) else null end
    ) order by ci.created_at, ci.variant_id
  ), '[]'::jsonb)) into result
  from public.cart_items ci
  join public.product_variants v on v.id = ci.variant_id
  join public.products p on p.id = v.product_id
  join public.categories c on c.id = p.category_id
  where ci.user_id = caller;
  return result;
end;
$$;
revoke all on function public.get_cart() from public, anon, authenticated;
grant execute on function public.get_cart() to authenticated;

create function public.mutate_cart(
  p_variant_id uuid, p_quantity integer, p_operation text, p_request_id uuid
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  receipt private.cart_mutations%rowtype;
  current_stock integer;
  visible boolean;
  old_quantity integer := 0;
  new_quantity integer;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'SF_AUTH_REQUIRED';
  end if;
  if p_variant_id is null or p_request_id is null or p_operation is null
     or p_operation not in ('add', 'set', 'remove') or p_quantity is null
     or (p_operation in ('add', 'set') and p_quantity not between 1 and 99)
     or (p_operation = 'remove' and p_quantity <> 0) then
    raise exception using errcode = 'P0001', message = 'SF_INVALID_QUANTITY';
  end if;

  -- Tuần tự hóa cập nhật cùng tài khoản, kể cả từ hai thiết bị.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text, 0));
  select * into receipt from private.cart_mutations
  where user_id = caller and request_id = p_request_id;
  if found then
    if receipt.variant_id <> p_variant_id or receipt.operation <> p_operation
       or receipt.quantity <> p_quantity then
      raise exception using errcode = 'P0001', message = 'SF_REQUEST_CONFLICT';
    end if;
    -- Trả giỏ hiện tại, không trả snapshot cũ của lần cập nhật trước.
    return public.get_cart();
  end if;

  if p_operation = 'remove' then
    delete from public.cart_items where user_id = caller and variant_id = p_variant_id;
  else
    select v.stock, p.is_visible and c.is_active into current_stock, visible
    from public.product_variants v
    join public.products p on p.id = v.product_id
    join public.categories c on c.id = p.category_id
    where v.id = p_variant_id
    for share of v, p, c;
    if not found or not visible then
      raise exception using errcode = 'P0001', message = 'SF_PRODUCT_UNAVAILABLE';
    end if;
    select quantity into old_quantity from public.cart_items
    where user_id = caller and variant_id = p_variant_id;
    new_quantity := case when p_operation = 'add' then coalesce(old_quantity, 0) + p_quantity else p_quantity end;
    if new_quantity > 99 then
      raise exception using errcode = 'P0001', message = 'SF_CART_LIMIT';
    end if;
    if new_quantity > current_stock then
      raise exception using errcode = 'P0001', message = 'SF_STOCK_CHANGED';
    end if;
    insert into public.cart_items(user_id, variant_id, quantity)
    values (caller, p_variant_id, new_quantity)
    on conflict (user_id, variant_id) do update set quantity = excluded.quantity;
  end if;

  insert into private.cart_mutations(user_id, request_id, variant_id, operation, quantity)
  values (caller, p_request_id, p_variant_id, p_operation, p_quantity);
  return public.get_cart();
end;
$$;
revoke all on function public.mutate_cart(uuid, integer, text, uuid) from public, anon, authenticated;
grant execute on function public.mutate_cart(uuid, integer, text, uuid) to authenticated;

comment on table public.cart_items is 'Giỏ theo tài khoản và biến thể; không giữ chỗ/trừ tồn kho. Ghi qua mutate_cart.';
comment on function public.mutate_cart(uuid, integer, text, uuid) is 'Chỉ giỏ của auth.uid(); kiểm tra hàng đang bán/tồn kho; request_id chống ghi trùng.';
notify pgrst, 'reload schema';
commit;

-- Refs #20. D01–D14 are provisional. See checkout-cod-orders-backend-plan.md.
begin;

create table private.checkout_quotes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_id uuid not null,
  snapshot jsonb not null,
  created_at timestamptz not null,
  expires_at timestamptz not null check (expires_at > created_at)
);
create index checkout_quotes_owner_expiry_idx on private.checkout_quotes (user_id, expires_at);

create sequence private.order_number_seq;
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  -- Preserve existing Auth deletion semantics and keep order history (D08/D11).
  user_id uuid references auth.users(id) on delete set null,
  checkout_quote_id uuid not null unique,
  source_address_id uuid not null,
  delivery_address jsonb not null check (jsonb_typeof(delivery_address) = 'object'),
  status text not null default 'pending' check (status in ('pending','confirmed','shipping','completed','cancelled')),
  version integer not null default 1 check (version >= 1),
  currency text not null default 'VND' check (currency = 'VND'),
  payment_method text not null default 'cod' check (payment_method = 'cod'),
  subtotal_vnd bigint not null check (subtotal_vnd > 0),
  shipping_vnd bigint not null check (shipping_vnd >= 0),
  total_vnd bigint not null check (total_vnd = subtotal_vnd + shipping_vnd and total_vnd <= 9000000000000),
  shipping_rule_version text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  completed_at timestamptz,
  cancelled_at timestamptz,
  stock_restored_at timestamptz,
  check ((completed_at is not null) = (status = 'completed')),
  check ((cancelled_at is not null) = (status = 'cancelled')),
  check ((stock_restored_at is not null) = (status = 'cancelled'))
);
create index orders_owner_page_idx on public.orders (user_id, created_at desc, id desc);
create index orders_status_page_idx on public.orders (status, created_at desc, id desc);
create index orders_page_idx on public.orders (created_at desc, id desc);

create table public.order_items (
  order_id uuid not null references public.orders(id) on delete restrict,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  line_no integer not null check (line_no between 1 and 100),
  product_code text not null,
  product_name text not null,
  sku text not null,
  size text not null,
  color text not null,
  image_paths text[] not null,
  quantity integer not null check (quantity between 1 and 99),
  unit_price_vnd bigint not null check (unit_price_vnd > 0),
  line_total_vnd bigint generated always as (unit_price_vnd * quantity) stored,
  created_at timestamptz not null,
  primary key (order_id, variant_id),
  unique (order_id, line_no)
);
create index order_items_product_idx on public.order_items (product_id);
create index order_items_variant_idx on public.order_items (variant_id);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  version integer not null check (version >= 1),
  from_status text check (from_status in ('pending','confirmed','shipping','completed','cancelled')),
  to_status text not null check (to_status in ('pending','confirmed','shipping','completed','cancelled')),
  actor_user_id uuid references auth.users(id) on delete set null,
  actor_role text not null check (actor_role in ('customer','admin')),
  reason_code text check (reason_code in ('customer_requested','cannot_fulfill','duplicate_confirmed')),
  created_at timestamptz not null,
  unique (order_id, version),
  check ((from_status is null) = (version = 1)),
  check ((reason_code is not null) = (to_status = 'cancelled'))
);
create index order_status_history_actor_idx on public.order_status_history (actor_user_id);

create table private.order_request_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  operation text not null check (operation in ('place_cod_order','change_order_status')),
  payload jsonb not null,
  order_id uuid not null references public.orders(id) on delete restrict,
  result jsonb not null,
  created_at timestamptz not null default clock_timestamp(),
  primary key (user_id, request_id)
);
create index order_request_receipts_order_idx on private.order_request_receipts (order_id);

alter table private.checkout_quotes enable row level security;
alter table private.order_request_receipts enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
-- RPC-only access, including reads. In particular, never grant direct access to actor IDs.
revoke all on private.checkout_quotes, private.order_request_receipts, public.orders,
  public.order_items, public.order_status_history from public, anon, authenticated;
revoke all on sequence private.order_number_seq from public, anon, authenticated;

create function private.orders_caller() returns uuid
language plpgsql stable set search_path = '' as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null or not exists (select 1 from auth.users where id = caller) then
    raise exception using errcode = 'PT401', message = 'SF_AUTH_REQUIRED';
  end if;
  return caller;
end;
$$;

create function private.orders_lock_caller(p_caller uuid) returns void
language sql set search_path = '' as $$
  select pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_caller::text, 0));
$$;

create function private.order_replay(
  p_caller uuid, p_request uuid, p_operation text, p_payload jsonb
) returns jsonb language plpgsql set search_path = '' as $$
declare
  receipt private.order_request_receipts%rowtype;
begin
  select * into receipt from private.order_request_receipts
    where user_id = p_caller and request_id = p_request;
  if not found then return null; end if;
  if receipt.operation <> p_operation or receipt.payload <> p_payload then
    raise exception using errcode = 'PT409', message = 'SF_REQUEST_CONFLICT';
  end if;
  return jsonb_build_object('schema_version', 1, 'replayed', true, 'result', receipt.result);
end;
$$;

create function private.orders_cart(p_caller uuid) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'variant_id', variant_id, 'quantity', quantity
  ) order by variant_id), '[]'::jsonb)
  from public.cart_items where user_id = p_caller;
$$;

create function private.checkout_snapshot(p_caller uuid, p_address uuid, p_place boolean)
returns jsonb language plpgsql set search_path = '' as $$
declare
  address_snapshot jsonb;
  cart jsonb;
  items jsonb;
  subtotal bigint;
  shipping constant bigint := 25000; -- D02, demo rule
  ids uuid[];
  products uuid[];
  categories uuid[];
  invalid_catalog boolean;
  insufficient_stock boolean;
begin
  select jsonb_build_object('recipient_name', a.recipient_name, 'phone', a.phone,
    'address_line', a.address_line, 'ward', a.ward, 'district', a.district, 'city', a.city)
  into address_snapshot
  from public.addresses a where a.id = p_address and a.user_id = p_caller for share;
  if not found then
    raise exception using errcode = 'PT404', message = 'SF_ADDRESS_UNAVAILABLE';
  end if;

  -- Caller lock is shared with mutate_cart. Variant-first matches Cart's row marks.
  cart := private.orders_cart(p_caller);
  if jsonb_array_length(cart) = 0 then
    raise exception using errcode = 'PT409', message = 'SF_CART_EMPTY';
  end if;
  if jsonb_array_length(cart) > 100 then
    raise exception using errcode = 'PT409', message = 'SF_CART_LIMIT';
  end if;
  select array_agg((line->>'variant_id')::uuid) into ids from jsonb_array_elements(cart) line;
  if p_place then
    perform v.id from public.product_variants v where v.id = any(ids) order by v.id for no key update;
  else
    perform v.id from public.product_variants v where v.id = any(ids) order by v.id for share;
  end if;
  select array_agg(distinct v.product_id) into products from public.product_variants v where v.id = any(ids);
  perform p.id from public.products p where p.id = any(products) order by p.id for share;
  select array_agg(distinct p.category_id) into categories from public.products p where p.id = any(products);
  perform c.id from public.categories c where c.id = any(categories) order by c.id for share;

  select jsonb_agg(jsonb_build_object(
      'variant_id', v.id, 'product_id', p.id, 'category_id', c.id, 'product_code', p.code,
      'product_name', p.name, 'sku', v.sku, 'size', v.size, 'color', v.color,
      'image_paths', p.image_paths, 'quantity', line.quantity,
      'unit_price_vnd', p.price_vnd::bigint, 'line_total_vnd', p.price_vnd::bigint * line.quantity
    ) order by v.id),
    sum(p.price_vnd::bigint * line.quantity)::bigint,
    bool_or(not (p.is_visible and c.is_active)), bool_or(v.stock < line.quantity)
  into items, subtotal, invalid_catalog, insufficient_stock
  from jsonb_to_recordset(cart) as line(variant_id uuid, quantity integer)
  join public.product_variants v on v.id = line.variant_id
  join public.products p on p.id = v.product_id
  join public.categories c on c.id = p.category_id;
  if invalid_catalog or items is null or jsonb_array_length(items) <> cardinality(ids) then
    raise exception using errcode = 'PT409', message = 'SF_PRODUCT_UNAVAILABLE';
  end if;
  if insufficient_stock then
    raise exception using errcode = 'PT409', message = 'SF_STOCK_CHANGED';
  end if;
  if subtotal + shipping > 9000000000000 then
    raise exception using errcode = 'PT400', message = 'SF_TOTAL_LIMIT';
  end if;
  return jsonb_build_object('schema_version', 1, 'cart', cart, 'items', items,
    'address_id', p_address, 'address', address_snapshot, 'subtotal_vnd', subtotal,
    'shipping_vnd', shipping, 'total_vnd', subtotal + shipping,
    'shipping_rule_version', 'flat_cod_v1', 'currency', 'VND', 'payment_method', 'cod');
end;
$$;

create function public.create_checkout_quote(p_address_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  snapshot jsonb;
  quoted_at timestamptz;
  quote private.checkout_quotes%rowtype;
begin
  if p_address_id is null then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_CHECKOUT';
  end if;
  perform private.orders_lock_caller(caller);
  snapshot := private.checkout_snapshot(caller, p_address_id, false);
  quoted_at := clock_timestamp();
  if (select count(*) from private.checkout_quotes q
      where q.user_id = caller and q.expires_at > quoted_at
        and not exists (select 1 from public.orders o where o.checkout_quote_id = q.id)) >= 10 then
    raise exception using errcode = 'PT429', message = 'SF_QUOTE_LIMIT';
  end if;
  insert into private.checkout_quotes (user_id, address_id, snapshot, created_at, expires_at)
  values (caller, p_address_id, snapshot, quoted_at, quoted_at + interval '300 seconds')
  returning * into quote;
  return (snapshot - 'cart') || jsonb_build_object('quote_id', quote.id, 'expires_at', quote.expires_at);
end;
$$;

create function public.place_cod_order(p_quote_id uuid, p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  payload jsonb := jsonb_build_object('v', 1, 'quote_id', p_quote_id);
  result jsonb;
  quote private.checkout_quotes%rowtype;
  snapshot jsonb;
  placed_at timestamptz;
  order_sequence text;
  placed public.orders%rowtype;
begin
  if p_quote_id is null or p_request_id is null then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_CHECKOUT';
  end if;
  perform private.orders_lock_caller(caller);
  result := private.order_replay(caller, p_request_id, 'place_cod_order', payload);
  if result is not null then return result; end if;

  select * into quote from private.checkout_quotes where id = p_quote_id and user_id = caller for update;
  if not found then
    raise exception using errcode = 'PT404', message = 'SF_QUOTE_NOT_FOUND';
  end if;
  if exists (select 1 from public.orders where checkout_quote_id = quote.id) then
    raise exception using errcode = 'PT409', message = 'SF_QUOTE_USED';
  end if;
  if quote.expires_at <= clock_timestamp() then
    raise exception using errcode = 'PT409', message = 'SF_QUOTE_EXPIRED';
  end if;
  if private.orders_cart(caller) <> quote.snapshot->'cart' then
    raise exception using errcode = 'PT409', message = 'SF_CART_CHANGED';
  end if;
  snapshot := private.checkout_snapshot(caller, quote.address_id, true);
  placed_at := clock_timestamp();
  if quote.expires_at <= placed_at then
    raise exception using errcode = 'PT409', message = 'SF_QUOTE_EXPIRED';
  end if;
  if snapshot <> quote.snapshot then
    raise exception using errcode = 'PT409', message = 'SF_QUOTE_STALE';
  end if;

  order_sequence := nextval('private.order_number_seq'::regclass)::text;
  insert into public.orders (order_number, user_id, checkout_quote_id, source_address_id, delivery_address,
    subtotal_vnd, shipping_vnd, total_vnd, shipping_rule_version, created_at, updated_at)
  values ('SF-' || lpad(order_sequence, greatest(6, length(order_sequence)), '0'), caller, quote.id,
    quote.address_id, snapshot->'address', (snapshot->>'subtotal_vnd')::bigint,
    (snapshot->>'shipping_vnd')::bigint, (snapshot->>'total_vnd')::bigint,
    snapshot->>'shipping_rule_version', placed_at, placed_at)
  returning * into placed;

  insert into public.order_items (order_id, variant_id, product_id, line_no, product_code, product_name,
    sku, size, color, image_paths, quantity, unit_price_vnd, created_at)
  select placed.id, (line->>'variant_id')::uuid, (line->>'product_id')::uuid, position::integer,
    line->>'product_code', line->>'product_name', line->>'sku', line->>'size', line->>'color',
    array(select jsonb_array_elements_text(line->'image_paths')),
    (line->>'quantity')::integer, (line->>'unit_price_vnd')::bigint, placed_at
  from jsonb_array_elements(snapshot->'items') with ordinality as items(line, position);

  update public.product_variants v set stock = v.stock - i.quantity
  from public.order_items i where i.order_id = placed.id and i.variant_id = v.id;
  delete from public.cart_items ci using public.order_items i
    where i.order_id = placed.id and ci.user_id = caller and ci.variant_id = i.variant_id;
  insert into public.order_status_history (order_id, version, to_status, actor_user_id, actor_role, created_at)
    values (placed.id, 1, 'pending', caller, 'customer', placed_at);

  result := jsonb_build_object('request_id', p_request_id, 'order_id', placed.id,
    'order_number', placed.order_number, 'status_at_creation', placed.status,
    'currency', placed.currency, 'payment_method', placed.payment_method,
    'subtotal_vnd', placed.subtotal_vnd, 'shipping_vnd', placed.shipping_vnd,
    'total_vnd', placed.total_vnd, 'created_at', placed.created_at);
  insert into private.order_request_receipts (user_id, request_id, operation, payload, order_id, result)
    values (caller, p_request_id, 'place_cod_order', payload, placed.id, result);
  return jsonb_build_object('schema_version', 1, 'replayed', false, 'result', result);
end;
$$;

create function public.lookup_order_request(p_request_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  receipt private.order_request_receipts%rowtype;
begin
  if p_request_id is null then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_CHECKOUT';
  end if;
  select * into receipt from private.order_request_receipts
    where user_id = caller and request_id = p_request_id;
  if not found then return jsonb_build_object('found', false); end if;
  return jsonb_build_object('found', true, 'operation', receipt.operation, 'result', receipt.result);
end;
$$;


create function private.order_transitions(p_status text, p_owner boolean, p_admin boolean)
returns text[] language sql immutable set search_path = '' as $$
  select case
    when p_admin and p_status = 'pending' then array['confirmed','cancelled']
    when p_admin and p_status = 'confirmed' then array['shipping','cancelled']
    when p_admin and p_status = 'shipping' then array['completed']
    when p_owner and p_status = 'pending' then array['cancelled']
    else array[]::text[]
  end;
$$;

create function public.get_order(p_order_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  administrator boolean := private.is_admin();
  selected public.orders%rowtype;
begin
  select * into selected from public.orders o
    where o.id = p_order_id and (administrator or o.user_id = caller);
  if not found then
    raise exception using errcode = 'PT404', message = 'SF_ORDER_NOT_FOUND';
  end if;
  return (to_jsonb(selected) - 'user_id' - 'checkout_quote_id') || jsonb_build_object(
    'schema_version', 1,
    'items', (select coalesce(jsonb_agg(to_jsonb(i) - 'order_id' order by i.line_no), '[]'::jsonb)
      from public.order_items i where i.order_id = selected.id),
    'events', (select coalesce(jsonb_agg(to_jsonb(h) - 'actor_user_id' - 'order_id' order by h.version), '[]'::jsonb)
      from public.order_status_history h where h.order_id = selected.id),
    'allowed_transitions', private.order_transitions(selected.status, selected.user_id = caller, administrator));
end;
$$;

create function private.orders_page(p_caller uuid, p_admin boolean, p_filter text, p_limit integer, p_cursor jsonb)
returns jsonb language plpgsql stable set search_path = '' as $$
declare
  cursor_at timestamptz;
  cursor_id uuid;
begin
  if p_filter is null or p_limit is null or p_limit not between 1 and 50
     or not (p_filter in ('all','processing','completed','cancelled')
       or (p_admin and p_filter in ('pending','confirmed','shipping'))) then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_FILTER';
  end if;
  if p_cursor is not null then
    if jsonb_typeof(p_cursor) <> 'object' or
       jsonb_typeof(p_cursor->'created_at') is distinct from 'string' or
       jsonb_typeof(p_cursor->'id') is distinct from 'string' then
      raise exception using errcode = 'PT400', message = 'SF_INVALID_FILTER';
    end if;
    begin
      cursor_at := (p_cursor->>'created_at')::timestamptz;
      cursor_id := (p_cursor->>'id')::uuid;
    exception when invalid_text_representation or invalid_datetime_format or datetime_field_overflow then
      raise exception using errcode = 'PT400', message = 'SF_INVALID_FILTER';
    end;
    if not isfinite(cursor_at) then
      raise exception using errcode = 'PT400', message = 'SF_INVALID_FILTER';
    end if;
  end if;

  return (
    with candidates as (
      select o.id, o.order_number, o.status, o.version, o.created_at, o.total_vnd, o.currency, o.payment_method
      from public.orders o
      where (p_admin or o.user_id = p_caller)
        and (p_filter = 'all' or o.status = p_filter
          or (p_filter = 'processing' and o.status in ('pending','confirmed','shipping')))
        and (cursor_id is null or (o.created_at, o.id) < (cursor_at, cursor_id))
      order by o.created_at desc, o.id desc
      limit p_limit + 1
    ), page as (
      select c.*, lines.distinct_line_count, lines.total_quantity, lines.product_names
      from (select * from candidates order by created_at desc, id desc limit p_limit) c
      cross join lateral (
        select count(*) as distinct_line_count, sum(i.quantity) as total_quantity,
          coalesce(jsonb_agg(i.product_name order by i.line_no) filter (where i.line_no <= 3), '[]'::jsonb)
            as product_names
        from public.order_items i where i.order_id = c.id
      ) lines
    )
    select jsonb_build_object('items', (select coalesce(jsonb_agg(to_jsonb(page)
      order by created_at desc, id desc), '[]'::jsonb) from page),
      'next_cursor', case when (select count(*) from candidates) > p_limit then
        (select jsonb_build_object('created_at', created_at, 'id', id)
          from page order by created_at, id limit 1)
      end)
  );
end;
$$;

create function public.list_my_orders(p_filter text default 'all', p_limit integer default 20,
  p_cursor jsonb default null) returns jsonb
language sql stable security definer set search_path = '' as $$
  select private.orders_page(private.orders_caller(), false, p_filter, p_limit, p_cursor);
$$;

create function public.list_admin_orders(p_filter text default 'all', p_limit integer default 20,
  p_cursor jsonb default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
begin
  if not private.is_admin() then
    raise exception using errcode = 'PT403', message = 'SF_FORBIDDEN';
  end if;
  return private.orders_page(caller, true, p_filter, p_limit, p_cursor);
end;
$$;

create function public.change_order_status(p_order_id uuid, p_target_status text, p_expected_version integer,
  p_request_id uuid, p_reason_code text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  administrator boolean;
  payload jsonb := jsonb_build_object('v', 1, 'order_id', p_order_id, 'target_status', p_target_status,
    'expected_version', p_expected_version, 'reason_code', p_reason_code);
  result jsonb;
  selected public.orders%rowtype;
  changed_at timestamptz;
  event_id uuid;
begin
  if p_order_id is null or p_request_id is null or p_expected_version is null or p_expected_version < 1
     or p_target_status is null or p_target_status not in ('pending','confirmed','shipping','completed','cancelled') then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_CHECKOUT';
  end if;
  perform private.orders_lock_caller(caller);
  result := private.order_replay(caller, p_request_id, 'change_order_status', payload);
  if result is not null then return result; end if;

  select r.role = 'admin' into administrator from public.user_roles r
    where r.user_id = caller for share;
  administrator := coalesce(administrator, false);

  select * into selected from public.orders o
    where o.id = p_order_id and (administrator or o.user_id = caller) for update;
  if not found then
    raise exception using errcode = 'PT404', message = 'SF_ORDER_NOT_FOUND';
  end if;
  if selected.version <> p_expected_version then
    raise exception using errcode = 'PT409', message = 'SF_ORDER_VERSION_CONFLICT';
  end if;
  if not p_target_status = any(private.order_transitions(selected.status, selected.user_id = caller, administrator)) then
    raise exception using errcode = 'PT409', message = 'SF_ORDER_TRANSITION_INVALID';
  end if;
  if (p_target_status <> 'cancelled' and p_reason_code is not null)
     or (p_target_status = 'cancelled' and (p_reason_code is null
       or p_reason_code not in ('customer_requested','cannot_fulfill','duplicate_confirmed')
       or (not administrator and p_reason_code <> 'customer_requested'))) then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_CHECKOUT';
  end if;

  if p_target_status = 'cancelled' then
    perform v.id from public.product_variants v
      join public.order_items i on i.variant_id = v.id
      where i.order_id = selected.id order by v.id for no key update of v;
    if exists (select 1 from public.product_variants v join public.order_items i on i.variant_id = v.id
      where i.order_id = selected.id and v.stock::bigint + i.quantity > 2147483647) then
      raise exception using errcode = 'PT409', message = 'SF_STOCK_CHANGED';
    end if;
    update public.product_variants v set stock = v.stock + i.quantity
      from public.order_items i where i.order_id = selected.id and i.variant_id = v.id;
  end if;

  changed_at := clock_timestamp();
  update public.orders set status = p_target_status, version = selected.version + 1, updated_at = changed_at,
    completed_at = case when p_target_status = 'completed' then changed_at end,
    cancelled_at = case when p_target_status = 'cancelled' then changed_at end,
    stock_restored_at = case when p_target_status = 'cancelled' then changed_at end
    where id = selected.id;
  insert into public.order_status_history (order_id, version, from_status, to_status, actor_user_id,
    actor_role, reason_code, created_at)
  values (selected.id, selected.version + 1, selected.status, p_target_status, caller,
    case when administrator then 'admin' else 'customer' end, p_reason_code, changed_at)
  returning id into event_id;
  result := jsonb_build_object('order_id', selected.id, 'status', p_target_status,
    'version', selected.version + 1, 'event_id', event_id, 'changed_at', changed_at);
  insert into private.order_request_receipts (user_id, request_id, operation, payload, order_id, result)
    values (caller, p_request_id, 'change_order_status', payload, selected.id, result);
  return jsonb_build_object('schema_version', 1, 'replayed', false, 'result', result);
end;
$$;

revoke all on function private.orders_caller(), private.orders_lock_caller(uuid),
  private.order_replay(uuid, uuid, text, jsonb), private.orders_cart(uuid),
  private.checkout_snapshot(uuid, uuid, boolean), private.order_transitions(text, boolean, boolean),
  private.orders_page(uuid, boolean, text, integer, jsonb) from public, anon, authenticated;
revoke all on function public.create_checkout_quote(uuid), public.place_cod_order(uuid, uuid),
  public.lookup_order_request(uuid), public.get_order(uuid), public.list_my_orders(text, integer, jsonb),
  public.list_admin_orders(text, integer, jsonb), public.change_order_status(uuid, text, integer, uuid, text)
  from public, anon, authenticated;
grant execute on function public.create_checkout_quote(uuid), public.place_cod_order(uuid, uuid),
  public.lookup_order_request(uuid), public.get_order(uuid), public.list_my_orders(text, integer, jsonb),
  public.list_admin_orders(text, integer, jsonb), public.change_order_status(uuid, text, integer, uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
commit;

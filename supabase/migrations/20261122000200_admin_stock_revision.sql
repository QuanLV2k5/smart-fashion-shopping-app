-- Refs #20, #29. D09 provisional. Coordinate removal of direct stock UPDATE with Admin Catalog.
begin;

alter table public.product_variants add column stock_revision bigint not null default 0
  check (stock_revision >= 0);

create function private.update_stock_revision() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.stock_revision := 0;
  elsif new.stock is distinct from old.stock then
    new.stock_revision := old.stock_revision + 1;
  else
    new.stock_revision := old.stock_revision;
  end if;
  return new;
end;
$$;
revoke all on function private.update_stock_revision() from public, anon, authenticated;
create trigger product_variants_stock_revision before insert or update on public.product_variants
for each row execute function private.update_stock_revision();

create function public.set_variant_stock(p_variant_id uuid, p_expected_revision bigint, p_new_stock integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := private.orders_caller();
  administrator boolean;
  updated public.product_variants%rowtype;
begin
  if p_variant_id is null or p_expected_revision is null or p_expected_revision < 0
      or p_new_stock is null or p_new_stock < 0 then
    raise exception using errcode = 'PT400', message = 'SF_INVALID_STOCK';
  end if;
  select r.role = 'admin' into administrator from public.user_roles r
    where r.user_id = caller for share;
  if administrator is distinct from true then
    raise exception using errcode = 'PT403', message = 'SF_FORBIDDEN';
  end if;

  update public.product_variants v set stock = p_new_stock
    where v.id = p_variant_id and v.stock_revision = p_expected_revision
    returning * into updated;
  if not found then
    raise exception using errcode = 'PT409', message = 'SF_STOCK_VERSION_CONFLICT';
  end if;
  return jsonb_build_object('variant_id', updated.id, 'stock', updated.stock,
    'stock_revision', updated.stock_revision);
end;
$$;
revoke all on function public.set_variant_stock(uuid, bigint, integer) from public, anon, authenticated;
grant execute on function public.set_variant_stock(uuid, bigint, integer) to authenticated;

notify pgrst, 'reload schema';
commit;

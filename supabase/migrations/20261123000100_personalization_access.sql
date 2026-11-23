-- Issue #18. Review before cloud deployment. Does not change the Orders contract.
begin;
alter table public.profiles
  add column access_state text not null default 'active' check (access_state in ('active','blocked')),
  add column access_version bigint not null default 0 check (access_version >= 0);

create table private.user_access_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  old_state text not null,
  new_state text not null,
  version bigint not null,
  created_at timestamptz not null default now()
);
alter table private.user_access_events enable row level security;
revoke all on private.user_access_events from public,anon,authenticated;

create function private.account_allowed() returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.profiles where id=auth.uid() and access_state='active');
$$;
revoke all on function private.account_allowed() from public,anon;
grant execute on function private.account_allowed() to authenticated;

create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.user_roles r join public.profiles p on p.id=r.user_id
    where r.user_id=auth.uid() and r.role='admin' and p.access_state='active');
$$;

create function private.require_active_account() returns uuid
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=auth.uid(); current_state text;
begin
  select access_state into current_state from public.profiles where id=caller;
  if caller is null or current_state is null then
    raise exception using errcode='PT401',message='SF_AUTH_REQUIRED';
  end if;
  if current_state<>'active' then
    raise exception using errcode='PT403',message='SF_ACCESS_BLOCKED';
  end if;
  return caller;
end $$;
revoke all on function private.require_active_account() from public,anon,authenticated;

-- PostgREST guard also covers future Orders RPCs while #30 is being reviewed.
-- Storage is protected separately below; JWT expiry is not used as a block switch.
create function private.check_app_access() returns void
language plpgsql stable security definer set search_path='' as $$
begin
  if auth.uid() is not null then perform private.require_active_account(); end if;
end $$;
revoke all on function private.check_app_access() from public,anon,authenticated;
grant execute on function private.check_app_access() to anon,authenticated;
-- If Orders already exists, protect SQL entry points as well as the REST hook.
do $$ begin
  if to_regprocedure('private.orders_caller()') is not null then
    execute 'create or replace function private.orders_caller() returns uuid language plpgsql stable security definer set search_path='''' as $body$ begin return private.require_active_account(); end $body$';
  end if;
end $$;
do $$
declare existing text;
begin
  select substring(setting from length('pgrst.db_pre_request=')+1) into existing
  from pg_roles r cross join lateral unnest(r.rolconfig) setting
  where r.rolname='authenticator' and setting like 'pgrst.db_pre_request=%';
  if coalesce(existing,'') not in ('','private.check_app_access') then
    raise exception 'Existing db_pre_request hook must be reviewed and chained first';
  end if;
end $$;
alter role authenticator set pgrst.db_pre_request='private.check_app_access';

do $$
declare target text;
begin
  foreach target in array array['profiles','user_roles','addresses','cart_items'] loop
    execute format('create policy active_account_required on public.%I as restrictive for all to authenticated using ((select private.account_allowed())) with check ((select private.account_allowed()))',target);
  end loop;
end $$;
create policy active_account_storage_insert on storage.objects as restrictive for insert to authenticated
with check ((select private.account_allowed()));
create policy active_account_storage_update on storage.objects as restrictive for update to authenticated
using ((select private.account_allowed())) with check ((select private.account_allowed()));
create policy active_account_storage_delete on storage.objects as restrictive for delete to authenticated
using ((select private.account_allowed()));

-- Existing security-definer entry points need the same check for SQL callers.
alter function public.get_cart() set schema private;
alter function private.get_cart() rename to get_cart_before_access;
revoke all on function private.get_cart_before_access() from public,anon,authenticated;
create function public.get_cart() returns jsonb
language plpgsql security definer set search_path='' as $$
begin perform private.require_active_account(); return private.get_cart_before_access(); end $$;
alter function public.mutate_cart(uuid,integer,text,uuid) set schema private;
alter function private.mutate_cart(uuid,integer,text,uuid) rename to mutate_cart_before_access;
revoke all on function private.mutate_cart_before_access(uuid,integer,text,uuid) from public,anon,authenticated;
create function public.mutate_cart(p_variant_id uuid,p_quantity integer,p_operation text,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
  perform private.require_active_account();
  return private.mutate_cart_before_access(p_variant_id,p_quantity,p_operation,p_request_id);
end $$;
alter function public.consume_ai_request() set schema private;
alter function private.consume_ai_request() rename to consume_ai_before_access;
revoke all on function private.consume_ai_before_access() from public,anon,authenticated;
create function public.consume_ai_request() returns boolean
language plpgsql security definer set search_path='' as $$
begin perform private.require_active_account(); return private.consume_ai_before_access(); end $$;
revoke all on function public.get_cart(),public.mutate_cart(uuid,integer,text,uuid),public.consume_ai_request() from public,anon;
grant execute on function public.get_cart(),public.mutate_cart(uuid,integer,text,uuid),public.consume_ai_request() to authenticated;

create function public.get_my_access() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=private.require_active_account();
begin
  return jsonb_build_object('state','active','is_admin',private.is_admin());
end $$;

create function public.list_app_users(p_search text default '',p_offset integer default 0) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
  perform private.require_active_account();
  if not private.is_admin() then raise exception using errcode='PT403',message='SF_FORBIDDEN'; end if;
  if p_search is null or length(p_search)>100 or p_offset is null or p_offset<0 or p_offset>100000 then
    raise exception using errcode='PT400',message='SF_INVALID_INPUT';
  end if;
  return (with filtered as (
    select p.id,p.full_name,p.phone,u.email,r.role,p.access_state,p.access_version,p.created_at
    from public.profiles p join auth.users u on u.id=p.id join public.user_roles r on r.user_id=p.id
    where strpos(lower(p.full_name||' '||coalesce(u.email,'')||' '||coalesce(p.phone,'')),lower(trim(p_search)))>0
  ), page as (select * from filtered order by created_at desc,id limit 50 offset p_offset)
  select jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(page) order by created_at desc,id) from page),'[]'::jsonb),
    'has_more',(select count(*) from filtered)>p_offset+50));
end $$;

create function public.get_app_user(p_user_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  perform private.require_active_account();
  if not private.is_admin() then raise exception using errcode='PT403',message='SF_FORBIDDEN'; end if;
  select jsonb_build_object('id',p.id,'full_name',p.full_name,'phone',p.phone,'email',u.email,'role',r.role,
    'access_state',p.access_state,'access_version',p.access_version,'created_at',p.created_at) into result
  from public.profiles p join auth.users u on u.id=p.id join public.user_roles r on r.user_id=p.id where p.id=p_user_id;
  if result is null then raise exception using errcode='PT404',message='SF_USER_NOT_FOUND'; end if;
  return result;
end $$;

create function public.set_user_access(p_user_id uuid,p_blocked boolean,p_expected_version bigint) returns jsonb
language plpgsql security definer set search_path='' as $$
declare caller uuid:=private.require_active_account(); target public.profiles%rowtype; desired text;
begin
  if not private.is_admin() then raise exception using errcode='PT403',message='SF_FORBIDDEN'; end if;
  if p_user_id is null or p_blocked is null or p_expected_version is null then
    raise exception using errcode='PT400',message='SF_INVALID_INPUT'; end if;
  -- Basic account moderation only. No role changes and no locking any admin.
  perform 1 from public.user_roles where user_id=p_user_id and role='customer' for share;
  if not found or p_user_id=caller then raise exception using errcode='PT403',message='SF_PROTECTED_ACCOUNT'; end if;
  select * into target from public.profiles where id=p_user_id for update;
  if not found then raise exception using errcode='PT404',message='SF_USER_NOT_FOUND'; end if;
  if target.access_version<>p_expected_version then
    raise exception using errcode='PT409',message='SF_ACCESS_VERSION_CONFLICT'; end if;
  desired:=case when p_blocked then 'blocked' else 'active' end;
  if target.access_state<>desired then
    update public.profiles set access_state=desired,access_version=access_version+1 where id=p_user_id;
    insert into private.user_access_events(user_id,actor_id,old_state,new_state,version)
    values(p_user_id,caller,target.access_state,desired,target.access_version+1);
  end if;
  return public.get_app_user(p_user_id);
end $$;

create table public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(user_id,product_id)
);
alter table public.favorites enable row level security;
revoke all on public.favorites from public,anon,authenticated;
grant select on public.favorites to authenticated;
create policy favorites_own on public.favorites for select to authenticated
using(user_id=auth.uid() and (select private.account_allowed()));

create function public.get_favorites() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=private.require_active_account();
begin
  return jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object('product_id',f.product_id,
    'product',case when p.is_visible and c.is_active then to_jsonb(p)-'created_at'-'updated_at'-'is_visible' ||
      jsonb_build_object('product_variants',coalesce((select jsonb_agg(to_jsonb(v)) from public.product_variants v where v.product_id=p.id),'[]'::jsonb)) end)
    order by f.created_at desc,f.product_id)
    from public.favorites f join public.products p on p.id=f.product_id join public.categories c on c.id=p.category_id
    where f.user_id=caller),'[]'::jsonb));
end $$;

create function public.set_favorite(p_product_id uuid,p_favorite boolean) returns void
language plpgsql security definer set search_path='' as $$
declare caller uuid:=private.require_active_account();
begin
  if p_product_id is null or p_favorite is null then raise exception using errcode='PT400',message='SF_INVALID_INPUT'; end if;
  perform pg_advisory_xact_lock(hashtextextended(caller::text,0));
  if not p_favorite then delete from public.favorites where user_id=caller and product_id=p_product_id; return; end if;
  perform 1 from public.products p join public.categories c on c.id=p.category_id
    where p.id=p_product_id and p.is_visible and c.is_active for share of p,c;
  if not found then raise exception using errcode='PT404',message='SF_PRODUCT_UNAVAILABLE'; end if;
  if (select count(*) from public.favorites where user_id=caller)>=200
    and not exists(select 1 from public.favorites where user_id=caller and product_id=p_product_id) then
    raise exception using errcode='PT400',message='SF_FAVORITES_LIMIT'; end if;
  insert into public.favorites(user_id,product_id) values(caller,p_product_id) on conflict do nothing;
end $$;

create table public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  rating integer not null check(rating between 1 and 5),
  body text not null default '' check(length(body)<=1000),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(user_id,product_id)
);
alter table public.product_reviews enable row level security;
revoke all on public.product_reviews from public,anon,authenticated;
-- No direct table reads: the public DTO never exposes reviewer UUID/email/phone.
create function private.completed_purchase(p_user_id uuid,p_product_id uuid) returns boolean
language plpgsql stable security definer set search_path='' as $$
declare result boolean;
begin
  if p_user_id is null or to_regclass('public.orders') is null or to_regclass('public.order_items') is null then return false; end if;
  execute 'select exists(select 1 from public.orders o join public.order_items i on i.order_id=o.id where o.user_id=$1 and o.status=''completed'' and i.product_id=$2)'
    into result using p_user_id,p_product_id;
  return result;
end $$;
revoke all on function private.completed_purchase(uuid,uuid) from public,anon,authenticated;

create function public.get_product_reviews(p_product_id uuid,p_offset integer default 0) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare own_id uuid:=auth.uid(); purchased boolean; visible boolean; own_review jsonb; product_name text;
begin
  perform private.check_app_access();
  if p_product_id is null or p_offset is null or p_offset<0 or p_offset>100000 then
    raise exception using errcode='PT400',message='SF_INVALID_INPUT'; end if;
  purchased:=private.completed_purchase(own_id,p_product_id);
  select p.name,p.is_visible and c.is_active into product_name,visible from public.products p join public.categories c on c.id=p.category_id where p.id=p_product_id;
  if product_name is null or not (visible or purchased or private.is_admin()) then
    raise exception using errcode='PT404',message='SF_PRODUCT_UNAVAILABLE'; end if;
  select jsonb_build_object('id',r.id,'rating',r.rating,'body',r.body,'created_at',r.created_at) into own_review
    from public.product_reviews r where r.user_id=own_id and r.product_id=p_product_id;
  return (with matches as (
    select r.id,r.rating,r.body,r.created_at,r.updated_at,'Người mua hàng'::text as author_name
    from public.product_reviews r where r.product_id=p_product_id
  ), page as (select * from matches order by created_at desc,id limit 20 offset p_offset)
  select jsonb_build_object('product_name',product_name,'can_review',purchased,'my_review',own_review,
    'orders_ready',to_regclass('public.orders') is not null,
    'count',(select count(*) from matches),'average',coalesce((select round(avg(rating),1) from matches),0),
    'items',coalesce((select jsonb_agg(to_jsonb(page) order by created_at desc,id) from page),'[]'::jsonb),
    'has_more',(select count(*) from matches)>p_offset+20));
end $$;

create function public.submit_product_review(p_product_id uuid,p_rating integer,p_body text) returns void
language plpgsql security definer set search_path='' as $$
declare caller uuid:=private.require_active_account();
begin
  if p_product_id is null or p_rating is null or p_rating not between 1 and 5 or p_body is null or length(trim(p_body))>1000 then
    raise exception using errcode='PT400',message='SF_INVALID_REVIEW'; end if;
  if not private.completed_purchase(caller,p_product_id) then
    raise exception using errcode='PT403',message='SF_REVIEW_PURCHASE_REQUIRED'; end if;
  -- One review/account/product. Set semantics make retry after a lost response safe.
  insert into public.product_reviews(user_id,product_id,rating,body) values(caller,p_product_id,p_rating,trim(p_body))
  on conflict(user_id,product_id) do update set rating=excluded.rating,body=excluded.body,updated_at=now();
end $$;

revoke all on function public.get_my_access(),public.list_app_users(text,integer),public.get_app_user(uuid),
  public.set_user_access(uuid,boolean,bigint),public.get_favorites(),public.set_favorite(uuid,boolean),
  public.submit_product_review(uuid,integer,text),public.get_product_reviews(uuid,integer) from public,anon,authenticated;
grant execute on function public.get_my_access(),public.list_app_users(text,integer),public.get_app_user(uuid),
  public.set_user_access(uuid,boolean,bigint),public.get_favorites(),public.set_favorite(uuid,boolean),
  public.submit_product_review(uuid,integer,text),public.get_product_reviews(uuid,integer) to authenticated;
grant execute on function public.get_product_reviews(uuid,integer) to anon;
notify pgrst,'reload schema';
notify pgrst,'reload config';
commit;

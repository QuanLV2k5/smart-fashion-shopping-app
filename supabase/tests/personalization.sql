-- Real PostgreSQL/RLS tests. Fixture claims simulate SQL callers, not Auth/JWT.
-- Execute on an isolated database after migrations; all fixture data rolls back.
begin;
insert into auth.users(id,email,raw_user_meta_data) values
('93000000-0000-4000-8000-000000000001','q06-a@example.com','{"full_name":"Q06 A","role":"admin"}'),
('93000000-0000-4000-8000-000000000002','q06-b@example.com','{"full_name":"Q06 B"}'),
('93000000-0000-4000-8000-000000000003','q06-admin@example.com','{"full_name":"Q06 Admin"}');
update public.user_roles set role='admin' where user_id='93000000-0000-4000-8000-000000000003';

set local role anon;
do $$ begin
  begin perform public.get_favorites(); raise exception 'FAIL anon favorites'; exception when insufficient_privilege then null; end;
  begin perform public.list_app_users(); raise exception 'FAIL anon admin'; exception when insufficient_privilege then null; end;
  perform public.get_product_reviews(id) from public.products where code='SF01';
end $$;
reset role;

select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$ declare product uuid; result jsonb; begin
  select id into strict product from public.products where code='SF01';
  if (select role from public.user_roles where user_id=auth.uid())<>'customer' then raise exception 'FAIL metadata escalation'; end if;
  perform public.set_favorite(product,true); perform public.set_favorite(product,true);
  if (select count(*) from public.favorites)<>1 then raise exception 'FAIL duplicate favorite'; end if;
  result:=public.get_favorites();
  if jsonb_array_length(result->'items')<>1 then raise exception 'FAIL favorite read'; end if;
  begin perform public.list_app_users(); raise exception 'FAIL customer user list'; exception when sqlstate 'PT403' then if sqlerrm<>'SF_FORBIDDEN' then raise; end if; end;
  begin perform public.set_user_access(auth.uid(),true,0); raise exception 'FAIL customer block'; exception when sqlstate 'PT403' then if sqlerrm<>'SF_FORBIDDEN' then raise; end if; end;
  begin update public.profiles set access_state='active'; raise exception 'FAIL direct status write'; exception when insufficient_privilege then null; end;
  begin update public.user_roles set role='admin'; raise exception 'FAIL direct role write'; exception when insufficient_privilege then null; end;
  begin insert into public.product_reviews(user_id,product_id,rating) values(auth.uid(),product,5); raise exception 'FAIL direct review write'; exception when insufficient_privilege then null; end;
  begin perform public.submit_product_review(product,5,'Chưa mua'); raise exception 'FAIL review without purchase'; exception when sqlstate 'PT403' then if sqlerrm<>'SF_REVIEW_PURCHASE_REQUIRED' then raise; end if; end;
  begin perform public.submit_product_review(product,0,''); raise exception 'FAIL invalid rating'; exception when sqlstate 'PT400' then if sqlerrm<>'SF_INVALID_REVIEW' then raise; end if; end;
  if (public.get_product_reviews(product)->>'can_review')::boolean then raise exception 'FAIL eligibility without purchase'; end if;
end $$;
reset role;

-- Hidden favorites remain removable and do not expose catalog metadata.
update public.products set is_visible=false where code='SF01';
set local role authenticated;
do $$ declare product uuid; item jsonb; begin
  select product_id into strict product from public.favorites;
  item:=public.get_favorites()#>'{items,0}';
  if item->'product'<>'null'::jsonb then raise exception 'FAIL hidden metadata'; end if;
  begin perform public.set_favorite(product,true); raise exception 'FAIL favorite hidden product'; exception when sqlstate 'PT404' then null; end;
  perform public.set_favorite(product,false); perform public.set_favorite(product,false);
  if (select count(*) from public.favorites)<>0 then raise exception 'FAIL remove hidden'; end if;
end $$;
reset role;
update public.products set is_visible=true where code='SF01';
set local role authenticated;
select public.set_favorite(id,true) from public.products where code='SF01';
reset role;

select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000002',true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.favorites)<>0 or jsonb_array_length(public.get_favorites()->'items')<>0 then raise exception 'FAIL A/B isolation'; end if;
  if (select count(*) from public.profiles where id='93000000-0000-4000-8000-000000000001')<>0 then raise exception 'FAIL read another profile'; end if;
end $$;
reset role;

-- When Orders is present, exercise its real COD/state-machine RPCs, not a fake eligibility flag.
do $$ declare address uuid; product uuid; variant uuid; quoted uuid; placed uuid; begin
  if to_regclass('public.orders') is null then raise notice 'SKIP: completed purchase requires Orders #30'; return; end if;
  select id into strict product from public.products where code='SF01';
  select id into variant from public.product_variants where product_id=product order by id limit 1;
  update public.product_variants set stock=10 where id=variant;
  insert into public.addresses(user_id,recipient_name,phone,address_line,ward,district,city)
  values('93000000-0000-4000-8000-000000000001','Q06 A','0901234567','1 Test','Ward','District','City') returning id into address;
  perform set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
  perform public.mutate_cart(variant,1,'add',gen_random_uuid());
  execute 'select (public.create_checkout_quote($1)->>''quote_id'')::uuid' into quoted using address;
  execute 'select (public.place_cod_order($1,$2)#>>''{result,order_id}'')::uuid' into placed using quoted,gen_random_uuid();
  begin perform public.submit_product_review(product,5,'Đơn chưa hoàn tất'); raise exception 'FAIL pending order review'; exception when sqlstate 'PT403' then null; end;
  perform set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000003',true);
  execute 'select public.change_order_status($1,''confirmed'',1,$2)' using placed,gen_random_uuid();
  execute 'select public.change_order_status($1,''shipping'',2,$2)' using placed,gen_random_uuid();
  execute 'select public.change_order_status($1,''completed'',3,$2)' using placed,gen_random_uuid();
  perform set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000002',true);
  begin perform public.submit_product_review(product,5,'Mượn đơn của A'); raise exception 'FAIL another buyer'; exception when sqlstate 'PT403' then null; end;
  perform set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
  perform public.submit_product_review(product,4,'  Đúng mô tả  ');
  perform public.submit_product_review(product,5,'Mặc đẹp');
  if (select count(*) from public.product_reviews where product_id=product)<>1 then raise exception 'FAIL duplicate reviews'; end if;
  if (public.get_product_reviews(product)->>'average')::numeric<>5 then raise exception 'FAIL average'; end if;
  if public.get_product_reviews(product)#>'{items,0}' ?| array['user_id','email','phone'] then raise exception 'FAIL reviewer privacy'; end if;
end $$;

select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000003',true);
set local role authenticated;
do $$ declare result jsonb; begin
  result:=public.list_app_users('q06-a@');
  if jsonb_array_length(result->'items')<>1 then raise exception 'FAIL admin search'; end if;
  begin perform public.set_user_access(auth.uid(),true,0); raise exception 'FAIL lock self/admin'; exception when sqlstate 'PT403' then if sqlerrm<>'SF_PROTECTED_ACCOUNT' then raise; end if; end;
  perform public.set_user_access('93000000-0000-4000-8000-000000000001',true,0);
  begin perform public.set_user_access('93000000-0000-4000-8000-000000000001',false,0); raise exception 'FAIL stale access revision'; exception when sqlstate 'PT409' then if sqlerrm<>'SF_ACCESS_VERSION_CONFLICT' then raise; end if; end;
end $$;
reset role;

select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$ begin
  begin perform private.check_app_access(); raise exception 'FAIL API guard'; exception when sqlstate 'PT403' then if sqlerrm<>'SF_ACCESS_BLOCKED' then raise; end if; end;
  begin perform public.get_cart(); raise exception 'FAIL blocked cart'; exception when sqlstate 'PT403' then null; end;
  begin perform public.consume_ai_request(); raise exception 'FAIL blocked AI'; exception when sqlstate 'PT403' then null; end;
  begin perform public.get_favorites(); raise exception 'FAIL blocked favorites'; exception when sqlstate 'PT403' then null; end;
  if (select count(*) from public.profiles)<>0 then raise exception 'FAIL blocked profile'; end if;
  begin insert into storage.objects(bucket_id,name) values('avatars',auth.uid()::text||'/blocked.jpg'); raise exception 'FAIL blocked avatar upload'; exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000003',true);
set local role authenticated;
select public.set_user_access('93000000-0000-4000-8000-000000000001',false,1);
reset role;
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$ begin
  if jsonb_array_length(public.get_favorites()->'items')<>1 then raise exception 'FAIL favorites lost after unblock'; end if;
  perform public.get_cart();
end $$;
reset role;
do $$ begin
  if (select count(*) from private.user_access_events where user_id='93000000-0000-4000-8000-000000000001')<>2 then raise exception 'FAIL audit'; end if;
  if not exists(select 1 from pg_roles r cross join lateral unnest(r.rolconfig) s where r.rolname='authenticator' and s='pgrst.db_pre_request=private.check_app_access') then raise exception 'FAIL API hook configuration'; end if;
end $$;
rollback;
select 'PASS: favorites ownership/hidden/retry, reviews completed purchase/privacy, admin/customer/access/audit/Storage' as result;

-- Development only. Fixtures and quota changes are rolled back.
begin;
insert into auth.users(id,raw_user_meta_data) values
('90000000-0000-0000-0000-000000000017','{"full_name":"AI quota fixture"}'),
('90000000-0000-0000-0000-000000000018','{"full_name":"AI quota B"}');
set local role anon;
do $$ begin
  begin perform public.consume_ai_request(); raise exception 'FAIL anonymous RPC';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000017',true);
set local role authenticated;
do $$ begin
  for i in 1..6 loop
    if public.consume_ai_request() is distinct from true then raise exception 'FAIL allowed request %',i; end if;
  end loop;
  if public.consume_ai_request() is distinct from false then raise exception 'FAIL quota cap'; end if;
  begin perform * from private.ai_request_windows; raise exception 'FAIL direct table access';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000018',true);
set local role authenticated;
do $$ begin
  if public.consume_ai_request() is distinct from true then raise exception 'FAIL user isolation'; end if;
end $$;
reset role;
update private.ai_request_windows set window_start=now()-interval '2 minutes'
where user_id='90000000-0000-0000-0000-000000000017';
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000017',true);
set local role authenticated;
do $$ begin
  if public.consume_ai_request() is distinct from true then raise exception 'FAIL window reset'; end if;
end $$;
reset role;
select 'PASS: anon denied; 6/min cap; private table denied; per-user isolation; window reset; rollback' as result;
rollback;

begin;
create table private.ai_request_windows (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_start timestamptz not null,
  used integer not null check (used between 1 and 6)
);
alter table private.ai_request_windows enable row level security;
revoke all on private.ai_request_windows from public, anon, authenticated;
create function public.consume_ai_request() returns boolean
language plpgsql security definer set search_path = '' as $$
declare caller uuid := auth.uid(); accepted uuid;
begin
  if caller is null then raise insufficient_privilege; end if;
  insert into private.ai_request_windows(user_id,window_start,used)
  values(caller,date_trunc('minute',now()),1)
  on conflict(user_id) do update set
    window_start=excluded.window_start,
    used=case when private.ai_request_windows.window_start=excluded.window_start then private.ai_request_windows.used+1 else 1 end
  where private.ai_request_windows.window_start<>excluded.window_start or private.ai_request_windows.used<6
  returning user_id into accepted;
  return accepted is not null;
end $$;
revoke all on function public.consume_ai_request() from public,anon;
grant execute on function public.consume_ai_request() to authenticated;
commit;

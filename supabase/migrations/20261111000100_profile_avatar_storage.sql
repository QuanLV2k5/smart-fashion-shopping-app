-- Smart Fashion: Storage bucket và RLS policy cho ảnh đại diện (Avatar).
-- Nhiệm vụ H01 Profile (Issue #4) do Hải soạn để gửi Quân review và áp dụng trên Supabase Cloud.

-- Tạo bucket 'avatars' nếu chưa tồn tại, cho phép đọc công khai (public url)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152, -- Giới hạn 2MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- RLS policies cho bucket avatars:
-- 1. Cho phép mọi người (kể cả khách) xem ảnh avatar công khai.
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
on storage.objects for select
to public
using (bucket_id = 'avatars');

-- 2. Chỉ user đã xác thực mới được upload avatar vào thư mục {auth.uid()} của chính mình.
drop policy if exists "avatars_user_insert" on storage.objects;
create policy "avatars_user_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

-- 3. Chỉ user sở hữu mới được cập nhật ảnh avatar của mình.
drop policy if exists "avatars_user_update" on storage.objects;
create policy "avatars_user_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

-- 4. Chỉ user sở hữu mới được xóa ảnh avatar của mình.
drop policy if exists "avatars_user_delete" on storage.objects;
create policy "avatars_user_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

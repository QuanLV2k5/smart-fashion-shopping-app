-- Smart Fashion: Storage bucket và RLS policy cho ảnh sản phẩm (product-images).
-- Nhiệm vụ H04 Admin Catalog & Storage Upload (Issue #19, PR #29) do Hải soạn để gửi Quân review và áp dụng trên Supabase Cloud.

-- Tạo bucket 'product-images' nếu chưa tồn tại, cho phép đọc công khai (public url)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880, -- Giới hạn 5MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- RLS policies cho bucket product-images:
-- 1. Cho phép mọi người (anon và authenticated) xem/tải ảnh sản phẩm công khai.
drop policy if exists "product_images_public_read" on storage.objects;
create policy "product_images_public_read"
on storage.objects for select
to public
using (bucket_id = 'product-images');

-- 2. Chỉ quản trị viên (Admin) mới có quyền upload ảnh sản phẩm mới.
drop policy if exists "product_images_admin_insert" on storage.objects;
create policy "product_images_admin_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'product-images'
  and (select private.is_admin())
);

-- 3. Chỉ quản trị viên (Admin) mới có quyền cập nhật ảnh sản phẩm.
drop policy if exists "product_images_admin_update" on storage.objects;
create policy "product_images_admin_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'product-images'
  and (select private.is_admin())
)
with check (
  bucket_id = 'product-images'
  and (select private.is_admin())
);

-- 4. Chỉ quản trị viên (Admin) mới có quyền xóa ảnh sản phẩm khỏi bucket.
drop policy if exists "product_images_admin_delete" on storage.objects;
create policy "product_images_admin_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'product-images'
  and (select private.is_admin())
);


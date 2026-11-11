-- Dữ liệu mô phỏng, đồng nhất với Figma. Chỉ nạp vào project phát triển.
-- Chạy sau initial_foundation. Không tạo tài khoản/mật khẩu hoặc admin mẫu.
-- image_paths để trống: ảnh sẽ được đưa vào Storage ở bước quản lý ảnh.
-- ON CONFLICT DO NOTHING giữ thay đổi đã có nếu vô tình chạy lại seed.

insert into public.categories (id, name, slug) values
('10000000-0000-0000-0000-000000000001', 'Áo', 'ao'),
('10000000-0000-0000-0000-000000000002', 'Quần', 'quan'),
('10000000-0000-0000-0000-000000000003', 'Váy & đầm', 'vay-dam'),
('10000000-0000-0000-0000-000000000004', 'Áo khoác', 'ao-khoac'),
('10000000-0000-0000-0000-000000000005', 'Giày & phụ kiện', 'giay-phu-kien')
on conflict do nothing;

insert into public.products (id, code, category_id, name, price_vnd, description, material) values
('20000000-0000-0000-0000-000000000001','SF01','10000000-0000-0000-0000-000000000001','Áo thun Essential',199000,'Phom regular, dễ phối hằng ngày.','Cotton'),
('20000000-0000-0000-0000-000000000002','SF02','10000000-0000-0000-0000-000000000002','Jeans Straight',249000,'Dáng straight, thoải mái khi di chuyển.','Denim cotton'),
('20000000-0000-0000-0000-000000000003','SF03','10000000-0000-0000-0000-000000000001','Sơ mi Oxford',289000,'Sơ mi xanh nhạt, phom gọn gàng.','Cotton'),
('20000000-0000-0000-0000-000000000004','SF04','10000000-0000-0000-0000-000000000002','Quần suông Studio',329000,'Quần suông đen cho trang phục hằng ngày.','Vải pha'),
('20000000-0000-0000-0000-000000000005','SF05','10000000-0000-0000-0000-000000000003','Đầm midi Sage',399000,'Đầm midi xanh sage.','Vải pha'),
('20000000-0000-0000-0000-000000000006','SF06','10000000-0000-0000-0000-000000000002','Shorts Linen',219000,'Quần shorts màu be, dễ phối.','Linen pha'),
('20000000-0000-0000-0000-000000000007','SF07','10000000-0000-0000-0000-000000000004','Áo khoác Daily',449000,'Áo khoác nhẹ màu camel.','Cotton pha'),
('20000000-0000-0000-0000-000000000008','SF08','10000000-0000-0000-0000-000000000005','Sneaker Everyday',359000,'Sneaker trắng cho trang phục casual.','Vải và vật liệu tổng hợp'),
('20000000-0000-0000-0000-000000000009','SF09','10000000-0000-0000-0000-000000000005','Túi Terra',179000,'Túi đeo vai màu terracotta.','Vật liệu tổng hợp'),
('20000000-0000-0000-0000-000000000010','SF10','10000000-0000-0000-0000-000000000001','Polo Weekend',229000,'Áo polo navy, phom thoải mái.','Cotton pha'),
('20000000-0000-0000-0000-000000000011','SF11','10000000-0000-0000-0000-000000000003','Chân váy A-line',269000,'Chân váy chữ A màu đen.','Vải pha'),
('20000000-0000-0000-0000-000000000012','SF12','10000000-0000-0000-0000-000000000005','Mũ Canvas',129000,'Mũ màu be; biến thể demo đã hết hàng.','Canvas')
on conflict do nothing;

insert into public.product_variants (product_id, sku, size, color, stock) values
('20000000-0000-0000-0000-000000000001','SF01-WHITE-S','S','Trắng ngà',6),
('20000000-0000-0000-0000-000000000001','SF01-WHITE-M','M','Trắng ngà',12),
('20000000-0000-0000-0000-000000000001','SF01-WHITE-L','L','Trắng ngà',5),
('20000000-0000-0000-0000-000000000001','SF01-WHITE-XL','XL','Trắng ngà',0),
('20000000-0000-0000-0000-000000000002','SF02-DENIM-M','M','Xanh denim',8),
('20000000-0000-0000-0000-000000000003','SF03-BLUE-M','M','Xanh nhạt',6),
('20000000-0000-0000-0000-000000000004','SF04-BLACK-M','M','Đen',5),
('20000000-0000-0000-0000-000000000005','SF05-SAGE-S','S','Xanh sage',4),
('20000000-0000-0000-0000-000000000006','SF06-BEIGE-M','M','Be',9),
('20000000-0000-0000-0000-000000000007','SF07-CAMEL-L','L','Camel',3),
('20000000-0000-0000-0000-000000000008','SF08-WHITE-39','39','Trắng',7),
('20000000-0000-0000-0000-000000000009','SF09-TERRA-ONE','One size','Terracotta',5),
('20000000-0000-0000-0000-000000000010','SF10-NAVY-M','M','Navy',10),
('20000000-0000-0000-0000-000000000011','SF11-BLACK-S','S','Đen',6),
('20000000-0000-0000-0000-000000000012','SF12-BEIGE-ONE','One size','Be',0)
on conflict do nothing;

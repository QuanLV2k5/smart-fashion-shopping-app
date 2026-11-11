# Ảnh catalog

Nguồn: file Figma Smart Fashion `EhOyKwsXn0h5srp9YE9Rmp`.
- `campaign.png`: ảnh hero của Home (`3:439`).
- `products-atlas.png`: ảnh sản phẩm của Explore (`4:417`), 4 cột × 3 hàng, SF01–SF12 theo thứ tự từ trái sang phải, từ trên xuống dưới.
- 0.1.3: ảnh chi tiết Product/Jeans dùng đúng atlas này. Ảnh thứ hai của gallery SF01/SF02 trùng chính xác `campaign.png` (đã tải từ URL MCP mới và so SHA256), nên tái sử dụng file. Main 342×300, thumbnail 48×48, ảnh giỏ 72×88 ở khung 390px.

Giữ nguyên ảnh tải từ Figma; Flutter chỉ chọn vùng ảnh tương ứng lúc hiển thị. Không dùng ảnh chụp toàn màn hình làm giao diện. Không dùng URL MCP tạm thời khi chạy app.

Supabase hiện có `image_paths = []`, vì vậy dùng ảnh cục bộ theo mã SF01–SF12. Nếu API có đường dẫn ảnh HTTPS hoặc key trong bucket `product-images`, repository ưu tiên ảnh đó. Chưa tạo bucket hay upload Storage trong bước này. Mã sản phẩm mới chưa có ảnh sẽ hiện biểu tượng ảnh trống.

Tên, giá, chất liệu, danh mục và tồn kho đều đọc từ Supabase; ảnh cục bộ không phải dữ liệu sản phẩm giả khi mất mạng.

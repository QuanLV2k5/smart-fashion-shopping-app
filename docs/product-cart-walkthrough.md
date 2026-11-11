# Chi tiết sản phẩm và giỏ hàng: từng bước để hiểu và demo

Bản **0.1.3+4** có chi tiết/gallery, chọn size/màu, thêm giỏ theo tài khoản, tăng/giảm/xóa và đọc lại giỏ từ Supabase khi mở app. Người dùng đã xác nhận trên Android: áo M/Trắng ngà + jeans M/Xanh denim = **448.000đ**, đóng/mở lại vẫn còn giỏ.

## 1. Sản phẩm khác biến thể thế nào?

Sản phẩm SF01 là Áo thun Essential, giá 199000 VNĐ. Biến thể là một lựa chọn cụ thể như **M + Trắng ngà**, có `id`, `sku` và tồn kho riêng. SF01 có S/M/L còn hàng và XL tồn kho 0.

UI lấy lựa chọn từ `product_variants`, không dựng thêm size/màu không có trong database. Đổi size/màu mà lựa chọn kia không còn ghép được cùng SKU còn hàng thì app bỏ lựa chọn không tương thích để người dùng chọn lại.

Giỏ dùng khóa `(user_id, variant_id)`: thêm cùng biến thể thì cộng số lượng, khác size/màu thì là dòng khác. Tên sản phẩm không đủ làm khóa giỏ.

## 2. Màn chi tiết lấy dữ liệu mới

`ProductGrid → /products/:id → productProvider(id) → CatalogRepository.loadProduct(id) → Supabase`

Repository đọc đúng ID, chỉ lấy sản phẩm đang hiển thị thuộc danh mục hoạt động và các biến thể. Không chỉ dựa vào tồn kho cũ của màn danh sách để quyết định thêm giỏ.

`ProductPage` hiển thị ảnh, tên/giá, mô tả, size/màu, tồn kho và CTA cố định. Thiếu lựa chọn thì bấm CTA sẽ cuộn tới vùng chọn và có thông báo; hết hàng thì khóa. Kéo xuống để đọc lại. Sản phẩm ngừng bán có lối quay về Khám phá.

| File | Vai trò |
|---|---|
| catalog/domain/variant_selection.dart | Ghép size/màu thành một biến thể |
| catalog/presentation/product_page.dart | Nhận thao tác chọn và thêm giỏ |
| catalog/presentation/widgets/product_gallery.dart | Vuốt/chạm thumbnail đổi ảnh |
| catalog/presentation/widgets/product_size_guide.dart | Bảng size tham khảo SF01/SF02 từ Figma |
| cart/domain/cart.dart | CartItem, snapshot, tổng tiền, hợp đồng repository |
| cart/data/supabase_cart_repository.dart | Gọi RPC và chuyển JSON/lỗi thành model |
| cart/presentation/cart_providers.dart | Provider đọc giỏ và controller ghi giỏ |
| cart/presentation/cart_page.dart | Hiển thị, tăng/giảm/xóa và tải lại |
| core/widgets/shop_page_scaffold.dart | Header, phần cuộn và CTA tránh vùng điều hướng hệ điều hành |

Các đường dẫn trong bảng tính từ `lib/features/`, riêng `core/` tính từ `lib/`.

## 3. Khách chưa đăng nhập

Khách vẫn xem chi tiết và chọn biến thể. Bấm thêm sẽ mở Login kèm đường quay lại sản phẩm và mã biến thể. Sau đăng nhập, app khôi phục lựa chọn hợp lệ; người dùng **bấm thêm lại**, không tự thêm ngoài ý muốn.

`authDestination` chỉ chấp nhận route đã triển khai và query `variant` hợp lệ, chặn URL ngoài. `/cart` mời đăng nhập nếu là khách; không tạo giỏ dưới một tài khoản giả mặc định.

## 4. App gửi gì lên Supabase?

`ProductPage → CartActions.change → CartRepository.mutate → RPC mutate_cart → PostgreSQL → CartSnapshot`

Payload chỉ gồm `p_variant_id`, `p_quantity`, `p_operation` (add/set/remove) và `p_request_id`. Không gửi userId, giá hoặc tồn kho để server tin theo. Server lấy tài khoản từ **auth.uid() trong JWT**, giá từ products và tồn kho từ product_variants.

Migration: `supabase/migrations/20261109000100_product_cart.sql`.

| Thành phần database | Vai trò |
|---|---|
| public.cart_items | Lưu chủ giỏ, biến thể và số lượng, không sao chép tên/giá |
| RLS cart_read_own | Chỉ đọc dòng của chính tài khoản |
| public.get_cart() | Trả giỏ của auth.uid() kèm tên/giá/tồn kho hiện tại |
| public.mutate_cart(...) | Kiểm tra quyền, hàng đang bán, số lượng và ghi trong một transaction |
| private.cart_mutations | Biên nhận requestId để thử lại không cộng trùng |

Client chỉ có SELECT theo RLS trên cart_items; không được INSERT/UPDATE/DELETE thẳng để bỏ qua kiểm tra. RPC chỉ cấp EXECUTE cho authenticated. Hàm dùng security definer vì cần ghi bảng mà client không được ghi trực tiếp; luôn kiểm tra auth.uid(), dùng tên bảng đầy đủ và `search_path = ''`.

Cập nhật cùng tài khoản được tuần tự hóa bằng transaction advisory lock. Server giữ share lock trên các dòng catalog liên quan khi kiểm tra tồn kho. Thêm giỏ **không giữ chỗ/trừ tồn kho**: hai người vẫn có thể cùng thêm vào giỏ riêng. Checkout sau này phải kiểm tra/trừ tồn trong transaction riêng.

Mỗi biến thể từ 1 đến 99, không vượt tồn kho, tính cả số lượng đã có. Hàng bị ẩn sau khi thêm vẫn có dòng để xóa nhưng không trả metadata đang ẩn. Hàng giảm tồn có cảnh báo để điều chỉnh hoặc xóa.

## 5. Vì sao có requestId?

Mạng có thể ngắt sau khi server đã ghi nhưng điện thoại chưa nhận phản hồi. App giữ requestId của thao tác chưa xác nhận; thử lại dùng ID cũ. Server thấy đã xử lý thì trả giỏ hiện tại, không cộng lần hai. Trong lúc chưa xác nhận, app chặn thao tác ghi khác và hướng dẫn vào giỏ bấm Thử lại. HTTP client không tự retry lệnh ghi.

Biên nhận nằm trên server, request đang chờ ở app giữ trong RAM; chưa có queue offline lưu bền. Nếu đóng app giữa một lần cập nhật chưa xác nhận, mở giỏ kiểm tra số lượng trước khi thực hiện thao tác mới.

## 6. Riverpod đọc và ghi tách nhau

- `cartProvider(userId)` dùng AsyncNotifier cho tải/lỗi/dữ liệu. Mở lại app sẽ gọi get_cart để đọc server.
- `cartActionsProvider(userId)` quản lý đang cập nhật, lỗi ghi và request đang chờ. Lỗi ghi không xóa các món đang hiển thị.
- Server xác nhận xong mới thay snapshot và badge; không báo thành công chỉ vì đã bấm nút.
- Mỗi tài khoản có family riêng. Session đổi thì đọc lại; phản hồi ghi của phiên cũ bị bỏ qua nếu tài khoản/phiên đã đổi.

`CartButton` trên Home/Explore/chi tiết dùng chung provider nên số lượng đồng nhất. Không cần copy giỏ sang từng màn hoặc lưu giá vào SharedPreferences.

Hai thiết bị dùng chung tài khoản có cùng dữ liệu server; thiết bị kia kéo xuống trong giỏ để tải thay đổi mới. Chưa có cập nhật realtime giữa hai thiết bị.

## 7. Tiền trong giỏ

Giá là int VNĐ. Mỗi dòng = giá hiện tại × số lượng; tổng = cộng các dòng đang bán. Món bị ẩn không có giá công khai nên không được tính; UI ghi rõ tạm tính các món đang bán.

Áo 199000 + jeans 249000 = 448000 (`448.000đ`). Tăng áo lên 2 thì tổng 647000. Chưa cộng phí giao hàng và chưa tạo đơn ở bước này.

## 8. Demo với giảng viên trong 4 phút

1. Khám phá → Áo thun Essential. Đổi ảnh gallery; mở bảng size.
2. Bấm thêm khi chưa chọn: app nhắc chọn đủ. Chỉ ra XL khóa vì stock = 0.
3. Chọn M + Trắng ngà → còn 12 → thêm giỏ → có phản hồi thành công.
4. Thêm Jeans Straight M + Xanh denim → giỏ 2 món, 448.000đ.
5. Tăng áo lên 2 → 647.000đ; giảm về 1 → 448.000đ. Xóa một dòng thì tổng đổi đúng.
6. Đóng/mở app: giỏ được đọc lại từ Supabase. Đăng xuất thì không thấy giỏ tài khoản cũ.
7. Chỉ migration và cart_providers, giải thích đúng biến thể, JWT/RLS, kiểm tra tồn kho và requestId.

Đây là catalog mẫu trong project phát triển, không phải dữ liệu giả được chèn vào UI khi lỗi mạng.

## 9. Figma và phạm vi

Nguồn: [Product 3:508](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=3-508), ProductReady 4:716, Jeans 4:760, [Cart 4:1176](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-1176), Added 6:818, CartEmpty 6:1084, SizeGuide 4:1082, Material 4:1068.

Ảnh main/thumbnail dùng atlas và campaign nguyên bản Figma. Đã tải và so hash để xác nhận ảnh chi tiết/gallery áo và jeans trùng asset hiện có, tránh lưu trùng. Main 342×300, thumbnail 48×48, ảnh giỏ 72×88. Nếu Supabase có đường dẫn ảnh thì ưu tiên ảnh đó; hiện chưa có ảnh Storage.

Điều chỉnh có chủ đích: mô tả mở rộng tại trang, bảng size là sheet; size/màu theo database thật. Bảng size tham khảo chỉ có cho SF01/SF02, không áp số đo cho giày/túi. Phản hồi thêm có Xem giỏ/Tiếp tục xem sản phẩm; chưa có CTA AI. Giỏ tăng/giảm/xóa được mọi dòng; footer Tiếp tục mua sắm vì checkout/COD chưa triển khai.

Chưa làm yêu thích/đánh giá, địa chỉ/checkout/đơn hoặc admin. Không tự đánh dấu toàn bộ H02/P01 Done, thay phân công hoặc sửa GitHub Issues.

## 10. Kiểm tra lại

```powershell
cd D:\CodexProjects\smart-fashion-shopping-app
.\scripts\check.ps1
flutter test tool/supabase_smoke_test.dart --no-pub
.\scripts\build-android.ps1 -Mode release
```

60 test mặc định không gọi cloud: lựa chọn biến thể, JSON/RPC payload, double submit, thử lại cùng requestId, đổi tài khoản khi ghi, UI/gallery/bảng size và chữ lớn ở 360/390/430. Smoke SDK riêng gọi cloud để đọc chi tiết và kiểm tra khách bị từ chối RPC giỏ.

`supabase/tests/cart.sql` kiểm thử SQL/RLS bằng BEGIN/ROLLBACK, đã chạy PostgreSQL cục bộ và Supabase thật. `cart_verification.sql` chỉ đọc để xác minh không còn fixture, giá demo giữ nguyên, RLS bật và không có quyền ghi thẳng. Android được người dùng thử riêng, không coi fixture là bằng chứng thiết bị.

Migration đã áp dụng qua SQL Editor: **không chạy lại** file tạo bảng trên cloud hiện tại. Lịch sử migration CLI cũ chưa baseline; không chạy db push mù. Xem `setup-verification.md` cho link query và kết quả build/thiết bị.

Nguồn kỹ thuật chính thức: [Database functions/RPC](https://supabase.com/docs/guides/database/functions), [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

# Trang chủ và danh sách sản phẩm: từng bước để hiểu và demo

Bản 0.1.2 bổ sung Home và Khám phá theo Figma, dùng catalog mẫu đã lưu thật trên Supabase. Khách chưa đăng nhập vẫn xem được; tab Tài khoản tiếp tục dùng luồng Auth đã làm trước đó.

Từ 0.1.3, chạm sản phẩm mở màn chi tiết thay khung xem nhanh; xem `product-cart-walkthrough.md` cho gallery, chọn biến thể và giỏ thật.

## 1. Bắt đầu từ trải nghiệm người dùng

1. Mở app: thấy Trang chủ, ảnh bộ sưu tập, danh mục và Lựa chọn hôm nay.
2. Bấm **Khám phá bộ sưu tập**: xem danh sách toàn bộ sản phẩm.
3. Gõ `ao thun`: vẫn tìm được **Áo thun Essential**, dù không gõ dấu.
4. Chọn danh mục hoặc bấm **Lọc** để chọn giá, danh mục, size, màu, còn hàng.
5. Bấm **Áp dụng bộ lọc** mới đổi kết quả. **Đóng** bỏ thay đổi chưa áp dụng. **Xóa bộ lọc** xóa bản nháp; cần bấm Áp dụng để xác nhận.
6. **Sắp xếp** có Đề xuất, Giá tăng dần, Giá giảm dần. Dòng số lượng cho biết kết quả hiện tại.
7. Chạm sản phẩm để mở chi tiết, xem ảnh/mô tả/chất liệu và chọn size/màu (0.1.3).
8. Kéo danh sách xuống ở đầu trang để tải lại. Chưa có kết quả thì dùng Tìm lại/Đặt lại.

Home và Khám phá có thanh điều hướng chung với Tài khoản. Nếu chưa có phiên, vào Tài khoản sẽ mở Login; đăng nhập xong quay lại Tài khoản. Từ Login có lối quay về cửa hàng.

## 2. Dữ liệu nằm ở đâu?

| Bảng Supabase | Dữ liệu app sử dụng | Ví dụ |
|---|---|---|
| categories | id, name, slug; chỉ danh mục đang hoạt động | Áo, Quần |
| products | id, code, category_id, name, description, material, price_vnd, image_paths | SF01, 199000 |
| product_variants | id, sku, size, color, stock | SF01-WHITE-M, M, Trắng ngà, 12 |

Sản phẩm là mẫu chung; biến thể là một lựa chọn cụ thể có tồn kho riêng. SF01 có S/M/L còn hàng và XL hết hàng. Hết XL không có nghĩa toàn bộ áo SF01 hết hàng. SF12 hiện hết toàn bộ biến thể, nên thẻ sản phẩm có nhãn **Hết hàng**.

Giá lưu bằng **int VNĐ**, không phải số thập phân. `formatVnd(199000)` chỉ định dạng thành `199.000đ`, không quyết định giá bán.

App chỉ đọc ở bước này. Repository lọc `is_visible = true`, đồng thời dùng `categories!inner` và `categories.is_active = true`. Supabase RLS tiếp tục kiểm soát quyền phía server; lọc trong app giúp màn khách chỉ hiển thị catalog công khai kể cả khi sau này đăng nhập bằng tài khoản admin. Không dùng secret/service-role key và không sửa policy/schema trong bước này.

## 3. Đọc code theo đường đi của dữ liệu

`HomePage / ExplorePage → catalogProvider → CatalogRepository → SupabaseCatalogRepository → Supabase → CatalogSnapshot → widget`

| File trong lib/ | Vai trò |
|---|---|
| features/catalog/domain/catalog.dart | Model Category, Product, Variant, Snapshot; hợp đồng repository và lỗi |
| features/catalog/data/supabase_catalog_repository.dart | Gọi API, đổi JSON thành model, kiểm tra kiểu giá/tồn kho và dịch lỗi |
| features/catalog/presentation/catalog_providers.dart | Cấp repository và FutureProvider dùng chung kết quả tải |
| features/catalog/domain/catalog_query.dart | Quy tắc tìm không dấu, lọc cùng SKU, khoảng giá, sắp xếp |
| features/catalog/presentation/home_page.dart | Bố cục Home, các điểm vào danh mục/bộ sưu tập |
| features/catalog/presentation/explore_page.dart | Từ khóa, bộ lọc/sắp xếp đang chọn và danh sách kết quả |
| features/catalog/presentation/catalog_filter_sheet.dart | Giữ bộ lọc nháp, Áp dụng/Đóng/Xóa |
| features/catalog/presentation/widgets/catalog_widgets.dart | Thẻ/ảnh sản phẩm, loading/lỗi/rỗng, khung xem nhanh, chip |
| core/widgets/store_scaffold.dart | Header, safe area và ba tab dùng chung |
| app/router/app_router.dart | `/` mở Home, `/explore` mở danh sách; giữ guard của Auth |

Không cần thêm code generation hoặc nhiều lớp controller chỉ để đọc một danh sách. `FutureProvider` đã quản lý Loading/Data/Error; `StatefulWidget` giữ thao tác tạm thời trên màn, còn quy tắc nghiệp vụ được tách ra Dart để test độc lập.

Hai màn dùng chung một `catalogProvider`, nên chuyển Home → Khám phá không tải lại API vô ích. Khi kéo làm mới, provider gọi repository lại. Nếu làm mới lỗi sau khi đã tải được, giữ dữ liệu cũ **trong phiên hiện tại** và báo chưa cập nhật được. Đây chưa phải cache offline lưu bền: đóng/mở lại app khi mất mạng vẫn có thể không tải được catalog.

Repository lấy sản phẩm theo trang 200 dòng để không phụ thuộc giới hạn mặc định 1000 của API. Hiện có 12 sản phẩm nên chỉ cần một trang. Danh mục tải một lần, giới hạn API mặc định vẫn áp dụng (hiện có 5). Catalog nhỏ được tìm/lọc/sắp xếp trong RAM; không gửi request trên từng ký tự. Khi dữ liệu tăng lớn, chuyển tìm/lọc/phân trang sang Supabase bên trong repository, giữ nguyên model và widget càng nhiều càng tốt.

## 4. Quy tắc lọc cần giải thích được

- Tìm theo tên, mã hoặc chất liệu, không phân biệt chữ hoa/dấu; nhiều từ đều phải xuất hiện.
- Dưới 300k: `< 300000`. 300k–500k: từ `300000` đến `500000`, gồm hai đầu. Trên 500k: `> 500000`.
- Size và màu phải nằm trên **cùng một biến thể có stock > 0**. Không ghép size của SKU này với màu của SKU khác.
- Không lọc thì vẫn thấy sản phẩm hết hàng. Bật Chỉ sản phẩm còn hàng hoặc chọn size/màu thì yêu cầu biến thể còn tồn.
- Đề xuất hiện sắp theo mã catalog; chưa có cá nhân hóa. Khi giá bằng nhau, dùng mã sản phẩm để giữ thứ tự ổn định.
- Khung xem nhanh chỉ đọc snapshot tồn kho, chưa giữ/chặn mua một đơn vị hàng. Bước checkout sau này phải kiểm tra tồn kho và giá lại tại server.

## 5. Figma và những điều chỉnh có chủ đích

Nguồn: [Home 3:439](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=3-439), [Explore 4:417](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-417), [Filter 6:714](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=6-714), Product 3:508, NoResults 6:1120, CatalogError 6:1156.

Giữ nền ivory, xanh primary/sage, Be Vietnam Pro, bố cục hai cột, khoảng cách và ảnh nguồn Figma. Ảnh được đóng gói ở `assets/images/catalog/`; không gọi URL MCP tạm thời lúc chạy. `image_paths` trên Supabase hiện trống nên dùng atlas SF01–SF12. Nếu sau này có ảnh HTTPS/key trong bucket `product-images`, repository ưu tiên ảnh đó; chưa tạo Storage bucket trong bước này. Mã mới chưa có ảnh dùng biểu tượng ảnh trống.

Các điều chỉnh để bản chạy thật rõ ràng:

- Không vẽ giờ/pin giả. Dùng safe area và thanh hệ điều hành.
- Có ba tab hoạt động: Trang chủ, Khám phá, Tài khoản. Giỏ, AI, Yêu thích sẽ tích hợp khi có nghiệp vụ; chưa thêm nút giả.
- Hiện đủ năm danh mục từ database bằng hàng cuộn ngang; bộ lọc dùng các size/màu có thật, không chép lựa chọn mẫu không tồn tại.
- Bộ casual cuối tuần là bộ sưu tập biên tập SF01 + SF02, **chưa phải kết quả Gemini**. Tổng tiền tính từ giá Supabase; không ghi cứng 448000 trong widget. Lựa chọn hôm nay ưu tiên SF01/SF02/SF05/SF07 đang công khai; nếu không còn các mã này thì lấy tối đa bốn sản phẩm đầu.
- Có dòng số kết quả, xóa từ khóa và đặt lại. Chữ lớn chuyển lưới sang một cột; màn rộng giới hạn nội dung 600px để đọc trên web.
- 0.1.2 có khung xem nhanh; 0.1.3 thay bằng chi tiết/gallery, chọn biến thể, bảng size và giỏ. Đánh giá/checkout vẫn chưa triển khai; đọc hướng dẫn riêng cho bước mới.

Đây là một phần Q03/H02, không tự đánh dấu toàn bộ Issue Done, đổi phân công hay giờ dự toán.

## 6. Kịch bản trình bày 3 phút

1. Mở Home → Khám phá: chỉ ra 12 sản phẩm là dữ liệu mẫu thật ở Supabase, không phải danh sách Dart ghi cứng.
2. Tìm `ao thun` → mở xem nhanh: giá 199.000đ; S/M/L còn tồn, XL hết hàng.
3. Xóa từ khóa → Lọc → chọn XL → Áp dụng: không có kết quả vì XL tồn kho 0. Bấm Tìm lại.
4. Lọc Dưới 300k → sắp Giá tăng dần: giá tăng đúng theo dữ liệu; Mũ Canvas vẫn hiện Hết hàng nếu chưa chọn còn hàng.
5. Chọn Chỉ sản phẩm còn hàng: loại Mũ Canvas. Mở Tài khoản để chỉ ra Auth là luồng riêng, duyệt catalog không buộc đăng nhập.
6. Chỉ file repository và query: giải thích database/RLS bảo vệ quyền, Flutter định dạng và hiển thị; test xác minh quy tắc cùng SKU.

Để kiểm chứng cập nhật dữ liệu, người quản lý có thể đổi giá một sản phẩm mẫu trong dashboard rồi kéo làm mới. Không dùng tài khoản khách ghi thẳng giá/tồn kho. Tác vụ này không thay dữ liệu demo để giữ kịch bản hiện hành.

## 7. Chạy và kiểm tra

```powershell
cd D:\CodexProjects\smart-fashion-shopping-app
.\scripts\check.ps1
flutter test tool/supabase_smoke_test.dart --no-pub
.\scripts\build-android.ps1 -Mode release
.\scripts\preview-phone.ps1 -UseSupabase
```

Test mặc định không gọi cloud. Smoke test gọi Supabase thật để đọc 5 danh mục/12 sản phẩm/15 biến thể, thử tìm/lọc và xác nhận khách không đọc được profiles. Chưa có test Safari/iOS native. Bằng chứng build, trình duyệt và thiết bị ghi trong `setup-verification.md`.

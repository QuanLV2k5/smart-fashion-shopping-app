# UI dùng chung tối thiểu — P01

Trạng thái **Pending Review**, 11/11/2026. Đây là quy tắc dùng lại component hiện có, không tạo design system mới. Liên quan [#9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9), cần Hải/Quân xác nhận.

## Nguồn đối chiếu

- [Token Flutter](../../lib/core/theme/app_tokens.dart), [theme](../../lib/core/theme/app_theme.dart), [design handoff](../design-handoff.md).
- Figma MCP đọc được metadata ngày 11/11/2026: [SF/Button 3:60](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=3-60), Default/Secondary/Disabled/Loading: 342×48; [SF/Input 3:73](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=3-73), Default/Filled/Error/Disabled: 342×76. Đây là kích thước tham chiếu frame 390 px, không ép chiều rộng cố định trên mọi máy.
- Các frame Addresses 4:1314, AddressBook 4:1336, AddressForm 4:1358, AddressEdit 4:1391, AddressError 4:1424, Cart 4:1176, SingleCart 4:1214, CartQty 4:1253 đã được đối chiếu metadata/design context/screenshot trong lượt P02 trước; không coi là đã kiểm tra ảnh Flutter của main hiện tại. P02 chưa merge.

## Quy tắc áp dụng

| Thành phần | Quy tắc dựa trên code hiện có |
| --- | --- |
| Màu | Ivory `#F7F5EF`, trắng `#FFFFFF`, ink `#242A27`, muted `#65716A`, primary `#254D40`, sage `#E2E9DF`, accent `#A54932`, outline `#D8DED7`, error `#AA3434`, success `#2C6849`, disabled `#B6BDB6`; dùng token thay hardcode mới |
| Typography | Be Vietnam Pro bundled, weight 400/500/600/700; headline 24/32–600, title 18/26–600, body 14/22–400, small 12/18, label 14/22–600; lấy TextTheme |
| Khoảng cách/bo góc | Spacing 4/8/12/16/24/32/48; radius 4/8/16. Không tạo thang mới cho mỗi màn |
| Buttons | Filled/Outlined theo theme, tối thiểu 48×48, radius 8; nhãn rõ, disabled/loading khi request; thao tác phá hủy có xác nhận và tách khỏi lưu |
| Forms | Nền trắng, padding 12, viền outline/focus primary 2; label và lỗi theo trường, giữ draft khi request lỗi. Chọn keyboard/autofill phù hợp, scroll khi mở bàn phím, tránh che nút lưu |
| Cards | Dùng cấu trúc product/cart sẵn có. Thẻ địa chỉ sage, tên + điện thoại cùng dòng, dấu chọn có ngữ nghĩa; chỉ là chuẩn đối chiếu P02 chưa có trên main |
| Loading | Hiển thị tiến trình, khóa thao tác lặp có liên quan; tránh lộ dữ liệu tài khoản cũ |
| Empty | Nói rõ chưa có dữ liệu và hành động tiếp theo (khám phá/thêm địa chỉ/reset filter); phân biệt lỗi tải |
| Error | Thông báo dễ hiểu, retry khi an toàn, không lộ raw SQL/token; không thay lỗi backend bằng dữ liệu giả. Request ghi chưa rõ kết quả cần chống lặp như RPC giỏ hiện có |
| Điều hướng | Dùng router/scaffold hiện tại; bảo toàn đường quay lại, guard màn cần login. Cart → Addresses chỉ chọn địa chỉ rồi trở về Cart; không bổ sung checkout |

Auth, Catalog và Cart trên main đã có scaffold, form, notice, loading/empty/error và product cards để tái sử dụng. Profile của [PR #11](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/11) và Addresses của [PR #12](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/12) là nguồn tham khảo chờ tích hợp; không thêm menu Account trùng H01 hoặc đổi router trong P01.

Điểm tái sử dụng cụ thể: [AuthScaffold/AuthButton/AuthField/AuthNotice](../../lib/features/auth/presentation/widgets/auth_widgets.dart), [CatalogBody/CatalogMessage/ProductPhoto/ProductGrid](../../lib/features/catalog/presentation/widgets/catalog_widgets.dart), [ShopPageScaffold/ShopNotice](../../lib/core/widgets/shop_page_scaffold.dart), [StoreScaffold](../../lib/core/widgets/store_scaffold.dart), [CartButton](../../lib/features/cart/presentation/widgets/cart_button.dart). Ưu tiên các thành phần này trước khi bổ sung widget cùng chức năng.

## Checklist review UI

- Chạy ở 360/390/430 px, chữ lớn (text scale 2), bàn phím mở và safe area; không overflow hoặc nút bị che. Không vẽ status bar giả để thay UI hoạt động.
- Focus/tab, label, trạng thái chọn/lỗi không chỉ phân biệt bằng màu; tương phản và nhãn trợ năng cần kiểm tra thực tế, chưa được chứng nhận accessibility.
- Ảnh evidence ghi màn, kích thước, commit, thiết bị và trạng thái; ảnh Figma không phải evidence Flutter chạy đạt.
- Component mới chỉ khi component hiện tại không đáp ứng; Hải review phần UI, Quân review contract/router, trạng thái thống nhất **Pending Review**.

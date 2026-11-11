# Thiết kế làm nguồn triển khai

[Figma Design Smart Fashion](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp)

| Flow | Starting node |
|---|---|
| Mua hàng | 4:60 |
| Phối đồ AI | 5:500 |
| Admin mobile | 5:749 |
| QA lỗi/ngoại tuyến | 15:1368 |

Theme ở `lib/core/theme/` chuyển nền tảng màu, font, spacing và radius từ
Figma sang Dart. Be Vietnam Pro 400/500/600/700 được bundle kèm OFL trong
`assets/fonts/`; không tải font ở runtime.

Đã triển khai Auth từ các node Login 4:100, Register 4:180, ConfirmEmail 4:230,
Logout 4:399 và đối chiếu cả trạng thái lỗi 4:152/4:205. Không có asset raster/SVG
trong các màn Auth này. SF/Input, SF/Button và SF/Banner được chuyển thành
widget dùng lại, cùng token theme. Xem `docs/auth-walkthrough.md` cho khác biệt
có chủ đích và phạm vi màn tài khoản tối thiểu.

Đã triển khai Home 3:439, Explore 4:417, Filter 6:714 và trạng thái rỗng/lỗi;
khung xem nhanh tham chiếu Product 3:508. Đã đọc context qua Figma MCP và tải
asset hero/atlas gốc vào `assets/images/catalog/`, không dùng screenshot cả màn
làm giao diện. Xem `docs/catalog-walkthrough.md` cho phạm vi và điều chỉnh.

Từ 0.1.3, khung xem nhanh đã thay bằng Product/Ready 3:508/4:716, Jeans 4:760,
gallery, SizeGuide 4:1082 và mô tả; giỏ tham chiếu Cart 4:1176, Added 6:818,
CartEmpty 6:1084. Chọn biến thể và ghi giỏ là nghiệp vụ Supabase thật;
xem `docs/product-cart-walkthrough.md` cho điều chỉnh và phần checkout/review chưa làm.

Kịch bản cần giữ đúng: áo 199.000đ + jeans 249.000đ = 448.000đ;
ship 25.000đ; COD 473.000đ. Giá dùng số nguyên VNĐ.

Prototype Figma có các nhánh preset; app thật phải quản lý state giỏ, biến
thể/tồn kho và authentication độc lập, không chép logic giả lập thành backend.

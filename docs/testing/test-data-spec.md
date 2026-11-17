# Đặc tả dữ liệu kiểm thử P01 / Q03

Ngày 11/11/2026, **Pending Review** bởi Quân (schema/seed) và Hải (Catalog/UI). [Issue #9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9), [Q03 #3](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3). Chỉ đặc tả; không tạo/chạy seed, không thay cloud. Q03 sở hữu việc chuẩn bị dữ liệu backend.

## Nguồn và giới hạn

Đối chiếu ba migration trên main `f64bfc9`:

- [Foundation](../../supabase/migrations/20261108000100_initial_foundation.sql): profiles, user_roles, categories, products, product_variants, addresses và RLS.
- [Demo catalog](../../supabase/migrations/20261108000200_demo_catalog.sql): 5 danh mục/12 sản phẩm/15 variants, giá VND nguyên.
- [Product/cart](../../supabase/migrations/20261109000100_product_cart.sql): cart_items và RPC giỏ hàng.

Đây là dữ liệu được khai báo trong repository, không phải xác nhận số bản ghi cloud hiện tại. Seed dùng ON CONFLICT DO NOTHING nên không bảo đảm khôi phục dữ liệu cloud đã sửa. Không tự rerun migration để reset test. UUID sản phẩm cố định trong migration; UUID variant sinh trên server, phải tra theo SKU thay vì hardcode ID đoán.

## Catalog chuẩn theo seed

| Mã | Sản phẩm | Danh mục | Giá VND |
| --- | --- | --- | --- |
| SF01 | Áo thun Essential | Áo | 199000 |
| SF02 | Jeans Straight | Quần | 249000 |
| SF03 | Sơ mi Oxford | Áo | 289000 |
| SF04 | Quần suông Studio | Quần | 329000 |
| SF05 | Đầm midi Sage | Váy/Đầm | 399000 |
| SF06 | Shorts Linen | Quần | 219000 |
| SF07 | Áo khoác Daily | Áo khoác | 449000 |
| SF08 | Sneaker Everyday | Giày/Phụ kiện | 359000 |
| SF09 | Túi Terra | Giày/Phụ kiện | 179000 |
| SF10 | Polo Weekend | Áo | 229000 |
| SF11 | Chân váy A-line | Váy/Đầm | 269000 |
| SF12 | Mũ Canvas | Giày/Phụ kiện | 129000 |

| SKU | Size | Màu | Tồn seed | Mục đích |
| --- | --- | --- | --- | --- |
| SF01-WHITE-S | S | Trắng ngà | 6 | Cùng sản phẩm, khác size |
| SF01-WHITE-M | M | Trắng ngà | 12 | Giỏ và tổng tiền |
| SF01-WHITE-L | L | Trắng ngà | 5 | Cùng sản phẩm, khác size |
| SF01-WHITE-XL | XL | Trắng ngà | 0 | Biến thể hết hàng |
| SF02-DENIM-M | M | Xanh denim | 8 | Danh mục Quần |
| SF03-BLUE-M | M | Xanh nhạt | 6 | Màu khác giữa sản phẩm |
| SF04-BLACK-M | M | Đen | 5 | Bộ lọc màu |
| SF05-SAGE-S | S | Xanh sage | 4 | Danh mục Váy/Đầm |
| SF06-BEIGE-M | M | Be | 9 | Bộ lọc size/màu |
| SF07-CAMEL-L | L | Camel | 3 | Tồn thấp hiện có |
| SF08-WHITE-39 | 39 | Trắng | 7 | Size số |
| SF09-TERRA-ONE | One size | Terracotta | 5 | One size |
| SF10-NAVY-M | M | Navy | 10 | Bộ lọc màu |
| SF11-BLACK-S | S | Đen | 6 | Chéo danh mục |
| SF12-BEIGE-ONE | One size | Be | 0 | Sản phẩm hết toàn bộ tồn |

SF01 chỉ có một màu trong seed. Trường hợp **hai màu cùng một sản phẩm** và ranh giới giá đúng 300000/500000 hiện dùng fixture unit/widget; dữ liệu API bổ sung phải do Q03 chuẩn bị trên môi trường được phép. Không tuyên bố đã có SKU SF01 màu đen trên cloud. Sản phẩm thuộc nhiều danh mục ở đây là tập sản phẩm trải nhiều danh mục; schema hiện tại mỗi sản phẩm chỉ có một category_id, không tự thêm quan hệ nhiều-nhiều.

## Giá và giỏ hàng

| Dữ liệu | Kết quả chuẩn |
| --- | --- |
| SF01-WHITE-M ×1 | 199000 VND |
| SF01-WHITE-M ×1 + SF02-DENIM-M ×1 | 448000 VND |
| SF01-WHITE-M ×2 + SF02-DENIM-M ×1 | 647000 VND |
| SF01-WHITE-S ×1 + SF01-WHITE-M ×1 | Hai dòng variant riêng; 398000 VND |
| SF07-CAMEL-L ×3 rồi yêu cầu ×4 | ×3 hợp lệ nếu tồn hiện tại vẫn 3; ×4 bị từ chối, không báo thành công giả |
| Qty 0, -1, 100; SKU tồn 0; variant không tồn tại | Không tạo cập nhật giỏ không hợp lệ; kiểm tra lỗi RPC và UI tương ứng |

Giới hạn số lượng 1..min(99, tồn hiện tại); tồn không được đặt chỗ chỉ bằng thêm giỏ. Kiểm tra lại tồn trước mỗi lượt API. Giá/tổng phía server, client không được tự gửi giá đáng tin cậy. Không thêm phí vận chuyển, thanh toán hoặc đặt hàng vào P01/P02.

## Hai tài khoản A/B và dữ liệu riêng

Nhóm cấp riêng hai tài khoản customer ở local/staging được phép. Dùng alias A/B trong tài liệu, giữ email/mật khẩu/JWT/UUID thật ngoài Git; không có tài khoản/password seed sẵn. Không dùng admin/service-role để giả lập khách hàng. Mỗi người tạo địa chỉ riêng A1/A2/B1 và giỏ khác nhau; ghi ID runtime trong ghi chú riêng an toàn.

| Fixture | Dữ liệu tổng hợp, không liên hệ người thật | Mục đích |
| --- | --- | --- |
| A1 | Người nhận `Khách kiểm thử A`; phone `0900000000`; city `Tỉnh kiểm thử`; district `Huyện kiểm thử`; ward `Xã kiểm thử`; address_line `Số 1 đường kiểm thử` | Địa chỉ đúng định dạng; không dùng để giao hàng thật |
| A2 | Như A1, tên `Khách kiểm thử A2`, số nhà 2 | Nhiều địa chỉ, chọn/xóa địa chỉ đang chọn |
| B1 | `Khách kiểm thử B`, số nhà 3, trường còn lại cùng định dạng A1 | Cách ly tài khoản |
| Invalid | Từng trường trống/whitespace; phone `abc`, 8 chữ số, 16 chữ số; name >100; address_line >250; city/district/ward >100 | Lỗi chỉ đúng trường; giữ draft, không ghi bản ghi sai |
| Boundary | name 1/100 ký tự; address_line 1/250; city/district/ward 1/100; phone 9/15 chữ số và có dấu + đầu | Kiểm tra ranh giới domain/DB, không coi số đúng cú pháp là số đã xác minh |

Schema addresses gồm id, user_id, recipient_name, phone, address_line, ward, district, city, created_at, updated_at; đối chiếu tên cột thực tế trước viết request. Không có is_default. Địa chỉ đang chọn lưu riêng theo userId và xác minh server; không seed lựa chọn toàn cục. Profile và roles tách biệt, không gửi role trong cập nhật profile.

## Quy trình dùng dữ liệu và kiểm tra RLS trực tiếp

Rà tĩnh migration foundation: `public.addresses` bật RLS, chỉ authenticated được grant SELECT/INSERT/UPDATE/DELETE; policy `addresses_own FOR ALL TO authenticated` dùng cả `USING (user_id = (select auth.uid()))` và `WITH CHECK` cùng điều kiện. Không có ngoại lệ admin trong policy addresses. Đây là kết luận từ SQL trong Git, không xác nhận cấu hình cloud đang khớp migration.

1. Quân xác nhận môi trường/URL và quyền tạo dữ liệu test; chưa có xác nhận thì các test cloud là Blocked, không dùng production thay thế.
2. Đọc catalog hiện tại, đối chiếu SKU/giá/tồn trên đây. Sai khác phải ghi lại, không âm thầm sửa cloud hoặc thay expected cho test đạt.
3. A/B tự tạo dữ liệu qua UI/API đã cho phép. Lấy JWT mỗi tài khoản cục bộ; API gửi publishable/anon key và Bearer JWT, không ghi header vào evidence.
4. Với A rồi lặp lại B: SELECT thấy địa chỉ mình và không thấy bên kia; INSERT user_id mình thành công, user_id bên kia bị chặn; UPDATE/DELETE địa chỉ mình thành công, địa chỉ bên kia không đổi. UPDATE đổi user_id sang bên kia phải bị WITH CHECK chặn. Anon không có quyền CRUD addresses.
5. Đối với UPDATE/DELETE trái phép, HTTP 2xx với danh sách rỗng vẫn có thể là RLS lọc 0 dòng; đọc lại bằng **chủ sở hữu** để chứng minh không đổi/không mất. DELETE hợp lệ cần returning ID/xác nhận server và đọc lại không còn, không chỉ nhìn toast.
6. Ghi request đã che nhạy cảm, HTTP status, số dòng, kiểm tra sau thao tác, commit và thời điểm. Logout A/login B, F5 và chuyển tài khoản trong request để kiểm tra client state; UI isolation không thay bằng chứng RLS API.
7. Chỉ dọn đúng dữ liệu do mình tạo trong môi trường được phép; không xóa catalog/user hoặc tắt RLS. Cleanup Pending Review nếu chưa có quyền.

Chưa chạy REST RLS A/B/anon trong lượt P01; mọi kết quả API tại mục này là expected, không phải Passed. [Matrix](test-matrix.md) theo dõi riêng từng quyền.

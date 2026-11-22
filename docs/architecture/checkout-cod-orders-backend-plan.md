# Chuẩn bị backend Checkout COD/Orders

Đối chiếu ngày 22/11/2026 trên `origin/main` tại `914a38b` và PR #29 tại `c6ee2cde`. Dùng [Issue #20](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/20), [thiết kế](checkout-cod-orders-design.md) và [đặc tả kiểm thử](../testing/checkout-cod-orders-test-spec.md) làm căn cứ.

## Sổ quyết định

Issue #20 đang mở và chưa có bình luận. Quân duyệt phạm vi tài liệu đề xuất ở PR #25 và yêu cầu chốt D01–D14 trước khi triển khai. Review #27 và #28 thuộc phạm vi đặc tả kiểm thử và kiểm thử đổi phiên. PR #29 được Phúc yêu cầu sửa, gồm stock concurrency và thao tác xóa biến thể. Chỉ ghi Approved khi có xác nhận rõ ràng của Quân cho nội dung từng quyết định và hoàn tất review liên quan theo thiết kế. Khi chốt, ghi nội dung được duyệt, người xác nhận, ngày và permalink. [Review #25](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/25#pullrequestreview-5957379472) · [Review #27](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/27#pullrequestreview-6010435305) · [Review #28](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/28#pullrequestreview-6010439108) · [Review #29](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/29#pullrequestreview-6009221188)

| ID | Nội dung cần chốt | Review | Trạng thái |
|---|---|---|---|
| D01 | Phạm vi giỏ, quote, TTL, giới hạn dòng và quote active | Quân + Hải | Pending Review |
| D02 | Rule ship 25.000đ cho demo, phạm vi áp dụng và version | Quân, Hải đối chiếu UI | Pending Review |
| D03 | Điều kiện stale theo giỏ, địa chỉ, catalog và giá, việc giữ tồn | Quân + Hải | Pending Review |
| D04 | Trạng thái, cạnh chuyển, quyền hủy, version và lý do | Quân + Hải | Pending Review |
| D05 | Thời điểm trừ/hoàn, hoàn đúng một lần và xử lý giỏ sau hủy | Quân + Hải | Pending Review |
| D06 | Namespace, canonical payload, replay, consume quote và retention receipt | Quân | Pending Review |
| D07 | Pending theo user, phục hồi restart và lookup khi mất phản hồi | Quân, Hải đối chiếu UI | Pending Review |
| D08 | FK và xóa/ẩn catalog hoặc user, snapshot địa chỉ, retention PII và ảnh | Quân + Hải | Pending Review |
| D09 | Giao thức lock giữa Cart, Orders và Admin Catalog, CAS, quyền ghi và người phụ trách migration | Quân + Hải | Pending Review |
| D10 | Bằng chứng mua hàng đã hoàn tất cho Reviews, giới hạn review và projection công khai | Quân | Pending Review |
| D11 | Khóa/xóa tài khoản, giữ lịch sử, thời điểm thu hồi quyền admin | Quân | Pending Review |
| D12 | Tên RPC, DTO, lỗi, giới hạn tiền, phân trang, lọc và timeline | Quân + Hải | Pending Review |
| D13 | UI hủy, quote stale, kết quả chưa xác định và định dạng mã đơn | Hải + Quân | Pending Review |
| D14 | Môi trường, JWT, hai kết nối, thứ tự migration, timeout, review/deploy và cleanup | Quân điều phối, cả nhóm xác nhận | Pending Review |

## D09 và PR #29

- `saveVariant()` gửi `product_id`, SKU, size, color và `stock` trong cùng `UPDATE ... WHERE id = ...`. Ví dụ admin mở form lúc tồn 10, checkout trừ còn 9, sau đó admin chỉ đổi màu và gửi lại 10. Row lock tuần tự hóa hai lệnh nhưng giá trị 10 vẫn ghi đè 9 sau khi lock được nhả. [Mã PR #29](https://github.com/QuanLV2k5/smart-fashion-shopping-app/blob/c6ee2cded93dba1937a251ce47519210ed4c910f/lib/features/admin/data/supabase_admin_repository.dart#L320-L354)
- Đề xuất tách chỉnh metadata khỏi điều chỉnh tồn. Admin lưu metadata bằng payload bỏ trường stock. Khi admin nhập số tồn tuyệt đối, gọi RPC kiểm tra role server và so revision đã đọc với revision hiện tại trong cùng thao tác cập nhật có điều kiện (compare-and-swap). Mọi writer thay đổi tồn, gồm đặt, hoàn và chỉnh admin, tăng revision trong cùng transaction. Revision ngăn cả trường hợp tồn đổi rồi quay về giá trị cũ. Khi xung đột, tải lại tồn và yêu cầu admin xác nhận lại. Giữ khởi tạo tồn khi tạo biến thể trong phạm vi review riêng.
- Checkout và hủy cần ghi thay đổi tồn nguyên tử trên dữ liệu hiện tại. Với nhiều variant, chốt thứ tự khóa thống nhất và rà các writer của category/product/variant cùng luồng role, Cart và Orders. Khi client admin đã chuyển sang đường ghi đã duyệt, thu hồi UPDATE cấp bảng và cấp lại theo cột metadata cần thiết. Quyền UPDATE cấp bảng hiện tại vẫn cho ghi stock dù thu hồi quyền ở riêng cột.
- `deleteVariant()` gọi DELETE theo ID. Nền đã đọc thiếu cả GRANT DELETE và policy DELETE cho variant, còn FK Cart dùng ON DELETE CASCADE. Đề xuất Hải và Quân chốt ngừng bán dưới D08/D09 để giữ định danh lịch sử và khả năng hoàn tồn. Nếu chốt ngừng bán riêng từng variant, rà read/Cart/quote/place để cùng áp dụng trạng thái đó, kể cả giỏ đang giữ variant. Đối chiếu policy Storage theo source ở migration `20261121000100_product_images_storage.sql` và xác nhận trên môi trường kiểm thử khi D14 được duyệt. [Mã DELETE](https://github.com/QuanLV2k5/smart-fashion-shopping-app/blob/c6ee2cded93dba1937a251ce47519210ed4c910f/lib/features/admin/data/supabase_admin_repository.dart#L369-L382)
- Kiểm thử hai kết nối theo COD-RACE-03. Checkout commit trước thì lần đặt tồn từ form cũ phải xung đột và giữ 9. Admin commit trước thì checkout kiểm tra tồn mới và chỉ trừ khi đủ. Lặp lại với hủy/hoàn, hai admin cùng revision và metadata-only trong lúc checkout. Kiểm quyền admin/customer đối với RPC và xác nhận đường UPDATE trực tiếp bị chặn sau chuyển đổi.

## Cấu trúc migration và RPC dự kiến

Nền hiện có Auth/role server, catalog/địa chỉ, Cart dùng advisory transaction lock theo caller, cart receipt riêng và các migration storage/AI. Đặt migration Orders sau migration nền cuối cùng ở thời điểm tích hợp và chốt thứ tự giữa Admin Catalog, Orders và Reviews với D14. Các nhóm dưới đây là thứ tự phụ thuộc để review.

| Nhóm | Nội dung | Phụ thuộc quyết định |
|---|---|---|
| Catalog–Orders | Điều chỉnh stock admin, quyền cột, ngừng bán và phối hợp rollout caller | D05, D08, D09, D11, D14 |
| Lưu trữ Orders | Header/items/events và kho quote/receipt riêng. Review snapshot, FK, constraints, retention, index và RLS trước khi mở RPC | D01, D04–D06, D08, D10–D12, D14 |
| Checkout và phục hồi | `create_checkout_quote`, `place_cod_order`, `lookup_order_request` theo tên dự thảo. Xác thực caller/địa chỉ, đọc nguồn server, tính tiền và ghi toàn bộ hiệu ứng đặt trong một transaction | D01–D03, D05–D09, D11–D12, D14 |
| Đọc và vận hành | `list_my_orders`, `get_order`, `list_admin_orders`, `change_order_status` theo tên dự thảo. Các đường đọc kiểm ownership/role, và chuyển trạng thái ghi event cùng hiệu ứng kho trong một transaction | D04–D06, D08–D14 |

[SQL fixture](../../supabase/tests/orders_fixtures.sql) dùng ID tổng hợp cố định cho A/B/admin và địa chỉ, tra variant theo SKU và chuẩn bị giỏ A gồm hai món. SQL một phiên dùng role và JWT claims như `cart.sql`. Với hai kết nối hoặc REST JWT, tạo fixture nhìn thấy được từ các phiên độc lập trong database thử dùng riêng, reset giữa ca và hủy database sau lượt chạy. Mỗi ca ghi expected, actual, commit/build, ngày và bằng chứng theo đặc tả.

## Đối chiếu tiêu chí Issue #20

| AC | Kịch bản cần chứng minh |
|---|---|
| AC1 | COD-QUOTE, COD-PLACE, COD-RACE và COD-ROLLBACK xác nhận caller/địa chỉ, đọc lại catalog, tính tiền server, snapshot và commit nguyên tử. |
| AC2 | COD-REPLAY gửi lại cùng ID sau khi mất response, so order/stock/event và kiểm khác payload. |
| AC3 | COD-QUOTE-01 và COD-UI kiểm tra subtotal 448.000đ, ship demo 25.000đ, tổng 473.000đ từ server cùng flow/loading/error/retry. |
| AC4 | COD-RLS và COD-HISTORY kiểm owner/admin list/detail, lọc, xác nhận thao tác và snapshot sau sửa/xóa địa chỉ hoặc đổi giá. |
| AC5 | COD-STATE, COD-ROLLBACK và COD-UI kiểm cạnh trái phép, hiệu ứng hủy theo rule đã duyệt và xử lý offline. |
| AC6 | REST với JWT anon/A/B/admin, SQL kiểm side effects sau lỗi, hai phiên độc lập tranh tồn và test lỗi sau khi đã phát sinh ghi trong transaction. COD-SESSION-02 là regression phiên có sẵn từ PR #28. |

## Bản triển khai thử trên nhánh backend

**D01–D14 đã được Quân xác nhận qua tin nhắn riêng**, theo thông tin Phúc cung cấp. Nhóm chưa có nguyên văn tin nhắn trong hồ sơ đối chiếu của PR. Các phương án trong bảng dưới đây và SQL hiện tại được giữ nguyên, từng mục chưa được đối chiếu với nội dung xác nhận.

| ID | Giả định trong bản triển khai |
|---|---|
| D01 | Quote toàn giỏ server, tối đa 100 dòng, quantity theo Cart 1–99, tối đa 10 quote đang hiệu lực chưa dùng, TTL 300 giây. |
| D02 | Phí demo 25.000đ, rule `flat_cod_v1`, cho mọi địa chỉ hợp lệ. Không tự áp dụng chính sách vận chuyển thật. |
| D03 | So tập variant/quantity, snapshot địa chỉ, catalog, giá và rule giữa quote/place. Quote không giữ tồn. Kiểm TTL lại sau khi lấy khóa. |
| D04 | Pending → confirmed → shipping → completed. Khách hủy đơn pending của mình. Admin hủy pending/confirmed và chuyển theo các cạnh đã mô tả. Cancelled và completed là trạng thái cuối. |
| D05 | Trừ ngay lúc đặt. Hủy hợp lệ hoàn đúng một lần qua khóa đơn, version và trạng thái. Hủy không tự đưa hàng đã đặt về giỏ. |
| D06 | Receipt thành công dùng chung namespace `(actor, request_id)`, so operation/payload chuẩn hóa trước khi kiểm dữ liệu hiện tại. Unique quote trên Orders ngăn hai request đặt cùng quote. Chưa chạy job xóa receipt/quote. |
| D07 | Backend có lookup riêng theo caller, trả `found:false` nếu chưa có receipt nhìn thấy được. Lưu pending và retry theo cùng user/request là việc của Flutter. |
| D08 | Catalog và biến thể của đơn dùng FK RESTRICT. Snapshot địa chỉ và quote ID không có FK tới bản nguồn. Xóa user giữ đơn/audit và bỏ liên kết user bằng SET NULL, xóa quote/receipt theo user. Cần Quân duyệt retention và quy trình xóa/ẩn danh PII; chưa có job hoặc quyền xóa mới. Đường dẫn ảnh lưu theo snapshot, khả năng giữ file Storage phụ thuộc chính sách catalog. |
| D09 | Dùng cùng advisory lock với Cart. Sau khóa quote/đơn và địa chỉ nếu có, lấy khóa variants theo UUID, rồi products và categories khi checkout. Variant-first theo row marks của Cart hiện tại, cần Quân và Hải review lại cùng các writer nền. Các thay đổi stock tăng revision qua trigger. |
| D10 | Bản Orders có `completed` và `order_items.product_id` làm đầu vào cho việc kiểm bằng chứng mua hàng. Reviews cần chốt và tích hợp riêng. |
| D11 | Auth caller phải còn tồn tại. Admin đọc từ `user_roles`; mutation admin mới lấy khóa chia sẻ trên role. Lookup/replay chỉ trả receipt lịch sử của actor; chưa có cột hoặc quy trình blocked account dùng chung. |
| D12 | RPC ở migration, tiền bigint đến 9.000.000.000.000đ, keyset cursor `created_at/id`, lỗi PTxxx, đọc qua RPC theo ownership/role. Header địa chỉ dùng `delivery_address`, bảng timeline `order_status_history`, receipt `private.order_request_receipts`. Timeline loại bỏ actor ID. |
| D13 | Mã đơn từ sequence `SF-` với ít nhất 6 chữ số, có thể có khoảng trống. UI hủy, stale, uncertain cần Hải/Quân xác nhận và tích hợp. |
| D14 | `20261122000100_orders.sql` chạy trước `20261122000200_admin_stock_revision.sql` sau migration catalog/storage hiện có. Xác nhận thêm lịch, timeout, bằng chứng REST/JWT, cleanup môi trường và rollback rollout trước khi dùng chung. |

### Tích hợp Admin Catalog

Hải cần đọc `stock_revision`, bỏ `stock` khỏi payload lưu metadata của biến thể hiện có và dùng `set_variant_stock(p_variant_id, p_expected_revision, p_new_stock)` khi thật sự chỉnh tồn. Khi nhận `SF_STOCK_VERSION_CONFLICT`, tải lại giá trị hiện tại và yêu cầu xác nhận lại. Kiểm tra quyền ghi theo cột sau khi chuyển mọi caller. UPDATE cấp bảng hiện tại vẫn cho phép client cũ ghi đè tuyệt đối và phải được thu hồi trong migration phối hợp trước khi đưa Orders và Admin Catalog vào phục vụ đồng thời. Không bổ sung quyền xóa cứng variant; chốt luồng ngừng bán với Quân trước.

### Chạy kiểm thử local

- SQL một phiên dùng `psql -v ON_ERROR_STOP=1 -f supabase/tests/orders.sql` trên database thử đã nạp migrations/seed. Script kiểm tra quyền, giá, stock, replay, rollback tại bước cuối, snapshot, phân trang và state machine. `orders_fixtures.sql` chạy riêng sẽ rollback ngay sau khi khởi tạo.
- REST/JWT và hai race dùng `python supabase/tests/orders_rest.py`. Đặt `ORDERS_TEST_API_URL`, `ORDERS_TEST_DB_URL`, `ORDERS_TEST_ANON_KEY`, `ORDERS_TEST_A_JWT`, `ORDERS_TEST_B_JWT`, `ORDERS_TEST_ADMIN_JWT`. URL phải là loopback, database riêng có psql, hai user mới và một user admin có JWT do Auth local phát. Script ghi dữ liệu thử, khóa row qua psql để quan sát hai request cùng chờ, rồi xác minh kết quả. Reset instance local sau lượt chạy.

Ngày 22/11/2026, PostgreSQL 18.7 local với Auth/Storage tối giản đã chạy thành công toàn bộ migration, SQL fixture, SQL Orders và bộ SQL nền. Hai race qua kết nối PostgreSQL độc lập đạt: một đơn dùng đơn vị tồn cuối và một lần đổi trạng thái cùng version. REST/PostgREST và JWT thật chưa chạy. Flutter analyze đạt và Flutter test đạt 157/157.

### Đối chiếu PR #30 và chuẩn bị chuyển quyền stock

- Phúc xác nhận Quân đã chốt D01–D14 qua tin nhắn riêng. Bảng trên ghi phương án SQL hiện tại, chờ đối chiếu từng mục khi có nguyên văn. Các kiểm tra kỹ thuật tiếp tục dựa trên SQL hiện tại.
- Migration `20261122000300_product_images_storage.sql` của PR #29 tại `42d1aa5` đã áp dụng sau tám migration của nhánh Orders trên PostgreSQL local. SQL policy cho phép admin thêm ảnh và anon đọc, đồng thời chặn customer thêm ảnh trên schema Storage mô phỏng. Migration nâng giới hạn từ 2 lên 5 MiB, thay ba policy ghi và để lại cả `product_images_read` lẫn `product_images_public_read`. Hải cần chốt giới hạn và gộp policy đọc trước khi tích hợp. Kiểm thử upload qua Storage API vẫn cần Supabase local. [Review PR #29](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/29#pullrequestreview-6011723835)
- Sau khi Hải chuyển các đường UPDATE của client sang payload metadata và RPC stock, xác nhận client cũ đã ngừng ghi stock trực tiếp. Trong migration phối hợp, thu hồi UPDATE cấp bảng và cấp UPDATE cho `product_id`, `sku`, `size`, `color`; rà quyền kế thừa trước khi phát hành. [Bài diễn tập SQL](../../supabase/tests/orders_stock_cutover.sql) áp dụng thay đổi bên trong transaction rồi rollback. Đã xác minh admin vẫn sửa metadata, tạo variant với tồn ban đầu và chỉnh tồn qua RPC; UPDATE trực tiếp stock/revision bị từ chối, khách không sửa được metadata hoặc gọi RPC stock, checkout và hủy vẫn trừ/hoàn đúng. Migration vận hành sẽ đi sau bản client của Hải.
- Với Supabase local dùng riêng, khởi động stack và reset database để nạp migrations/seed. Tạo tài khoản A/B/admin qua Auth, cấp quyền admin trên `public.user_roles` ở local rồi lấy access token của cả ba. Chạy `orders.sql`, `orders_stock_cutover.sql` bằng psql và chạy `orders_rest.py` với các biến môi trường ở trên. Bài REST còn kiểm tra ghi thẳng trạng thái bị chặn kể cả với admin, dùng lại request ID với payload khác, và form stock cũ xung đột sau checkout. Lượt kiểm tra hiện tại thiếu Docker, Supabase CLI và psql nên REST/JWT thật ở trạng thái **Not Run**.

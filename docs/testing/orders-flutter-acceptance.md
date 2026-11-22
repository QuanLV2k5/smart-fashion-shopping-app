# Nghiệm thu Flutter Checkout COD và Orders

## Chạy tự động với Supabase riêng

Workflow [Orders local integration](../../.github/workflows/orders-local.yml) tạo Supabase dùng một lần trên runner, chạy migrations, SQL, REST/JWT rồi chạy [Flutter acceptance](../../test/features/orders/orders_supabase_acceptance_test.dart). Bài Flutter dùng Auth và RPC thật qua các repository, Riverpod providers và tệp pending trên đĩa. Mô phỏng mất phản hồi bằng cách bỏ response HTTP sau khi server đã commit. Restart tự động tái tạo provider container và store với cùng thư mục. Các tương tác màn hình và đổi phiên đang có trong [widget tests](../../test/features/orders).

Để chạy trên máy có Docker, Supabase CLI, Flutter và psql, tạo thư mục tạm riêng, chạy `supabase init` trong đó rồi sao chép `supabase/migrations` của repo vào thư mục mới. Chạy `supabase start`, ghi `supabase status -o json` vào tệp local ngoài Git. Từ repo, đặt biến môi trường `ORDERS_SUPABASE_STATUS` trỏ tới tệp đó rồi chạy:

```shell
flutter test --no-pub test/features/orders/orders_supabase_acceptance_test.dart
```

Bài test tạo A, B và admin bằng Auth của instance tạm, chỉnh tồn variant demo và cố ý chỉnh thời hạn quote trong DB để tránh phải chờ năm phút. Runner và bài test kỳ vọng database dùng riêng tại loopback. Giữ tệp trạng thái ngoài Git vì chứa thông tin xác thực local. Khi hoàn tất, dừng và dọn instance thử.

## Kiểm tra trên thiết bị hoặc trình duyệt

Tạo hai customer và một admin trong instance thử. Dùng khóa client của instance và chỉ định cả URL lẫn khóa để tránh cấu hình mặc định trỏ tới backend dev của repo. Ví dụ Chrome:

```shell
flutter run -d chrome --dart-define=APP_ENV=development --dart-define=USE_SUPABASE=true --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=<local-client-key>
```

Android emulator dùng `10.0.2.2` để truy cập cổng host. Với mỗi ca, ghi commit, thiết bị/trình duyệt, bước tái hiện, số đơn và stock/revision trước/sau.

| Ca | Bước và kết quả cần thấy |
|---|---|
| Checkout và bấm trùng | A chọn địa chỉ, mở Checkout, kiểm giá/phí/tổng theo quote và bấm đặt hai lần nhanh. Chỉ hiện một đơn và tồn giảm một lần. |
| Offline và restart | Chặn phản hồi place sau commit bằng proxy thử hoặc ngắt kết nối khi gửi. Màn hình giữ yêu cầu chưa xác định. Dừng hẳn app, mở lại bằng A, kiểm tra lại đơn từ Cart. Cùng request ID dẫn đến đúng một đơn. Lặp thử mất mạng trước khi server nhận request. |
| Hết tồn và hết hạn | Sau quote, giảm tồn qua RPC admin hoặc mua món cuối bằng B. Đặt từ A phải báo hết tồn. Với quote hết hạn, đợi TTL hoặc sửa expiry ở instance thử, rồi đặt và lấy báo giá mới. |
| Hủy và hoàn tồn | Hủy đơn pending trong My Orders, xác nhận timeline và tồn tăng đúng một lần. |
| Quyền và đổi phiên | A đặt đơn. B truy cập deep link đơn A và `/admin/orders`. B không thấy dữ liệu A hay thao tác admin. Đăng nhập lại A và kiểm lịch sử chỉ chứa đơn của A. |
| Đồng thời | Mở cùng đơn pending bằng admin và customer, cùng gửi thao tác hợp lệ với version cũ. Một thao tác thắng, màn thua báo xung đột và tải lại trạng thái. |

## Admin Catalog và tồn kho

PR #29 tại `42d1aa5` có `/admin`, danh mục và sản phẩm. Orders dùng `/admin/orders` và `/admin/orders/:orderId` từ Account admin. Khi tích hợp, thêm mục Đơn hàng trong trang Admin Catalog tới route đã có và dùng chung kiểm role. Các RPC vẫn kiểm quyền server. Kiểm tra deep link, quay lại trang Admin Catalog và đăng xuất trong màn chi tiết.

| Caller | Hành vi hiện tại |
|---|---|
| Orders `place_cod_order`, `change_order_status` khi hủy | Trừ hoặc hoàn stock trong transaction, trigger tăng revision khi stock đổi. |
| Admin `set_variant_stock(p_variant_id, p_expected_revision, p_new_stock)` | Cập nhật có điều kiện theo revision, trả stock và revision hiện hành khi thành công. Mismatch trả `SF_STOCK_VERSION_CONFLICT`. |
| PR #29 `saveVariant()` | INSERT có tồn ban đầu. Khi sửa và `updateStock=true`, vẫn gửi stock tuyệt đối qua UPDATE theo ID. Cần tách metadata, đọc `stock_revision` và dùng RPC khi chỉnh tồn. |
| PR #29 `deleteVariant()` | UPDATE stock về 0 theo ID. Cần bỏ thao tác này hoặc thay bằng trạng thái ngừng bán đã thống nhất. Hủy đơn có thể hoàn tồn và bật lại khả năng mua nếu dùng số 0 để biểu thị ngừng bán. |
| Seed và test | Seed INSERT tồn khởi tạo. SQL test thao tác trong fixture cô lập. |

Thu hồi UPDATE stock trực tiếp sau khi cả hai đường ghi của PR #29 và mọi client liên quan đã chuyển đổi. [Diễn tập quyền SQL](../../supabase/tests/orders_stock_cutover.sql)

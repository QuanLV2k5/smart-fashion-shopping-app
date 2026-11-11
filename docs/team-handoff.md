# Bàn giao baseline ngày 10/11/2026

Đây là snapshot dự án **0.1.3+4** để nhóm clone, review và tiếp tục Sprint 1.
Không phải tuyên bố hoàn thành mọi Issue hoặc bắt đầu Sprint 2.

Repo ban đầu chưa có commit. Main được khởi tạo bằng README tối thiểu;
toàn bộ code bàn giao qua nhánh `chore/project-setup` và PR về main. Trong lúc
chờ review/merge, dùng hướng dẫn clone nhánh ở [team-workflow](team-workflow.md).
Xem [Pull requests](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pulls)
và [Actions](https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions)
để biết trạng thái remote hiện tại; local test không đồng nghĩa CI đã pass.

## Code đã có và phần cần tiếp nhận

| Thành viên / Issue hiện có | Baseline đã có | Việc tiếp theo trước khi chốt AC |
|---|---|---|
| Quân / Q02 [#2](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/2), Q03 [#3](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3) | Flutter/config/theme, Supabase schema/RLS, model/data catalog, kiểm thử, tài liệu và workflow | Theo dõi CI/PR, review, contract/ERD và xác nhận chạy thật của hai bạn theo AC |
| Hải / H01 [#4](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/4), H02 [#5](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/5) | Auth email/session, Home/tìm/lọc/chi tiết/chọn biến thể và đường thêm giỏ | Review/tự kiểm chứng code, làm hồ sơ còn thiếu, đối chiếu toàn bộ AC và phối hợp test/review H03 [#6](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6) |
| Phúc / P01 [#9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9), P02 [#7](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7), P03 [#8](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8) | Cart/RPC theo tài khoản, tăng/giảm/xóa và kiểm thử mẫu; schema addresses có sẵn | Review/tiếp nhận cart, phát triển địa chỉ, test phân quyền/luồng tích hợp, test matrix/review/retro theo Issue |

Các dòng trên không tự thay assignee, Planned/Actual hours hoặc đóng Issue.
Code Auth/cart hiện có được bàn giao nguyên trạng, không gán giả cho Hải/Phúc.
Mỗi người làm UI và backend cho phần còn lại của feature mình nhận, trao đổi
về contract chung. Quân hiện yêu cầu hỗ trợ UI mặc định; chưa tự mở rộng backend
của các thành viên hoặc triển khai Sprint 2 trong tác vụ bàn giao này.

## Dữ liệu và môi trường

- Flutter 3.47.5 / Dart 3.13.4; Java 25 dùng cho CI, Android SDK ở máy từng người.
- App mặc định nối `smart-fashion-dev`. URL/publishable key client được đóng
  gói có chủ đích, không phải secret/service-role key.
- Database cloud đã có ba migration trong supabase/migrations. Không chạy lại
  các file tạo bảng trên cloud hiện tại. Chưa baseline migration history CLI.
- Clone không mang theo tài khoản, password, session của Quân hoặc config máy.
  Mỗi người dùng tài khoản thử riêng; mail ngoài tổ chức chưa có SMTP riêng để bảo đảm gửi thư.
- Ảnh/font Figma đã bundle. APK/build output không đưa vào Git; build từ source.
- Chưa có sửa hồ sơ/avatar đầy đủ, địa chỉ UI, checkout/COD/đơn, AI, admin,
  yêu thích/đánh giá hoặc cache offline lưu bền. iPhone hiện dùng web.

## Bằng chứng đang có

Ngày bàn giao, `flutter pub get --enforce-lockfile` và `scripts/check.ps1`
đạt: analyzer không issue, **60 test**. Bản Android 0.1.3 trước đó đã được
người dùng thử thêm áo/jeans tổng 448.000đ và mở lại vẫn còn giỏ; APK/web đã build.
Chi tiết SQL/RLS, SDK cloud và giới hạn kiểm thử nằm trong
[setup-verification](setup-verification.md).

Các đoạn ghi “chưa commit/push” trong tài liệu ngày 08–09/11 là lịch sử trước
lần bàn giao GitHub này. Kết quả Actions, review và xác nhận clone của Hải/Phúc
phải được kiểm tra/ghi riêng, không suy ra từ kết quả trên máy Quân.

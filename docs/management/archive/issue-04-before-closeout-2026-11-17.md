# Snapshot Issue #4: [H01] Xây dựng xác thực và hồ sơ cá nhân

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/4
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Người dùng đăng ký, đăng nhập và quản lý hồ sơ qua Supabase thật.

## Phụ thuộc

Cần nền tảng, schema profiles và contract từ Q02; dùng quy tắc UI/DoD từ P01.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [x] Tạo Presentation/Domain/Data cho Auth và Profile, quản lý trạng thái bằng Riverpod.
- [x] Làm đăng ký email/mật khẩu, đăng nhập, đăng xuất và hồ sơ; xử lý cấu hình xác nhận email theo quyết định của nhóm.
- [x] Tích hợp Supabase Auth và dữ liệu hồ sơ; thiết kế quyền mặc định khách hàng.
- [x] Xử lý nhập liệu sai, mật khẩu sai, mất mạng và phiên đăng nhập; thông báo rõ ràng.

## Tiêu chí chấp nhận

- [x] Đăng ký/đăng nhập/đăng xuất và sửa hồ sơ chạy trên môi trường dùng chung.
- [x] Người dùng không tự nâng vai trò hoặc sửa hồ sơ người khác; chặn cả ở phía dữ liệu.
- [x] Loading/error và lỗi xác thực không gây crash; có tự kiểm thử trước PR.

## Bằng chứng cần gắn

- PR module Auth/Profile và test liên quan
- Ảnh/video luồng thật; cấu hình cần thiết được mô tả trong README

## Điều kiện hoàn thành

- [x] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

Không commit mật khẩu demo hoặc khóa đặc quyền. Nếu cần nhiều PR, PR đầu chỉ Refs Issue; PR cuối mới đóng Issue sau khi đủ acceptance criteria.


## Đối chiếu 17/11/2026

Auth/Profile của Hải đã tích hợp PR #11 → #13, giữ commit gốc; Phúc approve PR #13. Main 5dc2b77: ngày 17/11 chạy lại 131 test đạt (Auth 14, Profile 20); analyzer/format đạt. Quân đã xác nhận đăng ký/xác nhận email/login và Android chạy ổn, cả ba máy chạy được. SQL/RLS foundation cloud chạy lại đạt; REST JWT A/B vẫn theo dõi riêng theo DoD dự thảo. Avatar hiện là preset, chưa phải upload ảnh cá nhân. Checkbox Actual hours cũ được bỏ tick vì chưa có số thực tế được cung cấp. Giữ mở/In Review đến khi đủ DoD, xử lý hồ sơ còn thiếu trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

Auth/Profile/regression giữ nguyên bản đã chạy. Hồ sơ tích hợp đã qua review PR16. Tiếp tục theo dõi REST JWT A/B và nhánh lỗi mạng thật theo matrix; preset avatar chưa phải upload cá nhân.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


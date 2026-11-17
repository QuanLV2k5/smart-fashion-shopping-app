# Snapshot Issue #7: [P02] Xây dựng giỏ hàng và quản lý địa chỉ nhận hàng

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Người dùng có giỏ hàng và địa chỉ sẵn sàng cho checkout Sprint 2.

## Phụ thuộc

Q02 scaffold/schema; Q03 cung cấp model/contract biến thể; P01 UI/DoD; H02 bàn giao sự kiện thêm giỏ. Tích hợp H01 trước kiểm thử tài khoản cuối sprint.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [x] Làm model giỏ, thêm/xóa/đổi số lượng; gộp đúng cùng biến thể, tách đúng khác size/màu.
- [x] Hiển thị đơn giá/tổng tiền; kiểm tra số lượng dương và giới hạn tồn kho theo snapshot.
- [x] Làm thêm/sửa/xóa/chọn địa chỉ nhận hàng qua dữ liệu có quyền theo tài khoản.
- [x] Giữ trạng thái giỏ tách biệt khi logout/đổi tài khoản; tích hợp nút thêm từ catalog.

## Tiêu chí chấp nhận

- [x] Hai sản phẩm khác biến thể không bị gộp sai; tổng hiển thị đúng và số lượng hợp lệ.
- [x] Địa chỉ tài khoản A không đọc/sửa được bởi B; xử lý địa chỉ thiếu hoặc không hợp lệ.
- [x] Luồng catalog → chọn biến thể → giỏ → địa chỉ chạy được; logout/đổi tài khoản không lẫn giỏ.

## Bằng chứng cần gắn

- PR Cart/Addresses, test logic tổng tiền/biến thể
- Ảnh/video luồng thật và kết quả test truy cập chéo

## Điều kiện hoàn thành

- [ ] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.


## Đối chiếu 17/11/2026

Giỏ/địa chỉ đã tích hợp PR #12 → #13, giữ commit Phúc; main 5dc2b77. Ngày 17/11: 67 test cart+addresses đạt trong tổng 131, analyzer/format đạt. Quân xác nhận Android thêm hai món 448.000đ và mở lại còn giỏ; bản tích hợp chạy ổn, cả ba máy chạy được. Foundation SQL/RLS cloud A/B địa chỉ đạt với rollback; kiểm tra sau rollback còn 0 fixture. REST JWT A/B đủ CRUD, cart retry và mất mạng thực tế theo matrix vẫn cần ghi riêng. Actual hours chưa tổng hợp. Báo cáo bổ sung trên nhánh docs/replan-delivery-25nov chờ review. Giữ mở/In Review; xử lý ca/hồ sơ còn thiếu trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

Report giỏ/địa chỉ và hồ sơ tích hợp đã được Hải review PR16 và merge. Test cart+addresses 67 đạt trong tổng 131. Chưa có đủ kết quả REST JWT CRUD A/B, retry/network thật trên build xác định; tiếp tục theo dõi theo matrix, không coi SQL role test thay REST.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


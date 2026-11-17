# Snapshot Issue #1: [QO1] Lập Charter, chốt phạm vi và điều phối kế hoạch Sprint 1

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/1
Captured: 17/11/2026, before checklist simplification.

## Mục tiêu

Có cơ sở triển khai dự án và trạng thái phê duyệt được ghi nhận đúng, phù hợp hai môn học.

## Phụ thuộc

Không có điều kiện chặn khởi động; phối hợp H01 và P01. Chốt phạm vi nháp ngày 04/11 để các bạn bắt đầu song song.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/H01/P01... thành liên kết Issue thật. Không giả định Q01 là #1. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [x] Lập Charter đủ 13 mục theo mẫu chính thức; dùng ví dụ đã đọc để tham khảo cấu trúc.
- [x] Ghi rõ In-Scope/Out-of-Scope, SMART, stakeholder, 5 vai trò kiêm nhiệm, công suất và lịch bốn sprint.
- [ ] Trình giảng viên tiến độ rút gọn, yêu cầu lịch sử 15 tuần và đầu ra Android/iOS/APK; lưu trao đổi thật.
- [ ] Cùng Hải và Phúc lập WBS toàn dự án, nhập Sprint 1, Planning Poker và thống nhất reviewer.
- [ ] Đặt lịch review 10/11, 17/11, 24/11 và UAT 24–26/11; lấy các mẫu còn thiếu.

## Tiêu chí chấp nhận

- [ ] Có Charter/scope phiên bản rõ, WBS bao phủ cả sản phẩm lẫn quản trị; ba thành viên đã review.
- [ ] Có bằng chứng đã gửi đề nghị và trạng thái phản hồi/phê duyệt thật; không ghi Approved khi còn chờ.
- [ ] Các acceptance criteria của Sprint 1, trách nhiệm và lịch review đã thống nhất; có action theo dõi chữ ký/phản hồi còn thiếu.

## Bằng chứng cần gắn

- docs/management/project-charter.md và scope-baseline.md
- docs/management/wbs.md; biên bản kickoff/planning
- Liên kết PR và trao đổi stakeholder được phép chia sẻ

## Điều kiện hoàn thành

- [ ] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

Nếu phê duyệt bắt buộc chưa có, ghi blocker và giữ công việc phê duyệt ở trạng thái mở; không coi bản nháp là Charter Signed. Phần chuẩn bị có thể bàn giao riêng. Giờ điều phối nhập trong 6 giờ của gói này.

## Đối chiếu 17/11/2026

Quân xác nhận ngày 17/11: nhóm họp Retro ngày 13/11, cả ba chạy app thành công trên máy riêng. Đã có bộ Charter/WBS/Scope báo cáo 15/11 và kế hoạch R4 hoàn thiện ứng dụng ngày 25/11. Chữ ký/phê duyệt PO/giảng viên, review hồ sơ, Planning Poker và Actual hours chưa được cung cấp; không coi là Approved. Các checkbox AC cũ không thay cho bằng chứng. Giữ In Progress, theo dõi phần hồ sơ còn thiếu trước 18/11; không đổi lịch sử S1.

Liên kết đối chiếu: #10, #13, #14, #15. Kế hoạch R4 và kiểm kê S1 được bàn giao qua PR hồ sơ; không tự đóng Issue khi chưa đủ DoD.


## Cập nhật sau merge PR #16 — 17/11/2026

Charter/WBS/R4 và dự thảo Retro đã qua Hải review trong PR16. Ngày Retro do Quân xác nhận: 13/11. Còn bằng chứng phê duyệt PO/giảng viên, Planning Poker và xác nhận nội dung/action Retro; không coi tài liệu dự thảo là đã ký.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


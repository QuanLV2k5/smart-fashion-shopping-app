# Snapshot Issue #2: [Q02] Thiết lập nền tảng Flutter, Supabase, GitHub và CI

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/2
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Quân tạo nền tảng dùng chung trước khi Hải và Phúc bắt đầu các module. Ba thành viên cùng chạy được nền tảng và phát triển module song song.

## Phụ thuộc

Scope nháp từ Q01; phối hợp P01 về dữ liệu và DoD. Không chờ toàn bộ Q01 được đóng mới bắt đầu.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [ ] Chốt Flutter SDK cụ thể, app scaffold và cấu trúc module Presentation/Domain/Data; thống nhất routing/model/repository contract.
- [ ] Thiết kế schema, migration và quyền truy cập ban đầu cho profiles, catalog, địa chỉ; thống nhất contract đơn hàng cho Sprint 2.
- [x] Thiết lập repo/Projects, nhãn, milestone, PR template và bảo vệ main; Quân trực tiếp cấu hình, Hải phản biện và review.
- [x] Thiết lập GitHub Actions chạy định dạng, analyze, test và build kiểm tra Android trên PR; kiểm tra green run thật.
- [ ] Hoàn thiện ERD/schema, README, cấu hình mẫu, migration và seed dữ liệu; giúp cả hai bạn clone và chạy được.
- [x] Kiểm tra config client Supabase và phân quyền dữ liệu; giữ khóa đặc quyền, database password và Gemini key ở phía máy chủ, ngoài mã nguồn.

## Tiêu chí chấp nhận

- [x] Ba máy có thể chạy scaffold theo README; version SDK và cách cấu hình được ghi rõ.
- [ ] Schema/migration tái tạo được; có chính sách truy cập ban đầu và contract đủ cho H01/H02/P02.
- [x] Có PR foundation được Hải duyệt, CI thực sự chạy; main yêu cầu review và checks sau khi checks đã xuất hiện.
- [ ] Quân/Hải/Phúc truy cập được repo và Project với quyền phù hợp; cấu hình không chỉ ghi trong tài liệu.

## Bằng chứng cần gắn

- PR foundation; URL Actions run; ảnh Branch Protection và quyền Project
- docs/architecture/contracts.md, schema/ERD nháp, migration và README

## Điều kiện hoàn thành

- [ ] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

10 giờ bao gồm phần thiết lập GitHub trong hướng dẫn này. Dự toán đã gồm 2 giờ ERD/README chuyển từ H03. Các thao tác đã làm trước lúc mở Issue ghi đúng thời điểm thực hiện. Initial README bootstrap là bước tạo repo; mọi thay đổi tiếp theo qua PR. Không chọn required check chưa tồn tại hoặc bỏ qua lỗi CI để merge.

## Đối chiếu 17/11/2026

- PR #10 đã merge; Hải và Phúc approve ngày 11/11. CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/43066716263 (đạt).
- Quân xác nhận ngày 17/11: cả ba chạy app thành công trên máy riêng.
- Chạy lại main 5dc2b77: 131/131 test đạt, analyzer không lỗi, format 81 file/0 thay đổi. Catalog REST thật đạt 448.000đ; SQL/RLS foundation chạy lại trên cloud đạt với rollback.
- Contract/ERD và kế hoạch R4 được bổ sung trên nhánh docs/replan-delivery-25nov, chờ peer review/merge. Quyền Project từng tài khoản và Actual hours chưa có bằng chứng mới để đánh dấu hoàn tất.
- Giữ mở/In Review đến khi đủ DoD; xử lý phần hồ sơ còn thiếu trước 18/11. Mốc hoàn thiện đầy đủ ứng dụng: 25/11. Không thay ngày baseline Sprint 1.


## Cập nhật sau merge PR #16 — 17/11/2026

Contract/ERD và hồ sơ nền đã được Hải review qua PR16 và merge. Ba máy chạy được theo Quân xác nhận. Còn xác minh quyền truy cập Project của từng thành viên và đối chiếu AC nền trước đóng; không dùng quyền tài khoản chủ repo thay cho quyền hai thành viên.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


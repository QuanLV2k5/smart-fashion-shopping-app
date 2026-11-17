# Snapshot Issue #5: [H02] Xây dựng catalog, tìm lọc và chi tiết sản phẩm

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/5
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Khách xem và tìm được sản phẩm thật, chọn đúng size/màu để thêm vào giỏ.

## Phụ thuộc

Scaffold/schema từ Q02; model/contract và Data repository từ Q03; UI/test data từ P01. Contract bàn giao 05/11, repository bản đầu 06/11.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [x] Làm danh sách theo danh mục, tìm theo tên, lọc cơ bản theo giá/size/màu.
- [x] Làm chi tiết sản phẩm với ảnh, giá, mô tả và biến thể/tồn kho.
- [x] Tích hợp repository do Quân bàn giao trong Q03 vào Riverpod/presentation/domain; xử lý loading/empty/error.
- [x] Dùng chung model/contract biến thể Q03 và cung cấp sự kiện thêm giỏ cho P02; không tự viết lại Data repository.

## Tiêu chí chấp nhận

- [x] Dữ liệu đọc từ Supabase, tìm/lọc đúng trên bộ seed đã thống nhất.
- [x] Phân biệt biến thể; không chọn tổ hợp size/màu không tồn tại hoặc hết hàng để mua.
- [x] UI xử lý không có kết quả/lỗi mạng; có đường tích hợp với giỏ.

## Điều kiện hoàn thành

- [x] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

## Đối chiếu 17/11/2026

Code catalog/tìm-lọc/biến thể/chi tiết đã nằm trên main qua PR #10/#13, báo cáo qua PR #15 được Phúc review. Ngày 17/11: 131 test đạt, riêng Catalog 16; REST guest hai món 448.000đ/5 variants đạt; Quân xác nhận tìm kiếm/chọn biến thể/giỏ trên Android. Loading/empty/error và chặn biến thể hết tồn có widget/unit test; không suy thành toàn bộ mất mạng thực tế đã thử. Bản hiệu chỉnh báo cáo H03 và evidence nằm trên nhánh docs/replan-delivery-25nov chờ peer review. Actual hours chưa tổng hợp. Giữ mở/In Review; xử lý phần hồ sơ trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

AC catalog đã có code/test/ảnh và xác nhận Android; hiệu chỉnh báo cáo đã được Hải approve tại đúng HEAD PR16 và đã merge. Phạm vi Issue này đủ bằng chứng bàn giao, chờ/đối chiếu CI main trước chuyển Done.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


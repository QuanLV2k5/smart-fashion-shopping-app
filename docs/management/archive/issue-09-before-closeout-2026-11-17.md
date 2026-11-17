# Snapshot Issue #9: [P01] Lập test matrix, DoD, UI dùng chung và dữ liệu mẫu

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9
Captured: 17/11/2026, before checklist simplification.

 ## Mục tiêu
  
  Nhóm thống nhất tiêu chí hoàn thành và dữ liệu để phát triển, kiểm thử cùng một cách.
  
  ## Phụ thuộc
  
  Scope nháp Q01; phối hợp Q02 về schema và contract. Có thể bắt đầu ngay từ ngày 04/11.
  
  Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.
  
  ## Công việc
  
  - [x] Lập test matrix theo chức năng và acceptance criteria của Sprint 1; phân biệt test dự kiến và kết quả thực tế.
  - [x] Viết DoD code/tài liệu, quy tắc peer review và cách lưu evidence.
  - [ ] Thống nhất component/UI tối thiểu theo prototype sẵn có với hai bạn; không thiết kế lại toàn bộ Figma.
  - [x] Xác định dữ liệu mẫu/trường hợp nhiều danh mục, size/màu, hết hàng; Quân triển khai tệp seed tái tạo trong Q03. Không commit mật khẩu.
  - [ ] Cùng nhóm Planning Poker, rà soát Sprint 1: Quân 8 giờ, Hải 8,5 giờ, Phúc 8,5 giờ; không ép SP hoặc Actual hours bằng nhau.
  
  ## Tiêu chí chấp nhận
  
  - [ ] Test matrix có ID, bước thử, expected result, loại test và phần truy vết Issue/AC.
  - [ ] DoD được cả ba review; yêu cầu review/CI/test phù hợp công việc và bằng chứng cụ thể.
  - [ ] Đặc tả dữ liệu test đủ biến thể/giá/hết hàng, thống nhất với seed Q03 và UI cơ bản; không nhận công việc viết seed của Q03.
  
  ## Bằng chứng cần gắn
  
  - docs/testing/test-matrix.md và docs/management/definition-of-done.md
  - Seed dữ liệu, quy tắc component UI và biên bản planning
  
  ## Điều kiện hoàn thành
  
  - [ ] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
  - [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
  - [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
  - [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

## Đối chiếu 17/11/2026

PR #14 của Phúc có 7 file docs/42 test cases, CI đạt nhưng vẫn Draft và chưa có peer approval. Đã ghép nguyên commit a504ba1 vào nhánh docs/replan-delivery-25nov để cập nhật snapshot/test và review cùng hồ sơ chốt S1; không thay main hoặc xóa công Phúc. Main 5dc2b77 chạy lại 131 test đạt; SQL/RLS cloud đạt, REST JWT A/B còn thiếu. Quân xác nhận Retro 13/11 và ba máy chạy thành công; không suy thành đã Planning Poker hoặc đã đồng thuận từng dòng DoD. DoD/UI/matrix vẫn cần review và Actual hours/SP chưa tổng hợp. Giữ mở/In Review; hoàn tất review trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

7 file P01 của Phúc đã vào main qua PR16 và được Hải peer review cùng bản cập nhật. PR14 tự Merged cùng commit c30d3f3, không cần approve/merge riêng bản Draft cũ. Đồng thuận/Poker/SP và các ca REST/network còn thiếu phải ghi rõ; chưa coi merge tài liệu là chạy hết 42 ca.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


# Snapshot Issue #8: [P03] Kiểm thử giỏ và địa chỉ, điều phối Retro 1 và Risk snapshot

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Giỏ/địa chỉ được kiểm chứng; Sprint 1 kết thúc với dữ liệu rủi ro và hành động cải tiến thật.

## Phụ thuộc

Có phần chạy được P02 và test matrix P01; cả nhóm tham gia review/retro. Phúc review PR Auth/Catalog của Hải.

Sau khi cả chín Issue tồn tại, sửa các mã Q01/Q02/P01... thành liên kết Issue thật. Q01 hiện là Issue #1; các mã còn lại cần được thay bằng liên kết Issue thật sau khi tạo. Nếu bị chặn, thêm label status:blocked và comment nguyên nhân/người xử lý/hạn; giữ đúng Status hiện tại.

## Công việc

- [ ] Test khác biến thể, tổng tiền, số lượng sai, đổi tài khoản, địa chỉ thiếu và truy cập chéo.
- [x] Review PR Hải; theo dõi lỗi và kiểm tra lại phần đã sửa.
- [ ] Điều phối Sprint Review và Retro 1 ngày 10/11 theo 4Ls hoặc Sailboat; ghi người tham gia và action items.
- [ ] Cập nhật Risk Register, lưu baseline và snapshot Sprint 1; mỗi owner cung cấp rủi ro phần mình.
- [ ] Ghi dữ liệu hoàn thành/thời gian và tổng SP từ GitHub để dùng cho velocity/burndown.

## Tiêu chí chấp nhận

- [ ] Có test report giỏ/địa chỉ và liên kết review; lỗi chưa sửa được ghi minh bạch.
- [ ] Retro diễn ra thật, có ngày/người tham gia, nội dung và hành động kèm owner/hạn.
- [ ] Risk snapshot giữ được phiên bản trước; trạng thái và phản ứng dựa trên thực tế, không tự ghi rủi ro đã xảy ra.
- [ ] Số liệu tổng hợp khớp Issue/PR; việc chưa đạt DoD được chuyển tiếp, không đóng cho đủ 9/9.

## Bằng chứng cần gắn

- docs/testing/sprint-1-cart-report.md
- docs/management/retrospectives/sprint-1.md
- Risk Register baseline/snapshot; docs/management/metrics/sprint-1.md

## Điều kiện hoàn thành

- [ ] Tiêu chí chấp nhận đã đạt, có kết quả thật và reviewer kiểm tra.
- [x] Code/tài liệu đã qua PR phù hợp; với code, CI pass và test cần thiết đã chạy.
- [x] Liên kết PR, test report và bằng chứng cập nhật trong Issue.
- [x] Actual hours được ghi nhận; không lấy Planned hours làm giờ thực tế mặc định.

## Đối chiếu 17/11/2026

Quân xác nhận 17/11: Retro nhóm đã họp ngày 13/11, cả ba chạy app thành công trên máy riêng. Đã soạn hồi cứu dự thảo Retro từ các lỗi router/Profile và thiếu evidence; nội dung/bài học/action là đề xuất, chưa tự ghi là quyết định đã thống nhất. Risk snapshot hiện có trong bộ báo cáo 15/11. Test main chạy lại 131 đạt, cart+addresses 67; SQL/RLS cloud đạt, REST JWT/network còn theo dõi. Report giỏ/Retro/kiểm kê trên nhánh docs/replan-delivery-25nov chờ review. Actual hours/SP chưa có; không bịa velocity hoặc burndown. Giữ In Progress, bổ sung và xác nhận hồ sơ trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

Report giỏ và hồi cứu Retro đã được Hải review PR16 và merge. Retro họp 13/11 được Quân xác nhận. Bài học/action trong file là dự thảo biên soạn hồi cứu, cần nhóm xác nhận nội dung; Risk snapshot báo cáo 15/11 đã có. REST/mạng và SP/Poker chưa có kết quả đầy đủ, không dựng velocity.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


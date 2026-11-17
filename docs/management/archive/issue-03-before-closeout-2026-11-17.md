# Snapshot Issue #3: [Q03] Repository catalog, kiểm tra phân quyền và bàn giao nền tảng

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3
Captured: 17/11/2026, before checklist simplification.

## Mục tiêu

Quân nhận phần dữ liệu catalog từ H02 và hoàn thiện nền tảng. Đây là phần phát triển/kiểm chứng bổ sung có đầu ra riêng, không lặp lại 90 phút bootstrap Q02.

## Phụ thuộc

Q02 có scaffold/schema; P01 cung cấp bộ trường hợp và dữ liệu mẫu. Bàn giao contract/model trước 05/11, repository bản đầu trước 06/11 cho H02/P02.

## Công việc và phân bổ dự kiến

- [x] 3 giờ: Product/ProductVariant model, contract repository và Data implementation đọc catalog, tìm/lọc, chi tiết, biến thể; seed/migration tái tạo theo dữ liệu P01.
- [ ] 1 giờ: kiểm tra quyền hồ sơ/địa chỉ/catalog với hai tài khoản, sửa policy cần thiết và test lớp dữ liệu.
- [ ] 0,5 giờ: hoàn thiện ERD/README/CI theo cấu hình thật; review PR Phúc trong phạm vi liên quan.
- [ ] 0,5 giờ: hỗ trợ Hải/Phúc clone, cấu hình và xác nhận chạy, ghi blocker nếu chưa đạt.
- [ ] 1 giờ: phần tham gia planning/review/retro, điều phối ngắn và cập nhật công việc của Quân trong Sprint 1.

## Tiêu chí chấp nhận

- [x] H02 nhận được repository/model dùng chung; truy vấn tên/giá/size/màu/biến thể trả đúng dữ liệu mẫu.
- [ ] Seed/migration tái tạo được; quyền hồ sơ/địa chỉ giữa A và B được kiểm tra trên backend thật.
- [x] Hai bạn có xác nhận chạy theo README hoặc lỗi/blocker có người xử lý; CI và ERD phản ánh code hiện tại.
- [ ] Có test/evidence của phần dữ liệu và review chéo; không tính lại việc bootstrap Q02.

## Ranh giới với H02 và các gói khác

Quân làm model/contract/Data repository catalog; Hải làm UI, Riverpod/presentation/domain nối repository và xử lý tương tác catalog. H01 của Hải vẫn sở hữu Auth/Profile. Spike Gemini nếu thực hiện tính trong Q04 hoặc quỹ dự phòng có ghi nhận; không cộng ngầm vào Q03.

## Bằng chứng cần gắn

- PR Data repository/seed, test quyền/truy vấn và URL Actions.
- docs/architecture/contracts.md, ERD và README.
- Comment xác nhận chạy, commit và thiết bị của Hải/Phúc.

## Điều kiện hoàn thành

- [ ] Acceptance criteria trong phạm vi gói này đã đạt, có kết quả và review thật.
- [x] PR, CI/test phù hợp công việc và bằng chứng đã được liên kết.
- [ ] Actual hours được ghi từ thực tế; không dùng Planned hours để điền mặc định.

## Đối chiếu 17/11/2026

Repository/model catalog đã có trong PR #10, catalog UI tích hợp trên main 5dc2b77. Ngày 17/11 chạy lại 131 test đạt, analyzer/format đạt, REST guest SF01/SF02 = 448.000đ/5 variants. Foundation SQL/RLS cloud anon/A/B/admin đạt và rollback; kiểm tra sau rollback: 5 categories/12 products/15 variants/0 test_users/0 hidden/7 bảng RLS. Đây là SQL role/claim test, chưa thay REST JWT A/B CRUD. Quân xác nhận cả ba máy chạy thành công. Contract/ERD bổ sung trên nhánh docs/replan-delivery-25nov chờ peer review/merge; Actual hours chưa tổng hợp. Giữ mở/In Review, xử lý hồ sơ còn thiếu trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

Contract/ERD, data catalog và báo cáo cloud đã được Hải review qua PR16. SQL/RLS foundation cloud và guest REST đã đạt; ca REST JWT A/B đầy đủ vẫn cần chạy theo DoD, chưa đổi thành Passed.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


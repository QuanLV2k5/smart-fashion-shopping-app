# Rà soát Sprint 1 — snapshot và mẫu biên bản

Ngày chuẩn bị 11/11/2026, **Pending Review**. Đây là snapshot repository và mẫu để nhóm ghi cuộc họp thật; không tuyên bố đã tổ chức Sprint Review/retro. Liên quan [P01 #9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9), [H03 #6](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6), [P03 #8](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8).

## Đầu vào rà soát

- Sprint 1 theo [kế hoạch R3](../planning/Ke-hoach-do-an-04-11-den-01-12-2026.md): 04–10/11, review dự kiến 10/11; ngày họp thực tế chưa cung cấp.
- [Snapshot Git/Issue, evidence và giới hạn](../testing/p01-verification.md), [matrix](../testing/test-matrix.md), [DoD dự thảo](definition-of-done.md), [Planning Poker](planning-poker-sprint-1.md).
- Main f64bfc9 có Auth/Catalog/Product/Cart, chưa có Profile/Addresses. PR #11 và #12 vẫn mở/chưa merge; không báo mọi luồng đã tích hợp.

## Bảng đối chiếu công việc — không thay kết luận AC

| Issue | Trạng thái GitHub đọc ngày 11/11 | Nội dung cần nhóm xác nhận |
| --- | --- | --- |
| [#1 Q01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/1) | Closed | Link charter/scope/WBS/phê duyệt thật; docs/management chưa có các artifact này trên main đã đọc |
| [#2 Q02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/2) | Open | Ba máy setup, permissions/Projects, required reviews/checks và CI hiện hành |
| [#3 Q03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3) | Open | Seed/schema live, RLS API A/B, handoff và phản hồi hai thành viên; không đếm trùng H03 |
| [#4 H01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/4) | Closed | Issue đóng nhưng PR #11 chưa merge; cần đối chiếu căn cứ đóng và tiến độ tích hợp |
| [#5 H02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/5) | Open | Catalog baseline có code/tests; đối chiếu AC với backend và build mục tiêu, không coi baseline là toàn bộ công việc Hải đã nghiệm thu |
| [#6 H03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6) | Open | Báo cáo kiểm thử build/commit thật; bug owner và review backend; tách khỏi ERD/README/CI Q03 |
| [#7 P02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7) | Open | PR #12 mở; Edge CRUD/F5/isolation đã báo; API RLS trực tiếp và review Account/router còn thiếu |
| [#8 P03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8) | Open | Test report, retro thật, risk snapshot và số liệu carryover; không bịa đủ 9/9 |
| [#9 P01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9) | Open | Bộ tài liệu đã soạn, chưa có review ba người cho DoD/UI/data |

Số Issue đóng trong snapshot: 2/9, **không phải** 2/9 AC đạt hoặc số task nghiệm thu. Nhánh fix/sprint1-demo-integration đã ghép H01/P02 nhưng chưa merge vào main; báo cáo nhánh đó không thay kết quả tại main.

## Mẫu ghi cuộc họp thật

| Trường | Nội dung |
| --- | --- |
| Ngày/giờ/kênh/người điều phối | Pending Review |
| Người tham dự thật / người ghi | Pending Review |
| Commit/build/thiết bị/môi trường demo | Pending Review |
| Chức năng demo và Test ID đã chạy | Pending Review; dẫn evidence thay vì chỉ nói chạy tốt |
| Phản hồi stakeholder / link xác nhận | Pending Review |
| AC chấp nhận/chưa chấp nhận, người quyết định | Pending Review |
| Link biên bản/ảnh đã che dữ liệu nhạy cảm | Pending Review |

## Năng lực và thời gian

| Người | Planned hours Sprint 1 | Actual hours tự xác nhận | Chênh lệch/lý do |
| --- | --- | --- | --- |
| Quân | 8 | Chưa cung cấp | Pending Review |
| Hải | 8,5 | Chưa cung cấp | Pending Review |
| Phúc | 8,5 | Chưa cung cấp | Pending Review |

Không suy Actual = Planned, không chia giờ đều hoặc gán số giờ từ test count/commit count.

## Blocker, carryover và risk để nhóm xử lý

| Mục | Tác động | Đề nghị phối hợp, chưa phải giao việc | Chủ/hạn/quyết định |
| --- | --- | --- | --- |
| H01/P02/integration chưa vào main | Chưa nghiệm thu toàn tuyến trên main | Quân điều phối merge; Hải/Phúc review Account/router | Pending Review |
| RLS API trực tiếp chưa kiểm chứng | UI isolation chưa đủ chứng minh quyền CRUD | Quân xác nhận test environment; nhóm chạy RLS-01..07 | Pending Review |
| Chưa có review DoD/UI/data/Poker | P01 chưa đủ AC2 | Quân + Hải phản hồi bản dự thảo | Pending Review |
| Issue closed lệch trạng thái PR/artifact | Dễ báo sai tiến độ | Nhóm đối chiếu #1/#4, không tự reopen/close | Pending Review |
| Thiếu actual hours/meeting evidence | Không tính được variance/retro thật | Mỗi người cung cấp số thật và ngày họp | Pending Review |

Sau review mới điền carryover theo Issue/AC cụ thể; risk phải có ngày snapshot, mức độ/khả năng được nhóm xác nhận và bằng chứng. Các dòng trên là nhận diện để thảo luận, không giả định nhóm đã đánh giá severity hay đồng ý giải pháp.

## Mẫu retro chuyển cho P03

| Điều tốt/cần cải thiện có bằng chứng | Hành động cụ thể | Owner đồng ý | Hạn | Cách xác minh |
| --- | --- | --- | --- | --- |
| Pending Review — chỉ điền sau cuộc họp thật | Pending Review | Pending Review | Pending Review | Pending Review |

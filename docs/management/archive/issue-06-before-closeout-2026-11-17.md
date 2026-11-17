# Snapshot Issue #6: [H03] Kiểm thử Auth/Profile và Catalog, review chéo

Source: https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6
Captured: 17/11/2026, before checklist simplification.

Mục tiêu

Tổng hợp kiểm thử các module của Hải và review nền tảng do Quân thực hiện.

## Phụ thuộc

Q02 cung cấp nền tảng; H01/H02 có chức năng chạy được; P01 có test matrix.

## Công việc

- [x] Tổng hợp test tăng dần đã thực hiện trong H01/H02: auth, hồ sơ, quyền truy cập, tìm/lọc, biến thể và empty/error.
- [x] Kiểm tra lại lỗi sau sửa; ghi expected/actual/result và commit tương ứng.
- [x] Review PR nền tảng và phần tích hợp của Quân; kiểm tra schema/config và CI phù hợp.

## Tiêu chí chấp nhận

- [x] Có báo cáo auth/catalog; lỗi còn lại có Issue/owner.
- [x] Kết quả test gắn bản build và phản ánh thực tế, không ghi pass khi chưa chạy.
- [x] Có liên kết review PR Quân; test rủi ro backend được phối hợp với Q03.
- [x] ERD/README/CI hoàn thiện thuộc Q03; H03 chỉ tổng hợp test Auth/Catalog và review, không tính trùng.

## Điều kiện hoàn thành

- [x] Acceptance criteria đạt; có review và CI/test phù hợp.
- [x] Actual hours và evidence cập nhật.


## Đối chiếu 17/11/2026

PR #15 đã merge, Phúc approve. Kiểm kê 17/11 phát hiện bảng đếm test và review trong báo cáo cần hiệu chỉnh: Auth 14, Profile 20, Catalog 16, các nhóm còn lại 81; tổng 131. PR #10: Hải/Phúc approve 11/11; API PR #13 chỉ có approval Phúc, không có bằng chứng Hải approve PR này. Bản hiệu chỉnh giữ lịch sử, trên nhánh docs/replan-delivery-25nov chờ peer review. Main 5dc2b77 chạy lại 131/131 test, analyzer/format đạt. Actual hours chưa tổng hợp; giữ mở/In Review, hoàn tất hồ sơ trước 18/11.

Đối chiếu #10, #13, #14, #15. Hồ sơ bổ sung và kế hoạch R4 trên nhánh docs/replan-delivery-25nov, chờ peer review/merge.


## Cập nhật sau merge PR #16 — 17/11/2026

Bảng đếm 131 test, ngày review PR10 và reviewer PR13 đã được hiệu chỉnh trong PR16, Hải approve tại HEAD 15f9198 và đã merge. Report ghi rõ SQL/mock/REST và các gap backend còn nằm ở #3/#7/#8/#9; không coi gap chưa chạy là Passed. Phần báo cáo/review của H03 đủ bằng chứng, đối chiếu CI main trước Done.

- Main đã pull trên máy Quân: c30d3f36f01436403f3deec4e9cae29b3d4f3adf; giữ nguyên commit a504ba1 của Phúc.
- Hải approve PR #16 tại HEAD 15f9198: https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432 . PR #16 và #14 đều Merged.
- CI main: https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518 ; chỉ chốt khi kết quả đạt. Flutter/dependency/migration không đổi so với bản đã kiểm tra 131/131 test ngày 17/11.
- Quân xác nhận trong chat 17/11: Quân 8h, Hải 8h, Phúc 8h thực tế toàn Sprint 1, tổng 24h (ước nhớ hồi cứu). Đây là số tổng từng người; không phân bổ giả vào Actual hours từng Issue, các ô số theo Issue còn để trống. Không phải Story Points.


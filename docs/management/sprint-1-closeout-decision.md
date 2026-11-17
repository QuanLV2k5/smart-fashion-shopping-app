# Quyết định đơn giản hóa hồ sơ chốt Sprint 1 — 17/11/2026

## Căn cứ và hiệu lực

Quân yêu cầu trong chat ngày 17/11: đơn giản hóa Issue, dùng bằng chứng công việc/app đã chạy, hướng dẫn phần cần thành viên thao tác và hoàn thiện hồ sơ S1. Quyết định này điều chỉnh **cách nghiệm thu nội bộ S1**, giữ nguyên phạm vi chức năng R4 và hạn app đầy đủ 25/11. Bản cập nhật cần Hải review và CI đạt trước khi merge; không bỏ bảo vệ main.

AC cũ được lưu nguyên văn trong [archive](archive/issue-01-before-closeout-2026-11-17.md), mỗi Issue có một file. Bản mới ghi rõ đầu ra đã đạt và phần chuyển tiếp; không mô tả AC cũ chưa đạt thành đã đạt. Chữ ký giảng viên, kiểm thử bổ sung và Planning Poker không được giả lập để lấp hồ sơ.

## Quy tắc nghiệm thu S1 thay thế phần còn tranh luận của DoD v1

1. Chỉ cần 3 xác nhận trong Issue: đầu ra S1 có trên main; evidence truy cập được và ghi đúng loại/ngày/build; được peer review và có CI đạt. Tổng giờ 8h/người đã do Quân xác nhận, không bắt tự chia giờ giả theo từng Issue.
2. Kiểm chứng phân quyền S1 dùng **SQL/RLS chạy thật trên cloud với anon/A/B/admin trong BEGIN/ROLLBACK**, catalog REST guest, cùng test domain/widget/repository và xác nhận chạy app của người dùng. Đây là phương pháp nghiệm thu S1 được đề nghị thay yêu cầu mọi ca phải là REST JWT trong DoD v1; không thay chính sách RLS, quyền hay mã bảo mật.
3. REST JWT A/B đủ CRUD, mất mạng/phiên ở tình huống phức tạp và hồi quy toàn tuyến vẫn ở **#21**, phải có kết quả trước release #22. Không đánh dấu các ca này Passed; có rủi ro phần Auth/Data API trên đường HTTP chưa được bộ SQL trực tiếp phủ hết. Nếu phát hiện lỗi quyền/giá/dữ liệu thật, phải sửa ngay, không dùng quyết định này để bỏ qua Failed.
4. Charter/scope/WBS S1 nghiệm thu **bản bàn giao nội bộ** và trạng thái đã gửi, không phải Signed Charter. Quân xác nhận đã gửi giảng viên, chưa cung cấp phản hồi. Theo dõi phê duyệt ở **#23**, vẫn mở đến khi có kết quả thật. Không tự coi điều chỉnh nội bộ là Approved Scope Change của giảng viên.
5. Retro ngày 13/11 do Quân xác nhận. Nội dung hồi cứu không phải lời phát biểu ghi tại cuộc họp. Ba cải tiến đề xuất áp dụng từ 17/11 được nhóm xác nhận ở #23: cập nhật main trước PR, giữ regression Profile, evidence theo SHA/build.
6. Không có dữ liệu Planning Poker/SP S1 được cung cấp: ghi **không có dữ liệu**, không dựng velocity/burndown. S2 thống nhất ước lượng hiện tại qua #23; không backdate một cuộc họp S1.

## Checklist thống nhất cho 9 Issue

| Issue | Bàn giao được nghiệm thu nội bộ | Evidence chính | Phần chuyển tiếp được giữ |
|---|---|---|---|
| #1 Q01 | Charter/scope/WBS và R4, trạng thái đã gửi giảng viên | project-charter.md, scope-baseline.md, wbs.md; Quân xác nhận 17/11; review PR16 | Phê duyệt ngoài nhóm, nội dung cải tiến và ước lượng hiện tại: #23 |
| #2 Q02 | Scaffold/config/migration/CI/contracts, ba máy chạy và Project mở được | README, architecture/contracts.md, PR10/16, CI main; Quân xác nhận ba máy và quyền Project | Hồi quy bổ sung #21 |
| #3 Q03 | Data catalog/model/seed và kiểm tra quyền SQL cloud | SQL foundation, REST catalog, unit tests, PR10/16 | REST JWT sâu: #21 |
| #4 H01 | Auth/Profile, preset/reset avatar, guard và lỗi đã sửa | PR11→13, regression, CI, xác nhận signup/Android | REST JWT/mạng nâng cao #21; không gọi preset là upload |
| #5 H02 | Catalog/tìm-lọc/biến thể/chi tiết nối giỏ | PR10/13/15/16, catalog tests/ảnh, Android | Hồi quy bản tích hợp #21 |
| #6 H03 | Test report đã sửa số đếm/ngày/reviewer và review chéo | h03-auth-catalog-test-report.md, CI/reviews thật | Ghi gap trong matrix và #21 |
| #7 P02 | Giỏ/địa chỉ, tổng/biến thể/tài khoản, RPC idempotency | PR12→13, 67 test cart/address, SQL cart+foundation cloud, Android | REST/mạng sâu #21 |
| #8 P03 | Test giỏ, Risk snapshot có phiên bản, ngày Retro và tổng giờ | sprint-1-cart-report.md, retrospective, risk-sprint-1.md; 8h/người | Xác nhận action #23; kiểm thử bổ sung #21 |
| #9 P01 | 42 ca matrix/DoD/UI/data spec, đồng thuận qua PR/merge | Commit Phúc a504ba1, PR14→16, bảng evidence | Không tuyên bố 42/42 Pass; S2 estimates #23, retest #21 |

Đóng Issue S1 sau review/merge nghĩa là đã bàn giao phần S1 theo checklist điều chỉnh này; không phải nghiệm thu toàn ứng dụng hoặc xác nhận mọi ca nâng cao đã chạy. Issue #21/#23 vẫn mở và được liên kết, lịch S1 cũ vẫn giữ để thấy trễ thực tế.

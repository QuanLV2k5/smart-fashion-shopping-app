# Definition of Done — bản dự thảo P01

Trạng thái: **Pending Review**. Phúc soạn ngày 11/11/2026; Quân và Hải chưa xác nhận. Liên quan [Issue #9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9). Không coi tài liệu này là quyết định đã được cả ba phê duyệt.

## Điều kiện chung

- AC phải có mã truy vết trong [test matrix](../testing/test-matrix.md), phạm vi rõ và bằng chứng gắn commit/build, môi trường, người chạy, ngày chạy. Không dùng Planned hours làm Actual hours.
- Code theo [CONTRIBUTING](../../CONTRIBUTING.md), [workflow](../team-workflow.md): Flutter + Riverpod + Supabase, tách domain/data/presentation theo module; UI không tự gọi backend thay repository. Dùng token/component có sẵn, không sao chép logic hoặc sửa contract dùng chung mà thiếu trao đổi với chủ sở hữu.
- Validation tại client và ràng buộc backend phù hợp schema; lỗi theo trường, giữ dữ liệu nhập khi thất bại. Có loading/empty/error/retry; chặn gửi lặp và phản hồi cũ sau logout/đổi tài khoản. Không báo thành công trước khi server xác nhận.
- Không chứa secret, mật khẩu, dữ liệu cá nhân thật, file build hoặc log nhạy cảm trong Git/bằng chứng. Không tin userId/role/giá từ client để cấp quyền hoặc tính tiền backend.

## Kiểm thử và CI

| Phạm vi | Bằng chứng bắt buộc để đề nghị hoàn tất |
| --- | --- |
| Domain/repository/controller thay đổi | Unit test cho quy tắc, lỗi và race/account isolation liên quan; mock không được coi là xác minh RLS thật |
| UI/điều hướng thay đổi | Widget test hành vi chính, lỗi/empty/loading; ảnh hoặc video trên 360/390/430 px, keyboard và chữ lớn phù hợp |
| Luồng nhiều module/backend | Integration hoặc manual có bước tái hiện, commit/build, môi trường; ghi rõ chưa có automated integration nếu đúng |
| RLS | A/B và anon qua API bằng JWT người dùng, đủ SELECT/INSERT/UPDATE/DELETE, kiểm tra cả USING/WITH CHECK; ghi kết quả thật, không dùng service-role làm bằng chứng quyền người dùng |
| Code Flutter | `dart format --output=none --set-exit-if-changed lib test tool`, `flutter analyze --no-pub`, toàn bộ `flutter test --no-pub`; dependency đổi phải resolve lockfile và giải thích |
| Build/CI | Build APK debug/web theo phạm vi và workflow hiện có; CI xanh ở HEAD PR. Không dùng kết quả commit cũ thay kết quả commit mới |
| Chỉ tài liệu | Kiểm tra Markdown, link nội bộ/Issue, bảng và tính nhất quán bằng chứng; build cục bộ có thể ghi N/A kèm lý do. CI repository vẫn chạy theo cấu hình hiện có |

Lỗi test/build không được bỏ qua bằng cách xóa test hoặc nới assertion thiếu lý do. SQL test rollback cũng chỉ chạy ở môi trường được nhóm cho phép; không tắt RLS hoặc tự sửa cloud để làm test đạt.

## Review, bàn giao và merge

1. Tác giả tự rà toàn bộ diff, file mới, phạm vi và dữ liệu nhạy cảm; cập nhật README/handoff/schema contract khi liên quan.
2. PR dùng [mẫu repository](../../.github/pull_request_template.md), `Refs #N`, kết quả kiểm tra thật, ảnh nếu đổi UI, giới hạn và rủi ro; chỉ dùng từ khóa đóng Issue khi đủ AC và review thật.
3. Theo vòng review dự kiến: Hải review Quân, Phúc review Hải, Quân review Phúc; cần ít nhất một thành viên khác approve. Thay đổi Account phối hợp Hải, router/contract/backend phối hợp Quân. Không tự coi im lặng là approval.
4. Chủ repository xác nhận required checks/reviews và giải quyết discussion/conflict trước merge; tác giả không tự xác nhận branch protection đã bật nếu chưa kiểm chứng.
5. Chỉ đề nghị đóng Issue khi mọi AC đạt với evidence, peer review thật và tích hợp vào nhánh đích. Cập nhật Actual hours bằng số thật do người làm xác nhận; ghi carryover rõ nếu chưa đạt.

## Khi còn blocker/chưa kiểm chứng

Giữ trạng thái Planned/Not Run/Blocked/Failed đúng thực tế. Ghi thiếu gì, tác động, người xử lý dự kiến và hạn **Pending Review** nếu chưa được giao; không tự đặt tên người khác thành cam kết. Có thể mở Draft PR để review nhưng không tuyên bố Done. Ngoại lệ/hoãn test cần nhóm ghi quyết định có ngày, người phê duyệt và việc theo dõi; không biến một ngoại lệ thành Passed.

## Phiếu review dự thảo

| Thành viên | Vai trò | Kết quả/ngày/bằng chứng |
| --- | --- | --- |
| Phúc | Người soạn; tự rà | Đã chuẩn bị tài liệu; chưa phải peer approval |
| Quân | Review CI, backend, merge và tính khả thi | Pending Review |
| Hải | Review UI, Auth/Profile và độ phủ test | Pending Review |

# P01 — nguồn, kết quả kiểm tra và bàn giao

Người yêu cầu/soạn: Đinh Công Phúc (DinhCongPhuc). Ngày 11/11/2026, nhánh `feat/p01-testing-dod`, [Issue #9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9). Tài liệu là bản dự thảo chờ Quân/Hải review; không tự khai đã đáp ứng AC yêu cầu cả ba review.

## Mục lục tài liệu P01

- [Test matrix](test-matrix.md): trường hợp, bước, expected, loại, trạng thái và evidence.
- [Definition of Done](../management/definition-of-done.md): tiêu chí code/test/review/bàn giao/merge/blocker.
- [UI dùng chung](../ui/shared-ui-rules.md): token và component hiện có, đối chiếu Figma.
- [Dữ liệu kiểm thử](test-data-spec.md): đặc tả theo schema/seed Q03, không chạy seed.
- [Planning Poker](../management/planning-poker-sprint-1.md): mẫu ghi phiếu thật và capacity.
- [Sprint 1 Review](../management/sprint-1-review-template.md): snapshot và mẫu biên bản/retro/carryover.

## Snapshot Git và GitHub thực đọc

Đầu lượt working tree sạch trên feat/p02-addresses. Đã fetch origin, kiểm tra main bằng origin/main rồi tạo nhánh P01 riêng từ main; không sửa nhánh P02, không merge/rebase nhánh tính năng.

| Ref/PR | Commit/trạng thái đọc được |
| --- | --- |
| main = origin/main = nền P01 | `f64bfc9dbf71945a57caf94d93177e454cb00b57` |
| [PR #11 H01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/11) | Open, không Draft, chưa merged; head `309995b081556d1e0c9273dee86078f113613551`, base main f64bfc9 |
| [PR #12 P02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/12) | Open, không Draft, chưa merged; head `530f5a1a2285e5dc06a9a9df72ac8648363cf16e`, base main f64bfc9 |
| origin/fix/sprint1-demo-integration | `8cb765379f12a6adb7f2b1237c40385e9c1ceab7`; ghép H01/P02, chưa thuộc main; chỉ đọc, không checkout/merge |

GitHub public REST API GET Issues #1–#9 và PR #11/#12 đã đọc ngày trên. [#1](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/1) và [#4](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/4) Closed; [#2](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/2), [#3](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3), [#5](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/5), [#6](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6), [#7](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7), [#8](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8), [#9](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9) Open. Đây là snapshot, không bảo đảm trạng thái không đổi sau thời điểm đọc.

Đã đọc README, CONTRIBUTING, team-workflow, team-handoff, project-overview, design-handoff và tài liệu planning R3/nhật ký điều chỉnh; đối chiếu schema, seed, test hiện có. Issue đóng không tự chứng minh toàn bộ artifact/AC: #4 đã đóng nhưng PR #11 chưa merge; charter/scope/WBS được #1 nhắc chưa thấy ở docs/management của main này. Nhóm cần xác nhận nguồn bằng chứng tương ứng.

## Chức năng có thật tại nền main

| Nhóm | Thực trạng đọc code/test |
| --- | --- |
| Auth | Form đăng ký/login, validation, email confirmation/resend, session/logout/guard; fake/widget và repository tests |
| Catalog | Repository Supabase, domain query, tìm/lọc/sort, Home/Explore, loading/empty/error; fixtures không phải xác nhận dữ liệu cloud |
| Product/Cart | Detail/gallery/size guide, chọn variant, RPC cart, quantity/tổng VND, chống retry ghi trùng và stale response khi đổi tài khoản |
| Profile | Chưa có module H01 trên main; tham khảo PR #11 và báo cáo integration, không coi có trên nền P01 |
| Addresses | Chưa có module P02 trên main; PR #12 và kết quả lịch sử là bằng chứng riêng, không đặt link tương đối tới file không tồn tại |
| Integration | Không có thư mục integration_test trên main; end-to-end còn phải chạy trên build tích hợp được nhóm chấp nhận |

## Danh mục bằng chứng

| ID | Nguồn / kết quả / giới hạn |
| --- | --- |
| E-MAIN | Chạy thật 11/11/2026 tại f64bfc9: `flutter test --no-pub --concurrency 1 --reporter expanded`, exit 0, **60/60 Passed**. TEMP/TMP `D:\CodexTemp\smart-fashion-p02` (tên thư mục có sẵn, không phải nhánh chạy); Flutter 3.47.6/Dart 3.13.5 local, repo CI pin Flutter 3.47.5. Không upgrade SDK. Bằng chứng là stdout phiên công cụ: `+60: All tests passed!`; chưa có URL CI của P01 |
| E-P02 | Lịch sử lượt P02: **109/109** test đã đạt, người dùng cũng xác nhận; branch head 530f5a1. Không chạy lại 109 test trên P01 vì module không có ở main; không suy Passed cho case mới. [Handoff P02 tại commit](https://github.com/QuanLV2k5/smart-fashion-shopping-app/blob/530f5a1a2285e5dc06a9a9df72ac8648363cf16e/docs/p02-addresses-handoff.md) |
| E-EDGE | Phúc báo trước lượt P01: thêm/sửa/xóa địa chỉ thành công, F5 dữ liệu đúng; A/B không thấy địa chỉ nhau, giỏ A không xuất hiện ở B. Microsoft Edge; ngày chạy chính xác, phiên bản Edge, hash build và ảnh chưa cung cấp trong lượt này. Đây là kết quả thủ công do người dùng báo, không phải trợ lý chạy browser, không chứng minh đủ quyền RLS API |
| E-INTEGRATION | [Báo cáo nhánh integration](https://github.com/QuanLV2k5/smart-fashion-shopping-app/blob/8cb765379f12a6adb7f2b1237c40385e9c1ceab7/docs/testing/sprint-1-integration-review.md) ghi 131 tests và build APK/web, sửa profile whitespace/avatar/reset và Account/router. Là kết quả **được báo trong nhánh khác**, không chạy lại tại đây, chưa tích hợp main, không dùng làm CI HEAD P01 hoặc cộng với 60/109 |
| E-FIGMA | MCP metadata đọc thành công SF/Button 3:60 và SF/Input 3:73 ngày 11/11; kích thước/variant ghi trong UI rules. Các 8 frame P02 có đối chiếu lịch sử trước; chưa có bộ ảnh Flutter integrated build mới |
| E-GAP | Không gọi API cloud/seed/SQL trong P01; chưa có môi trường test được nhóm xác nhận, JWT A/B/anon và request evidence. RLS CRUD trực tiếp, security profile/role/cart chưa kiểm chứng trong lượt này |

### Nguồn test tự động tại main

Chạy toàn bộ test/ gồm [app smoke](../../test/app_smoke_test.dart), [config](../../test/core/app_config_test.dart), [VND](../../test/core/money_test.dart); [auth flow](../../test/features/auth/auth_flow_test.dart), [auth repository](../../test/features/auth/supabase_auth_repository_test.dart); [catalog query](../../test/features/catalog/catalog_query_test.dart), [catalog flow](../../test/features/catalog/catalog_flow_test.dart), [catalog repository](../../test/features/catalog/supabase_catalog_repository_test.dart); [cart domain](../../test/features/cart/cart_domain_test.dart), [cart controller](../../test/features/cart/cart_controller_test.dart), [product/cart flow](../../test/features/cart/product_cart_flow_test.dart), [cart repository](../../test/features/cart/supabase_cart_repository_test.dart).

Widget responsive hiện bao gồm 360/390/430 và chữ lớn/bàn phím theo các test cụ thể; không coi là đã kiểm đủ Profile/Addresses hoặc thiết bị thật. SQL/smoke scripts hiện có không được chạy trong P01 vì chạm môi trường backend.

## Đối chiếu Acceptance Criteria Issue #9

| AC theo thứ tự Issue | Artifact / mức đáp ứng | Còn thiếu |
| --- | --- | --- |
| AC1: Matrix có ID, bước, expected, loại test, Issue/AC | test-matrix.md đủ cột, bao phủ module và lỗi/security/account/responsive, tách lịch sử và test mới | Peer review độ phủ; các trường hợp Planned/Blocked chưa chạy |
| AC2: DoD được cả ba review, thực tế với review/CI/test/evidence | definition-of-done.md đã soạn tiêu chí cụ thể và phiếu review | **Chưa hoàn tất AC2**: cần Quân và Hải review thật; không tự đánh dấu cả ba đồng ý |
| AC3: Data có variant/giá/hết hàng, hợp Q03 và UI cơ bản; không giành seed | test-data-spec.md + shared-ui-rules.md dựa schema/seed/theme/Figma metadata; không tạo seed/code UI mới | Quân xác nhận dataset/test environment, Hải xác nhận UI; hai màu cùng sản phẩm chưa có seed live |

Các mục công việc kèm Issue: mẫu Planning Poker và Sprint Review đã chuẩn bị; chưa có phiếu/cuộc họp/đồng thuận, actual hours hoặc stakeholder acceptance mới. Phần DoD của Issue còn yêu cầu PR/CI/reviewer/evidence và actual hours: chưa PR/CI P01, chưa approval, actual chưa cung cấp. Không đề nghị đóng #9 lúc này.

## Kiểm tra tài liệu lượt này

Kiểm tra thực tế 11/11/2026:

- 7 file Markdown mới, 160 link: link tương đối trỏ file tồn tại; URL Issue/PR khớp repository và snapshot API đã đọc. Không tuyên bố đã HTTP-check toàn bộ URL ngoài (Figma/permalink).
- 42 Test ID duy nhất, đủ 10 cột, loại/trạng thái hợp lệ, không ô trống; 18 Passed (16 baseline tự động + 2 báo cáo Edge), 10 Blocked, 6 Not Run, 8 Planned. Không phải 42 test Flutter.
- Kiểm tra bảng, code fence, trailing whitespace/final newline và `git diff --no-index --check` trên **từng file mới** sạch. `git diff --check` trên tracked diff cũng sạch; tracked diff rỗng nên riêng lệnh này không đủ kiểm tra file untracked.
- Rà nội dung và pattern GitHub token/JWT/private key/Supabase secret không phát hiện credential thật; fixture địa chỉ là dữ liệu tổng hợp. Không có build/log/ảnh cá nhân trong danh sách thay đổi.
- Chỉ 7 file docs mới; chưa stage/commit/push/tạo PR, không chạm cloud. Không sửa lib/test/pubspec/migration/workflow.

Không chạy format/analyze/build Flutter mới cho thay đổi chỉ Markdown. Kết quả baseline **60/60 test** E-MAIN ở trên không thay CI sẽ chạy khi được phép tạo PR. Kiểm tra Markdown bằng Python stdlib và Git tại workspace, không cài dependency/linter mới; chưa có bằng chứng render thủ công mọi trang trên GitHub.

## Nội dung đề xuất để người dùng duyệt

Commit message: `docs(p01): add Sprint 1 test matrix and draft definition of done`

PR title: `docs(P01): test matrix, DoD, UI rules and test data specification`

PR body theo mẫu repository (chưa tạo PR):

```markdown
## Thay đổi

Refs #9

Thêm matrix truy vết AC và evidence; DoD dự thảo; quy tắc UI theo component hiện có;
đặc tả dữ liệu Q03; mẫu Planning Poker/Sprint Review. Tách kết quả main 60 test,
P02 lịch sử 109 test, báo cáo Edge và nhánh integration; không thay code/seed/cloud.

## Kiểm tra

- Dependency không đổi; pub get --enforce-lockfile: N/A cho tài liệu.
- Kiểm tra Markdown/link/ID/status và git diff --check: xem kết quả cuối p01-verification.md.
- Baseline flutter test --no-pub --concurrency 1 --reporter expanded: 60/60, main f64bfc9.
- Format/analyze/build cục bộ không chạy lại: chỉ Markdown; không thay thế required CI.
- CI HEAD PR và peer approval: chờ tạo PR sau khi được phép.
- Ảnh UI mới: N/A, không đổi UI; evidence không chứa token/mật khẩu.

## Tích hợp

- Account/router không sửa. Quân review CI/backend/data; Hải review UI/Auth/Profile.
- Không migration hoặc cloud changes; không tích hợp PR #11/#12 trong P01.
- DoD/UI/data cần Quân/Hải review; RLS API thật và end-to-end integrated build chưa kiểm chứng.
- Planning Poker/Review/Actual hours còn Pending Review; không coi planned hours là actual.
- Chưa đủ AC2 để đóng #9; đề nghị review dự thảo, không tự merge/đóng Issue.
```

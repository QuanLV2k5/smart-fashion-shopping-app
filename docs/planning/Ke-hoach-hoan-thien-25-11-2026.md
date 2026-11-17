# Kế hoạch R4 — hoàn thiện ứng dụng ngày 25/11/2026

Đề tài: **Xây dựng ứng dụng mua sắm thời trang thông minh**. Nhóm 05 — StyleAI.
Ngày lập: **17/11/2026**. Người yêu cầu điều chỉnh: Lê Văn Quân, qua trao đổi Codex.
Mốc bắt buộc nội bộ: **25/11 hoàn thiện đầy đủ ứng dụng trong phạm vi đã thống nhất**.
Đây là quyết định lịch thực hiện của nhóm; không thay cho phê duyệt của giảng viên hoặc UAT.

## 1. Cơ sở và tình trạng đầu kỳ

- Giữ [R3](Ke-hoach-do-an-04-11-den-01-12-2026.md), lịch milestone cũ và báo cáo ngày 15/11 làm lịch sử; không sửa ngược ngày hoàn thành.
- WBS báo cáo ngày 15/11 có **14 work package thuộc 6 nhóm sản phẩm, 48 task**, tổng forecast 121 giờ và 24 giờ dự phòng. Các mã Q/H/P dưới đây là task, không phải 48 work package.
- Main tại lần kiểm kê: `5dc2b77`, sau PR #10, #13, #15; PR #11/#12 đã được tích hợp và giữ commit tác giả. PR #14 của Phúc còn Draft.
- Đã có Auth/Profile, catalog/tìm-lọc/chi tiết/biến thể, giỏ và sổ địa chỉ. Quân xác nhận ngày 17/11: cả ba chạy được app trên máy riêng, Retro đã họp ngày 13/11.
- Chạy lại ngày 17/11: **131 test đạt**, analyzer không lỗi, format 81 file/0 thay đổi. Catalog cloud SF01+SF02 = 448.000đ; SQL/RLS foundation trên cloud đạt với BEGIN/ROLLBACK. Đây không phải bằng chứng hoàn thành checkout/AI/admin hoặc REST A/B bằng JWT thật.
- S2 cũ 11–17/11 chưa có Issue triển khai tính năng hoặc PR chức năng trên remote tại snapshot. Ghi nhận trễ, chuyển phần chưa làm sang lịch phục hồi dưới đây.

## 2. Lịch bốn sprint sau điều chỉnh

| Sprint | Baseline cũ | Lịch thực hiện/cổng bàn giao mới | Kết quả bắt buộc |
|---|---|---|---|
| S1 Foundation | 04–10/11 | Review bổ sung 11–17/11; xử lý hồ sơ còn thiếu trước 18/11 | Bản nền đã tích hợp; AC/evidence đúng; hoàn tất review P01 và dữ liệu giờ/Retro còn chờ |
| S2 Core Workflows | 11–17/11 | **18–21/11** | AI, admin sản phẩm/danh mục/ảnh/biến thể, cache, COD/đơn/admin đơn, yêu thích/đánh giá, quản lý người dùng có bản chạy tích hợp |
| S3 Integration & UAT readiness | 18–24/11 | **22–23/11** | Tích hợp toàn bộ phạm vi, thống kê, audit quyền, regression, APK pilot và kịch bản UAT |
| S4 Release & UAT | 25–30/11 | **24–25/11** | UAT, sửa/retest lỗi chặn, release Android và web dùng trên iPhone, bàn giao ngày 25/11 |

Ngày 26–29/11 dành cho hoàn chỉnh hồ sơ/hướng dẫn/diễn tập và nộp môn mobile trước 30/11. Không lấy các ngày này làm phần thời gian dự kiến phát triển chức năng còn thiếu. Giới hạn iOS: hiện chạy web trên iPhone; chưa có Mac để build iOS native.

## 3. Phạm vi và phân công không bỏ sót

Mỗi người làm **UI theo Figma + domain/state + repository/backend + test/handoff** cho phần mình. Quân phối hợp contract và migration, không viết thay toàn bộ phần của hai bạn.

| Gói / task R3 | Người chính / review | Hạn | Tiêu chí bàn giao |
|---|---|---|---|
| Q04/Q05 — AI Edge Function và UI | Quân / Hải | 20/11, tích hợp 21/11 | Nhập dịp/phong cách/ngân sách → Gemini thật → ID catalog hợp lệ/giá trong ngân sách → chi tiết/chọn biến thể/giỏ; đổi món/điều chỉnh nhu cầu; lỗi quota/timeout/no match. Secret chỉ ở server. Fallback phải ghi nhãn |
| Q06/Q08 — người dùng, yêu thích, đánh giá | Quân / Hải, Phúc kiểm thử điều kiện mua | 21/11 | Yêu thích tách tài khoản; danh sách/đánh giá sản phẩm; chỉ người có sản phẩm trong đơn hoàn tất được đánh giá; admin xem/quản lý trạng thái truy cập qua server, không tự nâng quyền |
| H04 — admin catalog/Storage | Hải / Quân | 20/11, tích hợp 21/11 | CRUD danh mục, thêm/sửa/ẩn sản phẩm, ảnh Storage, size/màu/tồn kho; phân quyền server; không xóa lịch sử sản phẩm đã đặt |
| H05/H06 — cache và audit catalog | Hải / Phúc | 21/11 | Catalog lưu bền, mở lại offline xem được snapshot có thời điểm; chưa có cache báo đúng; online refresh; kiểm tra lỗi và quyền Storage |
| P04/P05/P06 — COD và đơn | Phúc / Quân | RPC 19/11; UI/flow 21/11 | Transaction tính lại giá/stock/ship trên server, snapshot sản phẩm/địa chỉ, idempotency; checkout → thành công → lịch sử/chi tiết/timeline; customer chỉ xem đơn mình; admin chuyển trạng thái hợp lệ |
| P10 — thống kê admin | Phúc / Hải | 22/11 | Số đơn/tổng theo trạng thái và tổng giá trị đơn hoàn tất khớp dữ liệu; không gọi là doanh thu thực thu khi chưa có nghiệp vụ xác nhận |
| Q09/H08/H09/P08 — tích hợp và regression | Cả ba theo module; Phúc tổng hợp | 22–23/11 | Ba luồng mua/AI/admin cùng một build; kiểm thử quyền, giá, biến thể, stock, retry, đổi phiên và offline. Xử lý placeholder/nút chưa hoạt động trong phạm vi |
| H10/P09 — pilot và chuẩn bị UAT | Hải phát hành, Phúc QA, Quân phối hợp người thử | 23/11 | APK pilot cài mới; web trên iPhone thử thật; ít nhất 3 người dùng mục tiêu được mời theo Charter; kịch bản/build/dữ liệu rõ |
| Q12/H12/P12/P14 — UAT/sửa lỗi | Cả ba theo module; Phúc điều phối | 24–25/11 | UAT có người thử/ngày/build/kết quả thật; mọi lỗi chặn sửa và retest; sign-off ghi đúng có/chưa có |
| H15/H16/Q15/P15 — phát hành và demo | Hải build; Phúc smoke/video; Quân kiểm tra | 25/11 | APK release, web, tag/SHA, config mẫu/README; demo mua 473.000đ, AI 448.000đ, admin; video dự phòng từ bản chạy thật |

Onboarding nếu có giữ gọn/có bỏ qua; bảng hướng dẫn size có trong chi tiết. Avatar hiện có preset. Nếu UI bàn giao cam kết upload ảnh cá nhân thì phải có picker/Storage và test quyền tương ứng trước khóa phạm vi; không gọi preset là upload.

Ngoài phạm vi giữ nguyên: AR/thử đồ ảo, tìm bằng ảnh/quét nhãn, đo cơ thể AI, thanh toán online, vận chuyển tích hợp, multivendor, dashboard web riêng, dark mode toàn bộ. Không tự thêm lịch sử chat/lưu outfit. Brief Figma chỉ quy định thiết kế/prototype; không lấy tương tác mô phỏng làm kết quả backend thật.

## 4. Các mốc hằng ngày

| Ngày | Quân | Hải | Phúc | Cổng chung cuối ngày |
|---|---|---|---|---|
| 17/11 | Kiểm kê S1, kế hoạch R4/contract | Review tài liệu P01 và phần UI liên quan | Xác nhận hồ sơ P01/Retro/giờ | Không tính Issue chưa đủ DoD là Done |
| 18/11 | Chốt schema AI/favorite/review và contract user admin | Bắt đầu admin catalog/ảnh, review schema | Chốt schema/RPC đơn và trạng thái | Một người quản lý thứ tự migration; không sửa cloud chồng nhau |
| 19/11 | Edge Function gọi Gemini thật | Admin thêm/sửa sản phẩm/biến thể | RPC COD và test transaction/idempotency | Backend AI/COD có bằng chứng chạy thật |
| 20/11 | UI AI → sản phẩm/giỏ | Admin danh mục/ảnh/ẩn; nối store | Checkout/đơn khách và admin trạng thái | PR các luồng chính sẵn sàng review |
| 21/11 | Yêu thích/đánh giá và admin người dùng | Cache/offline + retest Storage | Kết thúc order flow; test adverse cases | Đủ tính năng bản đầu, không còn module chỉ là placeholder |
| 22/11 | Test AI/ngân sách/roles/review conditions | Tích hợp catalog/admin/cache; audit bảo mật | Thống kê + regression giỏ/đơn | Mọi phạm vi có bằng chứng và owner lỗi |
| 23/11 | Hỗ trợ pilot và rà các chức năng còn thiếu | APK pilot + web; thử cài mới | Chạy toàn tuyến, chuẩn bị UAT | Pilot đủ mua/AI/admin; khóa thêm chức năng mới |
| 24/11 | UAT và sửa lỗi phần Quân | UAT và sửa lỗi phần Hải | Điều phối UAT/sửa lỗi phần Phúc | Không còn lỗi chặn chưa có bản sửa |
| 25/11 | Retest/đối chiếu scope và bàn giao | Build/tag release, README | Smoke trên thiết bị, video/evidence | Release đủ phạm vi + kết quả kiểm chứng; công bố lỗi còn lại nếu có |

## 5. Cách phối hợp để tránh xung đột

- Hải review Quân; Quân review Phúc; Phúc review Hải. Mỗi PR nhỏ gắn Issue và ảnh/test phù hợp, cần ít nhất 1 approval người khác và CI `check-and-build` đạt trên HEAD.
- Nhánh bắt đầu từ main mới nhất; PR thông thường trong ngày, không giữ nhánh lớn đến 23/11. Không push trực tiếp main/force-push hoặc tắt rule để kịp lịch. Dùng Create a merge commit để giữ tác giả/commit gốc.
- Router, theme/model/contract chung: báo rõ trong PR, người thay sau cập nhật main rồi xử lý thủ công. Không thay cả file bằng ours/theirs.
- Mỗi migration có mã thời gian riêng, review SQL trước khi áp dụng. Cloud dev đã có migration thủ công; phải baseline lịch sử CLI trước deploy CLI. Không chạy lại migration tạo bảng cũ.
- Không chia sẻ secret/service-role/Gemini key trong chat/Git/Flutter. SMTP riêng chưa có: thử email chủ tổ chức hoặc cấu hình SMTP trước khi nghiệm thu đăng ký nhiều email thật; không ghi đã hỗ trợ mọi email nếu chưa kiểm chứng.

## 6. Công suất và rủi ro lịch

Đây là lịch phục hồi 8 ngày, không phải bằng chứng chắc chắn sẽ xong. Forecast còn lại để cả nhóm rà mỗi tối: Quân khoảng **28–34h**, Hải **26–32h**, Phúc **28–34h** gồm test/review/tích hợp; cần khoảng 3,5–4,25h/người/ngày trong 18–25/11. Đây là dự báo mới, **không cộng thành actual**, không dùng lại toàn bộ 121h R3 như effort còn lại. Phần dự phòng R3 chỉ dùng theo khả năng thực tế, tránh tính hai lần trong forecast.

Nếu backend AI hoặc COD chưa chạy thật hết 19/11, hoặc bản đầu chưa đủ tính năng hết 21/11: ghi ngay lỗi/người xử lý, ưu tiên sửa tích hợp và chia lại task trong nhóm. Không âm thầm bỏ cache/yêu thích/đánh giá/admin người dùng. Nếu công suất thực tế không đủ, Quân cần báo lại mốc/phạm vi cho người quyết định; không ghi Done thay cho sản phẩm thiếu.

## 7. Điều kiện hoàn thiện ngày 25/11

- Mua: login → tìm/lọc → variant → giỏ/địa chỉ → COD → đơn khách → admin cập nhật → đánh giá sau hoàn tất.
- AI: nhu cầu casual/đi chơi/500.000đ → kết quả catalog hợp lệ → chọn đủ variant → thêm giỏ; có nhánh lỗi/quota/no match.
- Admin: dashboard/thống kê → danh mục/sản phẩm/ảnh/stock/ẩn → đơn/trạng thái → người dùng. Customer bị chặn ở backend.
- Yêu thích, cache offline, validation/loading/empty/error/back/retry chạy thật; checkout/AI offline không báo thành công.
- Toàn bộ test core pass, không còn lỗi nghiêm trọng quyền/giá/tồn kho hoặc crash/chặn luồng; UAT và release smoke có build/ngày/kết quả.
- APK Android + web chạy trên iPhone có hướng dẫn; native iOS chưa xác minh phải ghi rõ. Tag/SHA và tài liệu khớp bản bàn giao.
- Issue chỉ Done khi đạt AC, review/CI/evidence và DoD. Actual hours/SP chưa có thì để trống, ghi thiếu; không biến throughput PR thành velocity SP.

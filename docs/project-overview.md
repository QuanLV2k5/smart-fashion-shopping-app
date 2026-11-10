# Đồ án Smart Fashion đang làm gì

Tài liệu này nối yêu cầu trong `SmartFashion-Planning` với code hiện tại.
Đọc tài liệu này trước khi đọc từng file Dart. Đây là mô tả phạm vi và trạng
thái, không phải biên bản nghiệm thu hoặc bằng chứng mọi chức năng đã xong.

## Hai thư mục trong CodexProjects

| Thư mục | Dùng để làm gì |
|---|---|
| `SmartFashion-Planning/` | Nguồn gốc brief/kế hoạch trên máy Quân; bản R3/brief được copy vào docs/planning để clone đọc được |
| `smart-fashion-shopping-app/` | Mã Flutter có thể chạy, test, cấu hình build và tài liệu kỹ thuật |

Trong thư mục kế hoạch, bản tháng và nhật ký R3 ngày 04/11/2026 là bản phân
công/ước lượng hiện hành. `history/` giữ các bản trước để so sánh. Brief
`Prompt-Figma-Smart-Fashion.md` mô tả phạm vi UI/prototype mới hơn các ví dụ
prototype cũ. Không lấy số giờ hoặc phân công cũ trong `history/` để ghi đè R3.

Đồ án dùng chung cho hai môn tại VKU: Phát triển ứng dụng di động đa nền tảng
và Quản trị dự án phần mềm. Nhóm gồm Quân, Hải, Phúc. Hạn nộp do nhóm cung
cấp là 01/12/2026; đó không mặc nhiên là ngày bảo vệ.

## Sản phẩm cần đạt

Một ứng dụng mua sắm thời trang cho người Việt 18–30 tuổi. Khách hàng và
admin dùng cùng app; thao tác hiển thị và dữ liệu được giới hạn theo quyền.

| Nhóm | Việc người dùng phải làm được |
|---|---|
| Tài khoản | Đăng ký, đăng nhập email/password, đăng xuất, sửa hồ sơ |
| Catalog | Xem, tìm/lọc, mở chi tiết, chọn size/màu còn hàng |
| Mua hàng | Giỏ riêng theo tài khoản/biến thể, địa chỉ, đặt COD, xem đơn |
| AI | Nhập dịp/phong cách/ngân sách, nhận sản phẩm có thật trong catalog |
| Cá nhân hóa | Yêu thích; đánh giá sản phẩm sau đơn hoàn tất |
| Admin mobile | Sản phẩm, danh mục, tồn kho, đơn, người dùng, thống kê cơ bản |
| Ngoại tuyến | Xem snapshot đã lưu; cần mạng để đặt hàng hoặc gọi AI |

Bộ demo phải khớp: áo 199.000đ + jeans 249.000đ = 448.000đ; phí giao hàng
25.000đ; COD 473.000đ. Giá trong code dùng số nguyên VNĐ.

Phạm vi này chưa gồm AR, tìm bằng ảnh, quét nhãn, AI đo cơ thể, thanh toán
online, ứng dụng người bán riêng, dashboard web riêng hoặc toàn bộ dark mode.
Web trong repository hiện dùng để preview và thử giao diện.

## Công nghệ và trách nhiệm

| Thành phần | Cách giải thích khi trình bày |
|---|---|
| Flutter + Dart | Viết phần lớn giao diện và xử lý dùng chung cho các nền tảng |
| Riverpod | Quản lý trạng thái tải/lỗi/dữ liệu và cấp đối tượng cho các màn |
| GoRouter | Chuyển màn hình và quản lý đường dẫn điều hướng |
| Supabase | Dịch vụ Auth, PostgreSQL, lưu ảnh và chạy Edge Functions |
| Gemini | Gợi ý phối đồ; sau này được gọi qua Edge Function |
| SharedPreferencesAsync | Lưu thiết lập/snapshot nhỏ trên từng thiết bị |
| Figma | Nguồn thiết kế để triển khai và so sánh giao diện |
| GitHub | Mã nguồn, Issue/PR, CI và bằng chứng quá trình làm việc |

Riverpod không phải database. GoRouter không lưu giỏ hàng. SharedPreferences
không thay database đơn hàng. Supabase vẫn cần schema, phân quyền và kiểm
thử thật; thêm dependency chưa có nghĩa backend đã hoạt động.

## Phân công theo kế hoạch R3

| Thành viên | Phần chính |
|---|---|
| Quân | Nền tảng, model/contract/data catalog, AI, admin người dùng, yêu thích/đánh giá |
| Hải | Auth/Profile, presentation catalog, admin sản phẩm/danh mục/biến thể, cache/tích hợp |
| Phúc | Giỏ/địa chỉ, đơn khách/admin, thống kê, QA/UAT và tổng hợp bằng chứng |

Đây là cách đọc lại kế hoạch hiện có, không thay assignee hoặc estimate trên
GitHub. Phần đánh giá cần phối hợp với đơn hàng của Phúc để kiểm tra điều kiện.

## Hiện tại đã làm đến đâu

| Phần | Trạng thái thực tế |
|---|---|
| Thiết kế Figma | Đã tạo file/UI/prototype theo brief; tương tác còn preset như handoff |
| Flutter | Android/iOS/web, Auth, Home/Explore, chi tiết/chọn biến thể và giỏ đã có |
| Kiểm tra local | Analyzer và 60 test đạt; xem verification cho build/thiết bị |
| Chạy trên máy bạn | Bạn đã xác nhận chạy bằng lệnh preview thành công |
| Supabase | Cloud dev/schema/RLS/catalog mẫu; Auth UI đã nối SDK, giữ xác nhận email; SMTP riêng chưa có |
| Chức năng sản phẩm | Auth, Home/Explore, chi tiết/gallery/chọn biến thể và giỏ Supabase tăng/giảm/xóa đã code; checkout/đơn, AI, admin, yêu thích/đánh giá và sửa hồ sơ chưa code |
| GitHub | Bàn giao qua nhánh chore/project-setup và PR; trạng thái review/CI xem GitHub và docs/team-handoff.md |
| iPhone native | Chưa build/cài/test; nhóm hiện chỉ có Windows và iPhone |

Vì vậy **Q02 chưa đạt đủ acceptance criteria**, dù phần nền Flutter đã chạy.
Nền Supabase, schema/quyền ban đầu và truy vấn thử đã có bằng chứng ở
`docs/setup-verification.md`. Q02 vẫn còn đưa code lên nhánh chung, review
và CI thật. Q03 đã có model/contract và repository đọc catalog; bàn giao/review,
cache lưu bền và các phần khác của Q03/H02 vẫn cần đối chiếu acceptance criteria.
Không tự đánh dấu các gói này Done. Xem `docs/catalog-walkthrough.md` cho phần vừa triển khai.

Ước lượng 40 / 40,5 / 40,5 giờ trong kế hoạch là dự toán, không phải giờ đã làm.
Thời gian thực tế, review, nghiệm thu và lịch sử commit phải có bằng chứng thật.

## Thứ tự làm tiếp để dễ tích hợp

1. Nắm được code nền và cách chạy trên thiết bị; thống nhất một phiên bản SDK.
2. Đọc nền Supabase/schema/quyền đã setup; hoàn thành bàn giao/PR/CI còn lại của Q02.
3. Chốt model/contract/catalog data ở Q03 để Auth, catalog và giỏ tích hợp cùng dữ liệu.
4. Triển khai từng luồng Figma nhỏ, nối dữ liệu, kiểm tra và review tăng dần.
5. Tích hợp checkout thật, admin, AI/cache theo kế hoạch; kiểm tra phân quyền và lỗi mạng.

Khi chưa có dữ liệu thật, dữ liệu mẫu phải được gọi rõ là dữ liệu mẫu. Prototype
Figma có kết quả preset không chứng minh Gemini hoặc checkout đã chạy thật.

## Nguồn đối chiếu trên máy

Các đường dẫn dưới đây tính từ gốc project Flutter trên máy Quân; thư mục
kế hoạch hiện nằm cạnh repository, chưa được đưa vào repository mã nguồn.

- `../SmartFashion-Planning/Prompt-Figma-Smart-Fashion.md`
- `../SmartFashion-Planning/Ke-hoach-do-an-04-11-den-01-12-2026.md`
- `../SmartFashion-Planning/Nhat-ky-dieu-chinh-uoc-luong-2026-11-04.md`
- `../SmartFashion-Planning/GitHub-Sprint-1/issues/Q02.md` và `Q03.md`
- Các Issue H01–H03, P01–P03 và hướng dẫn GitHub Sprint 1 cùng thư mục.

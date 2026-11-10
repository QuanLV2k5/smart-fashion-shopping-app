# Kế hoạch thực hiện đồ án ứng dụng mua sắm thời trang thông minh

Thời gian thực hiện: 04/11/2026–30/11/2026. Hạn nộp do nhóm cung cấp: 01/12/2026, theo giờ Việt Nam. Mục tiêu nội bộ: kiểm tra đủ hồ sơ ngày 29/11, dành 30/11 để xử lý sự cố và xác nhận bản nộp. Ngày bảo vệ thực tế theo thông báo của giảng viên; chưa coi 01/12 là ngày bảo vệ.

Tài liệu này là kế hoạch đề xuất, chưa phải biên bản đã thực hiện, phê duyệt của giảng viên hay bằng chứng nghiệm thu. Các giờ công là ước lượng ban đầu, phải cập nhật theo năng lực và dữ liệu thực tế.

Điều chỉnh phân công ngày 04/11/2026 theo yêu cầu của Quân: Quân trực tiếp khởi tạo Flutter, Supabase, schema và CI; Hải nhận Auth/Profile. Q01 trên GitHub đã tồn tại tại Issue #1 và được giữ nguyên. Đây là điều chỉnh kế hoạch của nhóm, chưa thay thế phê duyệt học phần của giảng viên.

<!-- UOC-LUONG-R3 -->
Phiên bản ước lượng R3 ngày 04/11/2026: Q01 = 0,5 giờ, Q02 = 1,5 giờ theo đánh giá của Quân; tổng 2 giờ cho khởi tạo. Phạm vi hoàn thiện được tách minh bạch sang các gói tiếp nối. Quân nhận thêm Data repository catalog trong Q03 từ phần catalog của Hải. Dự toán toàn dự án: Quân 40 giờ, Hải 40,5 giờ, Phúc 40,5 giờ; tổng 121 giờ, chưa gồm 8 giờ dự phòng/người. Chưa có dữ liệu tốc độ của cả nhóm, nên đây là forecast cần kiểm chứng sau Sprint 1, không phải số giờ thực tế hoặc cam kết điểm bằng nhau. Bản trước và nhật ký điều chỉnh được giữ trong history và Nhat-ky-dieu-chinh-uoc-luong-2026-11-04.md.

## 1. Căn cứ và điều kiện cần giải quyết ngay

- Kế thừa bản đề xuất môn Phát triển ứng dụng di động đa nền tảng: Flutter/Dart 3, Riverpod 2, Supabase Auth, PostgreSQL, Storage, Edge Functions, Gemini API, SharedPreferences và Clean Architecture.
- Áp dụng Pathway 1 của môn Quản trị dự án phần mềm: một sản phẩm chung, bổ sung đầy đủ quy trình và bằng chứng quản trị.
- Phân công cho Lê Văn Quân, Trần Lê Nguyên Hải và Đinh Công Phúc. Vai trò dưới đây là đề xuất ban đầu, chưa dựa trên khảo sát điểm mạnh cá nhân.
- Hướng dẫn yêu cầu lịch sử commit liên tục 15 tuần. Nhóm chỉ còn 27 ngày làm dự án trước ngày nộp, nên không thể tự tuyên bố đã đáp ứng điều kiện này bằng cách nén sprint. Ngày 04–05/11, Quân trình giảng viên kế hoạch rút gọn, thời điểm bắt đầu thật, phương án 4 sprint và đề nghị xác nhận bằng văn bản/email. Lưu phản hồi vào hồ sơ. Không đổi ngày commit hoặc tạo bằng chứng quá khứ.
- Nếu chưa được chấp thuận ngoại lệ, nhóm vẫn triển khai các việc không phụ thuộc phản hồi nhưng ghi rõ rủi ro điều kiện lịch sử 15 tuần còn mở. Theo hướng dẫn, không vượt Cổng chân thực có thể khiến điểm đồ án bị khống chế tối đa 5,0/10; kế hoạch này không bảo đảm loại bỏ ràng buộc đó.
- Bản đề xuất nêu Android/iOS. Đầu ra kiểm chứng trong tháng này ưu tiên APK Android; khả năng build/test iOS cần thiết bị và môi trường phù hợp. Ngày 04–05/11 xác định điều kiện của nhóm và xin chốt phạm vi nghiệm thu. Nếu môn đa nền tảng yêu cầu cả hai nền tảng, phải thêm công việc kiểm chứng iOS và cân đối lại phạm vi; không ghi đã hỗ trợ iOS chỉ vì dùng Flutter.
- Trong các tài liệu tham chiếu, hiện đã đọc được Project-Guidelines.md, bản đề xuất FashionApp và Project-Charter-Example.md. Chưa có các mẫu Charter chính thức, Risk Register, Checklist và Milestone Rubric được liên kết trong hướng dẫn. Quân lấy các mẫu còn thiếu từ giảng viên/LMS trước 06/11, đối chiếu biểu mẫu và cập nhật kế hoạch nếu có yêu cầu khác. Ví dụ Charter chỉ dùng tham khảo cấu trúc, không sao chép dữ kiện dự án mẫu.

## 2. Phạm vi một tháng

### 2.1. Phạm vi cam kết để trình chốt

| Nhóm chức năng | Mức hoàn thành trong tháng | Tiêu chí nghiệm thu chính |
|---|---|---|
| Xác thực và hồ sơ | Đăng ký, đăng nhập email/mật khẩu, đăng xuất, sửa hồ sơ; phân vai khách hàng/admin | Người dùng chỉ sửa hồ sơ được phép; không tự nâng quyền; lỗi nhập liệu được xử lý |
| Danh mục sản phẩm | Danh mục, tìm theo tên, lọc giá/size/màu, chi tiết, ảnh, biến thể và tồn kho | Kết quả đúng dữ liệu; chọn biến thể hợp lệ; có trạng thái loading/empty/error |
| Giỏ hàng và địa chỉ | Thêm/xóa, đổi số lượng, lưu địa chỉ nhận hàng | Phân biệt size/màu; số lượng hợp lệ; tổng tiền hiển thị nhất quán |
| Đơn hàng | Đặt COD, xem lịch sử và chi tiết; admin cập nhật trạng thái | Máy chủ xác thực người mua, tính lại giá và kiểm tra tồn kho; không tạo đơn dở dang khi lỗi |
| Tư vấn thời trang AI | Nhập phong cách, dịp sử dụng và ngân sách; gợi ý sản phẩm/phối đồ từ catalog | Kết quả gắn sản phẩm tồn tại; kiểm tra ngân sách; xử lý timeout, thiếu cấu hình và hết quota rõ ràng |
| Quản trị | Màn hình trong cùng ứng dụng Flutter, phân quyền admin: CRUD danh mục/sản phẩm/biến thể, quản lý đơn, danh sách người dùng và thông tin được phép quản lý | Người dùng thường không truy cập được cả ở UI và phía dữ liệu; ưu tiên ẩn/ngừng bán sản phẩm đã có trong đơn |
| Thống kê cơ bản | Số đơn, số đơn theo trạng thái và tổng giá trị đơn đã hoàn tất | Chỉ số khớp dữ liệu; không tính đơn hủy vào giá trị hoàn tất |
| Cá nhân hóa cơ bản | Yêu thích, lịch sử mua, đánh giá sau đơn hoàn tất | Không đánh giá sản phẩm chưa đủ điều kiện; không tạo nhiều đánh giá ngoài quy tắc đã chốt |
| Ngoại tuyến có giới hạn | Lưu thiết lập và snapshot dữ liệu catalog đơn giản; khi có mạng tải lại dữ liệu mới | Xem được dữ liệu đã lưu và biết đang ngoại tuyến; không đặt đơn hoặc gọi AI khi mất mạng |

Lịch sử mua dùng chung module đơn hàng. Cache không cam kết ảnh chưa lưu sẽ hiển thị ngoại tuyến. SharedPreferences chỉ dùng cho dữ liệu đơn giản; không tự lưu API key, khóa quản trị hoặc dữ liệu nhạy cảm vào cache.

Quản lý người dùng được giới hạn ở danh sách, hồ sơ và trạng thái truy cập trong phạm vi đã chốt. Tác vụ quản trị đặc quyền phải được kiểm tra phía máy chủ. Không mở rộng sang hệ thống quản lý tài khoản phức tạp trong tháng này.

### 2.2. Ngoài phạm vi đề xuất

Chưa triển khai AR/thử đồ ảo, đo cơ thể/gợi ý size bằng mô hình riêng, tìm bằng hình ảnh, quét nhãn mác, chatbot giọng nói, thanh toán trực tuyến, tích hợp đơn vị vận chuyển, ứng dụng cho người bán riêng hoặc xuất bản App Store/Google Play. Bảng size thông thường có thể hiển thị trong mô tả sản phẩm, không được gọi là AI gợi ý size.

Đây là giới hạn đề xuất cần stakeholder/giảng viên chốt; phần giới thiệu trong bản đề xuất cũ đã nhắc một số tính năng nâng cao nên phải làm rõ bằng văn bản. Nếu phát sinh điều chỉnh sau khi chốt baseline, áp dụng Change Request.

### 2.3. Kiến trúc và đầu ra triển khai

- Một ứng dụng Flutter có giao diện khách hàng và admin theo vai trò, dùng chung nền tảng dữ liệu. Chưa tách dashboard web riêng.
- Chia module theo tính năng, mỗi module giữ Presentation, Domain và Data; Riverpod quản lý trạng thái. Chốt giao diện repository/model sớm để ba người phát triển độc lập.
- Supabase cung cấp Auth, PostgreSQL, Storage và Edge Functions. Gemini được gọi qua Edge Function; kiểm tra người gọi, giới hạn yêu cầu và kiểm chứng sản phẩm trả về. Khóa đặc quyền và Gemini API key chỉ đặt phía máy chủ.
- Các bảng dự kiến: profiles/roles, categories, products, product_variants, addresses, orders, order_items, favorites và reviews. Giỏ hàng ban đầu có thể lưu cục bộ theo tài khoản, không bắt buộc thêm dịch vụ giỏ hàng riêng.
- Đặt đơn là nghiệp vụ máy chủ có giao dịch: lấy giá từ dữ liệu tin cậy, kiểm tra biến thể và tồn kho, ghi đơn/chi tiết và trừ tồn kho nhất quán. Có biện pháp chống tạo đơn trùng khi người dùng gửi lại yêu cầu.
- Đầu ra chính: APK đã cài thử trên thiết bị thật, backend cloud hoạt động, tài khoản demo khách/admin riêng, README cài đặt và video dự phòng. Nếu cần public web theo rubric hoặc yêu cầu của thầy, phải chốt sớm và bổ sung dự toán thay vì tự giả định APK đủ cho mọi cách diễn giải.

## 3. Năng lực, vai trò và cân bằng đóng góp

Dự toán R3 dùng đầu ra MVP và mẫu/kế hoạch đã có, với 40–40,5 giờ công chủ động/người trong tháng, khoảng 10 giờ/tuần. Dành thêm 8 giờ dự phòng/người; mức thời gian cần sắp xếp khoảng 48–48,5 giờ/người. Quỹ dự phòng không được tự điền thành giờ đã làm. Không bắt buộc chia đều số buổi hoặc dùng hết ngân sách giờ.

| Thành viên | Vai trò điều phối | Phần sản phẩm chịu trách nhiệm chính | Giờ dự kiến | Dự phòng |
|---|---|---|---:|---:|
| Lê Văn Quân | PM/Scrum Master; nền tảng/dữ liệu ban đầu và AI | Bootstrap, Data repository catalog, kiểm chứng nền tảng, AI, người dùng admin, yêu thích/đánh giá | 40 | 8 |
| Trần Lê Nguyên Hải | Technical Lead; review kiến trúc/bảo mật và phát hành | Auth/profile, UI catalog, admin sản phẩm, cache, tích hợp và phát hành | 40.5 | 8 |
| Đinh Công Phúc | QA/Test Lead; test/UAT và evidence | Giỏ/địa chỉ, đặt hàng, admin đơn, thống kê và nghiệm thu | 40.5 | 8 |

Cơ sở: Q01/Q02 theo tự đánh giá của Quân; các gói còn lại là dự báo chưa được hiệu chuẩn bằng kết quả nhóm. Giả định tận dụng thiết kế/mẫu hiện có, giao diện ở mức MVP, dùng dịch vụ đã chọn và tự kiểm thử nằm trong giờ phát triển. Checkout, AI và phân quyền vẫn có gói kiểm chứng riêng. Nếu giả định không đúng, phải re-estimate ngay; không giảm chất lượng để giữ con số thấp.

Cả ba đều làm giao diện, logic tích hợp, kiểm thử và tài liệu phần mình. Đầu mối chịu trách nhiệm điều phối, không làm thay toàn bộ công việc của vai trò đó. Cả nhóm cùng xây WBS, ước lượng, kiểm thử chéo và duyệt báo cáo.

Review luân phiên: Hải review Quân; Phúc review Hải; Quân review Phúc. PR liên quan phân quyền, schema, đơn hàng và AI cần thêm người thứ ba xem nếu cần. Không tự duyệt PR của mình.

Theo dõi hằng tuần: giờ thực tế theo Issue, Story Points hoàn thành, độ khó, chất lượng, số vòng sửa lỗi, review, tài liệu và trao đổi stakeholder. Nếu một người có tổng effort thực tế/dự báo vượt mức bình quân hơn 15%, cả nhóm chuyển các Issue chưa bắt đầu để cân bằng, có ghi nhận chuyển giao. Ngưỡng 15% là quy ước nội bộ đề xuất.

Mục tiêu phân công ban đầu là khoảng 1/3 công sức mỗi người. Báo cáo cuối kỳ ghi tỷ lệ đóng góp dựa trên thực tế, không giữ con số bằng nhau nếu bằng chứng khác đi. Không dùng số dòng code hoặc số commit làm thước đo duy nhất. Kế hoạch công bằng không bảo đảm giảng viên cho điểm cá nhân bằng nhau.

## 4. Phương pháp làm việc và mốc kiểm soát

Chọn Hybrid: chốt phạm vi/Charter/WBS và các mốc nộp ngay đầu dự án; phát triển tăng dần theo bốn sprint một tuần; vận hành công việc trên GitHub Projects theo Kanban. Lý do: thời gian ngắn, cần bản chạy hằng tuần, đồng thời phải giữ baseline và kiểm soát thay đổi.

| Sprint | Thời gian | Bản bàn giao và mốc bắt buộc |
|---|---|---|
| 1 | 04–10/11 | Chốt phạm vi, stakeholder, Charter/WBS; repo/CI/schema; đăng nhập, catalog, giỏ và địa chỉ chạy bản đầu; demo 10/11; Retro 1 và Risk snapshot 1 |
| 2 | 11–17/11 | Luồng đặt đơn thật, admin cơ bản, AI bản đầu và cache; demo 17/11; cập nhật rủi ro, burndown và điều chỉnh dự báo |
| 3 | 18–24/11 | Hoàn thiện cá nhân hóa/thống kê; đóng phạm vi tính năng mới 22/11; tích hợp và APK pilot 23/11; demo và bắt đầu UAT 24/11; Risk snapshot 2 |
| 4 | 25–30/11 | UAT và sửa lỗi đến 26/11; nghiệm thu mục tiêu 26/11; Final Retro 27/11; hoàn thiện hồ sơ 27–28/11; kiểm toán hồ sơ và diễn tập 29/11; dự phòng 30/11 |
| Nộp | 01/12 | Đại diện nhóm nộp đúng kênh, kiểm tra link và lưu xác nhận; không chờ sát giờ đóng form |

Charter và thỏa thuận tiến độ đặt mục tiêu được xác nhận trước 07/11; WBS baseline trước 07/11. Việc ký phụ thuộc phản hồi thật, phải cập nhật nếu chưa hoàn tất. Việc lấy chữ ký không được để đến ngày 30/11 mới bắt đầu.

Nhịp nhóm: cập nhật bất đồng bộ ngắn khoảng 3 phút/ngày theo ba ý đã làm/tiếp theo/vướng mắc; đầu sprint planning 15 phút; cuối sprint review 20 phút và retro 15 phút. Mỗi người dự trù khoảng một giờ phối hợp/sprint trong các gói điều phối hoặc test/report tương ứng; chỉ tính mỗi hoạt động một lần. Các giờ họp, review và ghi bằng chứng đã nằm trong dự toán, không cộng thêm ngoài tổng dự toán của từng người. Vướng mắc quá một buổi phải thông báo, không chờ đến cuối tuần.

## 5. WBS và từ điển công việc

WBS bao phủ toàn bộ công việc theo nguyên tắc 100% Rule, gồm phát triển sản phẩm và quản trị, kiểm thử, phát hành, bàn giao. Sáu nhánh: 1 quản trị; 2 nền tảng/CI/dữ liệu; 3 tài khoản/cá nhân hóa; 4 catalog/AI; 5 giỏ/đơn/admin; 6 kiểm thử/phát hành/hồ sơ. Mỗi hàng sau là một work package tối đa một sprint; mỗi gói tạo một Issue, có thể tách sub-issue khi cần. Giờ của sub-issue phải nằm trong tổng gói, không đếm hai lần.

Các mã dưới đây là mã kế hoạch, chưa phải số GitHub Issue. Ngày trong bảng là cửa sổ thực hiện; lịch CPM bên dưới xác định các phụ thuộc chính. Khi nhập GitHub phải bổ sung assignee, WBS ID, milestone, acceptance criteria chi tiết và liên kết PR/bằng chứng.

### Sprint 1 — 04–10/11

| Mã | WBS | Người | Việc cụ thể | Giờ | Kết quả để nghiệm thu |
|---|---|---|---|---:|---|
| Q01 | 1 | Quân | Khởi tạo dự thảo Charter/scope từ mẫu và kế hoạch có sẵn, gửi đề nghị/lịch, liên kết WBS | 0.5 | Draft có phiên bản; ghi đúng việc đã gửi/đang chờ; Q07/Q10/Q14 tiếp tục review/phê duyệt |
| Q02 | 2 | Quân | Bootstrap Flutter/Supabase, schema/quyền ban đầu, CI cơ bản, cấu hình và README ban đầu | 1.5 | Scaffold chạy/kết nối dữ liệu, migration/quyền ban đầu, PR/CI và README bản đầu; phần hoàn thiện chuyển Q03 rõ ràng |
| Q03 | 2 | Quân | Data repository catalog 3h, quyền 1h, CI/ERD/README 0,5h, onboarding 0,5h, phối hợp Sprint 1h | 6 | Repository/model dùng chung, query/policy được kiểm tra; seed/ERD/CI/README và xác nhận clone có evidence |
| H01 | 3 | Hải | Auth và hồ sơ: UI, Riverpod, repository, Supabase Auth và tự kiểm thử | 4 | Đăng ký/đăng nhập/đăng xuất/sửa hồ sơ chạy thật; không tự nâng quyền |
| H02 | 4 | Hải | UI catalog/tìm-lọc/chi tiết, Riverpod và tích hợp Data repository Q03 | 3 | UI dùng repository Q03, tìm/lọc/biến thể đúng; không viết lại backend |
| H03 | 6 | Hải | Tổng hợp test Auth/Catalog và review nền tảng của Quân | 1.5 | Test report/review có nguồn; kiểm thử khi phát triển đã tính trong H01/H02 |
| P01 | 6 | Phúc | Test matrix/DoD, UI cơ bản và đặc tả dữ liệu test cho seed Q03 | 2 | Test gắn AC, dữ liệu mẫu thống nhất; Q03 thực hiện tệp seed tái tạo |
| P02 | 5 | Phúc | Giỏ, số lượng, tổng tiền và địa chỉ | 4.5 | Luồng chạy thật, biến thể và tài khoản tách biệt |
| P03 | 6 | Phúc | Test giỏ/địa chỉ, Retro 1, Risk snapshot | 2 | Có test report, Retro action items và Risk snapshot 1 |

### Sprint 2 — 11–17/11

| Mã | WBS | Người | Việc cụ thể | Giờ | Kết quả để nghiệm thu |
|---|---|---|---|---:|---|
| Q04 | 4 | Quân | Edge Function tư vấn: xác thực, nhận nhu cầu, chọn catalog context, gọi Gemini và kiểm tra output | 4 | Không lộ khóa; chỉ trả sản phẩm hợp lệ; lỗi quota/timeout được xử lý |
| Q05 | 4 | Quân | UI tư vấn, bộ lọc ngân sách và điều hướng sản phẩm/thêm giỏ | 3 | Hoàn thành luồng nhập yêu cầu → gợi ý → chi tiết/giỏ; xử lý không có bộ phù hợp |
| Q06 | 3 | Quân | Admin xem/quản lý hồ sơ và trạng thái trong phạm vi đã chốt | 2 | Người thường bị chặn; thao tác đặc quyền được xác thực phía máy chủ |
| Q07 | 1 | Quân | Review stakeholder, log yêu cầu/change, theo dõi tiến độ và review chéo | 2 | Có phản hồi thật, quyết định và issue liên kết; không tự ghi Approved khi chưa được duyệt |
| H04 | 4 | Hải | Admin CRUD danh mục/sản phẩm/biến thể, ảnh Storage và tồn kho | 6 | Admin thao tác được; sản phẩm đã có trong đơn được bảo toàn lịch sử |
| H05 | 4 | Hải | Cache snapshot catalog và thiết lập, trạng thái ngoại tuyến và tải lại khi có mạng | 2 | Khởi động lại vẫn xem được snapshot đã lưu; không báo đơn offline là thành công |
| H06 | 2 | Hải | Rà soát truy cập dữ liệu/Storage; test catalog/cache; review chéo | 2 | Người thường không ghi dữ liệu admin; cache không chứa khóa đặc quyền |
| H07 | 1 | Hải | Snapshot velocity/burndown/CPM và cập nhật từ điển WBS | 1 | Có dữ liệu theo sprint và baseline/actual tách biệt |
| P04 | 5 | Phúc | Nghiệp vụ đặt đơn máy chủ, kiểm tra giá/tồn kho, chống gửi trùng | 5 | Không tin giá từ client; giao dịch lỗi không để dữ liệu dở dang; không bán vượt tồn |
| P05 | 5 | Phúc | UI checkout COD, lịch sử/chi tiết đơn và admin trạng thái đơn | 4 | Luồng mua hoàn chỉnh; chỉ xem đơn được phép; trạng thái chuyển đúng quy tắc |
| P06 | 6 | Phúc | Test đặt đơn, quyền truy cập và review chéo | 1.5 | Có bằng chứng giá bị sửa, thiếu hàng, request lặp và truy cập đơn của người khác |
| P07 | 1 | Phúc | Biên bản review/retro ngắn và cập nhật Risk Register | 0.5 | Risk có owner, hành động và hạn; bài học dẫn tới task cải tiến |

### Sprint 3 — 18–24/11

| Mã | WBS | Người | Việc cụ thể | Giờ | Kết quả để nghiệm thu |
|---|---|---|---|---:|---|
| Q08 | 3 | Quân | Yêu thích và đánh giá sau mua | 4 | Yêu thích tách tài khoản; chỉ đánh giá theo điều kiện đã chốt |
| Q09 | 6 | Quân | Sửa lỗi AI/nền tảng và test các tình huống AI không đáp ứng | 2 | Không hiển thị sản phẩm ảo; lỗi mạng/quota không làm treo hoặc crash app |
| Q10 | 1 | Quân | Stakeholder review, theo dõi CR, rủi ro và đóng phạm vi mới 22/11 | 2 | Mỗi thay đổi có tác động/ý kiến phê duyệt; cập nhật baseline và bằng chứng triển khai nếu được duyệt |
| Q11 | 1 | Quân | Viết nháp chương 1–2, gắn mục tiêu với bằng chứng | 2 | Phân biệt kế hoạch và kết quả đã đạt; không bịa số liệu đóng góp |
| H08 | 6 | Hải | Tích hợp auth/catalog/admin/cache, kiểm tra hiệu năng trên dữ liệu mẫu | 4 | Các module chạy cùng nhau; xử lý bộ lọc, hết hàng và dữ liệu stale |
| H09 | 2 | Hải | Audit phân quyền dữ liệu, quyền admin và bảo mật cấu hình | 2 | Người dùng không tự nâng quyền hoặc đọc/sửa tài nguyên người khác |
| H10 | 6 | Hải | Pipeline phát hành, APK pilot và kiểm tra cài đặt | 2 | APK cài và chạy được trên máy khác; ghi version/tag/commit SHA |
| H11 | 1 | Hải | Hoàn thiện WBS dictionary, CPM, metrics và nháp chương 3–5 | 3 | Gói công việc có owner/phụ thuộc/DoD; số liệu lấy từ GitHub và test thật |
| P08 | 6 | Phúc | Tích hợp giỏ/đơn/admin, test hồi quy và hỗ trợ sửa lỗi | 3 | Luồng mua với biến thể và quyền truy cập chạy ổn định |
| P09 | 6 | Phúc | Chuẩn bị/điều phối UAT, test trên thiết bị thật và buổi UAT đầu 24/11 | 3 | Người thử thật có kịch bản, kết quả và Issue lỗi; chưa coi là đã nghiệm thu |
| P10 | 5 | Phúc | Thống kê admin cơ bản | 2 | Các tổng số và giá trị đơn hoàn tất khớp truy vấn dữ liệu mẫu |
| P11 | 1 | Phúc | Risk snapshot 2, test report và evidence index | 2 | So sánh Risk snapshot 1/2; từng bằng chứng có ngày và liên kết nguồn |

### Sprint 4 — 25–30/11

| Mã | WBS | Người | Việc cụ thể | Giờ | Kết quả để nghiệm thu |
|---|---|---|---|---:|---|
| Q12 | 6 | Quân | Sửa lỗi UAT thuộc nền tảng/AI/cá nhân hóa | 2 | Các lỗi chặn nghiệm thu phần Quân được đóng và kiểm tra lại |
| Q13 | 1 | Quân | Hoàn thiện chương 1, 2, 6 và rà soát tính nhất quán | 4 | Nêu đúng business case, phương pháp, đóng góp và lịch sử risk/change |
| Q14 | 1 | Quân | Hoàn tất Charter/phê duyệt, hồ sơ CR và liên hệ người ký | 1 | Chữ ký/phản hồi thật; hồ sơ còn chờ được ghi đúng trạng thái |
| Q15 | 6 | Quân | Slide nội dung nghiệp vụ/quản trị, kịch bản AI và diễn tập | 3 | Phần trình bày khoảng 2 phút; xử lý câu hỏi scope/phương pháp |
| Q16 | 6 | Quân | Audit hồ sơ, quyền Drive và đại diện chuẩn bị nộp | 1 | Đủ 8 file; link mở bằng tài khoản ngoài; checklist và phiên bản cuối |
| H12 | 6 | Hải | Sửa lỗi UAT thuộc auth/catalog/cache | 2 | Lỗi chặn nghiệm thu phần Hải được đóng và kiểm tra lại |
| H13 | 1 | Hải | Hoàn thiện chương 3, 4, 5 | 4 | WBS/CPM/velocity/CI/kiểm thử có nguồn, số dự báo và số thực tế phân biệt |
| H14 | 1 | Hải | Xuất sơ đồ và số liệu GitHub cuối kỳ | 1 | Ảnh/số liệu có thời điểm; không dùng đồ thị tự tạo thay cho dữ liệu gốc |
| H15 | 6 | Hải | Build release APK, README, cấu hình demo và diễn tập kỹ thuật | 2 | Cài mới và smoke test release; có tag và hướng dẫn; không kèm secrets |
| H16 | 6 | Hải | Audit kỹ thuật, repo/PR/Actions và gói phát hành | 1 | Bản bàn giao truy nguyên được commit; người ngoài nhóm truy cập được phần được chia sẻ |
| P12 | 6 | Phúc | Sửa lỗi UAT thuộc giỏ/đơn/thống kê và regression | 2 | Luồng cốt lõi và quyền truy cập pass trên bản release |
| P13 | 1 | Phúc | Chương 7, phụ lục kiểm thử và hợp nhất evidence index | 4 | Kết quả UAT/đóng dự án phản ánh thực tế; không tự nhận nghiệm thu thay stakeholder |
| P14 | 1 | Phúc | Điều phối sign-off UAT và Final Retro | 1 | Biên bản có tiêu chí/kết quả/người xác nhận; Retro có bài học thực tế |
| P15 | 6 | Phúc | Video backup, slide QA/UAT và diễn tập luồng mua | 3 | Video quay bản chạy thật; phần trình bày khoảng 2 phút; demo mua hàng ổn định |
| P16 | 6 | Phúc | Audit chéo 8 deliverables và test link/thiết bị lần cuối | 1 | Checklist không thiếu mục; kiểm tra bằng phiên đăng xuất/tài khoản khác |

Tổng dự toán theo sprint:

| Sprint | Quân | Hải | Phúc | Cả nhóm |
|---|---:|---:|---:|---:|
| 1 | 8 | 8.5 | 8.5 | 25 |
| 2 | 11 | 11 | 11 | 33 |
| 3 | 10 | 11 | 10 | 31 |
| 4 | 11 | 10 | 11 | 32 |
| Tổng | 40 | 40.5 | 40.5 | 121 |

Chênh lệch toàn tháng chỉ 0,5 giờ. Đây là phân bổ ban đầu theo công việc; không phải tỷ lệ đóng góp thực tế. Việc phát sinh dùng dự phòng có ghi nhận hoặc được đổi người/phạm vi theo quyết định nhóm.

## 6. Phụ thuộc và CPM baseline

Giờ công là thời gian chủ động thực hiện; ngày lịch là cửa sổ giao việc/review. Q01 và Q02 chỉ tổng 2 giờ và đều đặt mục tiêu khởi tạo ngày 04/11, không còn kéo phần bootstrap qua ba ngày như bản cũ. Thời gian còn lại của sprint dành cho Data repository, tính năng và kiểm chứng; không ghi là đã làm setup liên tục.

CPM R3 dưới đây dùng ngày lịch ở mức giai đoạn theo lịch bàn giao, không quy đổi một ngày thành tám giờ công. Thời lượng và phụ thuộc cần tính lại khi có Actual:

| Mã | Hoạt động | Phụ thuộc | Ngày lịch | Cửa sổ baseline |
|---|---|---|---:|---|
| A | Q01/Q02 khởi tạo bản đầu, tổng 2 giờ chủ động | — | 1 | 04/11 |
| B | Contract/model/repository catalog bản đầu | A | 1 | 05/11 |
| C | Hoàn thiện quyền/CI/ERD/README nền tảng | B | 2 | 06–07/11 |
| D | Auth/Profile | A | 4 | 05–08/11 |
| E | UI catalog và Cart/Addresses, làm song song | B | 4 | 06–09/11 |
| F | Regression/review/Retro Sprint 1 | C, D, E | 1 | 10/11 |
| G | Checkout/đơn/admin core | F | 7 | 11–17/11 |
| H | AI/admin catalog/cache | F | 7 | 11–17/11 |
| I | Tích hợp, bảo mật, chức năng nhỏ và APK pilot | G, H | 6 | 18–23/11 |
| J | UAT, sửa lỗi và xác nhận | I | 3 | 24–26/11 |
| K | Khóa hồ sơ/slide đã viết dần | J | 2 | 27–28/11 |
| L | Audit và diễn tập | K | 1 | 29/11 |

Một đường găng: A → B → E → F → G → I → J → K → L, tổng 26 ngày lịch; nhánh qua H cũng găng. C có total float 2 ngày, D có 1 ngày khi lấy 29/11 làm mốc nội bộ. Kết thúc baseline 29/11; 30/11 dự phòng lịch. Quỹ 8 giờ/người là dự phòng công sức riêng, không cộng hai lần thành thời gian thực tế.

Bản CPM cũ được lưu trong history. Phê duyệt/chữ ký vẫn là phụ thuộc bên ngoài phải theo dõi, không được coi là đã xảy ra vì một gói dự thảo hoàn tất.

## 7. GitHub, ước lượng và Definition of Done

### 7.1. Thiết lập trước 06/11

- Repository và quyền truy cập cho ba thành viên; thống nhất danh tính Git để truy nguyên đóng góp.
- GitHub Projects với Backlog, Ready, In Progress, In Review, Done. Trường đề xuất: Owner, Sprint, WBS, Priority, Estimate/SP, Planned hours, Actual hours, Due date và Evidence URL. Nếu một trường không dùng được thì dùng nhãn/tệp ghi nhận tương đương, vẫn giữ nguồn dữ liệu thống nhất.
- Milestone Sprint 1/2/3/4 và Release. Mỗi work package trong bảng có Issue; Issue nêu output, acceptance criteria, phụ thuộc và ước lượng.
- Nhánh main được bảo vệ, chặn merge khi chưa đủ một approval của người khác và CI pass theo khả năng cấu hình của repo. Nếu không bật được cơ chế theo tài khoản hiện có, Quân ghi rủi ro và xử lý cùng giảng viên sớm; quy trình tự giác không được mô tả là đã bật Branch Protection.
- Conventional Commits; PR gắn Issue, ảnh/video khi có UI, ghi cách tự kiểm thử và ảnh hưởng migration/cấu hình.
- GitHub Actions: kiểm tra định dạng, flutter analyze, flutter test và build kiểm tra Android trên PR. Pipeline phát hành bản có tag và lưu APK; triển khai migration/Edge Function có bước kiểm tra và ghi nhận kết quả. Nếu một bước triển khai vẫn thủ công thì ghi đúng là CI tự động và CD có bước thủ công.

### 7.2. Ước lượng và chỉ số

Giờ trong kế hoạch dùng để cân bằng công suất, không phải Story Points. Đầu sprint, cả ba Planning Poker theo thang 1–2–3–5–8; gói quá lớn phải tách. Không quy đổi cứng một point bằng một số giờ và không gán tổng SP bằng nhau chỉ để đẹp báo cáo.

- Velocity sprint = tổng SP của các Issue đáp ứng DoD trong sprint; không tính phần đang làm và không bịa velocity trước khi có sprint đầu.
- Ghi snapshot SP còn lại mỗi ngày làm việc để dựng burndown; thay đổi phạm vi phải được ghi riêng và thể hiện trên đồ thị. Lưu dữ liệu gốc cùng chart xuất vào cuối sprint.
- PR throughput = số PR merged trong kỳ; ghi nhận cả chất lượng review, không chạy theo số lượng PR.
- Cuối sprint cập nhật giờ thực tế, lỗi còn mở, tỷ lệ test core pass, rủi ro và dự báo hoàn tất. Giữ baseline cũ để so sánh, không sửa lại lịch sử cho khớp kết quả.

### 7.3. DoD theo loại công việc

Với code: acceptance criteria đạt; có kiểm thử phù hợp rủi ro; PR được peer review; CI pass; phân quyền/lỗi mạng được xem xét khi liên quan; chạy được trên build chung; cập nhật tài liệu/migration; bằng chứng gắn Issue rồi mới chuyển Done. Không yêu cầu unit test hình thức cho thay đổi nhỏ không có logic.

Với tài liệu/quản trị: đủ nội dung theo mẫu; có nguồn và phiên bản/ngày; một thành viên khác review; người có thẩm quyền phê duyệt nếu loại tài liệu yêu cầu; liên kết bằng chứng hợp lệ. Tài liệu còn chờ chữ ký ghi đúng trạng thái, không chuyển thành approved chỉ vì đã viết xong.

Kiểm thử bắt buộc theo rủi ro: tính giá và biến thể; giao dịch/không vượt tồn kho; request đặt đơn lặp; đọc/sửa dữ liệu người khác; admin trái quyền; AI trả ID không hợp lệ/quá ngân sách; mất mạng khi checkout/AI; snapshot offline; đăng xuất/đổi tài khoản; trạng thái đơn và thống kê. Có unit test nghiệp vụ, integration test phía dữ liệu và kiểm thử luồng trên app thật, không chỉ mock toàn bộ backend rồi tuyên bố tích hợp thành công.

## 8. Stakeholder, rủi ro và kiểm soát thay đổi

### 8.1. Stakeholder và UAT

Ngày 04–05/11 xác định người có thẩm quyền chốt phạm vi/nghiệm thu: giảng viên chuyên ngành hoặc đại diện nhóm người dùng thật phù hợp Pathway 1. Đề xuất mời 3–5 người dùng mục tiêu tham gia thử, có đồng ý và phản hồi; họ không thay thế chữ ký giảng viên ở Charter nếu mẫu yêu cầu.

Đặt lịch review 10, 17, 24/11 ngay từ đầu; UAT 24–26/11; ngày mục tiêu sign-off 26/11. Biên bản ghi người tham gia, bản build, kịch bản, kết quả, lỗi và điều kiện còn lại. Có thể ký chấp thuận với hạn chế được thống nhất; không che lỗi chặn luồng chính. Nếu stakeholder chưa ký, hồ sơ là đang chờ, không được tự hoàn tất.

### 8.2. Risk Register ban đầu

| Rủi ro | Mức ban đầu | Owner | Trigger và phản ứng |
|---|---|---|---|
| Không được chấp thuận lịch sử ngắn/đầu ra APK | Cao | Quân | Chưa có phản hồi trước 07/11: nhắc qua kênh chính thức và xin hướng xử lý, lưu phản hồi |
| Thiếu thời gian hoặc một người bị quá tải | Cao | Cả ba | Hai buổi liên tiếp lệch kế hoạch hoặc effort dự báo lệch hơn 15%: chia lại task, dùng dự phòng, trình cắt phạm vi được phép |
| Gemini lỗi, quota hoặc trả sản phẩm không phù hợp | Cao | Quân | Thử API thật sớm bằng spike ghi riêng trong Q04 hoặc quỹ dự phòng; triển khai Q04 sớm sprint 2; timeout và kiểm chứng output; nếu dùng gợi ý theo quy tắc dự phòng phải ghi nhãn rõ, không gọi đó là kết quả AI |
| Schema/phân quyền sai, checkout không nhất quán | Cao | Quân và Phúc | Chốt contract 06/11, test chéo quyền và giá/tồn kho trước 17/11; lỗi chặn luồng được ưu tiên trước tính năng nhỏ |
| Stakeholder phản hồi/ký muộn | Cao | Quân | Chốt lịch đầu kỳ, gửi tài liệu sớm; bắt đầu xin xác nhận khi đủ dữ liệu, không dồn cuối tháng |
| APK hoặc thiết bị demo lỗi | Trung bình | Hải | Pilot 23/11; thử cài mới trên máy khác; release smoke test và giữ bản ổn định/video |
| Mạng demo yếu | Trung bình | Phúc | Chuẩn bị hotspot và video bản chạy thật; cache chỉ hỗ trợ xem, không giả lập AI/đơn hàng là online |
| Thiếu hồ sơ hoặc link truy cập sai | Trung bình | Phúc | Evidence index từ tuần 1; audit 24 và 29/11 bằng tài khoản ngoài nhóm |

Risk Register phải bổ sung xác suất/tác động, biện pháp, ngày, trạng thái và kết quả thực tế theo mẫu lấy được. Lưu bản ban đầu và các snapshot 10/11, 17/11, 24/11, cuối kỳ; ít nhất có dữ liệu tiến hóa qua Sprint 1 và Sprint 2. Bảng này là dự báo, chưa phải chứng minh biến cố đã xảy ra.

### 8.3. Change Request và biến cố quản lý thật

Quy trình: yêu cầu/biến cố thật → ghi CR hoặc risk/issue log → phân tích phạm vi, giờ, lịch, chất lượng và người bị ảnh hưởng → đề xuất xử lý → CCB theo Charter và stakeholder có thẩm quyền xem xét → ghi quyết định → cập nhật baseline/Issue → triển khai → kiểm thử và lưu kết quả.

CCB đề xuất gồm ba thành viên; stakeholder/giảng viên phê duyệt các thay đổi liên quan tiêu chí nghiệm thu theo thẩm quyền đã chốt. CCB nội bộ không tự thay giảng viên miễn điều kiện môn học.

Đề nghị điều chỉnh lịch/đầu ra ở đầu kỳ là yêu cầu thực tế và được lưu hồ sơ, nhưng không mặc nhiên coi đã đủ yêu cầu Approved Scope Change của môn học: xin giảng viên xác nhận loại hồ sơ này có được tính hay cần CR nghiệp vụ sau baseline. Các buổi review dùng để thu thập nhu cầu thật; nếu có thay đổi sau baseline, tạo CR và ghi tác động ngay. Không dựng chuyện stakeholder đổi ý, không gọi thay đổi chưa phê duyệt là Approved CR, không tạo sự cố để có minh chứng.

Mục tiêu đến 24/11 kiểm tra hồ sơ đã có ít nhất một biến cố quản lý thật được xử lý và một hồ sơ CR đáp ứng cách giảng viên yêu cầu. Nếu còn thiếu, Quân báo rõ và xin hướng xử lý trên tình hình thực tế; không lấp bằng biên bản giả. Tình huống có thể xảy ra như yêu cầu điều chỉnh bộ lọc, giới hạn ngân sách AI hoặc xử lý trễ tiến độ chỉ là ví dụ, không ghi như sự kiện đã xảy ra.

## 9. Hồ sơ nộp và trách nhiệm

Thư mục bàn giao theo cấu trúc hướng dẫn. Tạo chỉ mục bằng chứng trong repo từ tuần 1; Google Drive là nơi tổng hợp hồ sơ cuối kỳ. Repo, APK và bằng chứng GitHub được liên kết trong báo cáo/README và có thể đặt thư mục hỗ trợ bên cạnh tám file chính; không thay thế các file bắt buộc bằng link rời.

| File bắt buộc | Chủ trì | Người phối hợp/review | Mốc bản nháp và hoàn tất |
|---|---|---|---|
| 01_Final_Technical_Report.pdf | Cả ba theo chương | Review vòng Quân → Hải → Phúc → Quân | Viết dần từ 10/11; nháp đủ 24/11; khóa 28/11 |
| 02_Project_Charter_Signed.pdf | Quân | Hải và Phúc; PO/stakeholder và thầy ký theo yêu cầu | Nháp 05/11; mục tiêu phê duyệt 07/11; theo dõi chữ ký đến khi thật sự đủ |
| 03_WBS_and_WBS_Dictionary.pdf | Hải | Cả ba ước lượng, Quân review | Baseline 07/11; cập nhật phiên bản khi có thay đổi; cuối 28/11 |
| 04_Risk_Register_Evolution.xlsx | Phúc | Mỗi người cập nhật risk mình sở hữu | Baseline 05/11; snapshot mỗi sprint; cuối 27/11 |
| 05_Sprint_Retrospectives.pdf | Phúc | Cả ba ghi bài học và action items | Retro 1 ngày 10/11; Final Retro 27/11; hợp nhất 28/11 |
| 06_Scope_Change_Control_Record.pdf | Quân | CCB/stakeholder theo Charter | Mở log 04/11; từng CR theo sự kiện thật; audit trạng thái 24/11; cuối 28/11 |
| 07_Stakeholder_Acceptance_Signoff.pdf | Phúc điều phối | Quân liên hệ, stakeholder xác nhận | UAT 24–26/11; mục tiêu có xác nhận 26/11 |
| 08_Presentation_Slide_Deck.pdf | Cả ba | Quân hợp nhất, mỗi người review phần khác | Nháp 25/11; cuối 28/11; diễn tập 29–30/11 |

Báo cáo mục tiêu khoảng 20–23 trang, trong giới hạn 15–25: chương 1–2 do Quân, chương 3–5 do Hải, chương 6 do Quân với dữ liệu risk của Phúc, chương 7 và phụ lục test do Phúc. Số chương khác nhau không dùng để suy ra khối lượng: phần test/UAT/evidence của Phúc và PM/change của Quân đã được cân đối theo giờ. Cả ba đọc toàn bộ trước nộp.

Viết các hoạt động đã thực hiện ở quá khứ, có commit/Issue/PR/ngày và kết quả thật. Giai đoạn đang làm chỉ ghi trong log tiến độ; trong báo cáo cuối không biến việc dự kiến thành thành tích đã đạt. Không sao chép ví dụ OAuth2/Redis hoặc số liệu của dự án mẫu vào FashionApp.

## 10. Điều kiện khóa bản nộp và bảo vệ

### 10.1. Checklist sản phẩm ngày 26–29/11

- Hoàn thành luồng: đăng nhập → tìm/lọc → chọn size/màu → giỏ/địa chỉ → COD → xem đơn → admin cập nhật trạng thái.
- Hoàn thành luồng AI: yêu cầu theo dịp/phong cách/ngân sách → đề xuất catalog hợp lệ → xem sản phẩm/thêm giỏ; có trạng thái lỗi dịch vụ rõ ràng.
- Chức năng admin, cá nhân hóa và cache theo baseline đã duyệt hoạt động. Bất kỳ phần thiếu nào đều được ghi nhận và xử lý theo thay đổi phạm vi, không âm thầm bỏ.
- Không còn lỗi làm crash/chặn luồng chính hoặc lỗi nghiêm trọng về quyền/giá/tồn kho; toàn bộ kịch bản core trong test matrix pass và có kiểm thử lại trên release.
- APK release cài mới được, dữ liệu demo sạch, tài khoản demo quyền phù hợp; không đưa secret vào repo hoặc gói bằng chứng công khai.
- Báo cáo, snapshot rủi ro, CR, UAT, repo và APK cùng khớp phiên bản; còn thiếu phê duyệt phải được báo rõ.

### 10.2. Phân chia bảo vệ

Thuyết trình 6 phút: Quân khoảng 2 phút về bài toán, phương pháp và scope/change; Hải khoảng 2 phút về kiến trúc, WBS/CPM và chỉ số thực thi; Phúc khoảng 2 phút về kiểm thử, UAT và bài học. Bộ slide 8–10 trang, mỗi người chịu phần có bằng chứng tương ứng.

Demo 5 phút: Phúc khoảng 2 phút luồng mua; Quân khoảng 1,5 phút AI; Hải khoảng 1,5 phút admin và kết quả vận hành. Chuẩn bị sẵn dữ liệu/tài khoản; không dành thời gian demo để tạo hàng loạt dữ liệu. Q&A 5 phút: người sở hữu phần chính trả lời trước, các thành viên còn lại bổ sung; ai cũng cần hiểu toàn bộ luồng.

Video backup ghi từ bản chạy thật và nêu đúng khi dùng thay demo do sự cố. Video không thay thế yêu cầu có sản phẩm chạy được. Thực hành một lượt đủ 16 phút, có người bấm giờ và ghi câu hỏi khó.

## 11. Công việc khởi động ngày 04–05/11

1. Cả ba xác nhận lịch thực hiện cho khoảng 40–40,5 giờ dự kiến và 8 giờ dự phòng/người; nêu lịch bận và điểm mạnh để điều chỉnh owner nhưng giữ cân bằng effort.
2. Quân chốt stakeholder, gửi đề nghị tiến độ rút gọn và đầu ra nghiệm thu, lấy mẫu còn thiếu, mở Charter và scope baseline.
3. Quân tạo repo/Projects/CI, schema và contract nền tảng trong Q02; Hải review và chuẩn bị Auth/Catalog, kiểm tra khả năng tiếp nhận để chạy.
4. Phúc lập test matrix/DoD, dữ liệu demo và wireframe tối thiểu cho luồng mua; thống nhất style với hai bạn.
5. Cả ba nhập các gói Sprint 1 thành Issue, Planning Poker, phân reviewer và bắt đầu commit thật theo phần việc. Chốt lịch review với stakeholder và lưu biên bản khởi động.

## 12. Tài liệu nguồn

- D:\VKU\HK1_2026-2027\Mobile_Cross_Platform\Report\Capstone-Report-1-Proposal-FashionApp.docx
- D:\VKU\HK1_2026-2027\Quản trị dự án phần mềm\Project-Guidelines.md
- D:\VKU\HK1_2026-2027\Quản trị dự án phần mềm\Project-Charter-Example.md

Repo của nhóm và Q01 #1 đã có theo thông tin/quan sát ở các lượt trước. Lần cập nhật này chỉ thay các file kế hoạch/nội dung Issue trên máy; không tự sửa dữ liệu GitHub, tạo chữ ký hoặc ghi kết quả chưa thực hiện.

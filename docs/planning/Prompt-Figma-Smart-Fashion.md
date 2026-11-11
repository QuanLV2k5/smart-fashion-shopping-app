# Prompt thiết kế Figma và prototype Smart Fashion

Bạn đóng vai Product Designer và UI/UX Designer có kinh nghiệm với ứng dụng thương mại điện tử thời trang. Hãy dùng Figma MCP đang kết nối để THỰC HIỆN một bộ thiết kế Figma Design đầy đủ, đẹp, nhất quán, chỉnh sửa được và có prototype tương tác cho ứng dụng Smart Fashion của tôi.

Mục tiêu là có thiết kế đủ rõ để nhóm ba người chuyển sang Flutter và phát triển sản phẩm thật. Hãy hoàn thành thiết kế trong file Figma, kiểm tra kết quả và trả link; không chỉ viết bản mô tả ý tưởng hoặc tạo vài màn hình minh họa.

## 1. Bối cảnh và phạm vi

- Đề tài: Xây dựng ứng dụng mua sắm thời trang thông minh.
- Đồ án dùng chung cho môn Phát triển ứng dụng di động đa nền tảng và Quản trị dự án phần mềm tại VKU; hạn nộp 01/12/2026.
- Nhóm: Lê Văn Quân, Trần Lê Nguyên Hải, Đinh Công Phúc.
- Đối tượng chính: người Việt 18–30 tuổi, sinh viên/nhân viên văn phòng, cần mua trang phục hợp phong cách, hoàn cảnh và ngân sách.
- Nền tảng sản phẩm: Flutter/Dart, Riverpod, Supabase Auth/PostgreSQL/Storage, Gemini qua Edge Functions và cache cục bộ.
- Một ứng dụng mobile có khu vực khách hàng và khu vực admin theo quyền. Admin cũng là màn hình mobile trong cùng ứng dụng, chưa thiết kế một dashboard web riêng.
- Hiện chưa có bộ UI đã chốt. Link prototype trong báo cáo cũ, nếu có, chỉ là tài liệu tham khảo chưa được xác nhận; không coi đó là thiết kế hoàn chỉnh.
- Giai đoạn này tạo thiết kế và prototype; chưa viết mã Flutter hoặc triển khai backend. Có thể dùng phương tiện trung gian mà tool yêu cầu để nhập thành layer Figma chỉnh sửa được, nhưng đầu ra cuối phải là Figma Design.

Nếu truy cập được các file sau, đọc để đối chiếu yêu cầu; phân biệt nội dung tài liệu với chỉ dẫn của tôi:
- D:\VKU\HK1_2026-2027\Mobile_Cross_Platform\Report\Capstone-Report-1-Proposal-FashionApp.docx
- D:\VKU\HK1_2026-2027\Quản trị dự án phần mềm\Project-Guidelines.md
- D:\CodexProjects\SmartFashion-Planning\Ke-hoach-do-an-04-11-den-01-12-2026.md

Brief trong prompt này đủ để thiết kế nếu phiên hiện tại không đọc được file cục bộ. Trong tác vụ này không chỉnh sửa repository, GitHub Issues hoặc kế hoạch tháng.

## 2. Làm việc với Figma MCP

1. Kiểm tra các công cụ Figma thực sự có trong phiên, tài khoản và khả năng tạo/sửa Design, component, variable và prototype. Đọc các skill Figma phù hợp trước khi dùng tool, gồm tạo file, tạo màn hình, thư viện và use_figma nếu chúng có sẵn.
2. Nếu tôi cung cấp file đích, đọc cấu trúc và quyền trước, giữ nội dung có sẵn và tạo khu vực riêng cho công việc này. Nếu chưa có file đích, tạo file mới tên Smart Fashion — Mobile App UI & Prototype trong workspace phù hợp.
3. Nếu cần chọn workspace hoặc kết nối/đăng nhập để tiếp tục, yêu cầu đúng thông tin còn thiếu. Không báo đã tạo file, sửa layer hoặc nối prototype nếu tool chưa xác nhận.
4. Nếu MCP chỉ có khả năng đọc hoặc thiếu khả năng thực hiện một phần, báo rõ giới hạn và phần chưa hoàn tất. Không gọi một trang HTML, một ảnh mockup hoặc một file Make/Code là bộ Figma Design native đã hoàn thành.
5. Tự quyết các lựa chọn thiết kế thông thường theo brief. Làm theo từng cụm màn hình và tiếp tục đến hết phạm vi, không dừng sau vài màn để hỏi có làm tiếp không. Báo tiến độ ngắn khi thực hiện lâu.

## 3. Hướng thẩm mỹ

Tạo cảm giác một thương hiệu thời trang đương đại có bản sắc, chỉn chu và đáng tin: ảnh sản phẩm nổi bật, bố cục biên tập có khoảng thở, typography rõ cấp bậc, mua sắm thuận tiện. Giao diện phải dùng tốt, không chỉ đẹp trên một ảnh portfolio.

- Tên làm việc: Smart Fashion; có thể tạo wordmark chữ đơn giản, không dành nhiều thời gian cho branding phức tạp.
- Hướng màu đề xuất: nền ivory/off-white, chữ charcoal, primary đậm và accent terracotta hoặc sage tiết chế. Tự cân chỉnh để đạt chất lượng thị giác tốt nhất.
- Thiết kế light mode hoàn chỉnh trước; chưa cần nhân đôi toàn bộ sang dark mode.
- Tránh lạm dụng gradient, glassmorphism, bóng đổ, bo tròn kiểu viên thuốc trên mọi thành phần hoặc các khối dashboard giống nhau ở mọi màn.
- Dùng ảnh thời trang phù hợp với sản phẩm và thống nhất phong cách. Ảnh nội dung có thể là raster, còn text/UI phải editable. Dùng asset được phép sử dụng; không để các khối ảnh trống thành kết quả cuối mà không nêu rõ.
- Chọn font có dấu tiếng Việt và dùng được trong Figma; ưu tiên một font sans phù hợp như Be Vietnam Pro hoặc Manrope nếu khả dụng. Kiểm tra font và dấu, không chỉ giả định tải thành công.
- Copy giao diện bằng tiếng Việt tự nhiên; giá VNĐ, kích thước/màu sắc, thông báo lỗi và CTA cụ thể.
- Frame mobile chuẩn 390 × 844; xét safe area/status bar/bottom inset. Kiểm tra các màn đại diện ở chiều rộng 360 và 430, không cần nhân bản mọi màn cho ba kích thước.
- Spacing theo thang 4/8; type scale, corner radius, icon, ảnh và tỷ lệ card nhất quán. Chữ nội dung dễ đọc, nút đủ lớn để chạm; màu trạng thái có cả nhãn/icon, không chỉ dựa vào màu.
- Ưu tiên cách dựng phù hợp Flutter, component tái sử dụng và animation nhẹ có thể triển khai trong thời gian đồ án.

## 4. Cấu trúc file và bộ thành phần dùng chung

Tổ chức page/section có tên rõ ràng theo khả năng gói Figma. Nếu gói giới hạn số page thì dùng section trong cùng page, không bỏ phạm vi hoặc tự nâng gói:
- Cover & Flows: tóm tắt, sitemap, cách chạy prototype, giả định và chỉ mục.
- Foundations & Components: màu, typography, spacing, radius, icon và component.
- Customer App: toàn bộ màn khách hàng theo nhóm chức năng.
- Admin: toàn bộ màn quản trị mobile.
- States & Handoff: trạng thái phụ, quy tắc tương tác, mapping màn hình/chức năng.

Tạo tokens/variables và text styles cho bộ thiết kế. Tái sử dụng design system thích hợp nếu có sẵn; nếu chưa có, xây nền tảng local nhất quán. Dùng Auto Layout, constraints, component/instance và variants cho các phần lặp lại; đặt tên layer có nghĩa.

Các component cần có: button, icon button, text input, search, chip/filter, bottom navigation, app bar, product card, size/color selector, quantity stepper, address card, order card, status badge, AI product/outfit recommendation, bottom sheet, dialog, toast/banner, skeleton và empty/error state. Có variants cần thiết như default/selected/disabled/loading/error; không tạo mọi tổ hợp vô ích.

## 5. Toàn bộ giao diện khách hàng

Đề xuất bottom navigation gồm Trang chủ, Khám phá, Phối đồ AI, Yêu thích, Tài khoản. Giỏ ở vị trí dễ tìm như app bar; đơn hàng truy cập từ Tài khoản và sau checkout. Giữ navigation nhất quán.

### A. Bắt đầu, tài khoản và hồ sơ
- Splash/welcome ngắn; onboarding gọn và có bỏ qua nếu sử dụng.
- Đăng nhập email/mật khẩu, đăng ký, trạng thái xác nhận email nếu cấu hình yêu cầu, validation và lỗi xác thực.
- Hồ sơ/Tài khoản, chỉnh sửa thông tin và avatar, xác nhận đăng xuất.
- Cho phép xem catalog trước khi đăng nhập; khi cần đặt hàng hoặc dùng chức năng cần tài khoản thì dẫn đăng nhập và quay lại đúng ngữ cảnh.

### B. Khám phá và sản phẩm
- Trang chủ có hero thời trang, danh mục, bộ sưu tập hoặc gợi ý sản phẩm; CTA phối đồ AI nhìn thấy được nhưng không lấn át mua sắm.
- Danh mục/khám phá, danh sách hoặc lưới sản phẩm.
- Tìm kiếm, kết quả tìm kiếm, sắp xếp và bottom sheet lọc giá/danh mục/size/màu; có áp dụng/xóa bộ lọc.
- Chi tiết sản phẩm: gallery, tên/giá, size, màu, tồn kho, mô tả/chất liệu, hướng dẫn size dạng bảng, đánh giá và CTA thêm giỏ cố định hợp lý.
- Chặn thêm giỏ khi chưa chọn biến thể, thể hiện hết hàng và có phản hồi thêm thành công.
- Danh sách đánh giá và màn yêu thích có thêm/xóa.

### C. Giỏ hàng, địa chỉ, checkout và đơn
- Giỏ có ảnh, biến thể, giá, chỉnh số lượng/xóa; phân biệt cùng sản phẩm khác size/màu.
- Danh sách địa chỉ và form thêm/sửa, chọn địa chỉ giao hàng.
- Checkout COD: kiểm tra sản phẩm, địa chỉ, phí giao hàng, tổng tiền và CTA đặt hàng; không thêm thanh toán online.
- Xác nhận đơn thành công; đi tới chi tiết đơn hoặc tiếp tục mua.
- Danh sách/lịch sử đơn với bộ lọc trạng thái; chi tiết đơn có sản phẩm, địa chỉ, COD, tổng tiền và timeline trạng thái.
- Form đánh giá cho sản phẩm trong đơn hoàn tất; khách chưa đủ điều kiện không thấy hành động đánh giá như đã được phép.

### D. Tư vấn/phối đồ AI
- Màn nhập nhu cầu gồm phong cách, dịp sử dụng, ngân sách trang phục và nội dung tự do; có prompt gợi ý bấm thử.
- Trạng thái đang tư vấn, kết quả có giải thích ngắn và bộ sản phẩm từ catalog, tổng giá bộ đồ và lựa chọn thay món/điều chỉnh nhu cầu.
- Mỗi sản phẩm AI gợi ý mở được đúng trang chi tiết. Có thêm một món hoặc thêm bộ đồ khi đã chọn đủ size/màu; xử lý món hết hàng.
- Có trạng thái không có bộ phù hợp ngân sách, lỗi dịch vụ/quota/timeout và thử lại.
- Cảm giác AI nằm trong trải nghiệm mua sắm, không chỉ một màn chat chung chung với câu trả lời dạng đoạn văn.
- Không thêm lịch sử chat, lưu outfit hoặc chức năng mới cần backend riêng nếu chưa được yêu cầu.

### E. Ngoại tuyến và trạng thái hệ thống
- Xem catalog đã lưu với banner ngoại tuyến và dấu thời điểm cập nhật phù hợp.
- Khi chưa có cache: thông báo và thử lại; khi có mạng: trạng thái tải lại dữ liệu.
- Checkout/gọi AI cần mạng; không hiển thị đặt đơn thành công hoặc có kết quả AI trực tiếp khi đang ngoại tuyến.
- Chuẩn bị trạng thái loading, empty, lỗi và thành công cho các nhóm chính. Có giỏ trống, yêu thích trống, không có kết quả và chưa có đơn.

## 6. Toàn bộ giao diện quản trị mobile

Dùng cùng design language, tối ưu cho thao tác dữ liệu trên điện thoại. Admin đã đăng nhập có lối Vào quản trị và Quay lại cửa hàng; người dùng thường không thấy các thao tác admin. Tạo prototype flow riêng để demo vai trò admin.

- Dashboard: số đơn, đơn theo trạng thái và tổng giá trị đơn hoàn tất; nhãn chỉ số chính xác, trình bày gọn.
- Danh sách/tìm sản phẩm, trạng thái đang bán/ẩn/hết hàng.
- Form thêm/sửa sản phẩm: tên, giá, mô tả, danh mục, ảnh, biến thể size/màu, tồn kho và validation.
- Quản lý danh mục: danh sách, thêm/sửa; màn hoặc sheet tùy mật độ nội dung.
- Quản lý biến thể/tồn kho; trạng thái cập nhật và lỗi.
- Xác nhận ẩn/ngừng bán; bảo toàn lịch sử sản phẩm đã có trong đơn.
- Danh sách đơn, bộ lọc và chi tiết đơn; cập nhật trạng thái theo quy tắc, xác nhận thao tác và phản hồi thành công.
- Danh sách người dùng, chi tiết hồ sơ và trạng thái truy cập ở phạm vi cơ bản; hành động đặc quyền có xác nhận và trạng thái lỗi.
- Dùng list/card/form mobile thay vì ép bảng desktop nhiều cột vào màn nhỏ.

## 7. Dữ liệu demo nhất quán

Tạo khoảng 12–18 sản phẩm đại diện cho áo, quần, váy/đầm, áo khoác, giày/phụ kiện, với tên/mã/ảnh/giá/màu/size/tồn kho nhất quán. Có ít nhất một biến thể hết hàng. Ghi rõ đây là dữ liệu mô phỏng trong Cover/handoff; không đưa chú thích kỹ thuật lên mọi màn hình của sản phẩm.

Kịch bản demo mua và AI dùng cùng dữ liệu:
- Người dùng tìm đồ đi chơi phong cách casual, ngân sách trang phục 500.000đ.
- Một bộ gợi ý gồm áo thun 199.000đ và quần jeans 249.000đ, tổng sản phẩm 448.000đ.
- Phí giao hàng demo 25.000đ, tổng checkout 473.000đ nếu mua bộ này.
- Product detail, giỏ, checkout, đơn khách và đơn admin phải khớp sản phẩm/biến thể/số lượng/giá.
- Tên và giá các sản phẩm khác tự chọn hợp lý. Không dùng Lorem ipsum hoặc số liệu kinh doanh/phản hồi thật chưa tồn tại để tạo cảm giác đáng tin.

## 8. Prototype phải chạy được

Thiết lập flow starting points, liên kết thật giữa frame/overlay và tương tác đóng/mở/back. Thiết kế trạng thái chọn tab, lọc, size/màu, quantity, xác nhận và toast. Dùng transitions nhẹ, nhất quán; tránh animation gây chậm demo.

Ba flow bắt buộc:
1. Mua hàng: Welcome/đăng nhập khi cần → Trang chủ/Khám phá → tìm/lọc → chi tiết/chọn size-màu → giỏ → địa chỉ → checkout COD → thành công → chi tiết đơn.
2. AI: Phối đồ AI → nhu cầu casual/đi chơi/500.000đ → đang tư vấn → bộ 448.000đ → xem/đổi món/chọn biến thể → thêm giỏ → tiếp tục checkout; có nhánh lỗi và thử lại.
3. Admin: Dashboard → sản phẩm → thêm/sửa/ẩn → đơn hàng → chi tiết/cập nhật trạng thái → danh sách người dùng → quay lại cửa hàng.

Dùng variables/interactive component nếu tool hỗ trợ và có ích. Với nhập liệu/tính toán/AI, dùng dữ liệu preset và mô phỏng tương tác có chủ đích; ghi rõ đây là prototype, chưa nối Supabase/Gemini thật. Nếu một tương tác không thể làm bằng MCP hiện tại, ghi chính xác nút/frame còn thiếu và cách hoàn thiện; không tuyên bố prototype đầy đủ khi chỉ có mũi tên trên canvas.

Đường đi chính phải có điểm bắt đầu, điểm kết thúc và lối quay lại hợp lý. Các màn phụ không được trở thành ngõ cụt. Nút thay đổi trạng thái cần thể hiện kết quả; không nối mọi CTA về cùng một trang đích.

## 9. Quy trình thực hiện và kiểm tra

1. Lập screen/flow inventory và kiểm tra tools/file/library sẵn có.
2. Chọn một hướng visual rõ ràng; tạo foundations/components và bốn màn chuẩn: Home, Product Detail, AI Result, Admin Order Detail. Tự kiểm tra chất lượng rồi dùng cùng ngôn ngữ cho phần còn lại, không chờ tôi duyệt từng màn.
3. Hoàn thành toàn bộ nhóm màn/overlay/state ở brief. Dùng chung component, không vẽ lại mỗi màn theo một style khác.
4. Nối prototype và thiết lập flow starting points.
5. Kiểm tra lại layer/font/Auto Layout, ảnh, nội dung, bố cục, safe area, nội dung dài và responsive ở màn đại diện.
6. Xem render/screenshot các màn chủ chốt và các màn còn lại theo từng cụm; sửa clipping/overlap, ảnh trống và CTA bị che. Đối chiếu danh mục màn để không bỏ sót chức năng.
7. Kiểm tra từng đường đi prototype bằng khả năng kiểm tra của công cụ: reaction destinations, overlay/back và starting points. Nếu không thể chạy thử tương tác trực tiếp, nêu rõ phần đã kiểm tra cấu trúc và phần người dùng cần xác nhận, không ghi đã playtest.

## 10. Đầu ra và tiêu chí hoàn thành

Trả về:
- Link file Figma Design chỉnh sửa được.
- Link hoặc hướng dẫn mở ba prototype starting flows.
- Chỉ mục screen/node và danh sách chức năng/trạng thái đã phủ, kèm những phần thật sự còn thiếu.
- Bộ foundations/components/variants dùng lại được.
- Handoff ngắn: tokens, component, navigation, quy tắc biến thể/tồn kho/ngân sách AI/trạng thái đơn/ngoại tuyến và giới hạn mô phỏng.
- Mapping giao diện theo nhóm công việc: Quân nền tảng/Data catalog/AI; Hải Auth/UI catalog/admin sản phẩm; Phúc giỏ/đơn/thống kê/QA. Đây là định hướng bàn giao, không tự thay assignee hoặc estimate trên GitHub.

Chỉ đánh dấu hoàn tất khi các màn theo phạm vi đã có trong Figma và ba flow được nối bằng prototype thực tế, hoặc báo minh bạch phần bị tool chặn. Ưu tiên bộ thiết kế đẹp, đồng bộ, có thể triển khai hơn việc đạt một số lượng frame hình thức.

Ngoài phạm vi: AR/thử đồ ảo, tìm bằng ảnh, quét nhãn, AI đo cơ thể/gợi ý size riêng, thanh toán online, vận chuyển tích hợp, ứng dụng người bán, dashboard web và dark mode toàn bộ. Hướng dẫn size thường vẫn được thiết kế trong chi tiết sản phẩm.

Hãy bắt đầu kiểm tra Figma MCP và thực hiện thiết kế ngay theo brief này.

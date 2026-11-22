# Đặc tả kiểm thử Checkout COD/Orders — Issue #20

Trạng thái tài liệu **Dự thảo**. D01–D14 đang chờ review. Dùng [Issue #20](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/20) và [thiết kế Checkout COD/Orders](../architecture/checkout-cod-orders-design.md) làm căn cứ. AC1–AC6 là thứ tự sáu gạch đầu dòng trong mục Tiêu chí chấp nhận của Issue. Ca Reviews là kiểm tra giao thoa với [Issue #18](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/18).

## Cách sử dụng

- **PROVISIONAL** đánh dấu kỳ vọng phụ thuộc contract chưa duyệt. Khi có quyết định, đối chiếu lại kỳ vọng, mã lỗi, giới hạn và điều kiện trước khi nghiệm thu.
- Chuẩn bị ngay bằng cách rà fixture, phác thảo bảng quyền và kịch bản hai kết nối, thiết kế fake UI. **COD-SESSION-02** là ca duy nhất có thể chạy đầy đủ trên baseline S1 với fake hoặc môi trường local phù hợp. Đối chiếu ADDR-02, ADDR-05 và NAV-03 để tái sử dụng bước kiểm tra nền. Bằng chứng của [matrix Sprint 1](test-matrix.md) không được chuyển thành kết quả cho bộ này.
- Ca Orders cần bản triển khai hoặc fake theo điều kiện của từng ca. SQL hai kết nối cần kết nối độc lập, xác nhận thao tác thực sự chồng thời gian và ghi kết quả sau khi cả hai kết thúc. REST dùng JWT đúng vai trò; kiểm tra lại số dòng và dữ liệu sau thao tác bị chặn, kể cả khi HTTP trả thành công với 0 dòng.
- Chỉ dùng fake hoặc môi trường kiểm thử đã được nhóm duyệt theo D14. Dữ liệu tạo thêm thuộc fixture tổng hợp trong môi trường riêng. Ghi baseline trước mỗi biến thể ca, ghi Actual riêng cho từng biến thể và reset đúng phần fixture giữa các lượt. Ghi ngày, kết quả và bằng chứng theo lần chạy; che JWT, thông tin xác thực và dữ liệu cá nhân.

## Fixture dùng chung

| Fixture | Dữ liệu |
|---|---|
| A, B, A1, A2, B1 | Tái sử dụng tài khoản và địa chỉ tổng hợp theo [đặc tả dữ liệu P01/Q03](test-data-spec.md), dùng ID lấy lúc chạy. Admin là tài khoản thử có quyền server, Anonymous là phiên không đăng nhập. |
| Giỏ chuẩn | SF01-WHITE-M ×1 giá 199.000đ và SF02-DENIM-M ×1 giá 249.000đ theo seed. Tra variant theo SKU. Có thể tái sử dụng cấu trúc [fixture giỏ](../../test/features/cart/cart_fixtures.dart) và [fixture địa chỉ](../../test/features/addresses/address_fixtures.dart) cho fake. |
| Tồn biên | SF01-WHITE-XL có tồn 0 trong seed. Ca tranh món cuối dùng SF01-WHITE-M với tồn 1 được thiết lập trên bản fixture local độc lập; kiểm tra baseline thực tế trước khi chạy. |
| Q1/Q2, R1/R2 và đơn mẫu | Alias cho quote, request ID và đơn sinh lúc chạy hoặc trả từ fake; lưu quan hệ owner/quote/đơn trong ghi chú test. Không dùng ID minh họa như dữ liệu đã tồn tại. |

## Quyết định cần review trước khi nghiệm thu

- **Quân** xác nhận D06/D10/D11, chốt D02/D07 với Hải đối chiếu UI và điều phối D14.
- **Quân và Hải** xác nhận D01/D03/D04/D05/D08/D09/D12/D13. Phúc cần ưu tiên D04/D05/D06/D08/D09/D11/D14 trước khi chốt kỳ vọng các ca migration, quyền và transaction.
- **Cả nhóm** xác nhận D14, gồm môi trường, thứ tự migration, người phụ trách, khả năng chạy hai kết nối/REST JWT và cách dọn fixture.

## Checkout quote

### COD-QUOTE-01

- **Issue / quyết định** — #20 AC1, AC3 · D01, D02, D03, D12
- **Mục tiêu** — Tính quote toàn giỏ trên server
- **Điều kiện tiên quyết** — RPC quote và catalog seed đã kiểm tra
- **Dữ liệu kiểm thử** — A, A1, Giỏ chuẩn
- **Các bước thực hiện** — 1. Chọn A1. 2. Yêu cầu quote. 3. So dòng hàng, phí và tồn trước/sau.
- **Expected Result** — **PROVISIONAL** · Hai dòng đúng SKU/SL, tạm tính 448.000đ, phí 25.000đ, tổng 473.000đ; tồn và giỏ như trước.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-QUOTE-02

- **Issue / quyết định** — #20 AC1, AC6 · D01, D03, D12
- **Mục tiêu** — Chặn quote không hợp lệ
- **Điều kiện tiên quyết** — RPC quote; mỗi biến thể ca dùng trạng thái độc lập
- **Dữ liệu kiểm thử** — A, A1, B1, giỏ rỗng, SKU hết tồn hoặc catalog ngừng bán
- **Các bước thực hiện** — 1. Thử B1 với giỏ hợp lệ. 2. Thử A1 với giỏ rỗng. 3. Với A1 thử từng trạng thái hết tồn, sản phẩm ẩn và category inactive.
- **Expected Result** — **PROVISIONAL** · Mỗi trường hợp bị từ chối theo nguyên nhân; không cấp quote dùng được và không đổi tồn/giỏ.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-QUOTE-03

- **Issue / quyết định** — #20 AC1, AC3 · D01, D03, D12
- **Mục tiêu** — Buộc xác nhận lại khi quote cũ
- **Điều kiện tiên quyết** — RPC quote/place; clock kiểm soát được hoặc môi trường thử TTL
- **Dữ liệu kiểm thử** — A, A1, Giỏ chuẩn
- **Các bước thực hiện** — 1. Tạo quote. 2. Trên fixture độc lập, thay riêng từng yếu tố: giỏ, giá, trường địa chỉ, metadata snapshot, trạng thái bán hoặc thời điểm vượt TTL 300 giây theo đề xuất. 3. Thử đặt bằng quote cũ.
- **Expected Result** — **PROVISIONAL** · Quote cũ bị từ chối theo nguyên nhân, chẳng hạn `SF_CART_CHANGED`, `SF_QUOTE_STALE`, `SF_PRODUCT_UNAVAILABLE` hoặc `SF_QUOTE_EXPIRED` theo D12. Không tạo đơn/trừ tồn. Sau khi xử lý nguyên nhân, cần quote mới và xác nhận lại.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-QUOTE-04

- **Issue / quyết định** — #20 AC1 · D01, D12
- **Mục tiêu** — Kiểm tra giới hạn quote
- **Điều kiện tiên quyết** — RPC quote; tồn thử đủ để tách kiểm tra giới hạn khỏi lỗi tồn
- **Dữ liệu kiểm thử** — A, A1; fixture biên tổng hợp chỉ dùng ở local
- **Các bước thực hiện** — 1. Gọi quote với giỏ 100 rồi 101 variant khác nhau. 2. Lặp lại với một dòng 99 rồi 100 đơn vị; dùng fixture ở lớp phù hợp nếu Cart chặn sớm. 3. Tạo 10 quote đang hoạt động, thử quote thứ 11 rồi thử lại sau khi một quote hết hạn.
- **Expected Result** — **PROVISIONAL** · Mức 100 dòng, 99 đơn vị mỗi dòng và quote thứ 10 được nhận khi các điều kiện khác hợp lệ. Vượt giới hạn bị từ chối. Sau khi một quote hết hạn có thể tạo quote mới. Nếu Cart chặn đầu vào sớm, ghi rõ lớp đã kiểm chứng.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Transaction đặt đơn COD

### COD-PLACE-01

- **Issue / quyết định** — #20 AC1, AC3 · D02, D04, D05, D08, D12
- **Mục tiêu** — Đặt COD từ quote hợp lệ
- **Điều kiện tiên quyết** — RPC quote/place và đọc đơn; đã ghi baseline DB
- **Dữ liệu kiểm thử** — A, A1; Giỏ chuẩn và biến thể SF01-WHITE-M ×2 + SF02-DENIM-M ×1; request riêng cho từng lượt
- **Các bước thực hiện** — 1. Xin quote với từng giỏ. 2. Đặt đơn bằng request ID mới. 3. Đọc lại header/items/event, giỏ và tồn.
- **Expected Result** — **PROVISIONAL** · Một đơn COD pending, đủ snapshot và event đầu; tổng 473.000đ ở lượt chuẩn và 672.000đ ở lượt nhiều số lượng. Tồn giảm đúng SL mỗi SKU; giỏ đã mua được dọn.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-PLACE-02

- **Issue / quyết định** — #20 AC1, AC6 · D03, D05, D12
- **Mục tiêu** — Server tự kiểm tra giá, quyền và tồn lúc đặt
- **Điều kiện tiên quyết** — RPC quote/place; làm từng nhánh trên fixture độc lập
- **Dữ liệu kiểm thử** — A, B, A1, Giỏ chuẩn; quote của A
- **Các bước thực hiện** — 1. Với JWT A, gửi request đặt hợp lệ kèm giá/tổng/user ngoài chữ ký RPC. 2. Với JWT B, gửi quote của A bằng đúng chữ ký. 3. Với JWT A, giảm tồn xuống dưới SL đã báo giá rồi đặt bằng quote của A.
- **Expected Result** — **PROVISIONAL** · Request có tham số ngoài chữ ký bị từ chối theo giao diện đề xuất. B không đặt được bằng quote A; lượt thiếu tồn trả lỗi stock. Đối chiếu từng lượt để xác nhận không phát sinh order/items/event/receipt và không trừ tồn thêm.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Idempotency và replay

### COD-REPLAY-01

- **Issue / quyết định** — #20 AC2, AC6 · D06, D07, D12
- **Mục tiêu** — Retry sau khi response thành công bị mất
- **Điều kiện tiên quyết** — RPC place/lookup; có proxy hoặc harness bỏ response sau commit
- **Dữ liệu kiểm thử** — A, quote Q1, request R1
- **Các bước thực hiện** — 1. Đặt và bỏ response sau commit. 2. Lookup rồi gửi lại Q1/R1, kể cả khi giỏ đã dọn hoặc quote hết hạn. 3. Đọc lại tồn và đơn.
- **Expected Result** — **PROVISIONAL** · Trả cùng kết quả đặt và order ID; một đơn, một lần trừ tồn; lookup chỉ thấy receipt của A.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-REPLAY-02

- **Issue / quyết định** — #20 AC2, AC6 · D06, D12
- **Mục tiêu** — Phát hiện đổi payload hoặc dùng lại quote
- **Điều kiện tiên quyết** — RPC place/status; Q1 đã thành đơn theo R1
- **Dữ liệu kiểm thử** — A, A1, Q1/Q2 được tạo trước khi đặt, R1, R2 mới; đơn A đang pending
- **Các bước thực hiện** — 1. Gửi Q2/R1. 2. Dùng A gửi yêu cầu hủy đơn pending của mình với version và reason hợp lệ nhưng dùng lại R1. 3. Gửi Q1/R2.
- **Expected Result** — **PROVISIONAL** · Hai lần dùng R1 khác payload/thao tác báo xung đột; Q1/R2 bị từ chối vì quote đã dùng; không ghi thêm.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-REPLAY-03

- **Issue / quyết định** — #20 AC2, AC5 · D04, D06, D12
- **Mục tiêu** — Replay đổi trạng thái sau khi version đã tiến
- **Điều kiện tiên quyết** — RPC status; đơn pending có version đã đọc
- **Dữ liệu kiểm thử** — Admin, đơn A, request R1/R2
- **Các bước thực hiện** — 1. Confirm với R1. 2. Chuyển shipping với R2. 3. Gửi lại chính payload confirm của R1.
- **Expected Result** — **PROVISIONAL** · Replay trả event/version của lần confirm; đơn vẫn shipping, không thêm event hoặc đổi tồn.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Concurrency tranh tồn

### COD-RACE-01

- **Issue / quyết định** — #20 AC1, AC6 · D03, D05, D09, D14
- **Mục tiêu** — Hai khách tranh món cuối
- **Điều kiện tiên quyết** — Hai kết nối độc lập; đồng bộ trước lúc đặt; tồn đầu là 1
- **Dữ liệu kiểm thử** — A/A1, B/B1; mỗi giỏ một SF01-WHITE-M; quote riêng
- **Các bước thực hiện** — 1. Tạo cả hai quote. 2. Cho hai kết nối gửi place chồng thời gian. 3. Lưu kết quả cả hai và đọc DB sau khi cùng kết thúc.
- **Expected Result** — **PROVISIONAL** · Một đơn thành công, một yêu cầu bị từ chối do tồn; tồn cuối 0, chỉ một bộ order/items/event/receipt thành công.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-RACE-02

- **Issue / quyết định** — #20 AC2, AC6 · D06, D09, D14
- **Mục tiêu** — Hai kết nối đồng thời đặt cùng quote
- **Điều kiện tiên quyết** — Hai kết nối dùng cùng caller; tách dữ liệu giữa hai biến thể ca
- **Dữ liệu kiểm thử** — A, Q1 và request R1/R2
- **Các bước thực hiện** — 1. Gửi đồng thời Q1/R1 trên cả hai kết nối. 2. Reset fixture rồi gửi Q1/R1 và Q1/R2 đồng thời. 3. Đọc số đơn và tồn.
- **Expected Result** — **PROVISIONAL** · Cùng ID cho một lần ghi và replay; khác ID chỉ một request tạo đơn. Mỗi lượt trừ tồn một lần.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-RACE-03

- **Issue / quyết định** — #20 AC1, AC5, AC6 · D04, D05, D09, D12, D14
- **Mục tiêu** — Kiểm tra cập nhật tồn admin xen vào đặt/hủy
- **Điều kiện tiên quyết** — RPC stock của Hải có cơ chế kiểm tra tồn kỳ vọng; hai kết nối
- **Dữ liệu kiểm thử** — Admin, A, SKU dùng chung; baseline và số lượng biết trước
- **Các bước thực hiện** — 1. Lưu tồn kỳ vọng. 2. Chạy cập nhật admin chồng thời gian với đặt đơn; lặp lại với hủy. 3. Đọc thứ tự hoàn tất, tồn và event.
- **Expected Result** — **PROVISIONAL** · Tồn khớp một thứ tự thực thi hợp lệ; giá trị kỳ vọng đã cũ bị từ chối; không mất cập nhật hoặc hoàn tồn trùng.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Rollback và hoàn tồn

### COD-ROLLBACK-01

- **Issue / quyết định** — #20 AC1, AC6 · D05, D06, D09, D14
- **Mục tiêu** — Rollback lỗi giữa transaction đặt
- **Điều kiện tiên quyết** — Môi trường test riêng có điểm gây lỗi sau ghi hoặc trừ tồn, trước commit
- **Dữ liệu kiểm thử** — A, Giỏ chuẩn, A1, Q1/R1
- **Các bước thực hiện** — 1. Ghi baseline. 2. Gây lỗi khi đặt. 3. Đọc lại order/items/event/receipt, quote, giỏ và tồn từ kết nối khác.
- **Expected Result** — **PROVISIONAL** · Không có bản ghi đặt đơn dở hoặc receipt mồ côi; quote chưa dùng; giỏ và tồn bằng baseline.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-ROLLBACK-02

- **Issue / quyết định** — #20 AC2, AC5, AC6 · D04, D05, D06, D09, D14
- **Mục tiêu** — Hoàn đúng một lần và rollback nếu hủy lỗi
- **Điều kiện tiên quyết** — Đơn pending đã trừ tồn; có điểm gây lỗi trước commit
- **Dữ liệu kiểm thử** — A, đơn A, request hủy R1, SKU theo snapshot
- **Các bước thực hiện** — 1. Gây lỗi sau bước cộng tồn khi hủy; đọc lại. 2. Bỏ lỗi và hủy lại. 3. Replay request thành công rồi thử hủy bằng ID mới.
- **Expected Result** — **PROVISIONAL** · Lần lỗi giữ nguyên đơn/tồn/event/receipt. Hủy thành công hoàn đúng SL một lần, thêm một event; giỏ không tự được khôi phục.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-ROLLBACK-03

- **Issue / quyết định** — #20 AC4, AC5, AC6 · D04, D05, D09, D14
- **Mục tiêu** — Hủy và xác nhận cạnh tranh cùng version
- **Điều kiện tiên quyết** — Hai kết nối A/Admin; đơn pending
- **Dữ liệu kiểm thử** — A, Admin, đơn A cùng expected version
- **Các bước thực hiện** — 1. Gửi hủy của A và confirm của Admin đồng thời. 2. Đọc trạng thái, version, event, tồn sau cả hai.
- **Expected Result** — **PROVISIONAL** · Chỉ một thao tác thắng với version ban đầu. Nếu hủy thắng, hoàn tồn một lần; nếu confirm thắng, stock giữ mức sau đặt.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## RLS và JWT

### COD-RLS-01

- **Issue / quyết định** — #20 AC4, AC6 · D08, D12, D14
- **Mục tiêu** — Cách ly đơn và dòng con A/B
- **Điều kiện tiên quyết** — REST JWT thật, có đơn riêng A/B và ID cả hai
- **Dữ liệu kiểm thử** — A, B, đơn/items/events mỗi bên
- **Các bước thực hiện** — 1. Mỗi khách gọi list/get và SELECT trực tiếp orders/items/events cho mình và bên kia. 2. So get ID bên kia với ID không tồn tại.
- **Expected Result** — **PROVISIONAL** · Chỉ thấy đơn và dòng con của chính mình; get chéo không tiết lộ đơn tồn tại; timeline không lộ actor nội bộ.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-RLS-02

- **Issue / quyết định** — #20 AC4, AC6 · D04, D11, D12, D14
- **Mục tiêu** — Bao phủ Admin, Anonymous và ghi trực tiếp
- **Điều kiện tiên quyết** — REST với khoá công khai, JWT A/B/Admin và phiên anon; có đơn A/B
- **Dữ liệu kiểm thử** — A, B, Admin, anon; đơn và dòng con mẫu
- **Các bước thực hiện** — 1. Admin list/filter/get đơn hai khách. 2. Khách thử list admin và confirm. 3. Anon thử đọc và gọi Orders RPC. 4. Mỗi vai trò thử INSERT/UPDATE/DELETE trực tiếp trên bảng đơn và dòng con; đọc lại bằng caller có quyền.
- **Expected Result** — **PROVISIONAL** · Admin đọc đúng theo quyền và filter; khách không có quyền admin; anon không thấy dữ liệu đơn; không có ghi trực tiếp thành công, kể cả Admin.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-RLS-03

- **Issue / quyết định** — #20 AC2, AC4, AC6 · D06, D11, D12, D14
- **Mục tiêu** — Bảo vệ receipt và kiểm tra quyền mới nhất
- **Điều kiện tiên quyết** — REST JWT; cơ chế khóa/thu hồi đã triển khai theo D11
- **Dữ liệu kiểm thử** — A, B, Admin, quote/receipt của A; JWT còn hạn
- **Các bước thực hiện** — 1. B thử lookup ID của A và đọc trực tiếp quote/receipt. 2. Khách thử metadata tự nhận admin. 3. Thu hồi quyền Admin hoặc khóa A rồi gửi mutation bằng JWT cũ trong từng fixture độc lập.
- **Expected Result** — **PROVISIONAL** · Không lộ quote/receipt; metadata không cấp quyền; quyền bị thu hồi và account bị khóa bị chặn theo contract D11, không đổi DB.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## State machine đơn hàng

### COD-STATE-01

- **Issue / quyết định** — #20 AC4, AC5 · D04, D05, D12
- **Mục tiêu** — Đi đúng từng cạnh hợp lệ
- **Điều kiện tiên quyết** — RPC status và đọc timeline
- **Dữ liệu kiểm thử** — Admin, đơn pending; đọc version trước mỗi bước
- **Các bước thực hiện** — 1. Confirm. 2. Chuyển shipping. 3. Hoàn tất. 4. Đọc lại version/events/tồn sau từng lần.
- **Expected Result** — **PROVISIONAL** · Ba cạnh được phép đi tuần tự; mỗi lần tăng một version và ghi một event; stock không bị trừ thêm.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-STATE-02

- **Issue / quyết định** — #20 AC4, AC5 · D04, D05, D12
- **Mục tiêu** — Phân biệt quyền hủy và chuyển sai
- **Điều kiện tiên quyết** — Mỗi nhánh dùng đơn riêng; RPC status đã có
- **Dữ liệu kiểm thử** — A, B, Admin; đơn pending/confirmed/shipping/completed/cancelled
- **Các bước thực hiện** — 1. Thử owner hủy pending và Admin hủy pending/confirmed. 2. Thử owner hủy confirmed, B hủy đơn A, Admin hủy shipping/completed. 3. Thử nhảy bước, lùi, lặp status ID mới, chuyển từ cancelled và version cũ.
- **Expected Result** — **PROVISIONAL** · Chỉ ba biến thể hủy hợp lệ thành công. Lần bị chặn giữ nguyên trạng thái, version, tồn, event.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Snapshot và lịch sử

### COD-HISTORY-01

- **Issue / quyết định** — #20 AC1, AC3, AC4 · D08, D12, D13
- **Mục tiêu** — Đơn đã đặt giữ dữ liệu gốc
- **Điều kiện tiên quyết** — Đã đặt đơn A; có quyền chỉnh fixture trên môi trường test
- **Dữ liệu kiểm thử** — A1, Giỏ chuẩn, SKU/ảnh catalog thử
- **Các bước thực hiện** — 1. Lưu bản đọc đơn. 2. Sửa rồi xóa A1; đổi giá/tên/ảnh hoặc ẩn sản phẩm. 3. Mở lịch sử/chi tiết lại.
- **Expected Result** — **PROVISIONAL** · Snapshot địa chỉ, dòng hàng và tổng giữ giá trị lúc đặt; ảnh lịch sử theo cơ chế bất biến đã chốt. Đơn vẫn mở được.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-HISTORY-02

- **Issue / quyết định** — #20 AC3, AC4 · D04, D08, D12, D13
- **Mục tiêu** — Lọc, phân trang và timeline trả đúng phạm vi
- **Điều kiện tiên quyết** — RPC list/get; bộ đơn đủ vượt `limit=2` trong filter `all`, với hai đơn cùng thời điểm tạo nằm ở ranh giới giữa hai trang
- **Dữ liệu kiểm thử** — A/B/Admin, các trạng thái; hai đơn cùng thời điểm tạo
- **Các bước thực hiện** — 1. A đọc `all` với `limit=2` và đi theo cursor tới hết. 2. Chuyển sang `processing`, `completed` và `cancelled`, mỗi filter bắt đầu lại từ trang đầu. 3. Admin lọc `pending`. 4. Mở chi tiết và đối chiếu event đã ghi.
- **Expected Result** — **PROVISIONAL** · Mỗi đơn A xuất hiện đúng một lần theo thứ tự `created_at DESC, id DESC`. `processing` gồm pending/confirmed/shipping, hai filter terminal trả đúng trạng thái, Admin `pending` chỉ thấy pending. Timeline theo version tăng dần, chỉ hiện mốc đã có event.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## UI Checkout và lỗi mạng

### COD-UI-01

- **Issue / quyết định** — #20 AC3, AC4 · D01, D02, D03, D12, D13
- **Mục tiêu** — Đi luồng Cart → Addresses → Checkout → lịch sử
- **Điều kiện tiên quyết** — Build có route Checkout; mock repository cho lượt kiểm tra UI
- **Dữ liệu kiểm thử** — A, A1/A2, Giỏ chuẩn; quote và đơn trả từ fake
- **Các bước thực hiện** — 1. Từ Cart chọn A1 rồi Checkout. 2. Quan sát quote loading và tổng trả về. 3. Xác nhận COD, mở lịch sử/chi tiết. 4. Lặp với quote fake có tổng khác.
- **Expected Result** — **PROVISIONAL** · Đúng địa chỉ, dòng hàng và tổng từ DTO; không báo thành công trước phản hồi; chi tiết/timeline mở đúng đơn.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-UI-02

- **Issue / quyết định** — #20 AC3, AC5 · D03, D07, D12, D13
- **Mục tiêu** — Loading, lỗi nghiệp vụ, offline và retry
- **Điều kiện tiên quyết** — Build/widget với fake điều khiển quote/place và offline
- **Dữ liệu kiểm thử** — A, A1, Giỏ chuẩn; quote stale, lỗi xác định, offline
- **Các bước thực hiện** — 1. Bấm đặt nhiều lần khi pending. 2. Trả lần lượt lỗi stale và lỗi nghiệp vụ đã rollback. 3. Thử đặt khi offline rồi lấy quote mới và xác nhận khi online.
- **Expected Result** — **PROVISIONAL** · Một mutation đang chờ; stale buộc xem lại quote. Lỗi/offline không báo thành công; lần đặt mới chỉ gửi sau xác nhận hợp lệ.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-UI-03

- **Issue / quyết định** — #20 AC2, AC3, AC5 · D06, D07, D12, D13
- **Mục tiêu** — Phục hồi timeout chưa rõ kết quả
- **Điều kiện tiên quyết** — Build/widget có fake hoặc proxy kiểm soát timeout, lookup và restart
- **Dữ liệu kiểm thử** — A, Q1/R1; lookup found và not found
- **Các bước thực hiện** — 1. Kiểm tra R1 được lưu trước gửi. 2. Làm mất response, restart và đăng nhập A. 3. Thử từng kết quả lookup rồi retry nếu cần.
- **Expected Result** — **PROVISIONAL** · Hiển thị chưa rõ kết quả; found mở đúng đơn; not found không được coi là rollback. Retry giữ nguyên ID/payload.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-UI-04

- **Issue / quyết định** — #20 AC4, AC5 · D04, D05, D12, D13
- **Mục tiêu** — Admin xác nhận trước khi cập nhật trạng thái
- **Điều kiện tiên quyết** — Build có màn Admin Orders; fake kiểm soát phản hồi status
- **Dữ liệu kiểm thử** — Admin, một đơn pending và một đơn completed; fake trả thành công hoặc lỗi version
- **Các bước thực hiện** — 1. Lọc pending, mở chi tiết và chọn xác nhận đơn. 2. Đóng hộp thoại rồi kiểm tra số lần gọi RPC. 3. Mở lại, đồng ý và giữ phản hồi; thử bấm lặp. 4. Thử riêng phản hồi thành công và lỗi version; mở đơn completed.
- **Expected Result** — **PROVISIONAL** · Đóng hộp thoại không gọi RPC. Sau khi đồng ý chỉ gửi một mutation với version đã đọc. Chỉ cập nhật màn hình sau phản hồi thành công; lỗi version yêu cầu tải lại. Đơn completed không có hành động chuyển tiếp.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-UI-05

- **Issue / quyết định** — #20 AC1, AC3, AC4 · D01, D02, D04, D05, D08, D12, D13, D14
- **Mục tiêu** — Nghiệm thu luồng COD đầu cuối qua build tích hợp và backend thật
- **Điều kiện tiên quyết** — Build Checkout/Orders và RPC trên môi trường kiểm thử đã duyệt; có thể đọc lại đơn từ server
- **Dữ liệu kiểm thử** — A, A1, Giỏ chuẩn; Admin thử nghiệm
- **Các bước thực hiện** — 1. A mở Cart, chọn A1, kiểm tra quote và đặt COD. 2. Ghi order ID, tải lại ứng dụng và mở lịch sử/chi tiết. 3. Admin tìm và xác nhận đơn qua UI. 4. A tải lại chi tiết/timeline và đối chiếu đơn trên server.
- **Expected Result** — **PROVISIONAL** · Quote và đơn cùng tổng 473.000đ theo rule server; chỉ một đơn được ghi, có snapshot ở lịch sử sau khi tải lại. Admin xác nhận thành công; A thấy đúng trạng thái và mốc tương ứng trên cùng đơn.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Regression đổi tài khoản

### COD-SESSION-01

- **Issue / quyết định** — #20 AC2, AC3, AC4 · D06, D07, D12, D13
- **Mục tiêu** — Không rò trạng thái khi A đổi sang B
- **Điều kiện tiên quyết** — Build/widget với response trì hoãn và lưu pending theo user
- **Dữ liệu kiểm thử** — A/B, A1/B1, Q1/R1 của A, lịch sử riêng B
- **Các bước thực hiện** — 1. A đặt hoặc tải chi tiết, giữ response. 2. Logout A/login B rồi thả response A. 3. Reload B. 4. Đăng nhập lại A và lookup.
- **Expected Result** — **PROVISIONAL** · B chỉ thấy giỏ/địa chỉ/đơn của B, không có toast hoặc pending của A, không gửi R1 bằng JWT B; A có thể phục hồi request của mình.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

### COD-SESSION-02

- **Issue / quyết định** — #20 AC3, AC4 (hồi quy nền), #7 AC2/AC3 theo matrix S1 · D07/D13 chỉ liên quan khi nối Orders
- **Mục tiêu** — Rà hồi quy nền Cart/Addresses trước tích hợp
- **Điều kiện tiên quyết** — Build S1 hoặc fake hiện có; ca chỉ dùng luồng Cart/Addresses hiện hành
- **Dữ liệu kiểm thử** — A/B, A1/B1, SKU seed; address_fixtures/cart_fixtures
- **Các bước thực hiện** — 1. Chọn địa chỉ và thêm hàng bằng A. 2. Logout/login B và reload. 3. Chuyển lại A, kiểm tra lựa chọn hợp lệ theo tài khoản.
- **Expected Result** — B không thấy giỏ hoặc lựa chọn địa chỉ A. A chỉ thấy dữ liệu của A sau khi quay lại. Đây là kỳ vọng hồi quy S1; hành vi pending Orders ở SESSION-01.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

## Phụ thuộc Reviews

### COD-REVIEWS-01

- **Issue / quyết định** — #18 (điều kiện đánh giá sau mua), #20 (phụ thuộc Orders) · D04, D08, D10, D11
- **Mục tiêu** — Kiểm tra contract Orders–Reviews cùng Quân
- **Điều kiện tiên quyết** — Backend #18 đã tích hợp; dữ liệu review reset được; ca liên module
- **Dữ liệu kiểm thử** — A/B; A sở hữu đơn có sản phẩm X, B chưa mua X; Y chưa từng được mua trong đơn của A; chưa có review X của A
- **Các bước thực hiện** — 1. Thử đánh giá X bằng A từ fixture độc lập cho từng trạng thái pending/confirmed/shipping/cancelled. 2. Với đơn completed của A, thử bằng B cho X và bằng A cho Y. 3. Dùng A đánh giá X hai lần qua đường tạo review. 4. Đọc payload công khai.
- **Expected Result** — **PROVISIONAL** · Các lượt sai owner, sai sản phẩm hoặc chưa completed bị từ chối. Lượt hợp lệ tạo một review; lượt tạo trùng không tăng số bản ghi. Payload công khai không có mã đơn, địa chỉ, số điện thoại hoặc timeline.
- **Actual Result** — Chưa chạy
- **Status** — Not Run
- **Môi trường** —
- **SHA** —
- **Build** —

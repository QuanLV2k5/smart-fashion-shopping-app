# Q04 – Bằng chứng kiểm tra AI, 18/11/2026

Phạm vi: Issue #17, nhánh `feat/q04-ai-outfits`, phát triển trên main `b7c92a6`.
Hải là reviewer. Chưa tự đóng Issue hoặc merge main.

## Cập nhật phối đồ từ ảnh ngày 21/11/2026

Build mới: **0.1.6+7**. Function `ai-outfits` v12 đã deploy bằng Supabase CLI lên `smart-fashion-dev`; dùng secret Gemini đã lưu, không đọc giá trị secret. Mã nguồn gồm index/core/vision/garment và vẫn xác thực `/auth/v1/user` trước khi gọi AI.

### Smoke test cloud thật

Lần chạy lúc **11:06 ngày 21/11/2026, GMT+7**, dùng ảnh sơ mi xanh cắt từ atlas demo, không dùng ảnh cá nhân. CLI tạo một fixture Auth riêng, đăng nhập qua GoTrue thật và dọn đúng fixture sau test. Không dùng mật khẩu/JWT của Quân; không lưu credential vào evidence.

| Kiểm tra | Kết quả quan sát |
|---|---|
| Không đăng nhập | HTTP 401 |
| Gửi JPEG đến Gemini | Nhận diện áo sơ mi dài tay, xanh dương nhạt, trơn; khoảng 3.063 ms |
| Công sở, đi học/bảo vệ đồ án, mua thêm <=700.000đ | Quần suông Studio 329.000đ + Sneaker Everyday 359.000đ = **688.000đ**; khoảng 2.252 ms cho lượt tư vấn |
| Món người dùng đã có | Giữ áo đã nhận diện; không có áo shop trong kết quả và không tính giá áo |
| Giỏ thật | Thêm hai biến thể còn hàng bằng `mutate_cart`; giỏ hai dòng, tổng **688.000đ** |
| Retry giỏ | Gửi lại cùng request ID không tăng thêm số lượng |
| Ngân sách 50.000đ | Trả no-match, không bịa sản phẩm |
| Đổi quần, giữ sneaker và áo đã có | Jeans Straight + Sneaker Everyday = **608.000đ** |
| Ảnh trống PNG | Status `unclear`, garment null |
| Hồi quy tư vấn cũ 500.000đ | Áo thun Essential + Jeans Straight = **448.000đ** |
| Dọn fixture | Tài khoản fixture đã xóa; profile/quota/giỏ thuộc fixture được dọn theo cascade |

Số thời gian là quan sát của một lượt smoke, không phải benchmark hay SLA. Kết quả model có thể khác giữa các lần. Evidence JSON đã loại credential: `docs/testing/evidence/photo-ai-live-2026-11-21.json`.

### Kiểm thử local và thiết bị

- **154/154 Flutter tests**, analyzer không có issue; **25/25 Node tests**. Kiểm tra thêm sửa thuộc tính nhận diện, một món mua thêm, hủy picker giữ ảnh cũ, hủy AI bỏ phản hồi trễ, đổi tài khoản xóa ảnh, bố cục 360/390/430px và chữ lớn kèm bàn phím.
- Ảnh `ai-photo-*-390.png` từ widget Flutter với fixture chỉ dùng QA giao diện; không thay thế smoke Gemini thật ở trên. Tái tạo bằng `flutter test tool/photo_ai_capture_test.dart --no-pub`.
- APK mới cần Quân cài đè và thử camera/gallery thật trên Android. Build và widget test không thay cho xác nhận thiết bị.

### Kịch bản thử APK

1. Đăng nhập → Trang chủ → Phối đồ AI → **Phối từ ảnh món đồ đã có**.
2. Chụp riêng một chiếc áo ở nơi đủ sáng hoặc chọn ảnh JPG/PNG/WebP dưới 2 MB.
3. Bấm **Nhận diện món đồ**, kiểm tra/sửa loại/màu/họa tiết/kiểu dáng rồi **Xác nhận món đồ**.
4. Chọn dịp/phong cách, nhập ngân sách mua thêm và mô tả, bấm **Tìm món phối cùng**.
5. Kiểm tra khối **Bạn đã có**, tổng mua thêm, thử **Đổi món này**.
6. Bấm **Chọn món mua thêm**, chọn size/màu và thêm giỏ; kiểm tra không có dòng tính tiền cho món đã có.
7. Thử ảnh không có quần áo, hủy khi chờ, ngân sách 50.000đ và mất mạng. Không gửi ảnh khuôn mặt/thông tin riêng vào cấu hình Gemini miễn phí.

## Đã kiểm tra thực tế trên smart-fashion-dev ngày 18/11

- Secret `GEMINI_API_KEY` do Quân tự lưu trong Dashboard; chỉ kiểm tra tên secret, không lấy giá trị vào repo/app.
- Migration `20261118000100_ai_rate_limit.sql` đã chạy thành công bằng SQL Editor. Không chạy lại các migration cũ.
- `supabase/tests/ai_rate_limit.sql` chạy cloud PASS: anon không gọi được RPC; 6 lượt đầu được chấp nhận, lượt 7 bị chặn; user khác có quota riêng; client không đọc được bảng private; cửa sổ phút mới reset. Fixture và thay đổi quota được ROLLBACK.
- Function `ai-outfits` đã deploy trên dev. Bỏ gateway JWT legacy nhưng handler bắt buộc kiểm tra Auth `/auth/v1/user` trước quota/catalog/Gemini. Hai file nguồn đã đối chiếu nội dung với editor cloud khi triển khai.
- Web tại `http://localhost:8080/#/ai` dùng phiên người dùng thật đã đăng nhập từ trước. Không lấy token hoặc mật khẩu từ browser.
- Endpoint cloud không có Bearer đã thử trực tiếp: HTTP 401, code UNAUTHORIZED.
- Log cuộc gọi thành công: 18/11/2026 11:15:18 (GMT+7), POST 200, ID `b57be012-fdb9-4314-a93a-2cc5209e0ae8`; đối chiếu trong Supabase Function Logs.
- Kiểm thử mở rộng 700.000đ đã phát hiện model tự ghép vượt ngân sách; validator chặn đúng. Backend được đổi sang tạo tối đa 64 bộ hợp lệ rồi cho Gemini chọn outfitId. Sau sửa, cuộc gọi thật trả Áo thun Essential + Jeans Straight + Túi Terra = **627.000đ / 700.000đ**, còn **73.000đ**, không cần để model tự tính giá.
- Đổi áo trên bộ 700.000đ thành công qua Gemini thật: giữ Jeans Straight và Túi Terra, thay Áo thun Essential bằng Polo Weekend, tổng **657.000đ / 700.000đ**, còn **43.000đ**. Giá và món giữ lại được kiểm tra ở server, không dựa vào phép cộng của model.
- Gọi Gemini thật với Casual / Đi chơi / 500.000đ: trả Áo thun Essential (199.000đ) + Jeans Straight (249.000đ), tổng **448.000đ**, còn **52.000đ**.
- Nội dung Gemini quan sát: “Bộ đồ phong cách Casual năng động với áo thun Essential và quần Jeans Straight, rất phù hợp để đi chơi và nằm trong ngân sách 500k.” Không coi output cố định này là kết quả luôn được đảm bảo.
- Chọn áo M/Trắng ngà và jeans M/Xanh denim, thêm bộ qua RPC giỏ thật thành công. Giỏ trước thử: áo SL2 + jeans SL1, 647.000đ; sau thử: áo SL3 + jeans SL2, 1.095.000đ. Chênh đúng 448.000đ.
- Sau thử đã giảm mỗi món 1 để trả lại giỏ ban đầu: 3 món, 647.000đ. Không xóa giỏ hay thay dữ liệu sản phẩm.
- Đã quan sát lỗi dịch vụ và timeout thật với model Flash; ứng dụng báo lỗi/thử lại. Bản dev hiện chọn `gemini-flash-lite-latest` để phù hợp tác vụ ngắn, tối đa một lần retry với lỗi provider 5xx, cùng timeout Gemini 35 giây; client chờ tối đa 75 giây cho toàn chuỗi Auth/quota/catalog/AI/đọc lại.

## Kiểm thử tự động và build

Kết quả local: 142/142 Flutter tests, analyzer không có lỗi/cảnh báo, format đạt; 16/16 Node tests; APK debug và web build thành công.

- Node core/handler: ID giả, trùng ID, vượt ngân sách, stock=0, giá đổi sau Gemini, xác thực/JWT, input, quota, timeout, JSON lỗi, giữ các món còn lại khi đổi món.
- Flutter: validation ngân sách, hủy bỏ kết quả đến muộn, no-match, form/result/sheet ở 360/390/430px; giá đổi trước thêm; thành công một phần và retry dùng đúng request ID; đối chiếu catalog, tổng tiền, đăng xuất khi chờ kết quả.
- Schema Gemini có enum outfitId của các bộ được server tính sẵn trong ngân sách, không để model tự cộng tiền, tối đa 4096 token phản hồi (vẫn giới hạn lời giải thích 1200 ký tự ở validator). Log lỗi chỉ giữ mã kiểm tra an toàn (SHAPE/CATALOG/BUDGET/KEEP_IDS/JSON/OPTION_ID) và finishReason thuộc danh sách cho phép; không ghi response thô.
- Các test mock chỉ chứng minh logic. Cuộc gọi thật và giỏ thật ở phần trên là smoke test riêng.
- Ảnh `ai-form-390.png`, `ai-loading-390.png`, `ai-result-fixture-390.png` được render từ widget Flutter với fixture, font và atlas của app để kiểm tra layout. **Ảnh fixture không thay cho bằng chứng Gemini thật.** Lệnh tái tạo: `flutter test tool/ai_capture_test.dart --no-pub`.

## Tái hiện nhanh khi review

1. Chạy app cấu hình dev, đăng nhập tài khoản đã xác nhận email.
2. Trang chủ → Phối đồ AI → preset casual 500.000đ → Gợi ý trang phục.
3. Kiểm tra tổng <= ngân sách, mở chi tiết đúng sản phẩm; quay lại để chọn size/màu và thêm cả bộ.
4. Thử Đổi món: giữ các ID còn lại, loại món đã chọn, kiểm tra lại ngân sách/stock. Khi không có bộ hợp lệ phải báo no-match.
5. Thử ngân sách 50.000đ; thử mất mạng; hủy khi đang chờ. Không hiện bộ AI giả để che lỗi.
6. Kiểm tra giỏ sau mở lại app, số lượng/giá; không kết luận checkout hoàn tất nếu chưa có module checkout.

## Còn cần trước khi đóng Issue

- Hải review diff và CI HEAD đạt, sau đó Quân merge theo quy trình nhóm.
- Quân cài/chạy APK bản AI cuối trên Android và xác nhận luồng thực tế trên thiết bị. Build APK không thay bằng kiểm thử thiết bị.
- Kiểm tra nối tiếp sang checkout khi module phụ thuộc được tích hợp. Hiện main chỉ có giỏ và sổ địa chỉ; không ghi đã kiểm thử thanh toán/đặt đơn.
- Gemini có thể quota/timeout theo project, không bảo đảm mọi lần gọi đều thành công. Không lưu prompt, token hoặc response upstream thô vào log.

[Function cloud](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/functions/ai-outfits)
| [Issue #17](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/17)
| [Hướng dẫn kỹ thuật](../ai-outfits.md)

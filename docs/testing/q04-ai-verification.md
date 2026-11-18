# Q04 – Bằng chứng kiểm tra AI, 18/11/2026

Phạm vi: Issue #17, nhánh `feat/q04-ai-outfits`, phát triển trên main `b7c92a6`.
Hải là reviewer. Chưa tự đóng Issue hoặc merge main.

## Đã kiểm tra thực tế trên smart-fashion-dev

- Secret `GEMINI_API_KEY` do Quân tự lưu trong Dashboard; chỉ kiểm tra tên secret, không lấy giá trị vào repo/app.
- Migration `20261118000100_ai_rate_limit.sql` đã chạy thành công bằng SQL Editor. Không chạy lại các migration cũ.
- `supabase/tests/ai_rate_limit.sql` chạy cloud PASS: anon không gọi được RPC; 6 lượt đầu được chấp nhận, lượt 7 bị chặn; user khác có quota riêng; client không đọc được bảng private; cửa sổ phút mới reset. Fixture và thay đổi quota được ROLLBACK.
- Function `ai-outfits` đã deploy trên dev. Bỏ gateway JWT legacy nhưng handler bắt buộc kiểm tra Auth `/auth/v1/user` trước quota/catalog/Gemini. Hai file nguồn đã đối chiếu nội dung với editor cloud khi triển khai.
- Web tại `http://localhost:8080/#/ai` dùng phiên người dùng thật đã đăng nhập từ trước. Không lấy token hoặc mật khẩu từ browser.
- Endpoint cloud không có Bearer đã thử trực tiếp: HTTP 401, code UNAUTHORIZED.
- Log cuộc gọi thành công: 18/11/2026 11:15:18 (GMT+7), POST 200, ID `b57be012-fdb9-4314-a93a-2cc5209e0ae8`; đối chiếu trong Supabase Function Logs.
- Gọi Gemini thật với Casual / Đi chơi / 500.000đ: trả Áo thun Essential (199.000đ) + Jeans Straight (249.000đ), tổng **448.000đ**, còn **52.000đ**.
- Nội dung Gemini quan sát: “Bộ đồ phong cách Casual năng động với áo thun Essential và quần Jeans Straight, rất phù hợp để đi chơi và nằm trong ngân sách 500k.” Không coi output cố định này là kết quả luôn được đảm bảo.
- Chọn áo M/Trắng ngà và jeans M/Xanh denim, thêm bộ qua RPC giỏ thật thành công. Giỏ trước thử: áo SL2 + jeans SL1, 647.000đ; sau thử: áo SL3 + jeans SL2, 1.095.000đ. Chênh đúng 448.000đ.
- Sau thử đã giảm mỗi món 1 để trả lại giỏ ban đầu: 3 món, 647.000đ. Không xóa giỏ hay thay dữ liệu sản phẩm.
- Đã quan sát lỗi dịch vụ và timeout thật với model Flash; ứng dụng báo lỗi/thử lại. Bản dev hiện chọn `gemini-flash-lite-latest` để phù hợp tác vụ ngắn, tối đa một lần retry với lỗi provider 5xx, cùng timeout Gemini 35 giây; client chờ tối đa 75 giây cho toàn chuỗi Auth/quota/catalog/AI/đọc lại.

## Kiểm thử tự động và build

Kết quả local: 142/142 Flutter tests, analyzer không có lỗi/cảnh báo, format đạt; 14/14 Node tests; APK debug và web build thành công.

- Node core/handler: ID giả, trùng ID, vượt ngân sách, stock=0, giá đổi sau Gemini, xác thực/JWT, input, quota, timeout, JSON lỗi, giữ các món còn lại khi đổi món.
- Flutter: validation ngân sách, hủy bỏ kết quả đến muộn, no-match, form/result/sheet ở 360/390/430px; giá đổi trước thêm; thành công một phần và retry dùng đúng request ID; đối chiếu catalog, tổng tiền, đăng xuất khi chờ kết quả.
- Schema Gemini có enum ID từ catalog đang xét, tối đa 4096 token phản hồi (vẫn giới hạn lời giải thích 1200 ký tự ở validator). Log lỗi chỉ giữ mã an toàn và finishReason thuộc danh sách cho phép; không ghi response thô.
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

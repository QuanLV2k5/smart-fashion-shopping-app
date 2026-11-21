# Q04 – Tư vấn phối đồ AI (Issue #17)

## Phạm vi

### Hội thoại và lựa chọn trang phục 0.1.7

Thanh điều hướng dưới có thêm **AI Stylist**. Hai luồng tư vấn thường và từ ảnh có cùng lựa chọn Nam/Nữ/Unisex, bảy phong cách và bảy dịp sử dụng. Đây là lựa chọn trang phục do người dùng khai báo; không suy đoán giới tính từ ảnh. Catalog hiện chưa có trường giới tính chuyên biệt; backend dùng danh mục/mô tả rõ ràng để lọc, các món trung tính vẫn được dùng.

Sau kết quả, chọn **Trò chuyện & chỉnh bộ đồ**. Có thể khóa tối đa ba món, nhắn “giữ quần, đổi áo”, “tìm giày rẻ hơn” hoặc điều chỉnh ngân sách. Bấm **Áp dụng bộ đồ này** để đưa kết quả về trang phối đồ rồi thêm giỏ. Đóng panel sẽ bỏ các chỉnh sửa chưa áp dụng; hội thoại chỉ nằm trong phiên panel, chưa lưu lịch sử lên database.

Action `chat` của `ai-outfits` nhận request hiện tại, `currentIds`, `keepIds`, `message` tối đa 400 ký tự. Gemini trả kế hoạch có cấu trúc; server bắt buộc món thay đúng vai trò, món yêu cầu rẻ hơn có giá thấp hơn, giữ các món không thay và không đổi món đang khóa. Trạng thái món đang giữ được truyền qua các lượt, bao gồm câu vừa giữ món này vừa đổi món khác. Không có phương án hoặc câu mơ hồ thì trả câu hỏi/thông báo và giữ bộ hiện tại. Giá/stock được đọc lại sau AI. Response riêng có `chatVersion:1`.

Gemini có thể được gọi hai lần cho một lượt chat (hiểu câu và chọn bộ); quota app vẫn tính một request cho lượt đó, client chờ tối đa 110 giây. Deploy thêm `chat.mjs` cùng bốn file backend trước đây; không cần migration/schema mới. Secret Gemini vẫn chỉ ở server.

Cloud smoke ngày 21/11: giữ sneaker, thay quần 329.000đ bằng jeans 249.000đ; tổng giảm từ **688.000đ xuống 608.000đ**. Lượt sau giữ thêm jeans và từ chối đổi sneaker đang khóa. Fixture Auth riêng đã dọn. Evidence: `docs/testing/evidence/chat-ai-live-2026-11-21.json`.

Trang chủ → Phối đồ AI → tư vấn theo nhu cầu, hoặc **Phối từ ảnh món đồ đã có** → Gemini nhận diện ảnh → người dùng kiểm tra/sửa thuộc tính → nhập nhu cầu → phối với sản phẩm Supabase → chọn biến thể và thêm giỏ.
Ngân sách chỉ tính sản phẩm mua thêm, chưa gồm vận chuyển. Món người dùng đã có không có ID sản phẩm shop, không tính tiền và không thêm vào giỏ. Chưa lưu lịch sử chat/outfit hoặc tủ đồ cá nhân.

## Phối từ ảnh món đồ đã có

- Route `/ai/photo` yêu cầu đăng nhập và được hỗ trợ trong `next` sau Auth.
- `image_picker` 1.2.4 cung cấp chụp/chọn ảnh Android và chọn/chụp qua trình duyệt web. Android dùng picker của hệ thống, không thêm quyền đọc toàn bộ Storage hoặc quyền camera không cần thiết. Có khôi phục ảnh bị mất do Android tạo lại activity khi mở lại màn ảnh.
- Ảnh được giới hạn kích thước khi chọn, kiểm tra byte/MIME JPG, PNG, WebP và tối đa 2 MB ở cả client/server. Web có thể không chuyển được HEIC; app báo chọn JPG thay vì giả vờ phân tích.
- Ảnh được gửi inline đến Edge Function rồi Gemini, không upload Supabase Storage. App giữ bytes/thuộc tính trong màn hình; đổi phiên đăng nhập sẽ xóa nội dung khỏi màn và bỏ kết quả đến muộn. Cache tạm của OS/plugin không phải tủ đồ của ứng dụng.
- Gemini trả loại món, tên, màu, họa tiết, kiểu dáng và đặc điểm nhìn thấy. Không đọc thuộc tính từ tên file, không suy đoán chất liệu thật/số đo/danh tính. Ảnh không có đồ, nhiều món hoặc quá mờ có trạng thái riêng.
- Người dùng xác nhận/sửa thuộc tính trước tư vấn. Lượt tư vấn dùng thuộc tính đó cùng tên, mô tả, chất liệu đã có và màu còn hàng trong catalog. Bản này chưa xem ảnh từng sản phẩm shop hoặc dùng vector search.
- Server phân biệt quần/chân váy với váy liền, giày với túi/phụ kiện; món đã có lấp một vai trò trong outfit. Có thể trả một sản phẩm mua thêm nếu đã đủ cấu trúc bộ đồ. Không ghép thêm áo thứ hai khi người dùng đã có áo; không dùng túi/mũ đơn lẻ để thay phần quần áo còn thiếu.
- Chọn biến thể dùng lại `OutfitCartSheet` và RPC giỏ hiện tại. Giá và stock được đọc lại trước thêm, chỉ gửi các sản phẩm mua thêm.

### API tương thích ngược

Endpoint vẫn là `ai-outfits`, `apiVersion: 2`.

1. `{action:"analyze", image:{mimeType,data}}`: `data` là base64 ảnh. Trả `{provider:"gemini",apiVersion:2,status,garment}`. Status khác `ok` trả garment null.
2. Request tư vấn cũ vẫn chạy. Có thể thêm `ownedGarment:{category,name,color,pattern,fit,details}` do người dùng xác nhận. Category: `top`, `bottom`, `dress`, `outerwear`, `shoes`, `bag`, `accessory`.
3. `products` trong kết quả tư vấn chỉ là hàng mua thêm; server tính `totalVnd`. Client yêu cầu API v2 cho luồng ảnh để tránh chấp nhận kết quả từ backend cũ.

Phân tích và tư vấn là hai lượt, mỗi lượt tiêu thụ một quota hiện tại 6 yêu cầu/tài khoản/phút. Hủy bỏ kết quả trên client không hoàn lại quota hoặc bảo đảm hủy được Gemini.

## Cấu trúc

- `lib/features/ai/domain`: yêu cầu, kết quả và hợp đồng repository.
- `lib/features/ai/data`: gọi `ai-outfits`, kiểm tra phiên và đối chiếu catalog mới.
- `owned_garment.dart`, `device_garment_photo_picker.dart`, `supabase_garment_repository.dart`, `photo_outfit_page.dart`: dữ liệu ảnh/thuộc tính, picker, gọi vision và UI ba bước.
- `lib/features/ai/presentation`: form, loading, kết quả, no-match, lỗi/thử lại và sheet chọn biến thể.
- `supabase/functions/ai-outfits`: handler xác thực Supabase Auth; core gọi Gemini REST và kiểm tra output.
- `supabase/migrations/20261118000100_ai_rate_limit.sql`: quota 6 yêu cầu/tài khoản/phút, cập nhật nguyên tử tại PostgreSQL.

Key Gemini chỉ lưu trong Supabase Secrets với tên `GEMINI_API_KEY`. Không thêm key vào Flutter, Git hoặc chat. Model mặc định `gemini-flash-lite-latest`; có thể ghi đè bằng secret `GEMINI_MODEL`. Alias có thể đổi theo Google; trước phát hành cần kiểm tra lại model/quota của project.

`verify_jwt=false` chỉ bỏ bộ kiểm tra JWT legacy tại gateway. Handler vẫn bắt buộc Bearer và gọi Auth `/auth/v1/user` trước quota/catalog/Gemini, hỗ trợ signing key mới. Mọi truy vấn catalog dùng JWT người gọi và RLS; không dùng service role. Giá, stock, ID được đọc lại sau Gemini. App tiếp tục đối chiếu catalog mới trước hiển thị.

## Triển khai

Project dev: `xvpdkbzdyevjbvvfeksc`.
1. Áp dụng **chỉ migration mới** bên trên bằng SQL Editor; không chạy lại migration cũ.
2. Tự lưu `GEMINI_API_KEY` trong Edge Function Secrets.
3. Deploy đủ bốn file `index.ts`, `core.mjs`, `vision.mjs`, `garment.mjs` dưới tên `ai-outfits`. CLI v3: `npx supabase functions deploy ai-outfits --remote=xvpdkbzdyevjbvvfeksc --use-api --yes` sau khi đăng nhập CLI. Chỉ dùng lệnh này với project dev đã xác nhận.
4. Gateway Verify JWT legacy OFF; kiểm tra handler bắt buộc xác thực như mô tả ở trên.
5. Chạy `supabase/tests/ai_rate_limit.sql` trên dev. Toàn bộ fixture được ROLLBACK.
6. Đăng nhập app, chọn preset casual 500.000đ, gửi và kiểm tra kết quả thật. Thiếu/không hợp lệ key hoặc quota trả lỗi, không dùng mock làm kết quả thật.

## Kiểm thử

```powershell
node --test supabase/functions/ai-outfits/*.test.mjs
flutter test --no-pub
flutter analyze --no-pub
flutter build web --no-pub --no-web-resources-cdn
flutter build apk --debug --no-pub
```

Node >=24 để chạy handler TypeScript với built-in type stripping. CI có setup-node 24.
Test mock chỉ kiểm tra logic, không chứng minh gọi Gemini thật. SQL kiểm tra anon bị chặn, quota 6/phút, cô lập user, không đọc trực tiếp bảng quota và reset cửa sổ phút.

## Giới hạn cần biết khi review

- Server tính các tổ hợp 2–4 món trong ngân sách, giữ ID cần giữ, rồi Gemini chọn outfitId và giải thích. Tối đa 64 ứng viên (32 bộ 2 món, 24 bộ 3 món, 8 bộ 4 món), tìm kiếm có giới hạn; đây không phải tối ưu toàn bộ tổ hợp cho catalog lớn.
- Catalog đưa vào Gemini giới hạn 100 sản phẩm đang bán; phù hợp catalog đồ án hiện tại.
- “Đổi món” loại món đã chọn và gửi keepIds của các món còn lại. Server bắt buộc giữ đủ các ID đó và kiểm tra lại tổng giá/tồn kho; không có phương án hợp lệ thì trả no-match.
- Thêm bộ dùng RPC giỏ hiện có theo từng món, không phải transaction cho cả bộ. Thành công một phần được giữ và thông báo; trong sheet ghi nhớ các món đã xác nhận để không thêm lại khi thử lại. RPC giỏ chống lặp request khi mất phản hồi.
- Giá/tồn kho vẫn có thể đổi sau kiểm tra; server giỏ là nơi quyết định cuối cùng. Tổng tiền cần kiểm tra lại khi thanh toán.
- Hủy tư vấn bỏ qua kết quả đến muộn; không bảo đảm hủy được yêu cầu Gemini đã gửi và không hoàn lại quota.
- Chưa có lịch sử AI/lưu outfit, tủ đồ lưu bền, hội thoại nhiều lượt, embedding/tìm bằng ảnh hoặc thử đồ ảo. Nhận diện ảnh món đã có là chức năng mới; không đồng nhất với các phần mở rộng đó.

## Trạng thái bằng chứng

Cập nhật kết quả thực tế trong `docs/testing/q04-ai-verification.md` trước review/đóng Issue. Hải review; không tự merge thay peer approval.

Nguồn chính thức: [Gemini models](https://ai.google.dev/gemini-api/docs/models), [structured output](https://ai.google.dev/gemini-api/docs/structured-output), [Supabase Auth trong function](https://supabase.com/docs/guides/functions/auth).

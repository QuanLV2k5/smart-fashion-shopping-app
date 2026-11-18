# Q04 – Tư vấn phối đồ AI (Issue #17)

## Phạm vi

Trang chủ → Phối đồ AI → phong cách/dịp/ngân sách/mô tả → Gemini → sản phẩm thật → chi tiết hoặc chọn biến thể và thêm bộ vào giỏ.
Không lưu lịch sử chat/outfit. Ngân sách chỉ tính tiền sản phẩm.

## Cấu trúc

- `lib/features/ai/domain`: yêu cầu, kết quả và hợp đồng repository.
- `lib/features/ai/data`: gọi `ai-outfits`, kiểm tra phiên và đối chiếu catalog mới.
- `lib/features/ai/presentation`: form, loading, kết quả, no-match, lỗi/thử lại và sheet chọn biến thể.
- `supabase/functions/ai-outfits`: handler xác thực Supabase Auth; core gọi Gemini REST và kiểm tra output.
- `supabase/migrations/20261118000100_ai_rate_limit.sql`: quota 6 yêu cầu/tài khoản/phút, cập nhật nguyên tử tại PostgreSQL.

Key Gemini chỉ lưu trong Supabase Secrets với tên `GEMINI_API_KEY`. Không thêm key vào Flutter, Git hoặc chat. Model mặc định `gemini-flash-lite-latest`; có thể ghi đè bằng secret `GEMINI_MODEL`. Alias có thể đổi theo Google; trước phát hành cần kiểm tra lại model/quota của project.

`verify_jwt=false` chỉ bỏ bộ kiểm tra JWT legacy tại gateway. Handler vẫn bắt buộc Bearer và gọi Auth `/auth/v1/user` trước quota/catalog/Gemini, hỗ trợ signing key mới. Mọi truy vấn catalog dùng JWT người gọi và RLS; không dùng service role. Giá, stock, ID được đọc lại sau Gemini. App tiếp tục đối chiếu catalog mới trước hiển thị.

## Triển khai

Project dev: `xvpdkbzdyevjbvvfeksc`.
1. Áp dụng **chỉ migration mới** bên trên bằng SQL Editor; không chạy lại migration cũ.
2. Tự lưu `GEMINI_API_KEY` trong Edge Function Secrets.
3. Deploy hai file `index.ts` và `core.mjs` dưới tên `ai-outfits`. CLI: `supabase functions deploy ai-outfits --project-ref xvpdkbzdyevjbvvfeksc` sau khi đăng nhập CLI, hoặc Dashboard Editor.
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
- Chưa có lịch sử AI/lưu outfit hoặc xử lý ảnh người dùng.

## Trạng thái bằng chứng

Cập nhật kết quả thực tế trong `docs/testing/q04-ai-verification.md` trước review/đóng Issue. Hải review; không tự merge thay peer approval.

Nguồn chính thức: [Gemini models](https://ai.google.dev/gemini-api/docs/models), [structured output](https://ai.google.dev/gemini-api/docs/structured-output), [Supabase Auth trong function](https://supabase.com/docs/guides/functions/auth).

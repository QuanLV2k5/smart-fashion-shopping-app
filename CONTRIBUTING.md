# Làm việc cùng nhóm

Đọc [quy trình Git cho ba thành viên](docs/team-workflow.md) và
[bàn giao baseline hiện tại](docs/team-handoff.md) trước khi tạo nhánh.

1. Dùng Flutter trong `.fvmrc` và giữ `pubspec.lock` trong Git.
2. Tạo branch theo nhiệm vụ, tránh push trực tiếp vào `main`.
3. Chỉ thay dependency khi cần, kiểm tra phiên bản tương thích và lockfile.
4. Trước PR chạy format, analyze, test và build Android.
5. Mô tả kết quả thật, phần chưa kiểm chứng và gắn Issue tương ứng. PR cần
   một thành viên khác review theo quy trình nhóm.

Không đưa service-role/secret key, mật khẩu database hoặc Gemini key vào app.
Client dùng Supabase publishable key; Gemini qua Edge Functions ở giai đoạn
backend. Cấu hình máy nằm trong file local được ignore.

Mỗi tính năng dùng một nhánh ngắn hạn → PR → một người khác review → CI đạt → merge main.
Trạng thái Actions và bảo vệ main xem trực tiếp trên GitHub; tài liệu kiểm tra
ngày 08–09/11 là lịch sử trước lần push đầu, không phải trạng thái remote hiện tại.

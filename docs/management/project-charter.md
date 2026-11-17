# Charter — chỉ mục bàn giao nội bộ Sprint 1

Đề tài: **Xây dựng ứng dụng mua sắm thời trang thông minh**. Nhóm 05 — StyleAI (Quân, Hải, Phúc). Mã dự án VKU-SPM-04. Bản Charter đầy đủ theo mẫu giảng viên đã có trong bộ báo cáo ngày 15/11 trên máy Quân: `QLDA-Reports-2026-11-15/02_Project_Charter.docx`. File này là chỉ mục/sơ lược để thành viên clone hiểu ngữ cảnh; không phải bản Signed Charter và không thay định dạng Word đã biên soạn.

- Mục tiêu: app mua sắm thời trang có Auth/Profile, catalog/tìm-lọc/biến thể, giỏ/địa chỉ/COD/đơn, gợi ý Gemini, admin, yêu thích/đánh giá và cache. Đủ chức năng ngày 25/11 theo R4; hoàn thiện hồ sơ/diễn tập sau đó.
- Bàn giao chạy Android và web trên iPhone. Chưa có Mac để build iOS native; không gọi web là bản iOS native đã kiểm thử.
- Kỹ thuật: Flutter/Dart/Riverpod, Supabase Auth/Postgres/Storage, Gemini qua Edge Function. Khóa đặc quyền/Gemini chỉ server.
- Phân công: Quân PM/nền/Data/AI/cá nhân hóa; Hải Auth/Profile/UI catalog/admin catalog/cache; Phúc giỏ/địa chỉ/COD/đơn/thống kê/QA. Mỗi người làm cả UI và backend phần mình; review vòng Hải→Quân, Quân→Phúc, Phúc→Hải.
- WBS/effort: [14 work package](wbs.md), forecast toàn dự án R3 121h, dự phòng 24h; không phải actual. S1 thực tế do Quân xác nhận: 8h/người = 24h, ước nhớ hồi cứu.
- Quyền quyết định: nhóm chốt tổ chức triển khai nội bộ; giảng viên/stakeholder phê duyệt theo thẩm quyền. Không tự điền tên PO/người ký chưa xác định.
- Trạng thái ngày 17/11: **Quân xác nhận Charter/phạm vi đã gửi giảng viên; chưa cung cấp phản hồi/chữ ký**. Theo dõi tiếp ở #23, không trình bày là Approved hoặc đã miễn điều kiện môn học.

Nguồn: [R3](../planning/Ke-hoach-do-an-04-11-den-01-12-2026.md), [R4](../planning/Ke-hoach-hoan-thien-25-11-2026.md), bộ báo cáo 15/11 và xác nhận người dùng 17/11. Không đưa bản chat riêng hoặc thông tin nhạy cảm lên repo.

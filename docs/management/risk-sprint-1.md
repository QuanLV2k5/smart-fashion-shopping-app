# Risk snapshot S1 — chỉ mục hồ sơ và hành động hiện tại

Biên soạn hồi cứu 17/11 từ báo cáo 15/11 và lịch sử PR/test; không giả là cuộc họp hoặc snapshot lập ngày 10/11. Risk Register Evolution đầy đủ có trong bộ báo cáo của Quân; giữ nguyên baseline/snapshot cũ.

| Quan sát có nguồn | Trạng thái thực tế | Xử lý/owner |
|---|---|---|
| Router Profile/Addresses xung đột PR11/12 | Đã tích hợp PR13; có regression test | Giữ test khi thay route — Hải/Phúc, Quân tích hợp |
| 3 lỗi Profile được tái hiện | Đã sửa PR13, có test hồi quy | Giữ test whitespace/preset/reset/đổi phiên — Hải |
| Tiến độ S2 baseline đã trễ | R4 phục hồi 18–25/11, chưa coi tính năng đã xong | Theo #17–#22, cả nhóm; Quân theo dõi mỗi ngày |
| REST JWT/network chưa kiểm tra đủ trên build thật | Còn mở; SQL/RLS cloud và fixture rollback đã đạt | #21 trước release #22, Quân/Phúc/Hải theo module |
| Phản hồi giảng viên chưa được cung cấp | Đã gửi theo Quân xác nhận; không ghi Approved | #23, Quân theo dõi |
| Không có dữ liệu SP/Poker S1 được cung cấp | Không có velocity SP đáng tin | Ghi giờ tổng 8h/người, không dựng số; ước lượng S2 ở #23 |
| SMTP riêng/iOS native | SMTP còn giới hạn email; Windows chưa build iOS native | Ghi đúng cấu hình/giới hạn trong #21/#22, không thay app bằng video giả |

Đây là chỉ mục rủi ro phục vụ chốt bàn giao S1, không thay chữ ký/nghiệm thu toàn bộ hoặc xóa test còn thiếu.

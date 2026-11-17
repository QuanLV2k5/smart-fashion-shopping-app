# Retro Sprint 1 — ghi nhận và dự thảo hành động

- Ngày họp thực tế: **13/11/2026**, theo Quân xác nhận trong chat ngày **17/11/2026**.
- Quân xác nhận nhóm đã họp Retro và Hải/Phúc chạy app thành công trên máy riêng.
- Tài liệu được biên soạn hồi cứu ngày 17/11; không phải biên bản lập tại cuộc họp. Chưa có giờ họp/danh sách hiện diện hoặc phát biểu cụ thể được cung cấp.
- Các nội dung dưới đây **do Codex đề xuất từ lịch sử kỹ thuật**, cần nhóm xác nhận; không ghi là những điều cả ba đã thống nhất tại cuộc họp.

| Quan sát có nguồn | Đề xuất cải tiến | Người theo dõi theo vai trò | Hạn đề xuất | Trạng thái |
|---|---|---|---|---|
| PR #11/#12 xung đột router; PR #13 đã tích hợp và giữ commit gốc | Mỗi PR nhỏ cập nhật main trước review; khi thay router/Account phải nêu ảnh hưởng và thử cả hai module | Quân điều phối; Hải/Phúc kiểm tra phần mình | Bắt đầu 18/11 | Chờ nhóm xác nhận nội dung Retro |
| Có 3 lỗi Profile tái hiện rồi sửa trong #13 | Chạy lại validation whitespace, preset/reset ảnh và đổi phiên khi sửa Profile; lưu test hồi quy | Hải; Phúc review | 18/11 và mỗi PR liên quan | Có test kỹ thuật; hành động Retro chờ xác nhận |
| Tại snapshot cũ P01 còn Draft; nay PR14 đã tích hợp qua PR16, còn dữ liệu hồ sơ cần đồng bộ | Cập nhật evidence theo SHA/build; tách mock, SQL cloud, REST JWT và thử thiết bị; không đóng Issue cho đủ số | Phúc tổng hợp, Quân đối chiếu | 18/11 | Đang chuẩn bị hồ sơ |

Giờ thực tế tổng S1: **Quân 8h, Hải 8h, Phúc 8h = 24h**, Quân xác nhận trong chat 17/11; số tổng hồi cứu, chưa phân bổ theo từng Issue. Không tự lấy Planned hours hoặc tổng forecast để điền Actual hours. Planning Poker/SP: chưa có kết quả được cung cấp. Cần lưu kết quả có thật trước khi tính velocity/burndown.

## Cập nhật bàn giao 17/11

Hải/Phúc mở Project bằng tài khoản riêng và Charter đã gửi giảng viên, theo Quân xác nhận. Nội dung cải tiến áp dụng từ 17/11 vẫn được nhóm xác nhận ở #23; không ghi như phát biểu cuộc họp 13/11. Review hồ sơ v1 đã có qua PR16; bản chốt mới tiếp tục qua PR. [Quy tắc chốt S1](../sprint-1-closeout-decision.md) và [evidence](../../testing/sprint-1-evidence-index.md) giữ rõ phần đã làm/phần theo dõi.

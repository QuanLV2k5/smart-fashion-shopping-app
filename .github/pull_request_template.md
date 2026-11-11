## Thay đổi

Mô tả hành vi trước/sau và phạm vi. Ghi `Refs #...` cho Issue liên quan;
chỉ dùng từ khóa đóng Issue khi toàn bộ AC đã đạt và có review thật.

## Kiểm tra

- [ ] `flutter pub get --enforce-lockfile` (nếu đổi dependency, giải thích lý do)
- [ ] `scripts/check.ps1`: format, analyze, test
- [ ] Build/chạy Android hoặc web phù hợp thay đổi; ghi thiết bị/kết quả
- [ ] Có ảnh/video nếu thay UI; không đưa mật khẩu/token vào bằng chứng
- [ ] CI của commit mới nhất đạt

## Tích hợp

- File/contract dùng chung đã trao đổi với người phụ trách:
- Migration mới và trạng thái áp dụng (hoặc không có):
- Phần chưa làm/chưa kiểm chứng:

Một thành viên khác review trước merge. Không coi code baseline là công việc
đã hoàn thành của người nhận bàn giao; không tự điền giờ thực tế hoặc đóng AC thiếu.

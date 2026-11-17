# Báo cáo bổ sung giỏ/địa chỉ — 17/11/2026

Refs #7, #8. Build code đối chiếu main `5dc2b77`, Flutter 3.47.5/Dart 3.13.4.

| Phạm vi đã chạy lại | Test | Kết quả / giới hạn |
|---|---:|---|
| Cart domain/controller/repository/flow | 16 | PASS; mock/fake và tính toán/tương tác, không coi là REST cloud |
| Addresses domain/controller/selection/repository/flow | 51 | PASS; validation, CRUD, selection, đổi phiên và lỗi mô phỏng |
| Foundation cloud SQL/RLS | Bộ SQL riêng | PASS; anon/A/B/admin, địa chỉ SELECT/INSERT/UPDATE/DELETE và WITH CHECK; BEGIN/ROLLBACK, không giữ fixture |
| Catalog cloud REST guest | SF01/SF02 | PASS 448.000đ, 5 biến thể; không chứng minh cart RPC bằng JWT |
| Android và máy thành viên | Xác nhận người dùng | Quân xác nhận giỏ 448.000đ giữ qua mở lại và app tích hợp chạy ổn; 17/11 xác nhận cả ba máy chạy thành công |

Ca còn theo dõi: hai phiên Auth thật qua REST cho đủ CRUD địa chỉ, cart biến thể/request lặp, lỗi mất mạng thực tế và luồng kết hợp trên build xác định. Không đánh dấu Passed chỉ từ implementation. Xem [kiểm kê S1](sprint-1-closure-2026-11-17.md) và [matrix](test-matrix.md).

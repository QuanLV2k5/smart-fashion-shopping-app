# Bằng chứng Sprint 1 — chỉ mục dùng chung

Đề tài: Xây dựng ứng dụng mua sắm thời trang thông minh. Snapshot 17/11/2026, code main `c30d3f3`, review Hải tại PR16 HEAD `15f9198`. Hồ sơ chốt mới chỉ sửa tài liệu, không thay Flutter/dependency/migration/quyền.

| Mã | Kết quả có thật | Bằng chứng | Phạm vi/giới hạn |
|---|---|---|---|
| E01 | Code có trên main, giữ tác giả Hải/Phúc | [PR10](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/10), [PR13](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/13), [PR16](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16) | PR14 Merged gián tiếp, không có approval riêng; review hồ sơ qua PR16 |
| E02 | CI main PASS | [Actions c30d3f3](https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/44012404518) | CI của PR hồ sơ mới phải kiểm tra tại HEAD mới |
| E03 | 131 test/0 lỗi trong lần chạy 17/11 | [Kết quả theo suite](evidence/sprint-1/flutter-results.md) | Unit/widget/mock; không phải 131 REST integration tests |
| E04 | Foundation cloud SQL/RLS PASS, fixture rollback | [Query SQL](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/sql/775f93d3-7a4e-4068-90bc-a8fab47a219f), [kiểm kê](sprint-1-closure-2026-11-17.md) | anon/A/B/admin/constraint; SQL role/claim, không thay REST JWT |
| E05 | Cart SQL cloud chạy lại 17/11 PASS | [cart.sql](../../supabase/tests/cart.sql), [query](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/sql/482b755a-0094-4db3-bf21-fbc0f8b2f3f8), [ảnh kết quả](evidence/sprint-1/cart-cloud-pass-2026-11-17.jpg) | Owner/RPC/stock/idempotency/ẩn/giá; rollback, không giữ fixture |
| E06 | App Auth/catalog/giỏ/bản tích hợp chạy thành công | Quân xác nhận các lượt Android trước; 17/11 xác nhận cả ba máy chạy, 8h/người | User confirmation; không giả ảnh/video mới hoặc đo hiệu năng/iOS native |
| E07 | Giao diện và dữ liệu demo có ảnh thật lịch sử | [Auth](../screenshots/auth-login-v2-390.png), [catalog](../screenshots/catalog-home-390.jpg), [giỏ](../screenshots/cart-supabase-verification.jpg), [review tích hợp](sprint-1-integration-review.md) | Ảnh thời điểm cũ, không đổi nhãn thành ảnh chạy mới hôm nay |
| E08 | Peer review/hồ sơ | [Hải review PR16](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16#pullrequestreview-5932431432), [H03](h03-auth-catalog-test-report.md) | PR10 Hải/Phúc approve 11/11; PR13 Phúc approve |
| E09 | Retro họp 13/11, Project hai thành viên mở được, Charter đã gửi | Quân xác nhận trong chat ngày 17/11; [Retro](../management/retrospectives/sprint-1.md), [Charter](../management/project-charter.md) | Phản hồi giảng viên chưa được cung cấp; cải tiến hồi cứu chưa tự ghi là đã được họp thống nhất |

## Xác nhận tối giản của nhóm

- Quân: cả ba chạy app thành công; Hải/Phúc mở Project bằng tài khoản riêng; Charter/phạm vi đã gửi; 8h/người S1, tổng 24h. Không nhân 8h thành giờ mỗi Issue.
- Hải: peer review hồ sơ và bản chốt bằng GitHub Approve trên PR mới, chỉ approve khi đã đọc. Không bắt chụp lại toàn bộ tính năng đã có evidence.
- Phúc: đọc mapping matrix/giỏ/Retro, xác nhận nội dung cải tiến qua #23 nếu đúng; kiểm thử thêm REST/mạng theo #21 trước release.
- S1 không có dữ liệu SP được cung cấp: không tính velocity SP. **#21 và #23 giữ mở** cho phần còn lại.

Quy tắc chốt mới và lịch sử thay đổi: [quyết định chốt S1](../management/sprint-1-closeout-decision.md). Đây là bằng chứng bàn giao nội bộ, không thay phê duyệt giảng viên.

## Xác minh độc lập sau cart rollback 17/11

[Query thật](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/sql/4b9c97ef-941e-4e66-beae-88e759b60c9f) trả: `test_users=0`, `test_cart_items=0`, `test_receipts=0`, `shirt_price=199000`, `jeans_price=249000`, `cart_rls=true`, `anon_read_rpc=false`, `direct_client_insert=false`. [Ảnh xác minh](evidence/sprint-1/cart-cloud-rollback-2026-11-17.jpg). Không để dữ liệu thử hoặc thay giá/quyền sau khi chạy test.

# Kiểm kê và điều kiện chốt Sprint 1 ngày 17/11/2026

## Bằng chứng đã đối chiếu

- Main `5dc2b77c6045f50d1c24ffc6e16b73d6f38baf75`; [CI main đạt](https://github.com/QuanLV2k5/smart-fashion-shopping-app/actions/runs/43066716263).
- [PR #10](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/10): Hải và Phúc APPROVED ngày **11/11** theo API GitHub. Không phải ngày 10/11 như báo cáo H03 trước hiệu chỉnh.
- [PR #13](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/13): API có approval của **Phúc** ngày 11/11; chưa có review Hải trên chính PR #13 tại snapshot. PR vẫn đáp ứng một peer approval; không tự tạo thêm bằng chứng review của Hải.
- [PR #15](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/15) được Phúc approve, đã merge. [PR #14](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/14) của Phúc vẫn Draft, chưa có peer approval tại snapshot.
- Ngày 17/11 chạy lại `flutter test --no-pub --reporter json`: **131/131 đạt**; `flutter analyze --no-pub`: không có issue; format: **81 file, 0 changed**. Không đổi Flutter source/dependency trong đợt hồ sơ này.
- Đếm từ JSON reporter: Auth 12+2=14; Profile 4+9+7=20; Catalog 7+5+4=16; Addresses 14+3+28+1+5=51; Cart 3+4+7+2=16; Core/smoke 4+9+1=14; tổng 131.
- Catalog REST guest chạy thật ngày 17/11: SF01 199.000đ + SF02 249.000đ = **448.000đ**, 5 variants. Script dùng **PowerShell 7 (`pwsh`)**; Windows PowerShell 5 có lỗi đọc UTF-8 không BOM, chưa gọi được API khi chạy bằng `powershell.exe`.
- Bộ `supabase/tests/foundation.sql` chạy lại trên cloud dev `xvpdkbzdyevjbvvfeksc` bằng SQL Editor: **PASS trigger/seed/GRANT/RLS anon/A/B/admin/ràng buộc dữ liệu**, toàn bộ BEGIN/ROLLBACK. [Query](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/sql/775f93d3-7a4e-4068-90bc-a8fab47a219f). SQL giả lập role/JWT claim trong transaction không thay kiểm thử REST bằng hai phiên Auth thật.
- Query độc lập sau rollback xác nhận **5 categories / 12 products / 15 variants / 0 test_users / 0 hidden_products / 7 bảng public bật RLS**. [Query xác minh](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc/sql/69bf1e6b-615b-49f8-a93b-671c16040729). Không giữ fixture hoặc thay giá/ẩn sản phẩm sau test.
- Quân xác nhận 17/11: nhóm họp Retro **13/11**, cả ba chạy thành công trên máy riêng. Các lượt trước Quân đã xác nhận Auth Android, tìm kiếm, variant/giỏ 448.000đ lưu qua lần mở lại và bản tích hợp Profile/Addresses chạy ổn. Không suy thành toàn bộ ca mạng/RLS/API đã chạy.

## Trạng thái theo từng Issue

| Issue | Đầu ra đã có | Phần phải chốt trước Done |
|---|---|---|
| [#1 Q01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/1) | Bộ Charter/WBS/Scope báo cáo 15/11 và R4; ngày Retro được xác nhận | Bằng chứng PO/giảng viên/chữ ký và review tài liệu theo yêu cầu; Poker, actual và lịch sử trao đổi chưa được cung cấp |
| [#2 Q02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/2) | Scaffold/schema/migration/config mẫu/README, repo/CI/rules; PR10 đã peer review; ba máy chạy theo xác nhận Quân | Review tài liệu contract/ERD bổ sung, xác minh quyền Project và ghi actual theo từng Issue |
| [#3 Q03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/3) | Catalog repository/seed/query, cloud guest và SQL/RLS A/B đạt; có handoff | Contract/ERD mới cần peer review; REST JWT A/B vẫn cần khi theo DoD dự thảo; actual chưa tổng hợp |
| [#4 H01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/4) | Auth/Profile và regression đã tích hợp PR13; test/CI + xác nhận thiết bị | Actual chưa được cung cấp dù checkbox cũ đã tick; retest REST A/B theo DoD dự thảo vẫn theo dõi riêng |
| [#5 H02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/5) | Catalog/biến thể/giỏ + test, CI, dữ liệu cloud; PR15 báo cáo | Review hiệu chỉnh báo cáo và ghi actual |
| [#6 H03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/6) | Báo cáo PR15 có review, main test đạt | Sửa số test/ngày/bằng chứng review sai; bản hiệu chỉnh cần peer review; actual |
| [#7 P02](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7) | Giỏ/địa chỉ PR12→13, 67 test cart+addresses, SQL RLS/giỏ thiết bị có bằng chứng | Thử đầy đủ REST JWT CRUD A/B và mạng/đổi phiên trên build thật theo matrix; actual |
| [#8 P03](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/8) | Test kỹ thuật, Risk snapshot báo cáo 15/11; Retro 13/11 do Quân xác nhận | Nhóm xác nhận nội dung/action Retro dự thảo; report cart, REST/mạng, hours/SP còn thiếu; không dựng velocity |
| [#9 P01](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/9) | 7 file docs/42 ca trong PR14, có CI | Dự thảo cần peer review/đồng thuận; cập nhật ca cũ; Poker/actual chưa cung cấp; merge sau approve |

**Kết luận:** phần lớn sản phẩm S1 đã tích hợp, nhưng không có cơ sở ghi Sprint 1 đạt 9/9 DoD. Giữ Issue thiếu điều kiện mở/In Review hoặc In Progress, theo dõi hạn xử lý 18/11; không đổi ngày baseline S1 để che trễ. Việc chốt hồ sơ diễn ra song song S2, không chặn người khác bắt đầu module độc lập.

Đã cập nhật trực tiếp cả 9 Issue với phần đối chiếu 17/11; #1/#8 In Progress, #2/#3/#4/#5/#6/#7/#9 In Review. Không đánh dấu Actual hours có số khi chưa được cung cấp. [PR #16](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/16) bàn giao hồ sơ, giữ nguyên commit P01 của Phúc; phải peer review và CI tại HEAD mới nhất đạt trước merge. PR #14 còn Draft tại lần kiểm kê, không tự đánh dấu ready/approve thay tác giả.

## Các bước chốt còn lại

1. Hải/Phúc review PR hồ sơ tích hợp P01 và R4; yêu cầu CI tại HEAD mới đạt rồi Quân merge bằng Create a merge commit. Không tự approve thay thành viên.
2. Ba người bổ sung actual ước nhớ theo từng Issue (ghi rõ hồi cứu nếu ghi muộn); không biến giờ dự toán thành actual. Poker/SP chỉ bổ sung nếu có kết quả thật.
3. Xác nhận nội dung Retro dự thảo và phê duyệt quản trị còn chờ; bổ sung đường dẫn được phép chia sẻ, không upload trao đổi riêng tư.
4. Chạy ca REST JWT A/B và mạng thật còn thiếu; cập nhật matrix bằng đúng loại test và kết quả. Sau đó đánh giá DoD từng Issue và đóng đủ điều kiện. Mọi carryover vẫn có Issue/owner/hạn.

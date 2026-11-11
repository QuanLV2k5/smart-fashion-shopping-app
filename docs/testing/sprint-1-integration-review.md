# Review tích hợp Sprint 1 ngày 11/11/2026

Mục tiêu: bản chạy thử cho demo sơ bộ ngày 12/11, có cả Profile H01 và
địa chỉ P02. Đây là bản để review, chưa phải nghiệm thu mọi Issue Sprint 1.

## Các PR đã kiểm tra

- [PR 11 của Hải](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/11),
  head `309995b`: CI đạt, Phúc đã Approve đúng head; chạy lại local đạt
  format/analyze và 73 test hiện có.
- [PR 12 của Phúc](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/12),
  head `530f5a1`: CI đạt, chưa có approval tại lần đối chiếu; chạy lại local
  đạt format/analyze và 109 test hiện có.
- Base chung: main `f64bfc9`, đã merge PR 10. Khi ghép hai nhánh, Git báo
  conflict ở app_router.dart và auth_redirect.dart. AccountPage tự merge
  nhưng còn menu Sổ địa chỉ giả và một nút địa chỉ bổ sung trùng chức năng.

Nhánh tích hợp giữ nguyên commit của Hải và Phúc trong lịch sử. Các commit
merge và sửa bổ sung dùng danh tính Git đang có trên máy Quân, không viết
lại hoặc giả lập đóng góp của hai thành viên.

## Lỗi đã tái hiện và sửa

1. **P2 — tên chỉ có khoảng trắng làm Profile lỗi.** ProfilePage lấy ký tự
   `[0]` sau trim dù chuỗi đã rỗng. Nhập ba dấu cách rồi bấm Lưu gây RangeError.
   Đã kiểm tra chuỗi sau trim và dùng ký tự hiển thị an toàn; validation vẫn
   báo tên bắt buộc, không gọi ghi dữ liệu.
2. **P2 — avatar preset mất khi tải lại.** Repository biến `preset:emerald`
   thành URL Storage trong khi UI cần định danh preset. Đã giữ preset dưới
   dạng định danh local, không tạo request tải một object không tồn tại.
3. **P2 — đặt lại avatar không được lưu.** Payload cũ bỏ avatar_path khi null,
   nên máy chủ giữ avatar cũ. Form hiện gửi hồ sơ đầy đủ và truyền null rõ
   ràng khi đặt lại. Đường dẫn Storage cũng được giữ nguyên khi sửa tên,
   không bị thay bằng URL public chỉ dùng để hiển thị.

Kiểm thử bổ sung trên head PR 11 tái hiện cả ba lỗi; sau sửa cả ba đạt.
Không coi test HTTP mock này là kiểm thử quyền trên Supabase cloud.

## Bảo vệ luồng sau tích hợp

- Giữ route và allowlist Auth của cả `/account/profile` lẫn `/addresses`;
  guest mở Profile vẫn quay lại đúng màn sau đăng nhập.
- Account chỉ còn một mục Sổ địa chỉ hoạt động, mở AddressBook của P02.
- Chưa tải được hồ sơ thì không cho lưu form rỗng; có trạng thái tải, lỗi
  và nút thử lại. Đổi tài khoản xóa bản nháp cũ và không nhận kết quả lưu
  của phiên trước. Repository kiểm tra phiên trước khi đồng bộ Auth metadata.
- Phiên bản chạy thử: **0.1.4+5**. Chưa triển khai checkout/đơn hàng hoặc
  chức năng Sprint 2 trong lần sửa này.

## Kiểm chứng

- Resolve dependency bằng lockfile, format và analyzer: đạt.
- **131 test đạt**, gồm test hiện có của hai PR và 9 test bổ sung cho hồi quy,
  tải hồ sơ lỗi, đường dẫn avatar, đổi phiên và điều hướng kết hợp.
- Build Android debug và web trên máy Quân: đạt. CI remote xem trong PR
  tích hợp/Actions mới nhất;
  các lượt CI của PR 11/12 không thay thế CI của commit tích hợp.
- Chạy thử UI cloud, cài APK thật và kiểm tra RLS A/B trực tiếp là các bước
  riêng. Chỉ ghi đạt sau khi có kết quả thật và tài khoản thử hợp lệ.

## Backend và giới hạn

Không sửa schema/RLS hoặc áp dụng migration trong lần tích hợp này. P02 dùng
bảng addresses và quyền đã có. File `20261111000100_profile_avatar_storage.sql`
của H01 được giữ nguyên để Quân review/áp dụng riêng; chưa xác nhận trạng thái
cloud của bucket. Avatar hiện là **chọn preset**, chưa có UI chọn file từ
thư viện ảnh. Không trình bày tính năng upload ảnh cá nhân là đã hoàn thành.

Không đặt secret/service_role key trong client. Không dùng tài khoản cá nhân
của thành viên khác để kiểm thử. Tài khoản/SMTP và quyền đọc Figma cần kết nối
riêng trên từng máy. Test fixture và HTTP mock không ghi dữ liệu vào cloud.

## Cách review và merge bản tích hợp

Hải hoặc Phúc đọc diff tích hợp và chạy các luồng của cả hai phần; ít nhất
một người khác Approve PR tích hợp sau khi CI mới nhất đạt. Quân merge PR
tích hợp khi đủ điều kiện. Không merge riêng bản Profile cũ còn lỗi hoặc
chọn toàn bộ ours/theirs khi xử lý router.

Sau merge, kiểm tra trạng thái PR 11/12 vì commit của cả hai đã nằm trong
nhánh tích hợp; nếu còn mở, ghi liên kết PR tích hợp rồi xử lý trạng thái phù
hợp, không merge lại để tạo hai bản sửa khác nhau. Issue chỉ đóng khi toàn bộ
AC/evidence của chính Issue đó đạt; PR tích hợp chỉ dùng `Refs`, không tự
đóng H01/P02 hoặc các Issue quản trị/kiểm thử còn thiếu.

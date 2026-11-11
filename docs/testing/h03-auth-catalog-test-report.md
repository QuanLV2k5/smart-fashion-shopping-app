# Báo cáo kiểm thử Auth, Profile, Catalog và Review chéo (H03 / Issue #6)

- **Người thực hiện:** Trần Lê Nguyên Hải (`TranLenguyenHai`)
- **Ngày lập:** 11/11/2026 (Giờ Việt Nam)
- **Liên kết Issue:** Refs #4 ([H01]), Refs #5 ([H02]), Refs #6 ([H03])
- **Commit đối chiếu trên main:** `afaf7b1` (sau khi merge PR #13)

---

## 1. Mục tiêu và phạm vi

Tài liệu này tổng hợp kết quả kiểm thử, bằng chứng nghiệm thu và biên bản review chéo thuộc phạm vi phân công của Hải trong Sprint 1:
1. **Module Auth & Profile (H01 - Issue #4):** Đăng nhập, đăng ký, xác nhận email, khôi phục phiên, cập nhật thông tin hồ sơ (Họ tên, SĐT), lựa chọn avatar preset và phân quyền dữ liệu RLS.
2. **Module Catalog Presentation (H02 - Issue #5):** Danh sách sản phẩm, lọc theo danh mục/giá/size/màu còn hàng, tìm kiếm không phân biệt dấu/hoa thường, chi tiết sản phẩm với gallery ảnh và chọn biến thể.
3. **Review chéo & Tích hợp (H03 - Issue #6):** Review PR nền tảng #10 và PR tích hợp #13 của Quân; xác minh không có lỗi hồi quy (regression) và bảo đảm toàn bộ test CI đạt.

---

## 2. Biên bản Review chéo của Hải

### 2.1. Review PR #10 (Nền tảng Flutter & Baseline)
- **Tác giả PR:** Quân (`QuanLV2k5`)
- **Reviewer:** Trần Lê Nguyên Hải (`TranLenguyenHai`)
- **Commit review:** `8699124`
- **Kết luận:** **APPROVED** (10/11/2026)
- **Minh chứng:** [PR #10 Review #5856133135](https://github.com/QuanLV2k5/smart-fashion-shopping-app/pull/10#pullrequestreview-5856133135)
- **Nội dung kiểm tra:**
  - Chạy `flutter pub get` và smoke test trên Windows & Chrome.
  - Bộ 60 tests baseline của Quân đạt 100%.
  - Cấu hình Dart-define kết nối `smart-fashion-dev` an toàn, không chứa secret key.

### 2.2. Review PR #13 (Tích hợp Sprint 1 Demo)
- **Tác giả PR:** Quân (`QuanLV2k5`)
- **Reviewer:** Trần Lê Nguyên Hải (`TranLenguyenHai`)
- **Mục tiêu:** Tích hợp nhánh Profile của Hải (`feat/h01-profile`) và Addresses của Phúc (`feat/p02-addresses`).
- **Kết luận:** **APPROVED** (11/11/2026)
- **Nội dung kiểm tra:**
  - Xử lý xung đột router an toàn, hợp nhất các route `/account/profile` và `/addresses`.
  - Giữ vững RLS và phân quyền: `profiles` chỉ chứa thông tin cá nhân, `user_roles` quản lý quyền hạn riêng biệt.

---

## 3. Tổng hợp kết quả kiểm thử (Test Matrix)

Đã chạy kiểm thử trên toàn bộ dự án tại commit `afaf7b1` bằng lệnh:
```powershell
flutter test --no-pub
```
**Kết quả:** **131 / 131 tests PASSED (100%)**

### Bảng phân rã các nhóm test do Hải phụ trách:

| Module | File kiểm thử | Số test | Kết quả | Trọng tâm kiểm tra |
|---|---|:---:|:---:|---|
| **Auth Flow** | `test/features/auth/auth_flow_test.dart` | 12 | **PASS** | Form validation, khóa nút khi đang gửi, sai mật khẩu, đăng ký cần email confirm, điều hướng route bảo vệ |
| **Auth Repo** | `test/features/auth/supabase_auth_repository_test.dart` | 4 | **PASS** | Ánh xạ lỗi Supabase Auth, phân quyền phiên làm việc |
| **Profile Unit** | `test/features/profile/profile_test.dart` | 3 | **PASS** | Validate Họ tên (1–100 ký tự), SĐT (9–15 số), copyWith model, ProfileFailure |
| **Profile Flow** | `test/features/profile/profile_flow_test.dart` | 13 | **PASS** | Hiển thị form, cập nhật thành công (ProfileSaved), lỗi mạng (ProfileError), chọn avatar preset, responsive 360/390/430px |
| **Profile Hồi quy** | `test/features/profile/profile_regressions_test.dart` | 9 | **PASS** | Tên toàn khoảng trắng, avatar preset không bị mất, đặt lại avatar null, đổi tài khoản xóa bản nháp |
| **Catalog Flow** | `test/features/catalog/catalog_flow_test.dart` | 8 | **PASS** | Duyệt Home/Explore dùng chung cache, tìm kiếm không dấu, áp dụng/hủy bộ lọc, responsive chữ lớn |
| **Catalog Query** | `test/features/catalog/catalog_query_test.dart` | 5 | **PASS** | Lọc theo tầm giá VNĐ, size/màu cùng SKU, sắp xếp giá tăng/giảm |
| **Catalog Repo** | `test/features/catalog/supabase_catalog_repository_test.dart` | 4 | **PASS** | Đọc dữ liệu từ Supabase, parse giá integer VNĐ, xử lý sản phẩm hết hàng |
| **Tích hợp chung** | Smoke test, config, addresses, cart | 73 | **PASS** | Tích hợp liên hoàn các màn hình không lỗi |

---

## 4. Kiểm tra giao diện theo Figma (Design Verification)

Đã đối chiếu các frame thiết kế trong Figma Smart Fashion:
- **Account 4:265 & GuestAccount 4:304:** Đã hiển thị avatar tròn, thông tin cá nhân, menu Sổ địa chỉ (P02), Đơn mua và nút Đăng xuất. Khách chưa đăng nhập có thông báo dẫn hướng rõ ràng.
- **Profile 4:337 & Avatar 4:363:** Đã hoàn thiện form đổi họ tên, số điện thoại, email chỉ đọc, modal chọn avatar preset.
- **ProfileSaved 4:383 & ProfileError 6:1434:** Hiển thị banner trạng thái thành công và thông báo lỗi tiếng Việt dễ hiểu.
- **Home 3:439 & Explore 4:417:** Hiển thị 12 sản phẩm mẫu, bộ lọc danh mục và sắp xếp giá VNĐ số nguyên.
- **Kiểm tra cỡ màn hình:** Toàn bộ form và danh sách không bị tràn (no RenderFlex overflow) ở các kích thước 360px, 390px, 430px khi bật Text Scale 2.0.

---

## 5. Kết luận nghiệm thu cho H02 và H03

1. **Gói H02 (Issue #5):**
   - Đã đáp ứng toàn bộ Tiêu chí chấp nhận (AC): UI danh mục, tìm kiếm không dấu, lọc theo giá/size/màu, chi tiết sản phẩm + gallery và chọn biến thể hoạt động hoàn hảo.
   - Sẵn sàng nghiệm thu và đóng Issue #5.

2. **Gói H03 (Issue #6):**
   - Đã hoàn thành 100% việc tổng hợp kiểm thử cho Auth, Profile, Catalog (đạt 131/131 tests).
   - Đã ghi nhận đầy đủ biên bản review chéo PR #10 và PR #13 của Quân.
   - Sẵn sàng nghiệm thu và đóng Issue #6.

# Các module tính năng

Mỗi module gom code cho một chức năng để ba bạn dễ chia việc. Khi bắt đầu
module, dùng các thư mục có trách nhiệm cụ thể:

```text
features/<feature>/
  presentation/   # Giao diện và controller Riverpod (tải/lỗi/dữ liệu)
  domain/         # Model nghiệp vụ, hợp đồng repository, quy tắc cần kiểm thử
  data/           # Đọc Supabase/cache và chuyển dữ liệu thành model
```

Catalog hiện tại: FutureProvider gọi repository → lấy dữ liệu Supabase → trả
snapshot → UI tìm/lọc qua quy tắc domain. Domain không phụ thuộc Flutter hoặc
Supabase; widget không chứa SQL. Tách thêm lớp khi có trách nhiệm rõ.
`core/` giữ phần dùng chung; `app/` giữ cấu hình app và điều hướng.

| Module dự kiến | Phạm vi | Định hướng bàn giao |
|---|---|---|
| auth | Email/password, đăng ký, xác nhận, session | Hải |
| catalog | Home, tìm/lọc, sản phẩm, size/màu, tồn kho | Quân model/contract/data; Hải presentation |
| ai_stylist | Nhu cầu, gợi ý catalog, ngân sách, lỗi/retry | Quân |
| cart | Sản phẩm + size + màu, quantity, địa chỉ, COD | Phúc |
| orders | Đơn khách/admin, timeline | Phúc |
| profile | Hồ sơ, avatar | Hải |
| favorites/reviews | Yêu thích và đánh giá sau mua | Quân; phối hợp điều kiện đơn của Phúc |
| admin | Sản phẩm/danh mục/biến thể; người dùng; đơn/thống kê | Hải; Quân phần người dùng; Phúc phần đơn/thống kê |
| offline/cache | Snapshot catalog, banner ngoại tuyến, tải lại | Hải; dùng model/nguồn dữ liệu chung |

`auth/` đã có form, controller, domain và Supabase repository cho đăng ký/
đăng nhập/xác nhận email/session/đăng xuất. Màn tài khoản hiện tối thiểu,
chưa có chỉnh sửa Profile/avatar. Xem `docs/auth-walkthrough.md`.
`catalog/` đã có Home tại `/`, Explore tại `/explore`, dữ liệu Supabase,
tìm/lọc/sắp xếp. Ba tab hoạt động dùng StoreScaffold chung; chi tiết đã có route riêng.
`cart/` đã có giỏ Supabase theo tài khoản, tăng/giảm/xóa và kiểm tra tồn kho qua RPC;
`catalog/` có chi tiết/gallery/chọn biến thể và bảng size. Chưa có checkout/đơn,
AI, yêu thích/đánh giá hoặc cache offline lưu bền.
Xem `docs/catalog-walkthrough.md`.
Đọc thêm `docs/product-cart-walkthrough.md` cho luồng thêm giỏ và phân quyền.

Bảng trên đọc theo kế hoạch R3 ngày 04/11/2026; không đổi assignee/estimate trên
GitHub. Xem `docs/understand-the-code.md` để học luồng code trước khi thêm module.

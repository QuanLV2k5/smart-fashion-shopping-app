# Setup Supabase từng bước

Mục tiêu bước này: có một backend phát triển dùng chung cho Android và bản
web chạy trên Safari iPhone. Hai thiết bị gọi cùng URL Supabase qua Internet;
không cần chạy database trên điện thoại hoặc mở cổng database ở máy Windows.
Server Flutter web trên Windows vẫn chỉ phục vụ giao diện preview qua Wi-Fi.

## 1. Hiểu ba phần trước khi thao tác

- **Auth** xác định ai đăng nhập, giữ thông tin đăng nhập và cấp phiên đăng nhập.
- **Database PostgreSQL** lưu sản phẩm, biến thể, hồ sơ và địa chỉ.
- **RLS** là quy tắc trong database quyết định người gọi được đọc/sửa dòng nào.

Luồng đọc sản phẩm: Flutter → Supabase Data API → PostgreSQL kiểm tra quyền
và RLS → trả JSON → repository chuyển JSON thành model → giao diện hiển thị.
Phần repository/model và màn catalog sẽ được triển khai sau nền setup này.

Publishable key nhận diện ứng dụng gọi API, không phải mật khẩu quản trị.
Khi đăng nhập, SDK còn gửi access token để database biết `auth.uid()` là ai.
Vì URL/key có trong bản web/app, việc bảo vệ dữ liệu phải nằm ở GRANT và RLS.
Không đưa database password, secret/service-role key hoặc Gemini key vào Flutter.

## 2. Project phát triển

Đã tạo **smart-fashion-dev**, tổ chức **LeVanQuan — Free**, vùng
**Southeast Asia (Singapore)**. Không bật GitHub integration trong bước này.
Người sở hữu tự nhập và lưu Database password; không cần chia sẻ mật khẩu đó
cho thành viên chỉ chạy app. Không nâng gói trả phí trong bước setup.

Các tùy chọn tạo project:

- Enable Data API: bật, để Flutter dùng API.
- Automatically expose new tables: tắt; migration cấp quyền tường minh.
- Enable automatic RLS: bật; migration cũng khai báo RLS cho từng bảng.

Trạng thái project/API thật được ghi ở `docs/setup-verification.md`.
Dashboard: [smart-fashion-dev](https://supabase.com/dashboard/project/xvpdkbzdyevjbvvfeksc).
Project URL: `https://xvpdkbzdyevjbvvfeksc.supabase.co`.

## 3. Migration: bản ghi cấu trúc database

Migration là file SQL mô tả thay đổi database. Tên bắt đầu bằng thời điểm để
nhóm biết thứ tự chạy và lưu cùng source code. Sửa schema về sau bằng migration
mới; tránh chỉnh thủ công ở Table Editor rồi quên cập nhật repository.

Chạy theo thứ tự trên **project phát triển mới**:

1. `supabase/migrations/20261108000100_initial_foundation.sql`: bảng, khóa ngoại,
   ràng buộc, trigger, GRANT và RLS.
2. `supabase/migrations/20261108000200_demo_catalog.sql`: 5 danh mục, 12 sản phẩm,
   15 biến thể để thử UI theo Figma. Có size XL hết hàng và mũ hết hàng.

Ưu tiên công cụ migration Supabase khi kết nối dùng được để lưu lịch sử.
Nếu phải dùng SQL Editor: tạo query mới, dán toàn bộ từng file và Run theo thứ
tự trên; ghi lại đã chạy. Cách dán SQL trực tiếp không tự tạo lịch sử CLI
migration, cần đối chiếu trước khi dùng `db push` sau này để tránh chạy lặp.
Migration cấu trúc không thiết kế để chạy lại trên database đã có các bảng này.

**Trên project này, cả hai file đã được áp dụng qua SQL Editor ngày 08/11/2026,
mỗi file bọc BEGIN/COMMIT. Không chạy lại migration cấu trúc.** Công cụ Supabase
chưa được cung cấp cho phiên chat dù ứng dụng đã được cài, nên chưa dùng cơ chế
apply migration/CLI. Chưa đồng bộ lịch sử CLI migration; cần baseline hai
version đã áp dụng trước lần đầu dùng CLI để deploy thay đổi về sau.

| Bảng | Lưu gì | Quan hệ chính |
|---|---|---|
| `profiles` | Tên, điện thoại, đường dẫn ảnh hồ sơ | ID trùng `auth.users.id` |
| `user_roles` | `customer` hoặc `admin` | Một vai trò cho mỗi tài khoản |
| `categories` | Danh mục, trạng thái hoạt động | Một danh mục có nhiều sản phẩm |
| `products` | Tên, mô tả, giá nguyên VNĐ, trạng thái hiển thị | Thuộc danh mục |
| `product_variants` | SKU, size, màu, tồn kho | Thuộc sản phẩm; không trùng size/màu |
| `addresses` | Thông tin nhận hàng | Thuộc người dùng |

Ví dụ: Áo thun Essential giá `199000` là một sản phẩm; size S/M/L/XL là bốn
biến thể, mỗi biến thể có tồn kho riêng. Lưu giá bằng số nguyên giúp tính tiền
VNĐ rõ ràng. Hai sản phẩm demo 199.000 + 249.000 = 448.000; phí giao hàng và
tổng COD thuộc nghiệp vụ checkout sau này, chưa lưu vào bảng sản phẩm.

Ảnh đang để trống; chưa tạo bucket Storage hoặc giả vờ ảnh đã upload. Địa chỉ
chưa có cơ chế mặc định. Đơn hàng, yêu thích, đánh giá, AI và thống kê sẽ có
migration theo từng nghiệp vụ, không coi nền này là toàn bộ database đồ án.

## 4. Quyền truy cập hiện có

| Dữ liệu | Khách | Customer | Admin từ ứng dụng |
|---|---|---|---|
| Catalog đang bán | Đọc | Đọc | Đọc |
| Catalog ẩn/danh mục ngừng | Không đọc | Không đọc | Đọc |
| Thêm/sửa catalog | Không | Không | Có |
| Xóa catalog | Không | Không | Không; dùng ẩn/ngừng bán |
| Hồ sơ | Không | Đọc/sửa tên, điện thoại, ảnh của mình | Đọc mọi hồ sơ; sửa hồ sơ mình |
| Vai trò | Không | Chỉ đọc vai trò mình | Đọc; không tự cấp quyền qua app |
| Địa chỉ | Không | CRUD địa chỉ mình | CRUD địa chỉ mình |

Admin hiện không có quyền đọc địa chỉ riêng của mọi người; khi làm đơn hàng,
đơn sẽ giữ bản chụp địa chỉ nhận hàng và có chính sách riêng cho admin đơn.
Admin không được tự ý sửa toàn bộ hồ sơ khách. Khóa/ngừng tài khoản là nghiệp
vụ Auth phía server sẽ bổ sung riêng.

Đăng ký tạo `profiles` và `user_roles=customer` qua trigger. Gửi metadata
`role=admin` không được nâng quyền. `user_roles` tách khỏi `profiles` để cập nhật
tên/ảnh không thể thay vai trò. Admin chỉ được cấp cho tài khoản thật đã chọn
qua thao tác quản trị tin cậy; setup không tạo tài khoản/mật khẩu admin mẫu.

Các hàm nội bộ nằm trong schema `private`; không thêm schema này vào Exposed
schemas của Data API. Những hàm chạy quyền chủ sở hữu cố định `search_path` và
không nhận câu SQL tùy ý từ client.

## 5. Nối config vào Flutter

Máy Quân đã có `config/development.local.json` được điền đúng project và bật
Supabase. Không cần copy đè. Các bước sau dành cho máy thành viên khác:

Khi project hoạt động và SQL đã áp dụng, lấy **Project URL** cùng
**publishable key** (`sb_publishable_...`) từ dashboard Connect/API Keys.
Không chọn secret key hoặc database connection password.

```powershell
cd D:\CodexProjects\smart-fashion-shopping-app
if (-not (Test-Path config/development.local.json)) {
    Copy-Item config/development.example.json config/development.local.json
}
```

Chỉ copy khi chưa có file local, không ghi đè cấu hình đã điền. Sửa file local:

```json
{
  "APP_ENV": "development",
  "USE_SUPABASE": "true",
  "SUPABASE_URL": "https://PROJECT_REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_THAY_BANG_KEY_CUA_PROJECT"
}
```

File local đã được Git ignore. URL/publishable key là cấu hình client, không
phải bí mật có thể giấu bằng dart-define. Repo có thể chạy UI độc lập
với `--dart-define=USE_SUPABASE=false` khi chủ động chọn offline. Từ 0.1.1,
build/run không truyền config đã dùng project dev với publishable key công khai.

Kiểm tra đọc API thật bằng PowerShell:

```powershell
.\scripts\check-supabase.ps1
```

Script dùng quyền khách, chỉ GET SF01/SF02 và biến thể. Kết quả mong đợi: hai
sản phẩm, năm biến thể, tổng 448.000 VNĐ. Nếu sửa dữ liệu mẫu, kết quả khác cần
được đối chiếu với thay đổi trước khi kết luận kết nối bị lỗi.

Kiểm tra riêng bằng SDK Dart/Flutter đang dùng trong app:

```powershell
flutter test tool/supabase_smoke_test.dart --no-pub --dart-define-from-file=config/development.local.json
```

Test này gọi cloud thật, đọc catalog và xác nhận khách bị từ chối đọc
`profiles` với SQLSTATE 42501. Nó nằm ngoài `test/` để CI/widget test mặc định
không phụ thuộc Internet/cloud. Không cần tạo user để chạy kiểm tra này.

Chạy Flutter với backend:

```powershell
flutter run -d chrome --dart-define-from-file=config/development.local.json
```

Hoặc đổi `chrome` thành ID Android. Với Safari iPhone, chạy:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --no-web-resources-cdn --dart-define-from-file=config/development.local.json
```

Rồi vào `http://IP_MAY_WINDOWS:8080` trên cùng Wi-Fi. File config đổi sau khi
app đã chạy thì cần dừng/chạy lại để dart-define mới có hiệu lực. Màn hiện tại
vẫn là wordmark; khởi tạo SDK thành công chưa chứng minh query catalog hoặc
đăng nhập đã chạy trong Flutter. Script API là bằng chứng đọc cloud riêng.
Lệnh ngắn tương đương cho Safari: `.\scripts\preview-phone.ps1 -UseSupabase`.
Không có `-UseSupabase` thì script dùng backend dev mặc định; `-Offline` mới
chạy UI độc lập. `-UseSupabase` giữ lại để chọn file config local.

## 6. Kiểm chứng quyền và phần còn lại

`supabase/tests/foundation.sql` kiểm tra trigger, dữ liệu demo, quyền khách,
hai customer A/B, admin và ràng buộc giá/tồn kho/biến thể. File chạy toàn bộ
trên môi trường phát triển trong một transaction và kết thúc ROLLBACK.
Nó tạm tạo user fixture bằng SQL để kiểm tra trigger, không tạo mật khẩu hay
kiểm chứng luồng đăng ký email. Nếu lỗi giữa chừng, ROLLBACK trước khi chạy lại.

Đã thử bằng PGlite (PostgreSQL chạy cục bộ) với `auth.users`/`auth.uid()` giả
lập trong bộ kiểm tra ngoài app. Không thêm Node/PGlite vào dependencies
Flutter. Sau đó đã chạy cùng bộ SQL kiểm thử trên Supabase cloud và đạt;
Data API cùng query bằng SDK Flutter cũng đạt. Kiểm tra lại sau rollback:
5 danh mục, 12 sản phẩm, 15 biến thể, 0 user fixture, 6 bảng bật RLS.
Còn cần Auth thật, email xác nhận, đăng nhập/đăng xuất, khôi phục mật khẩu,
redirect Android/web và SDK trong app trên thiết bị.

Khi triển khai Auth, giữ xác nhận email theo cấu hình đã chọn và kiểm tra
redirect thực tế; không tắt bảo vệ chỉ để demo chạy nhanh. Chưa cấu hình
OAuth hay redirect về IP Wi-Fi thay đổi liên tục ở bước nền này.

## Cách trình bày ngắn với giảng viên

Cập nhật 0.1.3: migration `20261109000100_product_cart.sql` đã áp dụng riêng
qua SQL Editor, bổ sung giỏ và RPC/RLS. Hai migration nền vẫn giữ nguyên;
không chạy lại các file tạo bảng trên project hiện tại. Xem
[hướng dẫn chi tiết/giỏ](product-cart-walkthrough.md) và
[bằng chứng](setup-verification.md) cho trạng thái mới nhất; các mục nền ở trên
ghi kết quả tại thời điểm setup ban đầu.

“Nhóm dùng Flutter cho giao diện đa nền tảng và Supabase làm backend dùng
chung. Supabase Auth quản lý đăng nhập; PostgreSQL lưu dữ liệu quan hệ.
Sản phẩm và biến thể tách riêng để quản lý tồn theo size/màu. Chúng em lưu
thay đổi database bằng migration và dùng RLS để bảo vệ từng dòng ngay ở
server. Ví dụ người A chỉ sửa địa chỉ của A; ẩn nút trên giao diện không phải
là cơ chế bảo mật. Vai trò quản trị được cấp từ phía quản trị tin cậy.”

Nguồn chính thức: [Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[API keys](https://supabase.com/docs/guides/getting-started/api-keys),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[Auth và profiles](https://supabase.com/docs/guides/auth/managing-user-data),
[migrations](https://supabase.com/docs/guides/local-development/database-migrations).

# Đăng ký và đăng nhập: đọc code theo từng bước

Phạm vi: Auth email/mật khẩu theo Figma, xác nhận email, gửi lại email,
khôi phục phiên, màn tài khoản tối thiểu và xác nhận đăng xuất. Chưa làm sửa
hồ sơ/avatar, quên mật khẩu, Google login hoặc đơn hàng. Giỏ đã có ở bản 0.1.3,
xem `product-cart-walkthrough.md`. Catalog được
triển khai ở bước sau, xem `catalog-walkthrough.md`; app hiện mở Home trước,
bạn vào tab Tài khoản để dùng Auth.
Không coi phần này là hoàn thành toàn bộ H01 Auth/Profile.

## 1. Chạy app đúng cấu hình

```powershell
cd D:\CodexProjects\smart-fashion-shopping-app
flutter run -d chrome
```

Hoặc chọn `Smart Fashion · Supabase dev` trong VS Code. Từ 0.1.1, lệnh mặc
định đã nối backend phát triển. Bản trước thiếu dart-define sẽ tắt Auth dù
form vẫn hiển thị: đó là nguyên nhân Android báo “Tính năng tài khoản chưa
sẵn sàng”. Chế độ xem UI không có backend nay phải chọn tường minh bằng
`--dart-define=USE_SUPABASE=false`. Với Android thay `chrome` bằng ID thiết bị.

`AppConfig.fromEnvironment` đọc dart-define rồi gọi `AppConfig.forEnvironment`.
Chỉ khi môi trường development và cả URL/key đều trống mới dùng cấu hình
client công khai trong `development_backend.dart`. Một giá trị thiếu thì báo
lỗi, không ghép URL project này với key project khác. Staging/production
không được tự dùng backend dev. Có unit test riêng cho các nhánh này.

Web dùng Safari iPhone:

```powershell
.\scripts\preview-phone.ps1 -UseSupabase
```

Điện thoại cùng Wi-Fi vào `http://IP_MAY_WINDOWS:8080`. `localhost` trên
iPhone là chính iPhone, không phải máy Windows. Đổi IP/cổng thì phải cập nhật
URL callback cụ thể trên Supabase. Không thêm wildcard toàn bộ Internet.

## 2. Giao diện nhận dữ liệu

Nguồn Figma: [Login](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-100),
[Register](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-180),
[Confirm email](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-230),
[Logout](https://www.figma.com/design/EhOyKwsXn0h5srp9YE9Rmp?node-id=4-399).

- `login_page.dart`: email, mật khẩu, hiện/ẩn mật khẩu, nút gửi và banner lỗi.
- `register_page.dart`: họ tên, email, mật khẩu ít nhất 8 ký tự và nhập lại mật khẩu.
- `confirm_email_page.dart`: hướng dẫn xác nhận, gửi lại thư, chờ 60 giây.
- `widgets/auth_widgets.dart`: khung cuộn, nhận diện SF, ô nhập có focus,
  nút chính 52px/nút phụ 48px và banner dùng chung.

Tất cả nằm dưới `lib/features/auth/presentation/`. Form giữ nguyên thông tin
đã nhập khi lỗi; không đổi mật khẩu thành một thông báo lỗi như prototype.
Không điền sẵn email/mật khẩu demo. Các ô và CTA vẫn dùng được khi mở bàn
phím hoặc tăng cỡ chữ. Nền, font, spacing và radius dùng theme/token hiện có.
Email đang nhập được chuyển bằng route extra khi qua lại form, không đưa
email vào URL. Mật khẩu không được chuyển route hoặc giữ lại sau đăng ký.

Khác biệt có chủ đích trong phạm vi hiện tại: dùng thanh giờ/pin thật của
hệ điều hành thay status bar 9:41 giả; header chưa có thao tác Giỏ vì module
đó chưa triển khai. Màn tài khoản chỉ hiển thị tên/email và đăng xuất; các
mục hồ sơ/đơn/địa chỉ/yêu thích sẽ tích hợp ở các bước sau. Bản 0.1.2 đã dùng
bottom navigation chung với Home/Khám phá.
Trang `/` hiện mở Home, `/explore` mở danh sách sản phẩm thật từ Supabase.

## 3. Controller quản lý đang gửi/lỗi

`auth_controller.dart` quản lý trạng thái bằng Riverpod:

- `AsyncData`: đang rảnh hoặc thao tác vừa thành công.
- `AsyncLoading`: đang chờ server; khóa gửi lần hai và khóa chuyển form.
- `AsyncError`: yêu cầu thất bại; hiển thị thông báo tiếng Việt.

Mỗi màn có controller provider riêng để lỗi đăng nhập không xuất hiện ở
đăng ký. Controller gọi hợp đồng `AuthRepository`, không gọi SQL hoặc giữ
token. Khi màn bị hủy trong lúc chờ, controller không cập nhật state đã hủy.
Request có timeout; không tự retry thao tác đăng ký/gửi email.

## 4. Repository gọi Supabase

`domain/` không import Flutter/Supabase: có model `AuthUser`, hợp đồng
`AuthRepository`, `RegistrationResult`, `AuthFailure` và `AuthValidation`.
`data/supabase_auth_repository.dart` hiện thực hợp đồng bằng SDK:

| Thao tác | SDK | Kết quả cần hiểu |
|---|---|---|
| Đăng ký | `auth.signUp` | Gửi `full_name`; không gửi role/admin |
| Đăng nhập | `auth.signInWithPassword` | SDK nhận và lưu session khi đúng |
| Gửi lại email | `auth.resend(type: OtpType.signup)` | Server quyết định gửi và giới hạn tần suất |
| Đăng xuất | `auth.signOut(scope: local)` | Đăng xuất phiên hiện tại |
| Theo dõi phiên | `auth.onAuthStateChange` | Phát sự kiện đăng nhập/đăng xuất/refresh |

Tên/email được trim; mật khẩu giữ nguyên từng ký tự. Lỗi SDK được dịch bằng
error code, không đưa message thô, token hoặc mật khẩu vào UI/log.

**Quan trọng:** `signUp` trả user chưa có nghĩa đã đăng nhập. Khi server yêu
cầu xác nhận email, `session == null`: app mở màn Kiểm tra email. Khi bật
auto-confirm ở môi trường khác, SDK có session thì đi tiếp bình thường.
App không tắt xác nhận email và không giả lập kết quả đăng nhập thành công.

## 5. Database tạo hồ sơ và quyền

Supabase Auth tạo `auth.users`. Trigger đã setup ở migration nền tự tạo
`profiles` và `user_roles=customer`. App chỉ gửi `full_name`, không tự insert
profile hay cấp role. Quyền quản trị không lấy từ metadata do người dùng sửa.

Validation trên app giúp nhập liệu thuận tiện; quyền và ràng buộc thật vẫn
ở Auth/PostgreSQL/RLS. Ẩn một nút trên Flutter không thay cho phân quyền.

## 6. Session và chuyển màn

`main.dart` khởi tạo Supabase trước `runApp`, dùng PKCE và cơ chế lưu/khôi
phục phiên của SDK. Không tự lưu password vào SharedPreferences. SDK hiện
dùng storage mặc định để giữ session; đây không phải tuyên bố token được
mã hóa trong kho bảo mật phần cứng. Không đưa token vào Git hoặc ảnh bàn giao.

`auth_providers.dart` chuyển sự kiện SDK thành `authSessionProvider`.
`app/router/app_router.dart` lắng nghe sự kiện để chạy lại redirect:

- Chưa đăng nhập vào `/account` hoặc `/logout` → `/login`.
- Đã có phiên vào `/login`, `/register`, `/confirm-email` → `/account`.
- `/` vẫn cho khách vào; không bắt đăng nhập toàn bộ ứng dụng.
- `next` chỉ nhận `/` hoặc `/account` đã triển khai, không chuyển tới URL ngoài.

Đây là bảo vệ điều hướng phía client. Database vẫn phải kiểm tra RLS dù
người dùng đi thẳng qua API và bỏ qua giao diện.

## 7. Cấu hình Auth của project phát triển

Project `smart-fashion-dev`, Singapore:

- Email/password và đăng ký: bật. Confirm email: giữ bật.
- Minimum password length: đã đặt 8 ở provider Email.
- Site URL: `http://localhost:8080/`.
- Redirect allowlist: `http://localhost:8080/`, `http://127.0.0.1:8080/`,
  `http://192.168.100.8:8080/` (IP Wi-Fi hiện tại),
  `vn.edu.vku.smartfashion://auth-callback/` (Android).

Web gửi origin hiện tại làm redirect. Android dùng scheme ở trên, khai báo
trong AndroidManifest; Supabase/app_links nhận callback, tắt xử lý deeplink
trùng của Flutter. iOS đã khai báo cùng scheme trong scaffold nhưng chưa
build/test iOS native. Không đổi khóa, gói phí, OAuth hoặc SMTP trong bước này.

Liên kết PKCE tự tạo phiên khi mở lại đúng app/trình duyệt có code verifier.
Nếu mở email trên thiết bị/trình duyệt khác, địa chỉ email có thể đã được xác
nhận nhưng không tự tạo được phiên ở nơi đó: quay về app và đăng nhập bằng
email/mật khẩu. Liên kết hết hạn/đã dùng thì yêu cầu email mới. Không copy URL
chứa code/token vào báo cáo.

## 8. Thử thật và trình bày

SMTP mặc định của Supabase chỉ gửi đến email của thành viên tổ chức và có
giới hạn gửi thấp. Dùng email chủ Supabase cho lần thử này; người dùng tự
nhập mật khẩu trong app và tự mở email. Không gửi password/OTP trong chat.
Muốn bạn cùng nhóm hoặc người dùng ngoài tổ chức nhận thư cần SMTP riêng;
chưa có thông tin SMTP nên chưa cấu hình phần đó.

Checklist tự thử trên mỗi thiết bị:

1. Đăng ký → thấy Kiểm tra email; chưa vào Tài khoản khi chưa xác nhận.
2. Mở email xác nhận → trở lại app và đăng nhập.
3. Nhập sai mật khẩu → banner lỗi; nhập đúng → thấy tên/email thật.
4. Reload web/đóng mở app → phiên còn hợp lệ thì vẫn ở tài khoản.
5. Đăng xuất → quay lại đăng nhập; đi thẳng `/account` không được truy cập.

Kết quả đã quan sát trên web Windows: đăng ký/email confirmation/đăng nhập
thật đạt; reload giữ phiên, hủy đăng xuất giữ phiên, xác nhận đăng xuất và
chặn route tài khoản đạt. Database có 1 user đã xác nhận, 1 profile, 1 quyền
customer, 0 admin. Ngày 09/11, người dùng cài đè bản 0.1.1+2 từ Download
trên Android V2452A và xác nhận đăng nhập thành công. ADB đã đối chiếu đúng
phiên bản. Chưa kiểm tra Safari iPhone thật hoặc đăng ký user mới/callback
email native đến hết trên Android.

Build APK để bàn giao:

```powershell
.\scripts\build-android.ps1 -Mode release
```

File `build/app/outputs/flutter-apk/smart-fashion-dev-release.apk` là release
dùng backend phát triển, hiện ký bằng debug key theo scaffold. Không coi đây
là cấu hình signing production để đưa lên Play Store.

Kiểm thử tự động:

```powershell
.\scripts\check.ps1
flutter test tool/supabase_smoke_test.dart --no-pub --dart-define-from-file=config/development.local.json
```

Test trong `test/features/auth` dùng repository/HTTP fixture để kiểm tra
nhánh lỗi và điều hướng ổn định, không gửi thư. Test ở `tool/` gọi catalog
cloud thật, không kiểm chứng toàn bộ đăng ký email. Bằng chứng manual/cloud
và build nằm trong `docs/setup-verification.md`.

Cách trình bày: “Màn hình kiểm tra dữ liệu rồi gọi controller. Controller
quản lý tải/lỗi và gọi repository. Repository gọi Supabase Auth; SDK xử lý
session. Router theo dõi session để chuyển màn; trigger tạo hồ sơ và quyền
customer, còn RLS bảo vệ dữ liệu tại server.”

Nguồn: [Đăng ký](https://supabase.com/docs/reference/dart/auth-signup),
[Đăng nhập](https://supabase.com/docs/reference/dart/auth-signinwithpassword),
[redirect](https://supabase.com/docs/guides/auth/redirect-urls),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp).

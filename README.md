# Smart Fashion

Nhóm bắt đầu clone tại [quy trình làm việc ba thành viên](docs/team-workflow.md)
và [bàn giao baseline 10/11/2026](docs/team-handoff.md). Nếu main còn chỉ có
README khởi đầu, clone nhánh `chore/project-setup` để review/chạy thử; sau PR
được review và merge, tạo nhánh tính năng từ main mới nhất.

Ứng dụng mua sắm thời trang và tư vấn phối đồ cho đồ án VKU. Repository này
đã có nền Flutter, database/RLS, đăng ký/đăng nhập và Home/catalog Supabase theo Figma.
Home/catalog có tìm/lọc/sắp xếp; chi tiết có chọn biến thể và giỏ Supabase theo tài khoản.
Chưa triển khai checkout/đơn, AI hoặc admin. Màn tài khoản hiện tối thiểu;
chưa có chỉnh sửa hồ sơ/avatar.

## Bắt đầu để hiểu đồ án

Đọc theo thứ tự, mỗi tài liệu giải quyết một việc:

1. [Tổng quan yêu cầu và trạng thái thật](docs/project-overview.md): đang làm
   sản phẩm gì, ai làm gì, setup hiện chưa đáp ứng hết phần nào của Q02.
2. [Đọc và giải thích code](docs/understand-the-code.md): luồng khởi động,
   trách nhiệm từng file và cách trình bày kiến trúc với giảng viên.
3. [Chạy Android và iPhone](docs/android-and-iphone.md): dành cho nhóm hiện
   có Windows, Android và iPhone nhưng chưa có Mac.
4. [Setup Supabase từng bước](docs/supabase-setup.md): bảng dữ liệu, migration,
   quyền truy cập và cách kiểm tra API cloud.
5. [Đọc luồng đăng ký/đăng nhập](docs/auth-walkthrough.md): form → controller →
   repository → Supabase → session → router; cách thử và trình bày với giảng viên.
6. [Home và danh sách sản phẩm từng bước](docs/catalog-walkthrough.md): model,
   repository, Riverpod, tìm/lọc và kịch bản trình bày 3 phút.
7. [Chi tiết, size/màu và giỏ hàng](docs/product-cart-walkthrough.md): biến thể,
   RPC/RLS, chống ghi trùng, cách đọc code và kịch bản demo 4 phút.

## Chạy ngay

Cần Flutter **3.47.5** / Dart **3.13.4**; phiên bản SDK được ghi trong `.fvmrc`.
Không cần FVM nếu Flutter trên PATH đã đúng phiên bản.

```powershell
cd D:\CodexProjects\smart-fashion-shopping-app
flutter pub get
flutter run -d chrome
```

Chạy Android: mở emulator hoặc nối điện thoại có USB debugging, dùng
`flutter devices`, rồi `flutter run -d <device-id>`. Web dùng để preview
trong giai đoạn UI, không phải dashboard web riêng. iOS đã có scaffold,
nhưng cần macOS/Xcode để build và kiểm thử.
Build/run mặc định đã nối `smart-fashion-dev`. Chỉ xem UI offline khi truyền
`--dart-define=USE_SUPABASE=false`. File config local vẫn có thể ghi đè cấu hình
bằng `--dart-define-from-file=config/development.local.json`.

Để bạn dùng iPhone xem bản **web** qua Safari trong cùng Wi-Fi:

```powershell
.\scripts\preview-phone.ps1 -UseSupabase
```

Trên iPhone mở `http://IP_MAY_WINDOWS:8080`, thay bằng IPv4 của máy từ
`ipconfig`. Có thể dùng `.\scripts\preview-phone.ps1` để gọi cùng lệnh.
Đây là preview web, chưa phải bản iOS native cài vào iPhone; xem tài liệu
thiết bị phía trên để hiểu điều kiện ký/build iOS.

## Thành phần đã setup

- Flutter Android/iOS/web, Material 3, locale `vi_VN`.
- Riverpod 3.5, GoRouter 18.1, Supabase Flutter 2.18, SharedPreferences Async.
- Theme/token light từ Figma; Be Vietnam Pro bundle offline, có giấy phép OFL.
- Config qua `--dart-define-from-file`, backend có thể tắt để làm UI độc lập.
- Formatter VNĐ dùng số nguyên; test khởi động/route/config và lệnh CI.
- Auth email/password, xác nhận/gửi lại email, session và xác nhận đăng xuất.
- Home/Khám phá công khai, catalog Supabase, tìm không dấu, lọc và sắp xếp giá.
- Chi tiết/gallery, chọn size/màu còn hàng; giỏ riêng theo tài khoản, chỉnh số lượng/xóa.
- Baseline bàn giao qua `chore/project-setup` → PR → main; không tự đóng GitHub Issues.

Riverpod 3 được chọn cho repository mới với SDK hiện có; tài liệu cũ nhắc
Riverpod 2 không phải dependency đã tồn tại cần giữ. Dùng provider trực tiếp,
chưa thêm code generation khi chưa có tính năng cần đến.

## Cấu hình Supabase

Từ bản 0.1.1, không truyền config thì dùng `smart-fashion-dev` với URL và
publishable key client công khai trong `lib/core/config/development_backend.dart`.
Staging/production phải truyền URL/key riêng; không tự dùng mặc định dev.
Không lưu secret/service-role key hoặc mật khẩu vào file này.
Máy Quân đã có file local để ghi đè; không copy đè file đó. Máy thành viên
chỉ cần tạo config local khi muốn ghi đè:

```powershell
if (-not (Test-Path config/development.local.json)) {
    Copy-Item config/development.example.json config/development.local.json
}
```

Điền URL dự án và publishable key dành cho client, đổi `USE_SUPABASE` thành
`"true"`, rồi chạy:

```powershell
flutter run --dart-define-from-file=config/development.local.json
```

File `*.local.json` được ignore. Giá trị dart-define được đóng gói vào app,
không phải kho giữ bí mật. Không đưa secret/service-role, mật khẩu database
hoặc Gemini key vào đây. Gemini sẽ gọi qua Edge Functions.
Staging/production không được khởi động với backend tắt.

Đã chuẩn bị migration schema/RLS, dữ liệu mẫu và SQL kiểm thử trong
`supabase/`. SQL đã qua kiểm tra PostgreSQL cục bộ; trạng thái áp dụng cloud
được ghi riêng trong [kết quả kiểm tra](docs/setup-verification.md).
Xem [hướng dẫn Supabase](docs/supabase-setup.md) trước khi bật backend.

## Cấu trúc

```text
lib/
  app/                 # MaterialApp, router
  core/
    config/            # Dart defines, validation
    theme/             # Color/type/spacing/radius tokens
    services/          # Supabase client provider
    storage/           # SharedPreferencesAsync provider
    formatters/        # VNĐ
  features/
    auth/              # presentation / domain / data cho Auth
    catalog/           # Home/Explore, model/query và Supabase repository
    cart/              # Giỏ theo tài khoản, controller đọc/ghi và Supabase RPC
```

Xem [cấu trúc module và phân công](lib/features/README.md),
[nguồn thiết kế và quy tắc triển khai](docs/design-handoff.md),
[quy trình làm việc](CONTRIBUTING.md).

[Kết quả kiểm tra setup](docs/setup-verification.md): analyze và 60 test đạt;
APK debug và web preview đã build thành công. iOS chưa build trên Windows,
Supabase cloud đã có kiểm tra SQL/RLS, REST và SDK Flutter; xem mục Auth trong
tài liệu kiểm tra để biết phần manual/thiết bị đã kiểm chứng đến đâu.

## Kiểm tra trước PR

Build APK phát triển có Auth bằng lệnh dễ nhớ:

```powershell
.\scripts\build-android.ps1 -Mode release
```

APK bàn giao: `build/app/outputs/flutter-apk/smart-fashion-dev-release.apk`.
Đây là release dùng backend phát triển, hiện ký bằng debug key theo scaffold;
chưa phải bản ký phát hành trên Play Store.

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
flutter build web --no-pub
```

Sau khi có config cloud và nạp dữ liệu mẫu, chạy riêng
`.\scripts\check-supabase.ps1` để kiểm tra API thật. CI Flutter chưa gọi
cloud; không cần đưa credentials cá nhân vào workflow hiện tại.

Có thể chạy `.\scripts\check.ps1` để thực hiện ba kiểm tra format/analyze/test
ở đầu. Hai lệnh build vẫn chạy riêng khi cần kiểm tra cấu hình nền tảng.

Workflow `.github/workflows/flutter-ci.yml` chạy cùng SDK và dependencies
trong lockfile. Nó chỉ chạy trên GitHub sau khi push; không coi kiểm tra
local là bằng chứng CI remote đã pass. APK debug chưa phải bản phát hành
có signing production.

### Build Android trên Windows

Lần build đầu đã phát hiện Kotlin incremental cache không xử lý được đường
dẫn plugin ở ổ C trong khi checkout ở ổ D. Repo đặt `kotlin.incremental=false`
trong `android/gradle.properties` để build được trên bố cục ổ đĩa này; biên
dịch Kotlin có thể chậm hơn. Không thay Pub cache/SDK chung của máy.
Đây là [tùy chọn chính thức của Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).

## Nguồn kỹ thuật

- [Flutter tạo dự án](https://docs.flutter.dev/reference/create-new-app)
- [Riverpod](https://pub.dev/packages/flutter_riverpod)
- [GoRouter](https://pub.dev/packages/go_router)
- [Supabase Flutter](https://pub.dev/packages/supabase_flutter)
- [SharedPreferences Async](https://pub.dev/packages/shared_preferences)

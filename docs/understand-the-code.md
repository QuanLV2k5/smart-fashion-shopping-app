# Đọc và giải thích code nền

Mục tiêu là bạn tự chỉ ra được file nào làm việc gì và giải thích được dữ liệu
đi qua đâu. Chưa cần học hết API của các thư viện trước khi hiểu luồng này.

## Đọc theo thứ tự này

| Thứ tự | File | Câu hỏi cần trả lời |
|---|---|---|
| 1 | `lib/main.dart` | App khởi động và chuẩn bị gì trước khi vẽ? |
| 2 | `lib/core/config/app_config.dart` | App có đang dùng backend không? Lấy cấu hình từ đâu? |
| 3 | `lib/app/app.dart` | Theme, tiếng Việt và router được gắn ở đâu? |
| 4 | `lib/app/router/app_router.dart` | Đường dẫn `/` mở màn nào? Route sai quay lại ra sao? |
| 5 | `lib/features/auth/presentation/login_page.dart` | Form nhận dữ liệu và gọi controller thế nào? |
| 6 | `lib/core/theme/` | Màu, font, kích thước chữ, khoảng cách được dùng chung ra sao? |
| 7 | `test/` | Những gì đã được kiểm tra tự động? |

Luồng khởi động hiện tại:

`main → đọc/kiểm tra config → khởi tạo Supabase nếu bật → ProviderScope → SmartFashionApp → GoRouter → HomePage`

`WidgetsFlutterBinding.ensureInitialized()` chuẩn bị Flutter trước khi gọi
plugin bất đồng bộ. `runApp()` đưa widget gốc lên màn hình. `MaterialApp.router`
gắn theme, ngôn ngữ và điều hướng cho toàn app.

## Ba khái niệm Riverpod đang dùng

- **Provider**: nơi lấy một đối tượng hoặc trạng thái. Ví dụ `appRouterProvider`
  cung cấp router dùng trong app.
- **ProviderScope**: vùng quản lý các provider. Đặt ở gốc để các màn cùng truy cập.
- **ref.watch**: theo dõi provider; khi giá trị liên quan đổi, widget được cập nhật.
  Sau này `ref.read` thường được dùng khi xử lý một lần bấm nút.

`appConfigProvider.overrideWithValue(config)` đưa cấu hình đã đọc vào cây
provider. Khi test, có thể thay dữ liệu đầu vào để kiểm tra mà không cần gọi cloud.
`ref.onDispose` dọn router và bộ báo refresh khi vùng quản lý bị hủy.

Auth đã có controller quản lý tải/lỗi và stream provider theo dõi session;
xem [đọc code Auth](auth-walkthrough.md). Catalog dùng FutureProvider đọc dữ liệu
và quy tắc tìm/lọc thuần Dart; xem [Home/catalog](catalog-walkthrough.md).
Cart đã có provider đọc/ghi riêng và Supabase RPC; xem [chi tiết/giỏ](product-cart-walkthrough.md).

## Cấu trúc dùng khi bắt đầu một tính năng

Ví dụ catalog sẽ giữ các file liên quan trong `features/catalog/`:

```text
catalog/
  presentation/   # Màn, widget và controller Riverpod: người dùng đang thấy gì?
  domain/         # Product, ProductVariant, hợp đồng repository và quy tắc cần kiểm tra
  data/           # Cách đọc Supabase, đổi JSON thành model, đọc snapshot nếu có
```

Luồng catalog đã triển khai:

`catalogProvider → CatalogRepository → Supabase → CatalogSnapshot → UI`; nhập từ khóa gọi `queryCatalog` trên snapshot đã tải.

Page vẽ dữ liệu và nhận thao tác. Controller điều phối tải/lỗi/thành công.
Repository gom cách lấy dữ liệu. Domain giữ ý nghĩa/quy tắc của dữ liệu, ví dụ
biến thể nào còn hàng. Widget không chứa câu SQL.

Tách thêm một lớp khi nó có trách nhiệm rõ. Một thao tác đơn giản có thể gọi
repository qua controller; quy tắc tổng tiền/tồn kho/điều kiện đánh giá cần được
tách ra để kiểm thử. Khi thêm file, phải giải thích được file đó giúp việc gì.

Catalog chỉ có một model/contract/data dùng chung do Quân bàn giao. Hải làm
presentation và tích hợp vào model đó; giỏ của Phúc dùng cùng mã biến thể.

## Vì sao chọn các thư viện hiện tại

| Thành phần | Lợi ích trong đồ án | Chưa làm gì thay nhóm |
|---|---|---|
| Riverpod | Theo dõi trạng thái và cấp dependency, thuận tiện thay dữ liệu khi test | Không tự tạo logic đăng nhập/giỏ |
| GoRouter | Khai báo tập trung đường đi giữa các màn | Không tự kiểm tra quyền database |
| Supabase Flutter | Client cho Auth, database, ảnh và function | Không tự sinh schema/RLS đúng yêu cầu |
| SharedPreferencesAsync | Lưu dữ liệu nhỏ trên máy qua API bất đồng bộ | Không đảm bảo đơn hàng đã được máy chủ tạo |
| intl | Định dạng giá `473.000đ` theo tiếng Việt | Không tính giá/tồn kho từ dữ liệu đáng tin cậy |

SDK và dependency được ghi trong `.fvmrc`, `pubspec.yaml`, `pubspec.lock`.
File `.fvmrc` ghi phiên bản mong muốn, không tự cài SDK khi chỉ chạy `flutter`.
Báo cáo cũ nhắc Riverpod 2; setup hiện dùng Riverpod 3.5 đã kiểm tra với SDK
hiện có. Khi viết báo cáo kỹ thuật cuối, ghi đúng phiên bản trong lockfile.

## Cấu hình chạy UI và backend

Ở bước hiện tại, có ba trường hợp:

- Không truyền config: dùng cấu hình client công khai của `smart-fashion-dev`.
- Chọn UI offline: truyền `--dart-define=USE_SUPABASE=false`.
- Truyền file `development.local.json` và bật Supabase: khởi tạo client thật,
  cần URL và publishable key hợp lệ.

Trong chế độ UI local, `supabaseClientProvider` trả `null` có chủ đích. Khi
viết repository sau này phải xử lý rõ trường hợp chưa có backend, tránh báo
“đặt hàng thành công” dựa trên dữ liệu giả. Các môi trường staging/production
đã có kiểm tra cấu hình nhưng chưa được triển khai trong đợt setup.

URL và publishable key là cấu hình client. Quyền dữ liệu vẫn phải được bảo vệ
bằng Auth/RLS phía Supabase. Gemini key và khóa đặc quyền nằm phía máy chủ.

## Cách giải thích với giảng viên ở trạng thái hiện tại

“Nhóm em dùng Flutter và Dart để xây dựng phần giao diện và xử lý dùng chung.
Riverpod quản lý trạng thái, GoRouter quản lý điều hướng. Các tính năng sẽ
được chia thành giao diện, quy tắc/model và truy cập dữ liệu; Supabase là
backend đã có PostgreSQL/RLS và Auth được nối vào Flutter. Auth chia thành
giao diện, controller, domain và repository. Gemini/Edge Function và các
module mua hàng vẫn là các bước tiếp theo. iOS native cần build và kiểm thử trên môi trường
macOS trước khi nhóm xác nhận chạy được trên iPhone.”

Đây là lời mô tả đúng bản hiện tại. Khi code và kiểm thử tiến triển, cập nhật
phần đã hoàn thành theo bằng chứng thực tế.

## Hiểu đúng các kiểm tra

| Lệnh | Kiểm tra gì |
|---|---|
| `dart format` | Cách trình bày code thống nhất, không kiểm tra nghiệp vụ |
| `flutter analyze` | Phân tích tĩnh: kiểu dữ liệu, import, API/lint |
| `flutter test` | Những tình huống cụ thể đã viết trong `test/` |
| `flutter build apk` / `build web` | Biên dịch và đóng gói cho nền tảng |
| Chạy trên thiết bị | Hiển thị, bàn phím, mạng, quyền và hành vi thực tế |

60 test hiện tại kiểm tra nền, lựa chọn config, Auth/điều hướng, request SDK/PKCE bằng HTTP
fixture, form ở 360/390/430 với bàn phím và cỡ chữ lớn; thêm catalog mapping,
phân trang, tìm/lọc cùng SKU, sắp xếp, lỗi/retry/giữ snapshot; thêm chọn biến thể,
giỏ/RPC/requestId, đổi tài khoản khi ghi và luồng UI. Test cloud/manual
được ghi riêng trong setup-verification; không coi fixture là server thật.

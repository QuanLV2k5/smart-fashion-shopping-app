# P02 — Địa chỉ nhận hàng (Issue #7)

Ngày triển khai: 11/11/2026. Nhánh `feat/p02-addresses`, baseline `f64bfc9`
(PR #10). Đây là bàn giao code để review, chưa nghiệm thu toàn bộ P02.

## Tài liệu và blocker

Đã đọc tài liệu bàn giao baseline, thiết kế, kiến trúc, Supabase/schema/RLS,
luồng sản phẩm/giỏ, workflow và brief Figma trong repository.
Không tìm thấy `Prompt-Codex-Phuc.md`, kể cả file ẩn/ignore; đã hỏi Phúc đường
dẫn/nội dung, chưa có phản hồi khi viết tài liệu này.

Figma ban đầu chặn quyền, sau khi Phúc được cấp Can edit đã truy cập được.
Đã đọc metadata, design context và screenshot thực tế của đủ 8 frame:
Addresses `4:1314`, AddressBook `4:1336`, AddressForm `4:1358`,
AddressEdit `4:1391`, AddressError `4:1424`, Cart `4:1176`,
SingleCart `4:1214`, CartQty `4:1253`. UI địa chỉ đã chỉnh theo các frame đó,
dùng skill `figma-design-to-code`, theme/token và khung trang hiện có.

## Giao diện sau đối chiếu Figma

- Thẻ địa chỉ nền sage `#E2E9DF`, radius 8, padding 16, cao tối thiểu 138;
  tên/điện thoại cùng dòng, hai dòng địa chỉ và dấu check cho địa chỉ đang chọn.
  Nội dung dài/chữ lớn được xuống dòng và tăng chiều cao, không cắt dữ liệu.
- Addresses: chạm thẻ chọn tạm trong UI; footer **Giao tới địa chỉ này** mới
  xác minh với server, lưu ID và về Cart. Hủy/quay về Giỏ trước xác nhận không
  thay lựa chọn đã lưu. Không chuyển Checkout. Sửa địa chỉ/Thêm địa chỉ mới
  là nút sage toàn chiều rộng dưới thẻ/danh sách.
- AddressBook: footer **Thêm địa chỉ**, có sửa/xóa từng địa chỉ, hỗ trợ nhiều
  địa chỉ thực tế. Xóa có xác nhận và bảo vệ khi đổi tài khoản.
- Form thêm/sửa theo thứ tự Người nhận, Điện thoại, Tỉnh, Quận, Phường,
  Địa chỉ cụ thể; input nhãn bên trong, min-height 76, nền trắng, border token,
  gap 16. Dùng font Be Vietnam Pro cả nội dung và nút trong module.
- Error: chỉ ô không hợp lệ có border đỏ và thông báo cụ thể trong khung;
  giữ giá trị nhập. Lỗi request là banner, không tô đỏ giả tất cả trường.
- Các màn địa chỉ có liên kết **Giỏ** trên header. Next chuyển đúng ô tiếp
  theo, Done đóng bàn phím; form cuộn và footer tránh bàn phím/safe area.

Khác biệt có chủ đích: không có “Đặt làm địa chỉ mặc định” vì schema chưa hỗ
trợ; chọn theo userId trên thiết bị không phải mặc định đồng bộ. Không thêm
CTA Checkout/đặt đơn, gợi ý jeans hoặc đổi giá dòng giỏ. Error có thể tăng
chiều cao ô để giữ cả nội dung và thông báo. Header dùng căn chỉnh chung của
`ShopPageScaffold`, không vẽ status bar giả. Nút Xóa trong chế độ quản lý là
bổ sung cần thiết để giữ CRUD, không có trong screenshot một địa chỉ mẫu.

## Luồng dữ liệu và quyền

`Cart → /addresses/select → AddressBookController → AddressRepository → public.addresses`.
`Account → /addresses` là ngữ cảnh quản lý.
Domain không import Flutter/Supabase. Repository truy cập bảng trực tiếp qua
SDK; không sửa hoặc dùng lại RPC giỏ cho địa chỉ.

- Đọc có phân trang, sort `created_at`, `id`; chỉ lấy `user_id` hiện tại.
- Thêm chỉ gửi UUID tạo một lần cho form và sáu trường được phép sửa.
  `user_id` mặc định bằng `auth.uid()`; timestamp do server quản lý.
- Sửa/xóa lọc đồng thời `id` và `user_id`; không có dòng trả về thì báo đã
  mất địa chỉ/không có quyền, không báo thành công giả.
- Client kiểm tra phiên trước request. RLS `addresses_own` vẫn là ranh giới
  quyền ở server; bộ lọc phía client không thay RLS.
- Validation trim các trường: tên/phường/quận/tỉnh 1–100 ký tự Unicode,
  dòng địa chỉ 1–250; điện thoại khớp `^\+?[0-9]{9,15}$` sau trim.
- Không có `is_default`, không thêm schema/migration, không thay Supabase
  cloud hoặc dữ liệu demo. Không triển khai checkout/đặt đơn.

## Chọn địa chỉ, lỗi và phiên đăng nhập

`PreferencesAddressSelectionStore` chỉ lưu **ID** dưới khóa
`addresses.selected.v1.<userId>` trên từng thiết bị. Không lưu tên, điện thoại,
nội dung địa chỉ. Lựa chọn này không phải địa chỉ mặc định đồng bộ đa thiết bị.

Khi provider khởi tạo (mở Cart/Addresses sau khi mở app), phải đọc server trước
rồi mới phục hồi ID đã lưu. ID không còn trong danh sách thì xóa lựa chọn,
không tự chọn địa chỉ đầu tiên. Bấm Giao tới địa chỉ này cũng đọc server lại. Mở lại app không
tin dữ liệu địa chỉ từ preferences; lỗi mạng không phục hồi một lựa chọn chưa
được xác minh. Pull-to-refresh để nhận thay đổi từ thiết bị khác, chưa realtime.

Controller có tải/rỗng/lỗi/thành công, khóa ghi trùng, giữ danh sách khi lỗi
ghi. Logout/đổi user tạo lượt đọc mới; kiểm tra revision để bỏ phản hồi phiên
cũ, kể cả A → logout → A. Form đổi key theo tài khoản; hộp thoại xóa ẩn thông
tin cũ và khóa xác nhận nếu user thay đổi.

Ghi không tự retry. Khi timeout/mất mạng/500 khiến kết quả chưa rõ, khóa thao
tác mới cho đến khi đọc lại server thành công. Form giữ nội dung; UUID của
lần thêm giữ nguyên trong vòng đời form. Nếu tải lại thấy UUID đó đã tồn tại,
lần bấm Lưu tiếp theo là cập nhật rõ ràng, không thêm bản sao. Không có queue
ghi offline hoặc đảm bảo exactly-once qua lần tắt app. Nếu tắt app giữa lần
ghi chưa rõ kết quả, cần kiểm tra danh sách trước khi thêm lần nữa.

## Phối hợp Quân: router và contract

- `app_router.dart`: `/addresses` là quản lý, `/addresses/select` là chọn từ
  Cart; form `/addresses/new` và `/addresses/:id/edit` nhận `?from=cart` để
  giữ ngữ cảnh nếu cần quay lại từ deep link. Tất cả được bảo vệ bằng đăng
  nhập; deep link khi chưa đăng nhập quay về danh sách đúng ngữ cảnh sau login.
- `auth_redirect.dart`: cho phép `next=/addresses` hoặc `/addresses/select` không query/fragment;
  vẫn chặn URL ngoài và query không hỗ trợ.
- `cart_page.dart`: thêm lối Chọn địa chỉ và hiển thị lựa chọn từ cùng provider.
  Không đổi CartRepository, CartSnapshot, RPC hoặc logic giá/số lượng.
- Contract mới chỉ nằm trong module addresses: `AddressDraft`, `Address`,
  `AddressRepository`, `AddressSelectionStore`, `AddressBookState`.
  Chưa thay chữ ký contract chung/catalog/auth. Quân cần review các thay đổi
  router trước tích hợp; tài liệu này không phải thông báo đã gửi cho Quân.

## Phối hợp Hải (H01)

`lib/features/auth/presentation/account_page.dart` thuộc vùng H01 của Hải.
Thay đổi ở P02 chỉ thêm một `AuthButton` “Địa chỉ giao hàng” mở `/addresses`
trước nút Đăng xuất; không sửa Auth/Profile/controller. Đây là vị trí có thể
conflict khi Hải thay layout Account. Khi tích hợp, giữ lối quản lý địa chỉ
trong layout H01 mới và review cùng Hải; chưa gửi thông báo ngoài phiên chat.

## File tạo/chỉnh sửa

| File | Trách nhiệm |
|---|---|
| `lib/features/addresses/domain/address.dart` | Model, validation, failure, contract |
| `lib/features/addresses/data/supabase_address_repository.dart` | CRUD SDK, mapping, dịch lỗi |
| `lib/features/addresses/data/address_selection_store.dart` | Preferences tách user |
| `lib/features/addresses/presentation/address_providers.dart` | Riverpod/state/điều phối |
| `lib/features/addresses/presentation/addresses_page.dart` | Danh sách/chọn/xóa/trạng thái |
| `lib/features/addresses/presentation/address_form_page.dart` | Thêm/sửa/validation |
| `lib/features/addresses/presentation/widgets/address_widgets.dart` | Input, nút primary/secondary và liên kết Giỏ theo Figma |
| `lib/features/auth/presentation/account_page.dart` | Nút mở AddressBook; cần phối hợp H01 (chỉnh sửa) |
| `lib/app/router/app_router.dart` | Route/guard mới (chỉnh sửa) |
| `lib/app/router/auth_redirect.dart` | Allowlist đích đăng nhập (chỉnh sửa) |
| `lib/features/cart/presentation/cart_page.dart` | Đi địa chỉ/hiển thị lựa chọn (chỉnh sửa) |
| `test/features/addresses/address_domain_test.dart` | Validation/mapping |
| `test/features/addresses/address_controller_test.dart` | CRUD/lỗi/session/race |
| `test/features/addresses/address_flow_test.dart` | Widget/route/form/keyboard/chữ lớn |
| `test/features/addresses/supabase_address_repository_test.dart` | HTTP/payload/filter/phân trang/lỗi |
| `test/features/addresses/address_selection_store_test.dart` | Tách khóa/lưu ID/xóa lựa chọn |
| `test/features/addresses/address_fixtures.dart` | Fake dùng riêng cho test |
| `docs/p02-addresses-handoff.md` | Bàn giao, kiểm chứng, giới hạn |

## Kiểm chứng

SDK máy Phúc: Flutter 3.47.6 / Dart 3.13.5 (baseline mong muốn 3.47.5 /
3.13.4). Không upgrade SDK, không đổi pubspec/lockfile.

Kết quả lượt chỉnh UI theo Figma trước khi bổ sung nút Xóa trong form:

| Kiểm tra | Kết quả |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool` | 72 file, 0 thay đổi |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub --concurrency 1 --timeout 30s --reporter expanded` | 96/96 đạt, gồm 36 test P02 (19 widget/route test); 9 test UI mới trong lượt chỉnh Figma |
| `flutter build apk --debug --no-pub` | Đạt; `build/app/outputs/flutter-apk/app-debug.apk`, 202.782.581 byte |
| `flutter build web --no-pub --no-web-resources-cdn` | Đạt; `build/web/`; Wasm dry run đạt, chưa kiểm thử bản `--wasm` |
| `git diff --check` | Đạt |

Đã chạy SDK bằng đường dẫn `D:\flutter\bin\` vì Flutter/Dart chưa có trong PATH
của shell tác vụ. Ở lượt triển khai nền trước, một lần test bị hết dung lượng
Temp ổ C (errno 112). Lượt chỉnh UI này chạy thành công với `$env:TEMP`/`$env:TMP` trỏ tới
`D:\CodexTemp\smart-fashion-p02` trong riêng process kiểm tra. Không đổi biến
môi trường hệ thống hoặc tự xóa cache/dữ liệu cá nhân. Build Android lượt này
có cảnh báo Java native access nhưng trả exit code 0. APK là debug
phát triển, chưa cài/chạy trên thiết bị trong lượt này.

Các test mặc định dùng fake/HTTP fixture, không gọi hoặc sửa cloud. Test HTTP
403/zero-row chứng minh cách client xử lý lỗi, không phải bằng chứng RLS
cloud. `supabase/tests/foundation.sql` đã có kiểm tra A/B/admin với địa chỉ,
nhưng **chưa chạy lại** trong lượt P02 này. Cần kiểm thử CRUD/RLS bằng hai
tài khoản thật trên môi trường được nhóm cho phép và Android/Safari thật
trước nghiệm thu. Chưa commit, push, tạo PR, merge hoặc đóng Issue #7.

Ảnh render widget có font thật được tạo bằng test với
`--dart-define=P02_CAPTURE=true`, ở `build/p02-ui-review/` (Git ignore).
Đã xem ảnh selection, AddressBook nhiều địa chỉ, sửa và lỗi theo trường để
đối chiếu screenshot Figma. Đây là dữ liệu fixture/widget renderer, không
phải ảnh thiết bị hoặc bằng chứng CRUD cloud. Khi chạy test bình thường,
không xuất ảnh. Không thêm ảnh Figma làm giao diện hoặc thêm dependency.

## Bổ sung Xóa địa chỉ trong màn Sửa

Phúc báo đã kiểm thử trên Microsoft Edge: thêm, sửa và F5 tải lại thành công.
Đây là kết quả do Phúc cung cấp, không phải lần test Edge do agent thực hiện.
Nguyên nhân không thấy nút Xóa: danh sách `/addresses/select` ẩn nút này để
giữ bố cục chọn theo Figma; trước đó nút Xóa chỉ có ở AddressBook quản lý,
trong khi form Sửa chưa có lối xóa. Repository/controller đã có delete.

Đã thêm nút viền đỏ **Xóa địa chỉ** dưới các trường trong màn Sửa, tách khỏi
footer **Lưu địa chỉ**; màn Thêm không có nút Xóa. Không đổi bố cục danh sách.
Hộp thoại có Hủy/Xóa địa chỉ; Hủy giữ bản nháp. Đang xác nhận hoặc đang gửi
thì khóa thao tác lặp; đang gửi cũng khóa Lưu. Không yêu cầu bản nháp hợp lệ
để xóa bản ghi đã lưu.

Repository vẫn DELETE với `id`/`user_id`, `select('id')`, tắt retry ghi; kết
quả không có dòng thì báo lỗi, không coi là xóa thành công. UI chờ controller
trả kết quả rồi mới về danh sách và hiện thông báo. Điều hướng nằm ngoài
form con để vẫn hoạt động khi controller bỏ dòng làm form con bị hủy.

Xóa địa chỉ đang chọn bỏ ID trong RAM và preferences riêng userId; không
đụng lựa chọn của tài khoản khác. Nếu Supabase đã xác nhận xóa nhưng dọn
preferences lỗi, controller trả thành công của thao tác server và giữ cảnh
báo local; UI hiện cảnh báo đó thay vì yêu cầu xóa lại. ID stale trên máy
không còn được dùng trong RAM và sẽ được đối chiếu/xóa khi tải server lại.
Lỗi server/timeout giữ dữ liệu và bản nháp, không hiện thông báo thành công;
timeout yêu cầu tải lại trước thao tác tiếp theo.

Logout/đổi tài khoản trong hộp thoại ẩn thông tin và khóa xác nhận. Nếu phiên
đổi lúc request đang chạy, controller bỏ phản hồi cũ, UI không điều hướng
hoặc hiện thông báo thành công cho phiên mới. Các sửa đổi chỉ gồm:

- `lib/features/addresses/presentation/address_form_page.dart`
- `lib/features/addresses/presentation/address_providers.dart`
- `test/features/addresses/address_fixtures.dart`
- `test/features/addresses/address_controller_test.dart`
- `test/features/addresses/address_flow_test.dart`
- `docs/p02-addresses-handoff.md`

Không đổi repository, router, migration, RLS hoặc Supabase cloud trong lượt
bổ sung nút Xóa. Test mới gồm xác nhận/hủy, chờ server/khóa gửi lặp, thành
công/thất bại, dọn lựa chọn/local lỗi, xóa địa chỉ khác, logout/đổi user và
nút Xóa còn tiếp cận được ở 360/390/430 với chữ lớn/bàn phím.

Kết quả lượt bổ sung Xóa: `flutter analyze --no-pub` không issue;
`flutter test --no-pub --concurrency 1 --timeout 30s --reporter expanded`
đạt **109/109 test**, gồm 49 test P02. Thêm 6 controller test và 7 widget test
cho xóa; test thêm/sửa/chọn và hồi quy Auth/catalog/cart vẫn đạt. Format toàn
bộ lib/test/tool đạt (72 file); `git diff --check` đạt. Chưa kiểm thử xóa trên
Edge hoặc Supabase thật trong lượt này. Không build lại APK/web; các artifact
build/ảnh ở phần trước thuộc bản UI trước khi thêm nút Xóa trong form.

## Kiểm thử thực tế trên Edge và chuẩn bị kiểm chứng RLS A/B

Phúc xác nhận sau khi bổ sung nút Xóa: thêm, sửa, xóa thành công; sau F5 dữ
liệu vẫn chính xác và địa chỉ đã xóa không xuất hiện lại. Phúc tiếp tục xác
nhận trên Edge: A không thấy địa chỉ B và ngược lại; giỏ A không xuất hiện
khi đăng nhập B. Ghi nhận **CRUD/F5 và tách dữ liệu A/B qua UI Edge đạt theo
báo cáo của Phúc**; agent không kiểm thử Edge thay Phúc. Không lưu danh tính,
UUID tài khoản thật, địa chỉ cá nhân hoặc phiên đăng nhập trong tài liệu.

RLS API trực tiếp **chưa kiểm chứng**: chưa gửi request chéo A/B độc lập với
bộ lọc client để thử SELECT/INSERT/UPDATE/DELETE hoặc đổi user_id. UI không
hiện dữ liệu khác tài khoản không tự chứng minh API không cho đọc/sửa chéo.
Bộ 109/109 test đã đạt ở lượt trước và được chạy lại trong lượt chuẩn bị PR
(kết quả ở phần cuối); mock/fixture không thay bằng chứng RLS cloud.

### 1. Đối chiếu chính sách trong repository

Nguồn: `supabase/migrations/20261108000100_initial_foundation.sql`:

- Dòng 61: `addresses.user_id` mặc định `auth.uid()`, FK đến `auth.users`.
- Dòng 144: bật RLS cho `public.addresses`.
- Dòng 146–148: thu hồi quyền từ `PUBLIC`, `anon`, `authenticated` trước khi
  cấp lại; dòng 154 chỉ cấp SELECT/INSERT/UPDATE/DELETE cho `authenticated`.
- Dòng 191–192: policy duy nhất của addresses trong các migration hiện có:

```sql
create policy addresses_own on public.addresses for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
```

`USING` giới hạn dòng SELECT/UPDATE/DELETE có thể thấy/tác động; `WITH CHECK`
giới hạn chủ sở hữu của dòng mới sau INSERT/UPDATE. Do đó A không thể gán
`user_id=B` khi thêm hoặc chuyển địa chỉ đang sở hữu sang B. Admin của app
cũng chỉ CRUD địa chỉ của chính mình; policy này không có ngoại lệ admin.
Đã rà cả ba migration: chưa có migration sau thay đổi policy addresses.
Đây là kết luận từ source, **chưa xác nhận policy đang deploy trên cloud**.

### 2. Chọn môi trường và tài khoản thử

1. Nhờ Quân/nhóm xác nhận project **local/test/dev được phép tạo và xóa
   fixture địa chỉ**, ghi project ref, ngày và người cho phép. Không dùng
   production. Không tự áp migration hoặc chạy lại seed trên cloud chung.
2. Chuẩn bị hai tài khoản thử A/B khác UUID, đã xác nhận email và có phiên
   đăng nhập hợp lệ, ưu tiên vai trò customer. Dùng phiên Edge thường cho A
   và InPrivate/profile khác cho B nếu kiểm tra UI. Không chỉ dùng hai tab
   cùng profile vì có thể dùng chung local storage/session.
3. Chỉ dùng publishable key của đúng project và JWT người dùng A/B. Không
   dùng secret/service-role key hoặc kết quả truy vấn bằng chủ database làm
   bằng chứng RLS. Không gửi mật khẩu/JWT lên chat, ảnh chụp hoặc Git.
4. Chỉ tạo dữ liệu giả có nhãn `P02-RLS-<ma-lan-thu>-A/B`, không lấy địa chỉ
   thật làm mục tiêu thử xóa. Sinh UUID mới, ví dụ trong PowerShell:
   `[guid]::NewGuid().ToString()`. Ghi ID từng fixture để dọn đúng dòng.

### 3. Kiểm tra metadata cloud bằng truy vấn CHỈ ĐỌC

Người có quyền của project test chạy đoạn dưới trong SQL Editor. Không có
DDL/DML, không bật/tắt hoặc sửa RLS:

```sql
select n.nspname as schema_name, c.relname,
       c.relrowsecurity, c.relforcerowsecurity
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'addresses';

select policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'addresses'
order by policyname;

select r.role_name,
       has_table_privilege(r.role_name::name, 'public.addresses', 'SELECT') as can_select,
       has_table_privilege(r.role_name::name, 'public.addresses', 'INSERT') as can_insert,
       has_table_privilege(r.role_name::name, 'public.addresses', 'UPDATE') as can_update,
       has_table_privilege(r.role_name::name, 'public.addresses', 'DELETE') as can_delete
from (values ('anon'::text), ('authenticated'::text)) r(role_name);
```

Mong đợi: `relrowsecurity=true`, policy `addresses_own`, role authenticated,
cmd ALL và hai biểu thức kiểm tra chủ sở hữu; authenticated có bốn quyền,
anon không có quyền nào. `relforcerowsecurity=false` không tự nó là lỗi;
owner/bypass role là lý do không dùng SQL Editor để chứng minh A/B bị chặn.
Xem **tất cả** policy trả về: policy permissive bổ sung có thể mở rộng quyền.
Nếu cloud khác source, ghi nhận và phối hợp Quân, không tự sửa policy.

### 4. Chuẩn bị request REST độc lập với UI/repository

Dùng REST client trên máy (ví dụ công cụ đang có sẵn của nhóm). Đặt biến
cục bộ, không sync/export bí mật:

- `BASE=https://<project-ref-test-da-duoc-phep>.supabase.co`
- `KEY=<publishable-key>`
- `TOKEN_A`, `TOKEN_B`: access token của hai phiên; `USER_A`, `USER_B`: UUID.

Có thể lấy phiên bằng đăng nhập trong app và xem header Authorization của
request địa chỉ tại DevTools Network trên máy. Hoặc đăng nhập trực tiếp:

```http
POST {{BASE}}/auth/v1/token?grant_type=password
apikey: {{KEY}}
Content-Type: application/json

{"email":"<email-A-hoac-B>","password":"<nhap-cuc-bo>"}
```

Lưu `access_token` vào biến token tương ứng, `user.id` vào USER_A/B, không
ghi response đăng nhập vào biên bản. Xác minh từng token bằng:

```http
GET {{BASE}}/auth/v1/user
apikey: {{KEY}}
Authorization: Bearer {{TOKEN_A}}
```

Lặp lại với B; phải trả HTTP 200 và hai user ID khác nhau. Nếu 401/token hết
hạn thì đăng nhập lại, không tính đó là RLS đã chặn truy cập chéo.

Header cho các request địa chỉ có đăng nhập:

```http
apikey: {{KEY}}
Authorization: Bearer {{TOKEN_A}}
Content-Type: application/json
Prefer: return=representation
```

Đổi sang TOKEN_B để thử B. Với GET không cần Content-Type/Prefer. Các thử
truy cập chéo bên dưới **chỉ lọc theo ID**, không thêm `user_id=eq.USER_A`
hoặc đi qua controller của app: phải cho request tới server kiểm tra RLS.

### 5. Tạo fixture và kiểm tra quyền của chính mình

1. Sinh `ADDR_A`, `ADDR_B` là hai UUID mới. A gửi:

```http
POST {{BASE}}/rest/v1/addresses
```

```json
{
  "id": "<ADDR_A>",
  "recipient_name": "P02-RLS-<ma-lan-thu>-A",
  "phone": "0900000001",
  "address_line": "Fixture P02 RLS A",
  "ward": "Phuong thu",
  "district": "Quan thu",
  "city": "Thanh pho thu"
}
```

Mong đợi HTTP 201, một dòng có `id=ADDR_A`, `user_id=USER_A`. Không gửi
user_id để kiểm tra default `auth.uid()`. B làm tương tự với ADDR_B, nhãn B
và số `0900000002`; phải nhận đúng USER_B. Lưu snapshot hai dòng này.
Nếu muốn kiểm tra thêm INSERT với user_id tường minh bằng chính mình, tạo
một fixture UUID mới cho mỗi user, thêm `"user_id":"<USER_A/B>"`; cũng phải
201, đúng chủ. Ghi cả các ID phụ vào danh sách cleanup.

2. A GET `/rest/v1/addresses?id=eq.<ADDR_A>&select=*`: 200, đúng một dòng A.
   B GET ID của B: tương tự. Không chấp nhận `[]` cho ca đọc chính mình.
3. A PATCH `/rest/v1/addresses?id=eq.<ADDR_A>` với body
   `{"address_line":"Fixture A own update"}`: 200, một dòng đã sửa. B sửa
   dòng B tương tự. Mỗi chủ GET lại xác nhận giá trị mới; lưu snapshot mới.
4. Chưa xóa hai dòng chính; dùng chúng cho kiểm tra chéo trước.

### 6. Chạy ma trận truy cập chéo theo CẢ HAI chiều

Đầu tiên dùng TOKEN_A với đích B, sau đó đổi A/B để chạy lại toàn bộ. Mọi
body đều phải hợp lệ theo schema, tránh nhầm lỗi validation/FK thành RLS.

| Ca | Request bằng A | Kết quả mong đợi |
|---|---|---|
| SELECT dòng B | GET `/rest/v1/addresses?id=eq.<ADDR_B>&select=*` | 200, `[]` |
| SELECT tập A+B | GET `/rest/v1/addresses?id=in.(<ADDR_A>,<ADDR_B>)&select=id,user_id` | Chỉ một dòng A, không có B |
| INSERT giả chủ B | POST body hợp lệ như bước 5, **UUID fixture mới** và `"user_id":"<USER_B>"` | 403, code `42501`, RLS từ chối |
| UPDATE dòng B | PATCH `/rest/v1/addresses?id=eq.<ADDR_B>`, body `{"address_line":"Cross update must fail"}` | 200, `[]`, 0 dòng thay đổi |
| Chuyển chủ dòng A | PATCH `/rest/v1/addresses?id=eq.<ADDR_A>`, body `{"user_id":"<USER_B>"}` | 403, code `42501` do WITH CHECK |
| DELETE dòng B | DELETE `/rest/v1/addresses?id=eq.<ADDR_B>` | 200, `[]`, 0 dòng bị xóa |

Sau **mỗi** UPDATE/DELETE chéo, chủ thật GET lại đúng ID: bản ghi phải còn,
giá trị/owner/updated_at không đổi so với snapshot trước request đó. Sau
INSERT giả chủ, B GET UUID fixture mới phải `[]`. Sau chuyển chủ, A GET dòng
A phải vẫn thuộc A. Lặp lại đầy đủ bằng B đối với A, không suy ra chiều kia.

HTTP 2xx cho UPDATE/DELETE chéo **không tự động là lỗ hổng**: RLS có thể lọc
toàn bộ dòng. Phải kiểm tra body rỗng và đọc lại bằng chủ thật. Ngược lại,
chỉ thấy lỗi 4xx cũng chưa đủ: ghi HTTP + code + bằng chứng dữ liệu không đổi.
Nếu bất kỳ ca nào lộ/sửa/xóa được dòng khác, dừng thử ghi tiếp, giữ bằng
chứng đã che token và báo Quân; không tự tắt hoặc nới policy để thử lại.

### 7. Khách chưa đăng nhập và DELETE chính mình

1. Bỏ hẳn header Authorization, chỉ giữ `apikey: KEY`. Thử GET ID fixture,
   POST fixture mới hợp lệ, PATCH và DELETE ID fixture. Theo GRANT hiện có,
   cả bốn phải bị từ chối (thường HTTP 401 khi anon, code `42501`; môi trường
   có lớp gateway có thể trả 403). Không dùng token của A/B còn lưu trong
   REST client. Chủ thật GET lại phải xác nhận dữ liệu không đổi. Phân biệt
   401/code 42501 của quyền anon với 401 do key/token không hợp lệ.
2. Sau khi hoàn tất các ca chéo, A DELETE đúng ADDR_A với
   `Prefer: return=representation`: 200, một dòng trả về có ID ADDR_A.
   A GET lại ADDR_A phải `[]`; B vẫn GET được ADDR_B.
3. B DELETE ADDR_B tương tự; B GET lại phải `[]`. Đây là bằng chứng DELETE
   chính mình qua API, độc lập với kết quả UI/F5 trước đó.
4. Mỗi user tự dọn các fixture phụ đúng UUID đã tạo, gồm fixture INSERT giả
   chủ nếu ca đó bất ngờ được phép. Chỉ chủ thật xóa dòng của mình; nếu không
   dọn được, ghi rõ ID và nhờ người quản lý môi trường test xử lý. Không DELETE
   toàn bảng hoặc xóa theo nhãn rộng. Không xóa tài khoản/dữ liệu ngoài fixture.
5. Kiểm tra các ID cleanup bằng chủ thật trả `[]`, xóa biến chứa token/mật
   khẩu/response đăng nhập khỏi REST client sau khi dùng. Không thay policy,
   không chạy migration, không tạo user qua SQL.

### 8. Ghi biên bản và trạng thái xác minh hiện tại

Với mỗi ca ghi: ngày/giờ, project ref test, nhãn actor A/B/anon, ID fixture,
method/path, HTTP status, mã lỗi hoặc số dòng trả về, kết quả owner GET lại,
PASS/FAIL và cleanup. Ghi người kiểm thử; không ghi Authorization, key bí mật,
mật khẩu hoặc dữ liệu địa chỉ cá nhân. Khi có kết quả thật, điền vào bảng sau
ngay trong tài liệu này, không chuyển ca chưa chạy thành PASS theo suy đoán:

| Hạng mục | Trạng thái thực tế hiện tại |
|---|---|
| Đọc schema/GRANT/policy trong cả ba migration | Đã đối chiếu; khớp nguyên tắc CRUD riêng theo auth.uid() |
| CRUD/F5 trên Microsoft Edge | Phúc xác nhận đạt; không phải ma trận RLS API trực tiếp |
| A/B không thấy địa chỉ nhau trên UI Edge | Phúc xác nhận đạt hai chiều; chưa chứng minh API chéo bị chặn |
| Giỏ A không xuất hiện khi đăng nhập B trên Edge | Phúc xác nhận đạt; giữ nguyên Cart/RPC baseline |
| 109 test tự động | Đạt và chạy lại trong lượt chuẩn bị PR; fake/HTTP fixture không chứng minh cloud RLS |
| Metadata policy/GRANT đang deploy trên project test | Chưa xác minh trực tiếp |
| Project được nhóm cho phép, hai tài khoản A/B và hai JWT hợp lệ | Chưa cung cấp/xác nhận cho lượt kiểm thử API này |
| SELECT/INSERT/UPDATE/DELETE chính mình bằng API với A và B | Chưa chạy ma trận API độc lập |
| SELECT/INSERT/UPDATE/DELETE chéo A→B và B→A | Chưa xác minh |
| UPDATE chuyển user_id sang tài khoản khác | Chưa xác minh |
| Anon bị từ chối cả bốn thao tác | Chưa xác minh riêng cho addresses qua API thật |
| Cleanup fixture API | Chưa áp dụng: lượt này không tạo fixture/cloud request |

Lượt chuẩn bị này không có Supabase MCP, phiên A/B hay xác nhận môi trường
test; agent **không gọi API cloud, không chạy SQL trên cloud, không thay đổi
production/policy**. File `supabase/tests/foundation.sql` có sẵn các ca RLS
bằng role/fixture và ROLLBACK, nhưng không chạy lại trong lượt này. File đó
còn tạo user/đổi catalog trong transaction, nên không dùng thay ma trận REST
P02 hoặc tự chạy trên cloud chung chỉ vì có ROLLBACK.

Tham chiếu: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[API keys](https://supabase.com/docs/guides/getting-started/api-keys),
[PostgreSQL row security](https://www.postgresql.org/docs/17/ddl-rowsecurity.html).

## Chuẩn bị Pull Request P02 vào main — 11/11/2026

Chỉ chuẩn bị nội dung để Phúc duyệt. Chưa stage/commit/push/tạo PR, chưa
merge/rebase hoặc đóng Issue. Lượt này chỉ cập nhật tài liệu, không sửa code.

### Git và phạm vi đề xuất commit

Đã `git fetch origin` thành công và kiểm tra trực tiếp remote refs:

- `feat/p02-addresses`, local `main` và `origin/main` đều ở
  `f64bfc9dbf71945a57caf94d93177e454cb00b57` tại thời điểm rà soát.
- Ahead/behind theo commit: 0/0; P02 vẫn ở working tree, không phải không có
  thay đổi. Có **4 file tracked sửa + 14 file mới = 18 file**; index trống.
- Đã đọc toàn bộ diff tracked và diff từng file mới bằng
  `git diff --no-index -- /dev/null <file>`, không chỉ xem `git diff --stat`.
  Exit code 1 của `--no-index` biểu thị có khác biệt, không phải lỗi kiểm tra.
- Đề xuất commit đúng 18 file trong bảng **File tạo/chỉnh sửa** ở trên:
  7 file `lib/features/addresses/`, 6 file `test/features/addresses/`,
  `app_router.dart`, `auth_redirect.dart`, `account_page.dart`, `cart_page.dart`
  và tài liệu này. Không thêm file khác hoặc dùng `git add .` mà chưa rà lại.
- Không có file build/ảnh render, config local hoặc `.env` trong danh sách.
  Đã xác minh `build/`, `config/*.local.json`, `.env` bị ignore; các đường dẫn
  build/config local kiểm tra không được Git theo dõi hoặc stage.
- Đã quét mẫu JWT/private key/secret key và rà các vị trí token/password trong
  18 file. Không phát hiện credential thật hoặc dữ liệu người dùng thực tế.
  `test-token`, `test-refresh`, `fixture-only`, `public-test-key` chỉ là chuỗi
  giả trong MockClient; tên/địa chỉ/số điện thoại ở test là fixture/demo Figma,
  không lấy từ lần kiểm thử Edge. Tài liệu chỉ có placeholder thông tin Auth.

### Rủi ro tích hợp với H01 và router

`origin/feat/h01-profile` đang ở `309995b081556d1e0c9273dee86078f113613551`,
chưa nằm trong main tại thời điểm fetch. Đã đọc diff nhánh H01 ở ba file chung:

| File | P02 | H01 / nguy cơ khi tích hợp |
|---|---|---|
| `account_page.dart` | Thêm nút Địa chỉ giao hàng mở `/addresses` | Hải thay layout hồ sơ và đã có mục Sổ địa chỉ với placeholder. Giữ layout H01, nối mục đó đến `/addresses`, tránh hai lối trùng; nguy cơ conflict cao |
| `app_router.dart` | Guard/routes `/addresses*`, đích login theo ngữ cảnh | H01 thêm `/account/profile`, bảo vệ `/account/*`, thay đích login. Cần ghép cả hai nhóm route/guard, không chọn nguyên ours/theirs; nguy cơ conflict cao |
| `auth_redirect.dart` | Allowlist `/addresses`, `/addresses/select` | H01 thêm `/account/profile` cùng vùng allowlist; nguy cơ conflict cao |

Với **origin/main hiện tại**, chưa có thay đổi upstream để xung đột với
baseline P02. Kết luận trên là rà source/nguy cơ hunk chồng nhau, không phải
kết quả thử merge. Chưa merge/rebase, chưa tạo commit tạm/worktree/index tạm.
Nếu H01 vào main trước, P02 cần cập nhật/tích hợp sau khi Phúc cho phép và
Quân chốt thứ tự, rồi chạy lại cả test P02/H01 trên bản tích hợp. Kết quả 109
test hiện tại áp dụng cho P02 trên baseline main, không chứng minh H01+P02.

### Kiểm tra lại trước PR

Lượt chuẩn bị PR đã chạy với TEMP/TMP `D:\CodexTemp\smart-fashion-p02`:

- `dart format --output=none --set-exit-if-changed lib test tool`: 72 file,
  0 thay đổi.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub --concurrency 1 --timeout 30s --reporter expanded`:
  **109/109 test đạt**.
- `git diff --check`: đạt. Không đổi dependency hoặc lockfile.

Đã chạy `flutter pub get --enforce-lockfile`: đạt, không thay pubspec/lockfile.
Build bản cuối theo yêu cầu CONTRIBUTING trước PR: APK debug đạt
(`build/app/outputs/flutter-apk/app-debug.apk`), web đạt (`build/web/`,
`--no-web-resources-cdn`). Wasm dry run đạt, chưa kiểm thử bản `--wasm`.
Android chỉ có cảnh báo Java native access, exit code 0. Không cài thiết bị
trong lượt này; build output vẫn bị ignore và không nằm trong 18 file commit.

### Commit và Pull Request đề xuất

Commit message:

```text
feat(addresses): implement P02 address book and cart selection
```

PR title:

```text
feat(addresses): thêm CRUD và chọn địa chỉ theo tài khoản (P02)
```

Base `main`, compare `feat/p02-addresses`. Đề xuất mở **Draft** sau khi Phúc
cho phép vì còn xác minh RLS API, phối hợp H01 và review/CI. Reviewer chính
Quân; đề nghị Hải xem phần Account. Không dùng từ khóa tự đóng Issue.
Nội dung đề xuất theo `.github/pull_request_template.md`:

```markdown
## Thay đổi

Refs #7 — https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7

Bổ sung quản lý nhiều địa chỉ và chọn địa chỉ giao hàng từ Cart qua Supabase.
Form thêm/sửa và xác nhận xóa giữ dữ liệu khi lỗi; chỉ báo thành công sau
phản hồi server. Lựa chọn lưu ID riêng theo userId, được xác minh lại khi tải
server; logout/đổi tài khoản không dùng phản hồi phiên cũ.

UI đối chiếu các frame Figma Addresses/AddressBook/AddressForm/AddressEdit/
AddressError. Có route quản lý `/addresses`, route chọn `/addresses/select`
và nút mở sổ địa chỉ từ Account. Không đổi RPC/tính tiền giỏ, migration/RLS,
dependency; không có checkout/đặt đơn hoặc is_default.

## Kiểm tra

- [x] `flutter pub get --enforce-lockfile`.
- [x] Format/analyze/test bằng các lệnh tương đương `scripts/check.ps1`:
  72 file format không đổi, analyzer sạch, 109/109 test đạt.
- [x] Build APK debug và web của bản hiện tại đạt.
- [x] Phúc kiểm thử Edge: CRUD/F5 đúng; A/B không thấy địa chỉ nhau; giỏ A
  không xuất hiện khi đăng nhập B. Đây là bằng chứng UI, không phải test RLS
  API trực tiếp. Widget test có 360/390/430px, chữ lớn và bàn phím.
- [ ] Đính kèm ảnh/video Edge đã che thông tin nhạy cảm; ảnh widget hiện có
  chỉ là fixture trong build/p02-ui-review, không phải ảnh thiết bị thật.
- [ ] CI check-and-build của commit mới nhất đạt (chưa tạo PR/push).

## Tích hợp

- Quân review `app_router.dart`/`auth_redirect.dart`; Hải review nút địa chỉ
  trong `account_page.dart`. Chưa có xác nhận review của owner.
- H01 `309995b` sửa cùng ba file và có mục Sổ địa chỉ placeholder. Cần giữ
  layout H01, nối mục đó đến `/addresses`, ghép guard/profile route và cả hai
  allowlist sau khi Quân chốt thứ tự tích hợp. Chưa merge/rebase hoặc test
  bản kết hợp H01+P02.
- Không có migration mới, không thay đổi Supabase cloud.
- Chưa xác minh RLS API trực tiếp A/B (đọc/ghi chéo, giả/chuyển chủ, anon),
  chưa kiểm thử Android/Safari thật. Quy trình RLS và kết quả manual nằm
  trong docs/p02-addresses-handoff.md.

Giữ Draft đến khi chốt các mục kiểm chứng/tích hợp với reviewer. Dùng Refs
để liên kết Issue; không tự đóng Issue #7 hoặc ghi Actual hours thay Phúc.
```

### Các mục cần Quân/Hải review hoặc chưa hoàn tất

- Quân duyệt route/guard/allowlist và thứ tự tích hợp H01/P02; Hải review lối
  Sổ địa chỉ trong Account. Chưa có xác nhận review từ hai người trong phiên.
- Ma trận RLS API trực tiếp A/B, INSERT giả chủ, UPDATE chuyển chủ và anon
  còn chưa chạy; Quân xác nhận môi trường test và bằng chứng trước nghiệm thu.
- [Issue #7](https://github.com/QuanLV2k5/smart-fashion-shopping-app/issues/7)
  yêu cầu tích hợp H01 trước kiểm thử tài khoản cuối sprint. Chưa kiểm thử bản
  tích hợp H01+P02; chưa có bằng chứng thực tế B không sửa được địa chỉ A bằng
  request trực tiếp. Không tự đánh dấu toàn bộ AC/DoD hoàn tất.
- Chưa có ảnh/video Edge do Phúc cung cấp để đính kèm PR/Issue; ảnh widget là
  fixture, không thay video luồng thật. Chưa kiểm thử Android/Safari thật.
- CI của commit/PR mới chưa tồn tại; cần check-and-build đạt và reviewer khác
  duyệt trước merge. SDK local 3.47.6/Dart 3.13.5 khác CI Flutter 3.47.5.
- Actual hours chưa được cung cấp; không tự ghi theo estimate. Chưa tìm thấy
  `Prompt-Codex-Phuc.md`; phạm vi triển khai theo yêu cầu cụ thể trong phiên
  và tài liệu có trong repository, không khẳng định đã đọc file còn thiếu.

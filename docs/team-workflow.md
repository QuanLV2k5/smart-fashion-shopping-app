# Ba thành viên code cùng repo mà hạn chế xung đột

Repo: [QuanLV2k5/smart-fashion-shopping-app](https://github.com/QuanLV2k5/smart-fashion-shopping-app).
Tài khoản riêng: Quân `QuanLV2k5`, Hải `TranLeNguyenHai`, Phúc `DinhCongPhuc`.
Phân công/ước lượng vẫn theo [R3](planning/README.md); chưa bắt đầu Sprint 2 trong lần bàn giao này.

## 1. Nhớ ba khái niệm

- `main`: bản dùng chung đã tích hợp, để cả nhóm clone/chạy/demo.
- Feature branch: bản làm việc riêng cho **một nhiệm vụ**, ví dụ `feat/h01-profile`.
- Pull request (PR): đề nghị đưa nhánh riêng vào main để bạn khác review và CI kiểm tra.

Mỗi người clone một bản trên máy mình và dùng tài khoản GitHub của mình.
Hai người làm hai nhánh không ghi đè file đang mở trên máy nhau. Xung đột có
thể xuất hiện lúc merge nếu sửa cùng vùng code; cần xử lý và test, không có
cấu hình nào bảo đảm mọi thay đổi đều không lỗi.

## 2. Clone và chạy lần đầu

Cài Git, Flutter **3.47.5** / Dart **3.13.4**, Android SDK nếu chạy Android.
Phiên bản nhóm ghi ở `.fvmrc`; không tự `flutter upgrade` hoặc `pub upgrade`.

Sau khi PR baseline đã được review/merge:

```powershell
git clone https://github.com/QuanLV2k5/smart-fashion-shopping-app.git
cd smart-fashion-shopping-app
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
.\scripts\check.ps1
flutter run -d chrome
```

Trong lúc main mới chỉ có README khởi đầu, clone nhánh bàn giao để **review/chạy thử**:

```powershell
git clone --branch chore/project-setup https://github.com/QuanLV2k5/smart-fashion-shopping-app.git
cd smart-fashion-shopping-app
flutter pub get --enforce-lockfile
.\scripts\check.ps1
flutter run -d chrome
```

Đợi baseline merge main rồi mới tách nhánh tính năng từ main. Không tạo lịch
sử Git mới bằng `git init` trong bản clone. Không cần chép SDK, build/ hoặc
file local.properties từ máy Quân; Flutter tạo cấu hình máy khi build.

Mặc định app kết nối smart-fashion-dev bằng **publishable key công khai**.
Không cần file config local của Quân để chạy. Auth vẫn xác nhận email;
SMTP mặc định hiện giới hạn gửi tới thành viên tổ chức, nên không giả định
email bất kỳ đều đăng ký nhận thư được. Clone Git không tạo bản sao database.
Nhóm dùng cloud dev đã có; **không chạy lại migration tạo bảng**.

iPhone chưa có Mac dùng web qua Safari cùng Wi-Fi:
`.\scripts\preview-phone.ps1`, rồi mở `http://IP_MAY_WINDOWS:8080`.
Đó là web, chưa phải iOS native; xem [hướng dẫn thiết bị](android-and-iphone.md).

## 3. Bắt đầu mỗi nhiệm vụ

Ví dụ Hải làm hồ sơ H01, còn Phúc dùng nhánh `feat/p02-addresses` cho địa chỉ.
Tên nhánh theo nhiệm vụ, không dùng một nhánh cá nhân kéo dài cả tháng.

```powershell
git status
git switch main
git pull --ff-only origin main
git switch -c feat/h01-profile
```

Chỉ đổi nhánh khi đã commit hoặc lưu an toàn công việc đang làm. Đọc Issue,
kiểm tra code baseline và thống nhất phần còn thiếu trước khi viết lại module.
Nếu main chưa có trên máy nhưng đã merge remote, dùng
`git fetch origin` rồi `git switch --track origin/main`.

## 4. Code, kiểm tra và push

Mỗi PR tập trung một tính năng/bug, commit nhỏ có nội dung cụ thể. Ví dụ trên
nhánh của Hải, chỉ stage file đã xem diff và đúng phạm vi:

```powershell
git status
git diff
git add lib/features/auth test/features/auth
git diff --cached
git commit -m "feat(auth): update own profile with validation"
```

Trước push, lấy main mới nhất vào **nhánh đang làm**, không ghi đè main:

```powershell
git fetch origin
git merge origin/main
flutter pub get --enforce-lockfile
.\scripts\check.ps1
flutter build apk --debug --no-pub
git push -u origin feat/h01-profile
```

Nếu chủ đích đổi dependency, sửa pubspec.yaml, chạy `flutter pub get`, review
và commit cả pubspec.lock. Không dùng enforce-lockfile để cập nhật dependency.
Thay đổi chỉ liên quan docs không cần build APK; thay UI vẫn chạy thử màn bị ảnh hưởng.

Lần push đầu phải có quyền collaborator đã được chấp nhận. Repo public ai cũng
clone được nhưng không tự có quyền push. Nếu báo 403, kiểm tra tài khoản đang
đăng nhập và lời mời, không đổi sang tài khoản của Quân hoặc nhét token vào remote URL.

## 5. Tạo PR và merge

Trên GitHub: Pull requests → New pull request → base `main`, compare nhánh
của mình. Mô tả thay đổi, liên kết Issue bằng `Refs`, cách thử và phần chưa làm.
Giữ draft nếu chưa sẵn sàng. Người review theo kế hoạch: Hải review Quân,
Phúc review Hải, Quân review Phúc; có thể thêm người liên quan khi đổi contract.

CI tự kiểm tra dependency đã khóa, format, analyze, test, build Android và
web. Chỉ merge khi check **check-and-build của commit mới nhất** đạt và có
ít nhất một người khác duyệt. CI pass không thay việc chạy luồng trên máy.
Reviewer đọc cả logic, test và migration; không chỉ bấm Approve dựa vào ảnh.

Quân điều phối merge từng PR một vào main. Nếu main thay đổi sau khi PR được
duyệt, cập nhật main vào nhánh, xử lý/test lại và đợi CI/review mới nếu bị stale.
Sau merge, có thể xóa nhánh đã hoàn thành trên GitHub, rồi mỗi người:

```powershell
git switch main
git pull --ff-only origin main
flutter pub get --enforce-lockfile
.\scripts\check.ps1
```

Nhiệm vụ tiếp theo tạo nhánh mới từ main, không tiếp tục nhánh cũ đã merge.
Nếu main có lỗi sau merge, dùng PR sửa hoặc revert commit lỗi, không force-push/reset lịch sử chung.

## 6. Khi Git báo conflict

1. `git status` để biết file xung đột; báo người sửa cùng file.
2. Mở file, hiểu hai thay đổi, ghép phần cần giữ và xóa dấu `<<<<<<<`, `=======`, `>>>>>>>`.
3. Với pubspec.lock, giải quyết pubspec.yaml trước rồi chạy `flutter pub get`
   để sinh lockfile; không chọn toàn bộ ours/theirs một cách máy móc.
4. Chạy format/analyze/test và thử tính năng của cả hai phía.
5. `git add` đúng file đã giải quyết, `git commit`, rồi `git push` nhánh riêng.

Muốn dừng merge chưa hoàn tất, dùng `git merge --abort` rồi trao đổi lại;
đó không phải cách xóa các commit đã làm. Quy trình dùng merge để cập nhật
main nên không cần force-push nhánh đang chia sẻ.

## 7. Các file cần phối hợp trước khi sửa

| Phần | Người phụ trách/phối hợp |
|---|---|
| auth, profile, catalog presentation | Hải; Phúc review theo Issue |
| cart, addresses, orders | Phúc; Quân review theo Issue |
| catalog domain/data và contract chung | Quân; trao đổi với Hải/Phúc trước khi đổi chữ ký/model |
| app_router, main.dart, core/theme, pubspec và CI | Báo Quân và người đang dùng trước khi sửa |
| supabase/migrations | Người làm feature viết migration mới; Quân điều phối áp dụng cloud sau review |

Không ràng buộc người này chỉ được sửa một thư mục: thay đổi liên quan nhiều
lớp vẫn có trong cùng PR, nhưng cần thông báo owner của phần dùng chung.
Hai người không cùng nhận một thay đổi router/pubspec/schema mà chưa thống nhất.

**Git branch không tách database cloud.** Sửa Supabase dùng chung ảnh hưởng
cả nhóm ngay, dù code còn ở nhánh riêng. Không sửa/xóa migration đã áp dụng,
không reset schema/seed lại để thử. Viết file timestamp mới, review/test trước,
rồi Quân áp dụng đúng một lần và ghi kết quả. Lịch sử migration CLI hiện chưa
baseline, nên không tự chạy `supabase db push` lên project hiện tại.

## 8. Bằng chứng và giới hạn của baseline

Đọc [team-handoff](team-handoff.md): Auth/catalog/cart đã có một phần code
trước khi bàn giao; Hải/Phúc review, tiếp nhận và hoàn thiện AC còn thiếu.
Không tạo commit giả dưới tên người khác, không tự coi baseline là giờ thực tế
của từng thành viên. Không đóng H01/H02/P02 chỉ vì đã nhìn thấy màn hình.

Giữ pubspec.lock và .fvmrc trong Git; bỏ build/, APK, local.properties,
config/*.local.json, mật khẩu, keystore và secret/service-role key. Publishable
key client là công khai; RLS/RPC phía Supabase mới bảo vệ dữ liệu.

Sau khi mỗi người clone, chạy check, mở app thật, tự ghi lại commit/thiết bị/
kết quả hoặc blocker vào Issue liên quan. Quân không xác nhận hộ hai máy.

Nguồn chính thức: [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow),
[review PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews),
[bảo vệ nhánh](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches),
[quyền cộng tác](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/inviting-collaborators-to-a-personal-repository).

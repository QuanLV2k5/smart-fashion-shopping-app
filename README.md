# Smart Fashion

Repository dùng chung của Quân, Hải và Phúc cho đồ án Smart Fashion.

Đây là commit khởi đầu để có nhánh main làm base cho pull request đầu tiên.
Mã Flutter và tài liệu bàn giao đang được đưa lên nhánh **chore/project-setup**.

Trong lúc chờ review/merge, clone nhánh đó để kiểm tra:

```powershell
git clone --branch chore/project-setup https://github.com/QuanLV2k5/smart-fashion-shopping-app.git
cd smart-fashion-shopping-app
flutter pub get --enforce-lockfile
.\scripts\check.ps1
flutter run -d chrome
```

Dùng Flutter **3.47.5** / Dart **3.13.4**. Xem Pull requests và Actions để
kiểm tra bản bàn giao. Sau review/CI đạt và merge, main sẽ có toàn bộ dự án.
Không bắt đầu Sprint 2 hoặc tự đóng Issue chỉ từ commit khởi đầu này.

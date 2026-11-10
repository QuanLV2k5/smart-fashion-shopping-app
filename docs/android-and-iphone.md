# Chạy với Windows, Android và iPhone

Điều kiện nhóm đã xác nhận: máy tính Windows, có điện thoại Android và iPhone,
chưa có Mac. Một bộ mã Flutter vẫn được dùng chung; mỗi nền tảng có bước build
và cấu hình riêng. `android/` và `ios/` là hai phần cấu hình native của cùng app.

## Chọn đúng cách chạy

| Mục đích | Dùng gì hiện tại | Có chứng minh iOS native chạy được không? |
|---|---|---|
| Thử nhanh trên máy tính | Flutter web trên Chrome | Chưa |
| Thử app Android thật | Windows + Android qua USB | Chưa; đây là kiểm thử Android |
| Bạn dùng iPhone xem UI | Safari mở bản web từ Windows qua Wi-Fi | Chưa; đây là kiểm thử web trên iPhone |
| Cài app iOS native | Môi trường macOS/Xcode và ký app phù hợp | Chỉ xác nhận sau khi cài/chạy thử trên iPhone |

Flutter hướng dẫn build/chạy iOS bằng [Xcode trên macOS](https://docs.flutter.dev/platform-integration/ios/setup).
APK không cài được trên iPhone. Có thư mục `ios/` hoặc build simulator thành
công chưa đủ để kết luận một bản app đã cài được trên điện thoại thật.

Bạn đang dùng iPhone vẫn có thể lập trình trên Windows: dùng Chrome hoặc
Android Emulator để chạy code hằng ngày. Chỉ bước build/kiểm thử iOS native
mới cần môi trường macOS; cả nhóm không phải đổi sang hai bộ mã khác nhau.

## Bạn chạy Android native

1. Mở Developer options trên điện thoại, bật USB debugging.
2. Cắm USB truyền dữ liệu, chấp nhận thông báo cho phép debug từ máy tính này.
3. Trong thư mục project, chạy:

```powershell
flutter devices
flutter run -d MA_THIET_BI_ANDROID
```

Thay `MA_THIET_BI_ANDROID` bằng ID từ lệnh đầu. Nếu chỉ hiện Chrome/Edge,
Flutter chưa nhận điện thoại: kiểm tra dây, thông báo cho phép và driver USB.
Xem [hướng dẫn Android của Flutter](https://docs.flutter.dev/platform-integration/android/setup).

Để cài bản debug đã build, dùng APK trong `build/app/outputs/flutter-apk/`.
Bản đó hiện chỉ có màn khởi động tạm; lần setup trước chưa chạy thử trên
Android thật vì không có thiết bị kết nối.

## Bạn dùng iPhone xem bản web cùng Wi-Fi

Hai thiết bị phải ở cùng mạng Wi-Fi/LAN và mạng cho phép chúng kết nối với nhau.
Từ thư mục project, chạy:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --no-web-resources-cdn
```

Lệnh này mở server để trình duyệt trên thiết bị khác truy cập. Tùy chọn cuối
cho phép phục vụ tài nguyên renderer từ máy đang chạy, giảm phụ thuộc CDN.
Web-server là target Flutter hỗ trợ để mở app bằng trình duyệt tùy chọn:
[hướng dẫn Flutter web](https://docs.flutter.dev/platform-integration/web/building).

Mở cửa sổ PowerShell khác, chạy `ipconfig`, lấy **IPv4 Address của Wi-Fi/Ethernet
đang dùng**. Ví dụ máy Windows có IP `192.168.1.20`, trên Safari của iPhone mở:

```text
http://192.168.1.20:8080
```

Đây là IP ví dụ: thay bằng IP thật của máy bạn. `localhost` trên iPhone chỉ
chính iPhone; `0.0.0.0` là địa chỉ lắng nghe của server, không phải URL mở trên điện thoại.

Có thể dùng lệnh tắt đã kèm project:

```powershell
.\scripts\preview-phone.ps1
```

Script chỉ gọi lệnh Flutter phía trên và gợi ý địa chỉ mạng; đọc script để thấy
lệnh thực sự. Nếu PowerShell chặn script, dùng lệnh Flutter trực tiếp.

Nếu cổng 8080 đã được chương trình khác dùng, chạy
`.\scripts\preview-phone.ps1 -Port 8081` rồi dùng cổng 8081 trên điện thoại.

Nếu không mở được: kiểm tra đúng IP, cùng Wi-Fi, tắt VPN trong lúc thử nếu
VPN đang tách đường mạng, và kiểm tra mạng guest có chặn thiết bị cùng LAN.
Nếu Windows hỏi quyền mạng cho Flutter/Dart, cho phép trên mạng Private tin cậy.
Không cần tắt toàn bộ Firewall. Giữ cửa sổ server mở, dùng Ctrl+C để dừng.

Việc này giúp bạn cùng nhóm góp ý UI ngay. Nó không kiểm tra được signing,
quyền ảnh/tệp của app iOS hay lifecycle native trên iPhone.

## Khi cần chạy iOS native thật

Cách phù hợp để nhóm bắt đầu là sắp xếp một buổi dùng Mac ở trường/người quen:

1. Cài cùng phiên bản Flutter, Xcode và công cụ iOS theo Flutter doctor trên Mac.
2. Lấy đúng mã nguồn/commit chung và chạy `flutter pub get`.
3. Cắm iPhone vào Mac, Trust máy và bật Developer Mode theo hướng dẫn iOS.
4. Mở `ios/Runner.xcworkspace`, kiểm tra Signing & Capabilities và chọn Team.
5. Kiểm tra `flutter devices`, chạy `flutter run -d MA_IPHONE` từ project.

Tài khoản cá nhân miễn phí có thể dùng cho thử nghiệm trực tiếp với những
giới hạn của Apple; xem [Flutter về development signing](https://docs.flutter.dev/platform-integration/ios/setup).
Phân phối qua TestFlight/App Store cần quy trình/tài khoản chương trình Apple
tương ứng: [Flutter hướng dẫn phát hành iOS](https://docs.flutter.dev/deployment/ios).

Máy macOS cloud là một hướng khác, nhưng bản cho thiết bị thật vẫn cần ký.
Không phải cứ build ra file `.ipa` là gửi rồi cài được như APK; bản
`--no-codesign` dùng kiểm tra build, không phải bản cài iPhone.
[Ví dụ quy trình signing trên Codemagic](https://docs.codemagic.io/yaml-code-signing/signing-ios/).

Project hiện có deployment target iOS 15.0 theo scaffold. Cần kiểm tra phiên
bản iOS của thiết bị, plugin, signing và chạy thật khi có môi trường macOS.
Hiện chưa có bằng chứng kiểm thử iOS native, chưa cấu hình Team của nhóm.

## Hai bạn cùng phát triển

Hai bạn cùng sửa code Dart qua Git; mỗi máy có Flutter SDK và cấu hình local
riêng. Khi nối backend, cùng dùng môi trường Supabase phát triển đã thống nhất;
SharedPreferences/giỏ local nằm riêng trên từng thiết bị, không tự đồng bộ.

Code hiện mới ở máy Quân, chưa commit/push. Bạn khác clone GitHub lúc này chưa
nhận được phần setup. Sau khi nhánh đã được đưa lên GitHub, cần checkout đúng
nhánh/commit; giữ `pubspec.lock`, chạy `flutter pub get`, rồi chọn thiết bị.
Không copy `build/`, `.dart_tool/`, `android/local.properties` hoặc cache từ máy này sang máy khác.

Theo kế hoạch hiện tại, Android APK là đầu ra ưu tiên. Nếu giảng viên yêu cầu
cả hai bản native, nhóm cần chốt sớm thời điểm/môi trường kiểm thử iOS và báo
cáo đúng kết quả từng nền tảng.

abstract final class AuthValidation {
  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Vui lòng nhập họ và tên';
    if (name.length > 100) return 'Họ và tên tối đa 100 ký tự';
    return null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email chưa hợp lệ';
    }
    return null;
  }

  static String? password(String? value, {bool registering = false}) {
    // Không trim mật khẩu: khoảng trắng có thể là ký tự người dùng đã chọn.
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (registering && value.length < 8) return 'Cần ít nhất 8 ký tự';
    return null;
  }
}

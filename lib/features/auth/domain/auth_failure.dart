/// Lỗi đã được dịch sang tiếng Việt; không đưa lỗi thô/token ra giao diện.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.needsConfirmation = false});

  final String message;
  final bool needsConfirmation;

  static const unavailable = AuthFailure(
    'Tính năng tài khoản chưa sẵn sàng. Vui lòng thử lại sau.',
  );
  static const network = AuthFailure(
    'Chưa kết nối được. Kiểm tra Internet rồi thử lại.',
  );
  static const unknown = AuthFailure(
    'Chưa thực hiện được yêu cầu. Vui lòng thử lại.',
  );
}

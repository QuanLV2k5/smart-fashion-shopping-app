/// Model ứng dụng dùng, không phụ thuộc kiểu dữ liệu của Supabase SDK.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.emailConfirmed = false,
  });

  final String id;
  final String email;
  final String fullName;
  final bool emailConfirmed;
}

enum RegistrationResult { confirmationRequired, signedIn }

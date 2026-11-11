import 'auth_user.dart';

/// Hợp đồng: màn hình/controller không cần biết cách gọi Supabase.
abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watchUser();
  Future<void> signIn({required String email, required String password});
  Future<RegistrationResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> resendConfirmation(String email);
  Future<void> signOut();
}

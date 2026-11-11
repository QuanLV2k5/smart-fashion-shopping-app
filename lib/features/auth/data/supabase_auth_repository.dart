import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, {required this.emailRedirectTo});

  final SupabaseClient? _client;
  final String emailRedirectTo;

  GoTrueClient get _auth => _client?.auth ?? (throw AuthFailure.unavailable);

  AuthUser? _user(User? user) => user == null
      ? null
      : AuthUser(
          id: user.id,
          email: user.email ?? '',
          emailConfirmed: user.emailConfirmedAt != null,
          fullName: switch (user.userMetadata?['full_name']) {
            final String name => name,
            _ => '',
          },
        );

  @override
  AuthUser? get currentUser => _user(_client?.auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() => _client == null
      ? Stream.value(null)
      : _client.auth.onAuthStateChange.map(
          (event) => _user(event.session?.user),
        );

  @override
  Future<void> signIn({required String email, required String password}) =>
      _request(() async {
        await _auth.signInWithPassword(email: email.trim(), password: password);
      });

  @override
  Future<RegistrationResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => _request(() async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: emailRedirectTo,
      data: {'full_name': fullName.trim()},
    );
    // user != null chưa có nghĩa đã đăng nhập. Session mới là dấu hiệu đó.
    return response.session == null
        ? RegistrationResult.confirmationRequired
        : RegistrationResult.signedIn;
  });

  @override
  Future<void> resendConfirmation(String email) => _request(() async {
    await _auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: emailRedirectTo,
    );
  });

  @override
  Future<void> signOut() =>
      _request(() => _auth.signOut(scope: SignOutScope.local));

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 25));
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw AuthFailure.network;
    } on AuthException catch (error) {
      throw translateAuthFailure(error);
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }
}

AuthFailure translateAuthFailure(AuthException error) {
  if (error is AuthRetryableFetchException) return AuthFailure.network;
  if (error.statusCode == '429' ||
      const {
        'over_request_rate_limit',
        'over_email_send_rate_limit',
      }.contains(error.code)) {
    return const AuthFailure(
      'Bạn thao tác quá nhanh. Vui lòng chờ một lúc rồi thử lại.',
    );
  }
  return switch (error.code) {
    'invalid_credentials' => const AuthFailure(
      'Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.',
    ),
    'email_not_confirmed' => const AuthFailure(
      'Email chưa được xác nhận. Hãy kiểm tra hộp thư trước khi đăng nhập.',
      needsConfirmation: true,
    ),
    'weak_password' => const AuthFailure(
      'Mật khẩu chưa đủ mạnh. Hãy dùng ít nhất 8 ký tự.',
    ),
    'email_address_invalid' || 'validation_failed' => const AuthFailure(
      'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
    ),
    'user_already_exists' || 'email_exists' => const AuthFailure(
      'Không thể đăng ký với email này. Thử đăng nhập hoặc dùng email khác.',
    ),
    'signup_disabled' => const AuthFailure(
      'Đăng ký hiện chưa khả dụng. Vui lòng thử lại sau.',
    ),
    'email_address_not_authorized' => const AuthFailure(
      'Chưa gửi được thư đến email này. Vui lòng liên hệ hỗ trợ để được xác nhận tài khoản.',
    ),
    'otp_expired' ||
    'flow_state_expired' ||
    'flow_state_not_found' => const AuthFailure(
      'Liên kết đã hết hạn hoặc đã dùng. Vui lòng yêu cầu email mới.',
    ),
    _ => AuthFailure.unknown,
  };
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import 'auth_providers.dart';

// Mỗi màn có trạng thái tải/lỗi riêng để không mang lỗi đăng nhập sang đăng ký.
final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
final registrationControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
final confirmationControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
final logoutControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> signIn(String email, String password) async =>
      await _run(() async {
        await ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password);
        return true;
      }) ??
      false;

  Future<RegistrationResult?> signUp(
    String name,
    String email,
    String password,
  ) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUp(fullName: name, email: email, password: password),
  );

  Future<bool> resend(String email) async =>
      await _run(() async {
        await ref.read(authRepositoryProvider).resendConfirmation(email);
        return true;
      }) ??
      false;

  Future<bool> signOut() async =>
      await _run(() async {
        await ref.read(authRepositoryProvider).signOut();
        return true;
      }) ??
      false;

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (state.isLoading) return null; // Chặn double tap/double submit.
    state = const AsyncLoading();
    try {
      final result = await action();
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(
          error is AuthFailure ? error : AuthFailure.unknown,
          stack,
        );
      }
      return null;
    }
  }
}

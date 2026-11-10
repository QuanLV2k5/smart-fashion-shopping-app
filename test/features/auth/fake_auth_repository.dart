import 'dart:async';

import 'package:smart_fashion/features/auth/domain/auth_repository.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';

/// Chỉ dùng trong test. App thật không có tài khoản hay đăng nhập giả.
class FakeAuthRepository implements AuthRepository {
  static const user = AuthUser(
    id: 'test-id',
    email: 'test@example.com',
    fullName: 'Người kiểm thử',
    emailConfirmed: true,
  );
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? session;
  int loginCalls = 0;
  int registerCalls = 0;
  int resendCalls = 0;
  Future<void> Function()? onSignIn;
  RegistrationResult registrationResult =
      RegistrationResult.confirmationRequired;

  @override
  AuthUser? get currentUser => session;
  @override
  Stream<AuthUser?> watchUser() async* {
    yield session;
    yield* _changes.stream;
  }

  void setUser(AuthUser? user) {
    session = user;
    _changes.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    loginCalls++;
    if (onSignIn != null) {
      await onSignIn!();
    } else {
      setUser(user);
    }
  }

  @override
  Future<RegistrationResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    if (registrationResult == RegistrationResult.signedIn) setUser(user);
    return registrationResult;
  }

  @override
  Future<void> resendConfirmation(String email) async {
    resendCalls++;
  }

  @override
  Future<void> signOut() async {
    setUser(null);
  }

  Future<void> close() => _changes.close();
}

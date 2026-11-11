import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/auth/data/supabase_auth_repository.dart';
import 'package:smart_fashion/features/auth/domain/auth_failure.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MemoryPkceStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _items[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _items.remove(key);
  }
}

void main() {
  test(
    'signup gửi full_name, không gửi role; trim email/tên nhưng giữ mật khẩu',
    () async {
      late Map<String, dynamic> payload;
      final client = SupabaseClient(
        'https://test.supabase.co',
        'sb_publishable_test',
        authOptions: AuthClientOptions(pkceAsyncStorage: MemoryPkceStorage()),
        httpClient: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.path, '/auth/v1/signup');
          expect(
            request.url.queryParameters['redirect_to'],
            'vn.edu.vku.smartfashion://auth-callback/',
          );
          return http.Response(
            jsonEncode({
              'id': 'test-id',
              'aud': 'authenticated',
              'email': 'test@example.com',
              'created_at': '2026-11-08T00:00:00Z',
              'user_metadata': {'full_name': 'Test'},
            }),
            200,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(
        client,
        emailRedirectTo: 'vn.edu.vku.smartfashion://auth-callback/',
      );
      final result = await repository.signUp(
        fullName: ' Test ',
        email: ' test@example.com ',
        password: ' password ',
      );
      expect(payload['email'], 'test@example.com');
      expect(payload['password'], ' password ');
      expect(payload['data'], {'full_name': 'Test'});
      expect(payload['code_challenge_method'], 's256');
      expect(payload['code_challenge'], isNotEmpty);
      expect(result, RegistrationResult.confirmationRequired);
      expect(repository.currentUser, isNull);
    },
  );

  test('lỗi SDK được dịch theo code, không lộ message thô', () {
    expect(
      translateAuthFailure(
        const AuthException('raw error', code: 'invalid_credentials'),
      ).message,
      'Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.',
    );
    expect(
      translateAuthFailure(
        const AuthException('raw', code: 'email_not_confirmed'),
      ).needsConfirmation,
      isTrue,
    );
    expect(
      translateAuthFailure(AuthRetryableFetchException()),
      AuthFailure.network,
    );
    expect(
      translateAuthFailure(const AuthException('private raw error')).message,
      AuthFailure.unknown.message,
    );
    expect(
      translateAuthFailure(const AuthException('raw', statusCode: '429'))
          .message,
      contains('chờ'),
    );
  });
}

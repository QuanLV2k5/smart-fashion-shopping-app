import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart' as app;
import 'package:smart_fashion/features/profile/data/supabase_profile_repository.dart';
import 'package:smart_fashion/features/profile/domain/profile.dart';
import 'package:smart_fashion/features/profile/presentation/profile_providers.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/fake_auth_repository.dart';
import 'fake_profile_repository.dart';
import 'profile_flow_test.dart' as harness;

Map<String, dynamic> profileRow(String? avatar) => {
  'id': 'test-id',
  'full_name': 'Reviewer',
  'phone': '0901234567',
  'avatar_path': avatar,
  'updated_at': '2026-11-11T00:00:00Z',
};

Future<SupabaseClient> signedClient(
  Future<http.Response> Function(http.Request) handle, {
  void Function()? onAuthUpdate,
}) async {
  final user = {
    'id': 'test-id',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'reviewer@example.test',
    'created_at': '2026-11-11T00:00:00Z',
    'user_metadata': {'full_name': 'Reviewer'},
  };
  final client = SupabaseClient(
    'https://example.supabase.co',
    'public-test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token':
                'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'test-id', 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}))).replaceAll('=', '')}.fixture-signature',
            'token_type': 'bearer',
            'refresh_token': 'test-refresh-token',
            'expires_in': 3600,
            'user': user,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/auth/v1/user') {
        onAuthUpdate?.call();
        return http.Response(
          jsonEncode(user),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/auth/v1/logout') {
        return http.Response('{}', 200, request: request);
      }
      return handle(request);
    }),
  );
  addTearDown(client.dispose);
  await client.auth.signInWithPassword(
    email: 'reviewer@example.test',
    password: 'fixture-only',
  );
  return client;
}

void main() {
  test('a saved preset must remain a preset after repository fetch', () async {
    final client = await signedClient(
      (request) async => http.Response(
        jsonEncode([profileRow('preset:emerald')]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      ),
    );
    final profile = await SupabaseProfileRepository(client).fetchProfile();
    expect(profile!.avatarUrl ?? profile.avatarPath, 'preset:emerald');
  });

  test('reset avatar must send explicit null to the database', () async {
    late Map<String, dynamic> payload;
    final client = await signedClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode(profileRow(payload['avatar_path'] as String?)),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final result = await SupabaseProfileRepository(client).updateProfile(
      fullName: 'Reviewer',
      phone: '0901234567',
      avatarPath: null,
    );
    expect(payload.containsKey('avatar_path'), isTrue);
    expect(payload['avatar_path'], isNull);
    expect(result.avatarPath, isNull);
  });

  test(
    'logout during a profile write must not update another auth session',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      late http.Request write;
      var metadataUpdates = 0;
      final client = await signedClient((request) {
        write = request;
        started.complete();
        return response.future;
      }, onAuthUpdate: () => metadataUpdates++);
      final pending = SupabaseProfileRepository(client)
          .updateProfile(fullName: 'Name from old session');
      final rejected = expectLater(pending, throwsA(isA<ProfileFailure>()));
      await started.future;
      await client.auth.signOut(scope: SignOutScope.local);
      response.complete(
        http.Response(
          jsonEncode(profileRow(null)),
          200,
          request: write,
          headers: {'content-type': 'application/json'},
        ),
      );
      await rejected;
      expect(metadataUpdates, 0);
    },
  );

  testWidgets('whitespace-only name must show validation without crashing', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..session = const app.AuthUser(
        id: 'test-id',
        email: 'reviewer@example.test',
        fullName: 'Reviewer',
        emailConfirmed: true,
      );
    final profile = FakeProfileRepository(
      initialProfile: const UserProfile(
        id: 'test-id',
        email: 'reviewer@example.test',
        fullName: 'Reviewer',
      ),
    );
    await harness.pumpProfileApp(
      tester,
      authRepository: auth,
      profileRepository: profile,
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile_full_name')),
      '   ',
    );
    await tester.tap(harness.saveButton());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
  });

  testWidgets('a failed profile fetch blocks saving and offers retry', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..session = FakeAuthRepository.user;
    final profile = FakeProfileRepository()
      ..onFetch = () async => throw ProfileFailure.network;
    await harness.pumpProfileApp(
      tester,
      authRepository: auth,
      profileRepository: profile,
    );
    expect(find.text('Tải lại hồ sơ'), findsOneWidget);
    expect(tester.widget<FilledButton>(harness.saveButton()).onPressed, isNull);
    expect(profile.updateCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving retains storage path rather than replacing it with a public URL',
    (tester) async {
      final auth = FakeAuthRepository()..session = FakeAuthRepository.user;
      final profile = FakeProfileRepository(
        initialProfile: const UserProfile(
          id: 'test-id',
          email: 'test@example.com',
          fullName: 'Reviewer',
          avatarPath: 'test-id/avatar.png',
          avatarUrl: 'https://example.test/avatar.png',
        ),
      );
      await harness.pumpProfileApp(
        tester,
        authRepository: auth,
        profileRepository: profile,
      );
      await tester.tap(harness.saveButton());
      await tester.pumpAndSettle();
      expect(profile.currentProfile!.avatarPath, 'test-id/avatar.png');
    },
  );

  testWidgets(
    'account switch clears profile draft and discards an old write result',
    (tester) async {
      final auth = FakeAuthRepository()..session = FakeAuthRepository.user;
      const oldProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        fullName: 'Account A',
      );
      final profile = FakeProfileRepository(initialProfile: oldProfile);
      final pendingWrite = Completer<UserProfile>();
      profile.onUpdate = (_, _, _) => pendingWrite.future;
      final container = await harness.pumpProfileApp(
        tester,
        authRepository: auth,
        profileRepository: profile,
      );
      final pending = container
          .read(profileControllerProvider.notifier)
          .updateProfile(fullName: 'Old unsaved name');
      profile.currentProfile = const UserProfile(
        id: 'user-b',
        email: 'b@example.test',
        fullName: 'Account B',
      );
      auth.setUser(
        const app.AuthUser(
          id: 'user-b',
          email: 'b@example.test',
          fullName: 'Account B',
          emailConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account A'), findsNothing);
      expect(find.text('Account B'), findsOneWidget);
      pendingWrite.complete(oldProfile);
      expect(await pending, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Đã cập nhật hồ sơ cá nhân thành công.'), findsNothing);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/account/profile',
      );
    },
  );
}

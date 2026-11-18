import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_fashion/features/ai/data/supabase_ai_repository.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';

import '../cart/cart_fixtures.dart';

const input = AiRequest(style: 'Casual', occasion: 'Đi chơi', budget: 500000);
Future<SupabaseClient> clientFor(
  Future<http.Response> Function(http.Request) handle,
) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'public-test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token':
                'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'user-a', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}))).replaceAll('=', '')}.fixture',
            'refresh_token': 'fixture',
            'expires_in': 3600,
            'token_type': 'bearer',
            'user': {
              'id': 'user-a',
              'aud': 'authenticated',
              'created_at': '2026-11-18T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/auth/v1/logout') {
        return http.Response('{}', 200);
      }
      return handle(request);
    }),
  );
  addTearDown(client.dispose);
  await client.auth.signInWithPassword(
    email: 'fixture@example.test',
    password: 'fixture-only',
  );
  return client;
}

http.Response outfit(List<String> ids) => http.Response(
  jsonEncode({
    'provider': 'gemini',
    'products': [
      for (final id in ids) {'id': id},
    ],
    'explanation': 'Phù hợp',
    'totalVnd': 1,
  }),
  200,
  headers: {'content-type': 'application/json'},
);
void main() {
  test('client resolves catalog IDs and calculates real total rather than model price', () async {
    final client = await clientFor((_) async => outfit([shirtId, jeansId]));
    final result = await SupabaseAiRepository(
      client,
      DetailCatalogRepository(),
    ).recommend(input);
    expect(result.totalVnd, 448000);
  });
  test('unknown IDs, duplicated IDs and budget failure never become recommendations', () async {
    for (final ids in [
      [shirtId, 'invented'],
      [shirtId, shirtId],
    ]) {
      final client = await clientFor((_) async => outfit(ids));
      await expectLater(
        SupabaseAiRepository(
          client,
          DetailCatalogRepository(),
        ).recommend(input),
        throwsA(isA<AiFailure>()),
      );
    }
    final client = await clientFor((_) async => outfit([shirtId, jeansId]));
    await expectLater(
      SupabaseAiRepository(client, DetailCatalogRepository()).recommend(
        const AiRequest(style: 'Casual', occasion: 'Đi chơi', budget: 300000),
      ),
      throwsA(isA<AiFailure>()),
    );
  });
  test('late response after logout is ignored', () async {
    final pending = Completer<http.Response>();
    final called = Completer<void>();
    final client = await clientFor((_) {
      called.complete();
      return pending.future;
    });
    final result = SupabaseAiRepository(
      client,
      DetailCatalogRepository(),
    ).recommend(input);
    final rejected = expectLater(result, throwsA(isA<AiFailure>()));
    await called.future;
    await client.auth.signOut();
    pending.complete(outfit([shirtId, jeansId]));
    await rejected;
  });
  test('quota and timeout codes give actionable messages', () {
    expect(
      SupabaseAiRepository.messageForCode('AI_QUOTA'),
      contains('giới hạn'),
    );
    expect(
      SupabaseAiRepository.messageForCode('AI_TIMEOUT'),
      contains('quá thời gian'),
    );
  });
}

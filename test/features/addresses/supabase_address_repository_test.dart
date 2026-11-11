import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/addresses/data/supabase_address_repository.dart';
import 'package:smart_fashion/features/addresses/domain/address.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'address_fixtures.dart';

const userId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> row([String id = 'a']) => {
  'id': id,
  'user_id': userId,
  ...draft.fields,
  'created_at': '2026-11-11T00:00:00Z',
  'updated_at': '2026-11-11T00:00:00Z',
};

Future<SupabaseClient> backend(
  Future<http.Response> Function(http.Request) handler,
) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'public-test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token': 'test-token',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'email': 'test@example.com',
              'created_at': '2026-11-11T00:00:00Z',
            },
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return handler(request);
    }),
  );
  addTearDown(client.dispose);
  await client.auth.signInWithPassword(
    email: 'test@example.com',
    password: 'fixture-only',
  );
  return client;
}

http.Response response(
  http.Request request,
  dynamic body, [
  int status = 200,
]) => http.Response(
  jsonEncode(body),
  status,
  request: request,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'CRUD đúng endpoint, payload, bộ lọc chủ sở hữu và trường server quản lý',
    () async {
      final requests = <http.Request>[];
      final client = await backend((request) async {
        requests.add(request);
        return response(
          request,
          request.method == 'DELETE'
              ? [
                  {'id': 'a'},
                ]
              : request.headers['accept'] == 'application/vnd.pgrst.object+json'
              ? row()
              : [row()],
        );
      });
      final repo = SupabaseAddressRepository(client);
      expect(await repo.load(userId), hasLength(1));
      expect((await repo.create(userId, 'a', draft)).userId, userId);
      expect((await repo.update(userId, 'a', draft)).id, 'a');
      await repo.delete(userId, 'a');
      expect(requests.map((r) => r.method), ['GET', 'POST', 'PATCH', 'DELETE']);
      for (final request in requests) {
        expect(request.url.path, '/rest/v1/addresses');
        if (request.method != 'POST') {
          expect(request.url.queryParameters['user_id'], 'eq.$userId');
        }
        if (request.method == 'PATCH' || request.method == 'DELETE') {
          expect(request.url.queryParameters['id'], 'eq.a');
        }
      }
      expect(jsonDecode(requests[1].body), {'id': 'a', ...draft.fields});
      expect(jsonDecode(requests[2].body), draft.fields);
    },
  );
  test('phân trang đầy đủ và sort ổn định', () async {
    var calls = 0;
    final requests = <http.Request>[];
    final client = await backend((request) async {
      calls++;
      requests.add(request);
      return response(
        request,
        calls == 1 ? [for (var i = 0; i < 100; i++) row('$i')] : [row('last')],
      );
    });
    expect(
      await SupabaseAddressRepository(client).load(userId),
      hasLength(101),
    );
    expect(calls, 2);
    expect(
      requests.first.url.queryParameters['order'],
      'created_at.asc.nullslast,id.asc.nullslast',
    );
    expect(requests.last.url.queryParameters['offset'], '100');
  });
  test(
    'RLS từ chối, zero-row update/delete và server lỗi không lộ chi tiết',
    () async {
      var status = 403;
      var code = '42501';
      final client = await backend(
        (request) async => status == 200
            ? response(request, <Map<String, dynamic>>[])
            : response(request, {
                'code': code,
                'message': 'private SQL details',
              }, status),
      );
      final repo = SupabaseAddressRepository(client);
      await expectLater(
        repo.create(userId, 'a', draft),
        throwsA(
          isA<AddressFailure>()
              .having((e) => e.uncertain, 'definite permission error', false)
              .having(
                (e) => e.message.contains('private'),
                'no raw SQL',
                false,
              ),
        ),
      );
      status = 200;
      await expectLater(
        repo.update(userId, 'a', draft),
        throwsA(isA<AddressFailure>()),
      );
      await expectLater(
        repo.delete(userId, 'a'),
        throwsA(isA<AddressFailure>()),
      );
      status = 500;
      code = 'XX000';
      await expectLater(
        repo.create(userId, 'a', draft),
        throwsA(
          isA<AddressFailure>().having(
            (e) => e.uncertain,
            'unknown commit',
            true,
          ),
        ),
      );
    },
  );
  test(
    'ghi lỗi mạng không tự retry; sai user/validation bị chặn trước HTTP',
    () async {
      var calls = 0;
      final client = await backend((request) async {
        calls++;
        throw http.ClientException('offline');
      });
      final repo = SupabaseAddressRepository(client);
      await expectLater(
        repo.create(userId, 'a', draft),
        throwsA(isA<AddressFailure>()),
      );
      expect(calls, 1);
      await expectLater(
        repo.load('other-user'),
        throwsA(isA<AddressFailure>()),
      );
      await expectLater(
        repo.create(
          userId,
          'a',
          const AddressDraft(
            recipientName: '',
            phone: '',
            addressLine: '',
            ward: '',
            district: '',
            city: '',
          ),
        ),
        throwsA(isA<AddressFailure>()),
      );
      expect(calls, 1);
    },
  );
  test('chưa kết nối backend báo lỗi rõ', () async {
    await expectLater(
      const SupabaseAddressRepository(null).load(userId),
      throwsA(isA<AddressFailure>()),
    );
  });
}

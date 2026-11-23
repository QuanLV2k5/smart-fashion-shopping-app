import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_fashion/features/personalization/data/supabase_personalization_repository.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';

import '../ai/supabase_ai_repository_test.dart' show clientFor;

void main() {
  test(
    'writes bind the initiating session and send desired state, not a toggle',
    () async {
      var calls = 0;
      final client = await clientFor((request) async {
        calls++;
        expect(request.url.path, '/rest/v1/rpc/set_favorite');
        expect(request.headers['Authorization'], startsWith('Bearer eyJ'));
        expect(jsonDecode(request.body), {
          'p_product_id': 'p1',
          'p_favorite': true,
        });
        return http.Response('', 204, request: request);
      });
      final repo = SupabasePersonalizationRepository(client);
      await repo.setFavorite('user-a', 'p1', true);
      expect(calls, 1);
      await expectLater(
        repo.setFavorite('user-b', 'p1', true),
        throwsA(isA<PersonalizationFailure>()),
      );
      expect(calls, 1);
    },
  );
  test('a blocked status is represented as blocked, never active', () async {
    final client = await clientFor(
      (request) async => http.Response(
        jsonEncode({'code': 'PT403', 'message': 'SF_ACCESS_BLOCKED'}),
        403,
        request: request,
        headers: {'content-type': 'application/json'},
      ),
    );
    final access = await SupabasePersonalizationRepository(client)
        .access('user-a');
    expect(access.blocked, isTrue);
    expect(access.admin, isFalse);
    expect(access.userId, 'user-a');
  });
  test(
    'missing migration and network errors cannot silently grant access',
    () async {
      final client = await clientFor(
        (request) async => http.Response(
          jsonEncode({'code': 'PGRST202', 'message': 'Not found'}),
          404,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      );
      await expectLater(
        SupabasePersonalizationRepository(client).access('user-a'),
        throwsA(
          isA<PersonalizationFailure>().having(
            (e) => e.code,
            'code',
            'SF_BACKEND_NOT_READY',
          ),
        ),
      );
    },
  );
}

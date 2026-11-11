import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/cart/data/supabase_cart_repository.dart';
import 'package:smart_fashion/features/cart/domain/cart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_domain_test.dart' show cartRow;
import 'cart_fixtures.dart';

void main() {
  test('RPC chỉ gửi variant/quantity/operation/requestId; không nhận user hoặc giá từ client', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'items': [cartRow()],
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = SupabaseCartRepository(client);
    expect((await repository.loadCart()).totalQuantity, 1);
    final result = await repository.mutate(
      const CartMutation(
        variantId: whiteM,
        quantity: 1,
        operation: CartOperation.add,
        requestId: 'request-id',
      ),
    );
    expect(result.subtotalVnd, 199000);
    expect(requests.last.url.path, '/rest/v1/rpc/mutate_cart');
    expect(jsonDecode(requests.last.body), {
      'p_variant_id': whiteM,
      'p_quantity': 1,
      'p_operation': 'add',
      'p_request_id': 'request-id',
    });
  });
  test(
    'lỗi stock có thể hiểu được, server lỗi không tự retry ghi hoặc lộ lỗi thô',
    () async {
      int calls = 0;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(
            '{"code":"XX000","message":"internal private details"}',
            500,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await expectLater(
        SupabaseCartRepository(client).mutate(
          const CartMutation(
            variantId: whiteM,
            quantity: 1,
            operation: CartOperation.add,
            requestId: 'r',
          ),
        ),
        throwsA(
          isA<CartFailure>()
              .having((e) => e.uncertain, 'uncertain', true)
              .having(
                (e) => e.message.contains('private'),
                'no raw error',
                false,
              ),
        ),
      );
      expect(calls, 1);
      expect(
        translateCartFailure(
          const PostgrestException(message: 'SF_STOCK_CHANGED', code: 'P0001'),
        ).refreshProduct,
        isTrue,
      );
    },
  );
}

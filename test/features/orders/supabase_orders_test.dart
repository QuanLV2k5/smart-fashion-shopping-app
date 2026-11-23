import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/orders/data/supabase_checkout_repository.dart';
import 'package:smart_fashion/features/orders/data/supabase_orders_repository.dart';
import 'package:smart_fashion/features/orders/domain/checkout.dart';
import 'package:smart_fashion/features/orders/domain/orders.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'sends only the migration RPC parameters and rejects another session',
    () async {
      const user = 'user-a';
      const placed = {
        'request_id': 'request-a',
        'order_id': 'order-a',
        'order_number': 'SF-000001',
        'currency': 'VND',
        'payment_method': 'cod',
        'subtotal_vnd': 199000,
        'shipping_vnd': 25000,
        'total_vnd': 224000,
      };
      final calls = <String>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'fixture-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          http.Response reply(Object data, [int status = 200]) => http.Response(
            jsonEncode(data),
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
          if (request.url.path == '/auth/v1/token') {
            return reply({
              'access_token': 'fixture-user-token',
              'refresh_token': 'fixture-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': user,
                'aud': 'authenticated',
                'created_at': '2026-11-22T03:00:00Z',
              },
            });
          }
          expect(request.headers['authorization'], 'Bearer fixture-user-token');
          final rpc = request.url.pathSegments.last;
          calls.add(rpc);
          final params = jsonDecode(request.body);
          switch (rpc) {
            case 'place_cod_order':
              expect(params, {
                'p_quote_id': 'quote-a',
                'p_request_id': 'request-a',
              });
              return reply({
                'schema_version': 1,
                'replayed': false,
                'result': placed,
              });
            case 'lookup_order_request':
              expect(params, {'p_request_id': 'request-a'});
              return reply({
                'found': true,
                'operation': 'place_cod_order',
                'result': placed,
              });
            case 'list_admin_orders':
              expect(params, {'p_filter': 'pending', 'p_cursor': null});
              return reply({'items': <Object>[], 'next_cursor': null});
            case 'change_order_status':
              expect(params, {
                'p_order_id': 'order-a',
                'p_target_status': 'confirmed',
                'p_expected_version': 1,
                'p_request_id': 'status-a',
                'p_reason_code': null,
              });
              return reply({
                'code': 'PT409',
                'message': 'SF_ORDER_VERSION_CONFLICT',
              }, 409);
            default:
              fail('Unexpected request $rpc');
          }
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.test',
        password: 'fixture-only',
      );
      final checkout = SupabaseCheckoutRepository(client);
      final orders = SupabaseOrdersRepository(client);
      const request = CheckoutRequest(
        quoteId: 'quote-a',
        requestId: 'request-a',
      );
      await expectLater(
        checkout.place('user-b', request),
        throwsA(
          isA<OrdersFailure>().having(
            (error) => error.code,
            'code',
            'SF_AUTH_REQUIRED',
          ),
        ),
      );
      expect(calls, isEmpty);
      expect((await checkout.place(user, request)).totals.total, 224000);
      expect((await checkout.lookup(user, request))?.id, 'order-a');
      expect(
        (await orders.list(user, 'pending', null, admin: true)).orders,
        isEmpty,
      );
      await expectLater(
        orders.change(
          user,
          const OrderChange(
            orderId: 'order-a',
            target: OrderStatus.confirmed,
            version: 1,
            requestId: 'status-a',
          ),
        ),
        throwsA(
          isA<OrdersFailure>().having(
            (error) => error.code,
            'code',
            'SF_ORDER_VERSION_CONFLICT',
          ),
        ),
      );
      expect(calls, [
        'place_cod_order',
        'lookup_order_request',
        'list_admin_orders',
        'change_order_status',
      ]);
    },
  );
}

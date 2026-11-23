import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_fashion/features/admin/data/supabase_admin_repository.dart';
import 'package:smart_fashion/features/admin/domain/admin_models.dart';

import '../ai/supabase_ai_repository_test.dart' show clientFor;

void main() {
  group('SupabaseAdminRepository.saveVariant & stock concurrency contract', () {
    test('stock update calls RPC set_variant_stock and returns server stock_revision without guessing', () async {
      final requests = <http.Request>[];
      final client = await clientFor((request) async {
        requests.add(request);
        expect(request.url.path, '/rest/v1/rpc/set_variant_stock');
        expect(jsonDecode(request.body), {
          'p_variant_id': 'v-1',
          'p_expected_revision': 2,
          'p_new_stock': 14,
        });
        return http.Response(
          jsonEncode({'variant_id': 'v-1', 'stock': 14, 'stock_revision': 7}),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = SupabaseAdminRepository(client);
      final saved = await repo.saveVariant(
        id: 'v-1',
        productId: 'p-1',
        sku: 'SF01_M',
        size: 'M',
        color: 'Đen',
        stock: 14,
        expectedStockRevision: 2,
        updateMetadata: false,
        updateStock: true,
      );

      expect(requests.length, 1);
      expect(saved.id, 'v-1');
      expect(saved.stock, 14);
      // Phải dùng đúng revision server trả về (7), không tự đoán 2 + 1 = 3
      expect(saved.stockRevision, 7);
    });

    test('metadata-only edit updates sku/size/color without stock column or RPC call', () async {
      final requests = <http.Request>[];
      final client = await clientFor((request) async {
        requests.add(request);
        expect(request.method, 'PATCH');
        expect(request.url.path, '/rest/v1/product_variants');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('stock'), isFalse);
        expect(body, {'sku': 'SF01_M_NEW', 'size': 'M', 'color': 'Xanh'});
        return http.Response('', 204, request: request);
      });

      final repo = SupabaseAdminRepository(client);
      final saved = await repo.saveVariant(
        id: 'v-1',
        productId: 'p-1',
        sku: 'SF01_M_NEW',
        size: 'M',
        color: 'Xanh',
        stock: 14,
        expectedStockRevision: 7,
        updateMetadata: true,
        updateStock: false,
      );

      expect(requests.length, 1);
      expect(saved.sku, 'SF01_M_NEW');
      expect(saved.stock, 14);
      expect(saved.stockRevision, 7);
    });

    test('SF_STOCK_VERSION_CONFLICT throws AdminStockConflictFailure without fallback update', () async {
      var calls = 0;
      final client = await clientFor((request) async {
        calls++;
        expect(request.url.path, '/rest/v1/rpc/set_variant_stock');
        return http.Response(
          jsonEncode({'code': 'PT409', 'message': 'SF_STOCK_VERSION_CONFLICT'}),
          409,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = SupabaseAdminRepository(client);
      await expectLater(
        repo.saveVariant(
          id: 'v-1',
          productId: 'p-1',
          sku: 'SF01_M',
          size: 'M',
          color: 'Đen',
          stock: 20,
          expectedStockRevision: 1,
          updateMetadata: false,
          updateStock: true,
        ),
        throwsA(isA<AdminStockConflictFailure>()),
      );
      expect(calls, 1);
    });

    test('missing set_variant_stock RPC fails closed with AdminFailure and never falls back to direct stock PATCH', () async {
      final paths = <String>[];
      final client = await clientFor((request) async {
        paths.add('${request.method} ${request.url.path}');
        return http.Response(
          jsonEncode({
            'code': '42883',
            'message': 'function public.set_variant_stock does not exist',
          }),
          404,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = SupabaseAdminRepository(client);
      await expectLater(
        repo.saveVariant(
          id: 'v-1',
          productId: 'p-1',
          sku: 'SF01_M',
          size: 'M',
          color: 'Đen',
          stock: 20,
          expectedStockRevision: 0,
          updateMetadata: false,
          updateStock: true,
        ),
        throwsA(
          isA<AdminFailure>().having(
            (e) => e.message,
            'message',
            contains('set_variant_stock'),
          ),
        ),
      );
      expect(paths, ['POST /rest/v1/rpc/set_variant_stock']);
    });

    test(
      'deleteVariant is disabled and never sets stock=0 or mutates database',
      () async {
        var calls = 0;
        final client = await clientFor((request) async {
          calls++;
          return http.Response('', 204, request: request);
        });

        final repo = SupabaseAdminRepository(client);
        await expectLater(
          repo.deleteVariant('v-1', expectedStockRevision: 0),
          throwsA(
            isA<AdminFailure>().having(
              (e) => e.message,
              'message',
              contains('is_visible'),
            ),
          ),
        );
        expect(calls, 0);
      },
    );
  });
}

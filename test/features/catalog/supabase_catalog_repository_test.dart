import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_fashion/features/catalog/data/supabase_catalog_repository.dart';
import 'package:smart_fashion/features/catalog/domain/catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> row() => {
  'id': 'p1',
  'code': 'SF01',
  'category_id': 'c1',
  'name': 'Áo thun',
  'description': '',
  'material': 'Cotton',
  'price_vnd': 199000,
  'image_paths': <String>[],
  'product_variants': [
    {'id': 'v1', 'sku': 'sku1', 'size': 'M', 'color': 'Trắng', 'stock': 0},
  ],
};

void main() {
  test(
    'mapping giữ VND nguyên và hàng hết tồn, không đổi dữ liệu lỗi thành 0',
    () {
      final parsed = productFromJson(row(), imageUrl: (path) => path);
      expect(parsed.priceVnd, 199000);
      expect(parsed.inStock, isFalse);
      expect(parsed.availableSizes, isEmpty);
      for (final invalid in [0, -1, 199000.5, '199000', null]) {
        expect(
          () => productFromJson({
            ...row(),
            'price_vnd': invalid,
          }, imageUrl: (p) => p),
          throwsFormatException,
        );
      }
      final bad = row();
      (bad['product_variants'] as List).first['stock'] = -1;
      expect(
        () => productFromJson(bad, imageUrl: (p) => p),
        throwsFormatException,
      );
    },
  );
  test('không có backend trả lỗi dễ hiểu, không tạo catalog giả', () async {
    await expectLater(
      const SupabaseCatalogRepository(null).loadCatalog(),
      throwsA(isA<CatalogFailure>()),
    );
  });
  test(
    'repository dùng bộ lọc công khai, phân trang và map ảnh HTTPS',
    () async {
      final requests = <Uri>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          final isCategory = request.url.path.endsWith('/categories');
          if (isCategory) {
            return http.Response(
              jsonEncode([
                {'id': 'c1', 'name': 'Áo', 'slug': 'ao'},
              ]),
              200,
              request: request,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          final offset = int.parse(
            request.url.queryParameters['offset'] ?? '0',
          );
          return http.Response(
            jsonEncode(
              offset == 0
                  ? List.generate(
                      200,
                      (i) => {
                        ...row(),
                        'id': 'p$i',
                        'code': 'SF$i',
                        'image_paths': ['https://images.example/item.png'],
                      },
                    )
                  : [row()],
            ),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);
      final catalog = await SupabaseCatalogRepository(client).loadCatalog();
      expect(catalog.categories, hasLength(1));
      expect(catalog.products, hasLength(201));
      expect(
        catalog.products.first.imageUrls.single,
        'https://images.example/item.png',
      );
      expect(
        requests.where((url) => url.path.endsWith('/products')),
        hasLength(2),
      );
      for (final request in requests.where(
        (url) => url.path.endsWith('/products'),
      )) {
        expect(request.queryParameters['is_visible'], 'eq.true');
        expect(request.queryParameters['categories.is_active'], 'eq.true');
        expect(request.queryParameters['order'], 'code.asc.nullslast');
      }
    },
  );
  test('lỗi API không rò nội dung kỹ thuật ra giao diện', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          '{"message":"internal details","code":"42501"}',
          403,
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseCatalogRepository(client).loadCatalog(),
      throwsA(
        isA<CatalogFailure>().having(
          (e) => e.message.contains('internal'),
          'không rò lỗi',
          isFalse,
        ),
      ),
    );
  });
}

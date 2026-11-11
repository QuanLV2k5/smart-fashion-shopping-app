// Chạy riêng với --dart-define-from-file=config/development.local.json.
// Dùng API thật, không chạy trong bộ widget test/CI mặc định.
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/features/catalog/data/supabase_catalog_repository.dart';
import 'package:smart_fashion/features/catalog/domain/catalog_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'SDK đọc catalog cloud và từ chối đọc hồ sơ khi chưa đăng nhập',
    () async {
      final config = AppConfig.fromEnvironment();
      config.validate();
      expect(
        config.useSupabase,
        isTrue,
        reason: 'Chạy test này với config local đã bật Supabase.',
      );
      // Client mới không có phiên đăng nhập: quyền của khách (anon).
      final client = SupabaseClient(
        config.supabaseUrl,
        config.supabasePublishableKey,
      );
      addTearDown(client.dispose);

      final catalog = await SupabaseCatalogRepository(client).loadCatalog();
      expect(catalog.categories, hasLength(5));
      expect(catalog.products, hasLength(12));
      expect(catalog.products.expand((p) => p.variants), hasLength(15));
      expect(queryCatalog(catalog, search: 'ao thun').single.code, 'SF01');
      expect(
        queryCatalog(catalog, filters: const CatalogFilters(size: 'XL')),
        isEmpty,
      );
      expect(
        catalog.products.singleWhere((p) => p.code == 'SF12').inStock,
        isFalse,
      );
      final detail = await SupabaseCatalogRepository(client)
          .loadProduct(catalog.products.first.id);
      expect(detail?.code, 'SF01');
      expect(detail?.variants, hasLength(4));
      for (final request in [
        client.rpc<dynamic>('get_cart'),
        client.rpc<dynamic>(
          'mutate_cart',
          params: {
            'p_variant_id': detail!.variants.first.id,
            'p_quantity': 1,
            'p_operation': 'add',
            'p_request_id': '94000000-0000-0000-0000-000000000001',
          },
        ),
      ]) {
        await expectLater(
          request,
          throwsA(
            isA<PostgrestException>().having(
              (e) => e.code,
              'anon RPC denied',
              '42501',
            ),
          ),
        );
      }

      final products = await client
          .from('products')
          .select('code,price_vnd,product_variants(sku,stock)')
          .inFilter('code', ['SF01', 'SF02'])
          .order('code', ascending: true);

      expect(products.map((product) => product['code']), ['SF01', 'SF02']);
      expect(products[0]['price_vnd'], 199000);
      expect(products[1]['price_vnd'], 249000);
      expect(products[0]['product_variants'], hasLength(4));
      expect(products[1]['product_variants'], hasLength(1));
      await expectLater(
        client.from('profiles').select('id').limit(1),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'SQLSTATE', '42501'),
        ),
      );
    },
  );
}

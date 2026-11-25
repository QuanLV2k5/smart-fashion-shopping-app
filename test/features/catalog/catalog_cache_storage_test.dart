import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fashion/features/catalog/data/catalog_cache_storage.dart';
import 'package:smart_fashion/features/catalog/data/supabase_catalog_repository.dart';
import 'package:smart_fashion/features/catalog/domain/catalog.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/widgets/catalog_widgets.dart';

class FakePreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CatalogSnapshot sampleSnapshot;
  late FakePreferences preferences;

  setUp(() {
    preferences = FakePreferences();
    sampleSnapshot = CatalogSnapshot(
      categories: const [
        CatalogCategory(id: 'c1', name: 'Áo Nam', slug: 'ao-nam'),
      ],
      products: [
        CatalogProduct(
          id: 'p1',
          code: 'SF01',
          categoryId: 'c1',
          name: 'Áo Sơ Mi Linen',
          description: 'Mô tả',
          material: 'Linen',
          priceVnd: 199000,
          imageUrls: ['https://example.com/img.jpg'],
          variants: const [
            ProductVariant(
              id: 'v1',
              sku: 'SF01_M',
              size: 'M',
              color: 'Trắng',
              stock: 10,
            ),
          ],
        ),
      ],
    );
  });

  group('CatalogCacheStorage', () {
    test('saves and loads catalog snapshot correctly', () async {
      final storage = CatalogCacheStorage(preferences);
      await storage.saveCache(sampleSnapshot);

      final loaded = await storage.loadCache();
      expect(loaded, isNotNull);
      expect(loaded!.isFromCache, isTrue);
      expect(loaded.categories.length, 1);
      expect(loaded.categories.first.name, 'Áo Nam');
      expect(loaded.products.length, 1);
      expect(loaded.products.first.name, 'Áo Sơ Mi Linen');
      expect(loaded.products.first.priceVnd, 199000);
      expect(loaded.products.first.variants.length, 1);
    });

    test('returns null when cache is empty', () async {
      final storage = CatalogCacheStorage(preferences);
      final loaded = await storage.loadCache();
      expect(loaded, isNull);
    });

    test('clears cache successfully', () async {
      final storage = CatalogCacheStorage(preferences);
      await storage.saveCache(sampleSnapshot);
      await storage.clearCache();

      final loaded = await storage.loadCache();
      expect(loaded, isNull);
    });

    test('returns null gracefully when cache JSON is corrupted', () async {
      await preferences.setString(
        'smart_fashion_catalog_snapshot_cache',
        '{corrupted json invalid format: true',
      );
      final storage = CatalogCacheStorage(preferences);
      final loaded = await storage.loadCache();
      expect(loaded, isNull);
    });

    test('recovers and overwrites corrupted cache on next save', () async {
      await preferences.setString(
        'smart_fashion_catalog_snapshot_cache',
        'invalid string format',
      );
      final storage = CatalogCacheStorage(preferences);
      await storage.saveCache(sampleSnapshot);

      final loaded = await storage.loadCache();
      expect(loaded, isNotNull);
      expect(loaded!.isFromCache, isTrue);
      expect(loaded.products.first.code, 'SF01');
    });
  });

  group('SupabaseCatalogRepository offline cache fallback', () {
    test('falls back to cache when backend client is null', () async {
      final storage = CatalogCacheStorage(preferences);
      await storage.saveCache(sampleSnapshot);

      final repo = SupabaseCatalogRepository(null, storage);
      final snapshot = await repo.loadCatalog();

      expect(snapshot.isFromCache, isTrue);
      expect(snapshot.products.first.code, 'SF01');
    });

    test('falls back to cache when loading single product offline', () async {
      final storage = CatalogCacheStorage(preferences);
      await storage.saveCache(sampleSnapshot);

      final repo = SupabaseCatalogRepository(null, storage);
      final product = await repo.loadProduct('p1');

      expect(product, isNotNull);
      expect(product!.code, 'SF01');
      expect(product.priceVnd, 199000);
    });

    test(
      'handles corrupted cache offline gracefully by throwing CatalogFailure',
      () async {
        await preferences.setString(
          'smart_fashion_catalog_snapshot_cache',
          '{broken json content}',
        );
        final storage = CatalogCacheStorage(preferences);
        final repo = SupabaseCatalogRepository(null, storage);
        expect(() => repo.loadProduct('p1'), throwsA(isA<CatalogFailure>()));
      },
    );
  });

  group('CatalogBody offline banner widget test', () {
    testWidgets('shows offline banner when catalog is from cache', (
      tester,
    ) async {
      final cachedSnapshot = CatalogSnapshot(
        categories: sampleSnapshot.categories,
        products: sampleSnapshot.products,
        cachedAt: DateTime(2026, 11, 17, 10, 30),
        isFromCache: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogProvider.overrideWith((ref) async => cachedSnapshot),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CatalogBody(
                builder: (snapshot) =>
                    Text('Sản phẩm: ${snapshot.products.length}'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Đang xem dữ liệu ngoại tuyến'),
        findsOneWidget,
      );
      expect(find.text('Sản phẩm: 1'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });
  });
}

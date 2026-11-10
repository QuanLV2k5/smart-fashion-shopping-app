import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/catalog/domain/catalog.dart';
import 'package:smart_fashion/features/catalog/domain/catalog_query.dart';

import 'catalog_fixtures.dart';

void main() {
  test('tìm không dấu, hoa thường, nhiều từ và Unicode tổ hợp', () {
    final catalog = fixtureCatalog();
    for (final query in [
      'ao thun',
      '  ÁO   THUN ',
      'a\u0301o thun',
      'sf01',
      'Cotton essential',
    ]) {
      expect(queryCatalog(catalog, search: query).map((p) => p.code), ['SF01']);
    }
    expect(queryCatalog(catalog, search: 'không tồn tại'), isEmpty);
  });
  test('lọc size/màu phải trùng SKU và còn tồn kho', () {
    final catalog = CatalogSnapshot(
      categories: [],
      products: [
        product(
          variants: [
            variant(size: 'S', color: 'Đen', stock: 2),
            variant(size: 'M', color: 'Trắng', stock: 3),
            variant(size: 'XL', color: 'Đen', stock: 0),
          ],
        ),
      ],
    );
    expect(
      queryCatalog(
        catalog,
        filters: const CatalogFilters(size: 'M', color: 'Đen'),
      ),
      isEmpty,
    );
    expect(
      queryCatalog(catalog, filters: const CatalogFilters(size: 'XL')),
      isEmpty,
    );
    expect(
      queryCatalog(
        catalog,
        filters: const CatalogFilters(size: 'S', color: 'Đen'),
      ),
      hasLength(1),
    );
  });
  test('mặc định giữ hàng hết tồn, chỉ còn hàng loại hàng hết tồn', () {
    expect(queryCatalog(fixtureCatalog()), hasLength(3));
    expect(
      queryCatalog(
        fixtureCatalog(),
        filters: const CatalogFilters(onlyInStock: true),
      ),
      hasLength(2),
    );
  });
  test('khoảng giá không giao nhau, ranh giới 300k và 500k rõ ràng', () {
    expect(PriceRange.under300.includes(300000), isFalse);
    expect(PriceRange.from300to500.includes(300000), isTrue);
    expect(PriceRange.from300to500.includes(500000), isTrue);
    expect(PriceRange.above500.includes(500000), isFalse);
    final result = queryCatalog(
      fixtureCatalog(),
      filters: const CatalogFilters(
        categoryId: 'ao',
        priceRange: PriceRange.under300,
      ),
      sort: CatalogSort.priceAscending,
    );
    expect(result.map((p) => p.code), ['SF12', 'SF01']);
  });
  test('sắp xếp ổn định và collection chỉ chứa mã đã chọn', () {
    final catalog = fixtureCatalog();
    expect(
      queryCatalog(
        catalog,
        sort: CatalogSort.priceDescending,
      ).map((p) => p.code),
      ['SF02', 'SF01', 'SF12'],
    );
    expect(
      queryCatalog(
        catalog,
        collectionCodes: {'SF01', 'SF02'},
      ).map((p) => p.code),
      ['SF01', 'SF02'],
    );
    final equal = CatalogSnapshot(
      categories: [],
      products: [
        product(code: 'SF02'),
        product(code: 'SF01'),
      ],
    );
    expect(
      queryCatalog(equal, sort: CatalogSort.priceAscending).map((p) => p.code),
      ['SF01', 'SF02'],
    );
    expect(equal.products.first.code, 'SF02');
  });
}

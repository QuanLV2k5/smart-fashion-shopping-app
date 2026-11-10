import 'package:smart_fashion/features/catalog/domain/catalog.dart';

CatalogProduct product({
  String code = 'SF01',
  String name = 'Áo thun Essential',
  String category = 'ao',
  int price = 199000,
  List<ProductVariant>? variants,
}) => CatalogProduct(
  id: code,
  code: code,
  categoryId: category,
  name: name,
  description: 'Phom regular, dễ phối hằng ngày.',
  material: 'Cotton',
  priceVnd: price,
  imageUrls: [],
  variants: variants ?? [variant(size: 'M', color: 'Trắng ngà', stock: 3)],
);

ProductVariant variant({
  required String size,
  required String color,
  required int stock,
}) => ProductVariant(
  id: '$size-$color',
  sku: '$size-$color',
  size: size,
  color: color,
  stock: stock,
);

CatalogSnapshot fixtureCatalog() => CatalogSnapshot(
  categories: const [
    CatalogCategory(id: 'ao', name: 'Áo', slug: 'ao'),
    CatalogCategory(id: 'quan', name: 'Quần', slug: 'quan'),
  ],
  products: [
    product(
      variants: [
        variant(size: 'M', color: 'Trắng ngà', stock: 3),
        variant(size: 'XL', color: 'Trắng ngà', stock: 0),
      ],
    ),
    product(
      code: 'SF02',
      name: 'Jeans Straight',
      category: 'quan',
      price: 349000,
    ),
    product(
      code: 'SF12',
      name: 'Mũ Canvas',
      price: 129000,
      variants: [variant(size: 'One size', color: 'Be', stock: 0)],
    ),
  ],
);

class FakeCatalogRepository implements CatalogRepository {
  int calls = 0;
  Future<CatalogSnapshot> Function()? onLoad;
  @override
  Future<CatalogSnapshot> loadCatalog() async {
    calls++;
    return onLoad == null ? fixtureCatalog() : onLoad!();
  }

  @override
  Future<CatalogProduct?> loadProduct(String id) async {
    for (final product in fixtureCatalog().products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

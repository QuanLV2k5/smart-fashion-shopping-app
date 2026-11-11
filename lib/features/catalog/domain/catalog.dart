/// Dữ liệu nghiệp vụ thuần Dart, không phụ thuộc Flutter hay Supabase.
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.slug,
  });
  final String id;
  final String name;
  final String slug;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    required this.stock,
  });
  final String id;
  final String sku;
  final String size;
  final String color;
  final int stock;
}

class CatalogProduct {
  CatalogProduct({
    required this.id,
    required this.code,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.material,
    required this.priceVnd,
    required List<String> imageUrls,
    required List<ProductVariant> variants,
  }) : imageUrls = List.unmodifiable(imageUrls),
       variants = List.unmodifiable(variants);
  final String id;
  final String code;
  final String categoryId;
  final String name;
  final String description;
  final String material;
  final int priceVnd;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  bool get inStock => variants.any((v) => v.stock > 0);
  List<String> get availableSizes =>
      variants.where((v) => v.stock > 0).map((v) => v.size).toSet().toList();
}

class CatalogSnapshot {
  CatalogSnapshot({
    required List<CatalogCategory> categories,
    required List<CatalogProduct> products,
  }) : categories = List.unmodifiable(categories),
       products = List.unmodifiable(products);
  final List<CatalogCategory> categories;
  final List<CatalogProduct> products;
}

abstract interface class CatalogRepository {
  Future<CatalogSnapshot> loadCatalog();
  Future<CatalogProduct?> loadProduct(String id);
}

class CatalogFailure implements Exception {
  const CatalogFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/catalog.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  const SupabaseCatalogRepository(this.client);
  final SupabaseClient? client;

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    final backend = client;
    if (backend == null) {
      throw const CatalogFailure(
        'Cửa hàng chưa kết nối được. Vui lòng thử lại sau.',
      );
    }
    try {
      final results = await Future.wait([
        backend
            .from('categories')
            .select('id,name,slug')
            .eq('is_active', true)
            .order('id', ascending: true),
        _loadProducts(backend),
      ]).timeout(const Duration(seconds: 25));
      final categories = results[0]
          .map(
            (row) => CatalogCategory(
              id: _text(row, 'id'),
              name: _text(row, 'name'),
              slug: _text(row, 'slug'),
            ),
          )
          .toList();
      final categoryIds = categories.map((c) => c.id).toSet();
      final products = results[1]
          .map(
            (row) => productFromJson(
              row,
              imageUrl: (path) => catalogImageUrl(backend, path),
            ),
          )
          .where((p) => categoryIds.contains(p.categoryId))
          .toList();
      return CatalogSnapshot(categories: categories, products: products);
    } on CatalogFailure {
      rethrow;
    } on FormatException {
      throw const CatalogFailure(
        'Thông tin sản phẩm chưa hợp lệ. Vui lòng thử lại sau.',
      );
    } on TimeoutException {
      throw const CatalogFailure(
        'Kết nối mất nhiều thời gian. Kiểm tra mạng rồi thử lại nhé.',
      );
    } on PostgrestException {
      throw const CatalogFailure(
        'Chưa tải được catalog. Vui lòng thử lại sau.',
      );
    } catch (_) {
      throw const CatalogFailure(
        'Không thể kết nối cửa hàng. Kiểm tra mạng rồi thử lại nhé.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadProducts(
    SupabaseClient backend,
  ) async {
    const pageSize = 200;
    final rows = <Map<String, dynamic>>[];
    while (true) {
      final page = await backend
          .from('products')
          .select(
            'id,code,category_id,name,description,material,price_vnd,image_paths,categories!inner(is_active),product_variants(id,sku,size,color,stock)',
          )
          .eq('is_visible', true)
          .eq('categories.is_active', true)
          .order('code', ascending: true)
          .range(rows.length, rows.length + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }

  @override
  Future<CatalogProduct?> loadProduct(String id) async {
    final backend = client;
    if (backend == null) {
      throw const CatalogFailure(
        'Cửa hàng chưa kết nối được. Vui lòng thử lại sau.',
      );
    }
    try {
      final row = await backend
          .from('products')
          .select(
            'id,code,category_id,name,description,material,price_vnd,image_paths,categories!inner(is_active),product_variants(id,sku,size,color,stock)',
          )
          .eq('id', id)
          .eq('is_visible', true)
          .eq('categories.is_active', true)
          .maybeSingle()
          .timeout(const Duration(seconds: 25));
      return row == null
          ? null
          : productFromJson(
              row,
              imageUrl: (path) => catalogImageUrl(backend, path),
            );
    } catch (_) {
      throw const CatalogFailure(
        'Chưa tải được sản phẩm. Kiểm tra kết nối rồi thử lại.',
      );
    }
  }
}

String catalogImageUrl(SupabaseClient backend, String path) {
  final uri = Uri.tryParse(path);
  if (uri == null) throw const FormatException('Invalid image path');
  if (uri.hasScheme) {
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Image must use HTTPS');
    }
    return path;
  }
  if (path.startsWith('/') || path.split('/').contains('..')) {
    throw const FormatException('Invalid storage path');
  }
  return backend.storage.from('product-images').getPublicUrl(path);
}

/// Mapping nằm ở data: API trả sai giá/tồn kho thì báo lỗi, không tự đổi thành 0.
CatalogProduct productFromJson(
  Map<String, dynamic> row, {
  required String Function(String) imageUrl,
}) {
  final images = row['image_paths'];
  final variants = row['product_variants'];
  if (images is! List || variants is! List) {
    throw const FormatException('Invalid lists');
  }
  return CatalogProduct(
    id: _text(row, 'id'),
    code: _text(row, 'code'),
    categoryId: _text(row, 'category_id'),
    name: _text(row, 'name'),
    description: _text(row, 'description', allowEmpty: true),
    material: _text(row, 'material', allowEmpty: true),
    priceVnd: _integer(row, 'price_vnd', minimum: 1),
    imageUrls: images.map((path) {
      if (path is! String || path.trim().isEmpty) {
        throw const FormatException('Invalid image');
      }
      return imageUrl(path);
    }).toList(),
    variants: variants.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid variant');
      }
      return ProductVariant(
        id: _text(value, 'id'),
        sku: _text(value, 'sku'),
        size: _text(value, 'size'),
        color: _text(value, 'color'),
        stock: _integer(value, 'stock', minimum: 0),
      );
    }).toList(),
  );
}

String _text(Map<String, dynamic> row, String key, {bool allowEmpty = false}) {
  final value = row[key];
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

int _integer(Map<String, dynamic> row, String key, {required int minimum}) {
  final value = row[key];
  if (value is! int || value < minimum) throw FormatException('Invalid $key');
  return value;
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/catalog.dart';

/// Bộ lưu trữ bộ nhớ đệm (cache) ngoại tuyến cho Catalog bằng SharedPreferencesAsync.
class CatalogCacheStorage {
  const CatalogCacheStorage([this._prefs]);
  final SharedPreferencesAsync? _prefs;

  static const _cacheKey = 'smart_fashion_catalog_snapshot_cache';

  SharedPreferencesAsync get _effectivePrefs =>
      _prefs ?? SharedPreferencesAsync();

  /// Lưu trữ snapshot catalog vào bộ nhớ bền vững của thiết bị.
  Future<void> saveCache(CatalogSnapshot snapshot) async {
    try {
      final prefs = _effectivePrefs;
      final data = {
        'cached_at': DateTime.now().toIso8601String(),
        'categories': snapshot.categories
            .map((c) => {'id': c.id, 'name': c.name, 'slug': c.slug})
            .toList(),
        'products': snapshot.products.map((p) {
          return {
            'id': p.id,
            'code': p.code,
            'category_id': p.categoryId,
            'name': p.name,
            'description': p.description,
            'material': p.material,
            'price_vnd': p.priceVnd,
            'image_urls': p.imageUrls,
            'variants': p.variants.map((v) {
              return {
                'id': v.id,
                'sku': v.sku,
                'size': v.size,
                'color': v.color,
                'stock': v.stock,
              };
            }).toList(),
          };
        }).toList(),
      };

      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {
      // Bỏ qua lỗi ghi cache nếu bộ nhớ đầy để không chặn luồng hiển thị chính.
    }
  }

  /// Đọc dữ liệu snapshot catalog đã lưu từ trước.
  Future<CatalogSnapshot?> loadCache() async {
    try {
      final prefs = _effectivePrefs;
      final jsonStr = await prefs.getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final cachedAtStr = map['cached_at'] as String?;
      final cachedAt = cachedAtStr != null
          ? DateTime.tryParse(cachedAtStr)
          : null;

      final categoriesList = (map['categories'] as List? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return CatalogCategory(
          id: m['id'] as String,
          name: m['name'] as String,
          slug: m['slug'] as String,
        );
      }).toList();

      final productsList = (map['products'] as List? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        final rawVariants = m['variants'] as List? ?? [];
        final rawImages = m['image_urls'] as List? ?? [];

        final variants = rawVariants.map((v) {
          final vm = v as Map<String, dynamic>;
          return ProductVariant(
            id: vm['id'] as String,
            sku: vm['sku'] as String,
            size: vm['size'] as String,
            color: vm['color'] as String,
            stock: (vm['stock'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        final imageUrls = rawImages.map((e) => e.toString()).toList();

        return CatalogProduct(
          id: m['id'] as String,
          code: m['code'] as String,
          categoryId: m['category_id'] as String,
          name: m['name'] as String,
          description: m['description'] as String? ?? '',
          material: m['material'] as String? ?? '',
          priceVnd: (m['price_vnd'] as num?)?.toInt() ?? 0,
          imageUrls: imageUrls,
          variants: variants,
        );
      }).toList();

      return CatalogSnapshot(
        categories: categoriesList,
        products: productsList,
        cachedAt: cachedAt,
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = _effectivePrefs;
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}

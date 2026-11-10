import 'catalog.dart';

enum CatalogSort {
  recommended('Đề xuất'),
  priceAscending('Giá tăng dần'),
  priceDescending('Giá giảm dần');

  const CatalogSort(this.label);
  final String label;
}

enum PriceRange {
  under300('Dưới 300k'),
  from300to500('300k–500k'),
  above500('Trên 500k');

  const PriceRange(this.label);
  final String label;
  bool includes(int price) => switch (this) {
    under300 => price < 300000,
    from300to500 => price >= 300000 && price <= 500000,
    above500 => price > 500000,
  };
}

class CatalogFilters {
  const CatalogFilters({
    this.categoryId,
    this.priceRange,
    this.size,
    this.color,
    this.onlyInStock = false,
  });
  final String? categoryId;
  final PriceRange? priceRange;
  final String? size;
  final String? color;
  final bool onlyInStock;
  int get count => [
    categoryId,
    priceRange,
    size,
    color,
    if (onlyInStock) true,
  ].where((v) => v != null).length;

  CatalogFilters withCategory(String? id) => CatalogFilters(
    categoryId: id,
    priceRange: priceRange,
    size: size,
    color: color,
    onlyInStock: onlyInStock,
  );
}

/// Catalog nhỏ: tải một lần, tìm/lọc/sắp xếp tại máy, không gọi API mỗi ký tự.
List<CatalogProduct> queryCatalog(
  CatalogSnapshot catalog, {
  String search = '',
  CatalogFilters filters = const CatalogFilters(),
  CatalogSort sort = CatalogSort.recommended,
  Set<String>? collectionCodes,
}) {
  final words = normalizeSearch(search).split(' ').where((w) => w.isNotEmpty);
  final result = catalog.products.where((product) {
    if (collectionCodes != null && !collectionCodes.contains(product.code)) {
      return false;
    }
    if (filters.categoryId != null &&
        product.categoryId != filters.categoryId) {
      return false;
    }
    if (filters.priceRange != null &&
        !filters.priceRange!.includes(product.priceVnd)) {
      return false;
    }
    final text = normalizeSearch(
      '${product.name} ${product.code} ${product.material}',
    );
    if (!words.every(text.contains)) return false;
    // Size và màu phải cùng một biến thể còn hàng, không ghép hai SKU khác nhau.
    if (filters.size != null || filters.color != null || filters.onlyInStock) {
      if (!product.variants.any(
        (v) =>
            v.stock > 0 &&
            (filters.size == null || v.size == filters.size) &&
            (filters.color == null || v.color == filters.color),
      )) {
        return false;
      }
    }
    return true;
  }).toList();
  result.sort((a, b) {
    final byPrice = switch (sort) {
      CatalogSort.recommended => 0,
      CatalogSort.priceAscending => a.priceVnd.compareTo(b.priceVnd),
      CatalogSort.priceDescending => b.priceVnd.compareTo(a.priceVnd),
    };
    return byPrice != 0 ? byPrice : a.code.compareTo(b.code);
  });
  return result;
}

String normalizeSearch(String text) {
  var result = text.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    result = result.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  // Cả Unicode tổ hợp (bàn phím có thể gửi chữ + dấu riêng).
  return result
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

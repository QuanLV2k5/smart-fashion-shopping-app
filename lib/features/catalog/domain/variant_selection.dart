import 'catalog.dart';

/// Hai lựa chọn luôn phải ghép được thành cùng một SKU còn hàng.
class VariantSelection {
  const VariantSelection({this.size, this.color});
  final String? size;
  final String? color;

  VariantSelection chooseSize(CatalogProduct product, String? value) =>
      VariantSelection(
        size: value,
        color:
            value == null ||
                product.variants.any(
                  (v) => v.size == value && v.color == color && v.stock > 0,
                )
            ? color
            : null,
      );
  VariantSelection chooseColor(CatalogProduct product, String? value) =>
      VariantSelection(
        color: value,
        size:
            value == null ||
                product.variants.any(
                  (v) => v.color == value && v.size == size && v.stock > 0,
                )
            ? size
            : null,
      );
  ProductVariant? resolve(CatalogProduct product) {
    for (final variant in product.variants) {
      if (variant.size == size && variant.color == color) return variant;
    }
    return null;
  }
}

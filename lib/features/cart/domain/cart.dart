import '../../catalog/domain/catalog.dart';

abstract final class CartLimits {
  static const maximumQuantity = 99;
}

class CartItem {
  const CartItem({
    required this.variantId,
    required this.quantity,
    required this.product,
  });
  final String variantId;
  final int quantity;

  /// null khi sản phẩm bị ẩn/ngừng bán: không đưa metadata không công khai về app.
  final CatalogProduct? product;
  ProductVariant? get variant => product?.variants.single;
  int get lineTotalVnd => (product?.priceVnd ?? 0) * quantity;
  bool get needsAttention => product == null || variant!.stock < quantity;
  int get maximumQuantity {
    final stock = variant?.stock ?? 0;
    return stock < CartLimits.maximumQuantity
        ? stock
        : CartLimits.maximumQuantity;
  }
}

class CartSnapshot {
  CartSnapshot(List<CartItem> items) : items = List.unmodifiable(items);
  final List<CartItem> items;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotalVnd => items.fold(0, (sum, item) => sum + item.lineTotalVnd);
  bool get needsAttention => items.any((item) => item.needsAttention);
}

enum CartOperation { add, set, remove }

class CartMutation {
  const CartMutation({
    required this.variantId,
    required this.quantity,
    required this.operation,
    required this.requestId,
  });
  final String variantId;
  final int quantity;
  final CartOperation operation;
  final String requestId;
  bool sameAction(String id, int count, CartOperation mode) =>
      variantId == id && quantity == count && operation == mode;
}

abstract interface class CartRepository {
  Future<CartSnapshot> loadCart();
  Future<CartSnapshot> mutate(CartMutation mutation);
}

class CartFailure implements Exception {
  const CartFailure(
    this.message, {
    this.uncertain = false,
    this.refreshProduct = false,
  });
  final String message;

  /// Có thể server đã ghi, nhưng client chưa nhận được phản hồi. Retry cùng requestId.
  final bool uncertain;
  final bool refreshProduct;
  @override
  String toString() => message;
}

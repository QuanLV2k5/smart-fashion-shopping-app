import 'package:supabase_flutter/supabase_flutter.dart';

import '../../catalog/data/supabase_catalog_repository.dart';
import '../domain/cart.dart';

class SupabaseCartRepository implements CartRepository {
  const SupabaseCartRepository(this.client);
  final SupabaseClient? client;

  SupabaseClient get _backend {
    final backend = client;
    if (backend == null) {
      throw const CartFailure(
        'Giỏ hàng chưa kết nối được. Vui lòng thử lại sau.',
      );
    }
    return backend;
  }

  @override
  Future<CartSnapshot> loadCart() async {
    try {
      final data = await _backend
          .rpc<dynamic>('get_cart')
          .timeout(const Duration(seconds: 25));
      return cartFromJson(
        data,
        imageUrl: (path) => catalogImageUrl(_backend, path),
      );
    } catch (error) {
      if (error is CartFailure) rethrow;
      throw const CartFailure(
        'Chưa tải được giỏ hàng. Kiểm tra kết nối rồi thử lại.',
      );
    }
  }

  @override
  Future<CartSnapshot> mutate(CartMutation mutation) async {
    try {
      final data = await _backend
          .rpc<dynamic>(
            'mutate_cart',
            params: {
              'p_variant_id': mutation.variantId,
              'p_quantity': mutation.quantity,
              'p_operation': mutation.operation.name,
              'p_request_id': mutation.requestId,
            },
          )
          .retry(enabled: false)
          .timeout(const Duration(seconds: 25));
      return cartFromJson(
        data,
        imageUrl: (path) => catalogImageUrl(_backend, path),
      );
    } on CartFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw translateCartFailure(error);
    } catch (_) {
      throw const CartFailure(
        'Chưa xác nhận được cập nhật giỏ. Thử lại để kiểm tra yêu cầu trước; số lượng sẽ không bị cộng trùng.',
        uncertain: true,
      );
    }
  }
}

CartFailure translateCartFailure(
  PostgrestException error,
) => switch (error.message) {
  'SF_STOCK_CHANGED' => const CartFailure(
    'Tồn kho vừa thay đổi hoặc số lượng trong giỏ đã đạt giới hạn còn hàng. Vui lòng kiểm tra lại.',
    refreshProduct: true,
  ),
  'SF_PRODUCT_UNAVAILABLE' => const CartFailure(
    'Sản phẩm này hiện đã ngừng bán. Bạn hãy chọn món khác nhé.',
    refreshProduct: true,
  ),
  'SF_INVALID_QUANTITY' || 'SF_CART_LIMIT' => const CartFailure(
    'Số lượng cần từ 1 đến 99 và không vượt tồn kho.',
  ),
  'SF_AUTH_REQUIRED' => const CartFailure('Bạn cần đăng nhập để lưu giỏ hàng.'),
  'SF_REQUEST_CONFLICT' => const CartFailure(
    'Yêu cầu cập nhật chưa hợp lệ. Vui lòng tải lại giỏ.',
  ),
  _ =>
    error.code == 'PGRST202' || error.code == '42883'
        ? const CartFailure('Giỏ hàng chưa kết nối được. Vui lòng thử lại sau.')
        : const CartFailure(
            'Chưa xác nhận được cập nhật giỏ. Thử lại để kiểm tra yêu cầu trước; số lượng sẽ không bị cộng trùng.',
            uncertain: true,
          ),
};

CartSnapshot cartFromJson(
  dynamic data, {
  required String Function(String) imageUrl,
}) {
  if (data is! Map<String, dynamic> || data['items'] is! List) {
    throw const FormatException('Invalid cart');
  }
  final ids = <String>{};
  final items = (data['items'] as List).map((row) {
    if (row is! Map<String, dynamic>) {
      throw const FormatException('Invalid item');
    }
    final id = row['variant_id'];
    final quantity = row['quantity'];
    if (id is! String ||
        id.isEmpty ||
        !ids.add(id) ||
        quantity is! int ||
        quantity < 1 ||
        quantity > CartLimits.maximumQuantity) {
      throw const FormatException('Invalid quantity/variant');
    }
    final rawProduct = row['product'];
    if (rawProduct != null && rawProduct is! Map<String, dynamic>) {
      throw const FormatException('Invalid product');
    }
    final product = rawProduct == null
        ? null
        : productFromJson(
            rawProduct as Map<String, dynamic>,
            imageUrl: imageUrl,
          );
    if (product != null &&
        (product.variants.length != 1 || product.variants.single.id != id)) {
      throw const FormatException('Mismatched variant');
    }
    return CartItem(variantId: id, quantity: quantity, product: product);
  }).toList();
  return CartSnapshot(items);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/supabase_cart_repository.dart';
import '../domain/cart.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => SupabaseCartRepository(ref.watch(supabaseClientProvider)),
);
final currentCartUserIdProvider = Provider<String?>(
  (ref) =>
      (ref.watch(authSessionProvider).value ??
              ref.watch(authRepositoryProvider).currentUser)
          ?.id,
);

/// Mỗi tài khoản có state riêng. UI chỉ đọc family của tài khoản đang đăng nhập.
final cartProvider =
    AsyncNotifierProvider.family<CartController, CartSnapshot, String>(
      CartController.new,
      retry: (_, _) => null,
    );

class CartController extends AsyncNotifier<CartSnapshot> {
  CartController(this.userId);
  final String userId;
  @override
  Future<CartSnapshot> build() async {
    if (ref.watch(currentCartUserIdProvider) != userId) return CartSnapshot([]);
    return ref.watch(cartRepositoryProvider).loadCart();
  }

  void replace(CartSnapshot cart) {
    if (ref.read(currentCartUserIdProvider) == userId) state = AsyncData(cart);
  }
}

class CartActionState {
  const CartActionState({this.isUpdating = false, this.failure});
  final bool isUpdating;
  final CartFailure? failure;
}

/// Ghi tách khỏi đọc: lỗi ghi không xóa dữ liệu giỏ đang hiển thị.
final cartActionsProvider =
    NotifierProvider.family<CartActions, CartActionState, String>(
      CartActions.new,
    );

class CartActions extends Notifier<CartActionState> {
  CartActions(this.userId);
  final String userId;
  CartMutation? _pending;
  bool _writing = false;
  int _sessionRevision = 0;
  @override
  CartActionState build() {
    ref.watch(currentCartUserIdProvider);
    _sessionRevision++;
    _pending = null;
    return const CartActionState();
  }

  Future<bool> change(
    String variantId,
    int quantity,
    CartOperation operation,
  ) async {
    if (_writing ||
        ref.read(cartProvider(userId)).isLoading ||
        ref.read(currentCartUserIdProvider) != userId) {
      return false;
    }
    if (_pending != null &&
        !_pending!.sameAction(variantId, quantity, operation)) {
      state = const CartActionState(
        failure: CartFailure(
          'Vui lòng vào giỏ và bấm Thử lại để xác nhận lần cập nhật trước rồi tiếp tục.',
          uncertain: true,
        ),
      );
      return false;
    }
    final revision = _sessionRevision;
    final mutation =
        _pending?.sameAction(variantId, quantity, operation) == true
        ? _pending!
        : CartMutation(
            variantId: variantId,
            quantity: quantity,
            operation: operation,
            requestId: const Uuid().v4(),
          );
    _pending = mutation;
    _writing = true;
    state = const CartActionState(isUpdating: true);
    try {
      final cart = await ref.read(cartRepositoryProvider).mutate(mutation);
      if (!ref.mounted ||
          revision != _sessionRevision ||
          ref.read(currentCartUserIdProvider) != userId) {
        return false;
      }
      _pending = null;
      ref.read(cartProvider(userId).notifier).replace(cart);
      state = const CartActionState();
      return true;
    } catch (error) {
      if (ref.mounted &&
          revision == _sessionRevision &&
          ref.read(currentCartUserIdProvider) == userId) {
        final failure = error is CartFailure
            ? error
            : const CartFailure(
                'Chưa xác nhận được cập nhật giỏ. Vui lòng thử lại.',
                uncertain: true,
              );
        if (!failure.uncertain) _pending = null;
        state = CartActionState(failure: failure);
      }
      return false;
    } finally {
      _writing = false;
    }
  }

  Future<bool> retryPending() async {
    final pending = _pending;
    if (pending == null) return false;
    return change(pending.variantId, pending.quantity, pending.operation);
  }

  bool get hasPending => _pending != null;
}

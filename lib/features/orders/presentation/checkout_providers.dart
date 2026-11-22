import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_provider.dart';
import '../../../core/storage/preferences_provider.dart';
import '../../addresses/presentation/address_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../data/supabase_checkout_repository.dart';
import '../domain/checkout.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => SupabaseCheckoutRepository(ref.watch(supabaseClientProvider)),
);

final checkoutRequestStoreProvider = Provider<CheckoutRequestStore>(
  (ref) => PreferencesCheckoutRequestStore(ref.watch(preferencesProvider)),
);

final checkoutProvider =
    AsyncNotifierProvider.family<CheckoutController, CheckoutState, String>(
      CheckoutController.new,
      retry: (_, _) => null,
    );

class CheckoutState {
  const CheckoutState({
    this.quote,
    this.pending,
    this.placed,
    this.busy = false,
    this.message,
  });

  final CheckoutQuote? quote;
  final CheckoutRequest? pending;
  final PlacedOrder? placed;
  final bool busy;
  final String? message;
}

const _uncertain =
    'Chưa xác nhận được kết quả đặt hàng. Kiểm tra kết nối rồi kiểm tra lại yêu cầu này.';

class CheckoutController extends AsyncNotifier<CheckoutState> {
  CheckoutController(this.userId);

  final String userId;
  int _generation = 0;
  bool _working = false;

  @override
  Future<CheckoutState> build() async {
    _generation++;
    if (ref.watch(authenticatedUserIdProvider) != userId)
      return const CheckoutState();
    final pending = await ref.watch(checkoutRequestStoreProvider).read(userId);
    return CheckoutState(
      pending: pending,
      message: pending == null ? null : _uncertain,
    );
  }

  bool _active(int generation) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(authenticatedUserIdProvider) == userId;

  bool get _cartReady {
    final cart = ref.read(cartProvider(userId));
    final actions = ref.read(cartActionsProvider(userId));
    return !cart.isLoading &&
        !cart.hasError &&
        cart.value?.items.isNotEmpty == true &&
        !actions.isUpdating &&
        !ref.read(cartActionsProvider(userId).notifier).hasPending;
  }

  Future<void> loadQuote() async {
    final current = state.asData?.value;
    final generation = _generation;
    if (!_active(generation) ||
        _working ||
        current == null ||
        current.pending != null)
      return;
    final address = ref.read(addressBookProvider).asData?.value.selected;
    if (address == null || !_cartReady) {
      state = const AsyncData(
        CheckoutState(
          message: 'Vui lòng kiểm tra giỏ hàng và chọn địa chỉ giao hàng.',
        ),
      );
      return;
    }
    _working = true;
    state = const AsyncData(CheckoutState(busy: true));
    try {
      final quote = await ref
          .read(checkoutRepositoryProvider)
          .quote(userId, address.id);
      if (_active(generation)) state = AsyncData(CheckoutState(quote: quote));
    } catch (error) {
      if (_active(generation))
        state = AsyncData(CheckoutState(message: _message(error)));
    } finally {
      _working = false;
    }
  }

  Future<void> place() async {
    final current = state.asData?.value;
    final quote = current?.quote;
    final generation = _generation;
    if (!_active(generation) ||
        _working ||
        current?.pending != null ||
        quote == null)
      return;
    if (!quote.expiresAt.isAfter(DateTime.now())) {
      state = AsyncData(
        CheckoutState(message: const OrdersFailure('SF_QUOTE_EXPIRED').message),
      );
      return;
    }
    if (!_cartReady ||
        ref.read(addressBookProvider).asData?.value.selected?.id !=
            quote.addressId) {
      state = const AsyncData(
        CheckoutState(
          message: 'Giỏ hoặc địa chỉ đã thay đổi. Vui lòng lấy báo giá mới.',
        ),
      );
      return;
    }
    final store = ref.read(checkoutRequestStoreProvider);
    final request = CheckoutRequest(
      quoteId: quote.id,
      requestId: const Uuid().v4(),
    );
    _working = true;
    state = AsyncData(CheckoutState(quote: quote, busy: true));
    try {
      final saved = await store.read(userId);
      if (!_active(generation)) return;
      if (saved != null) {
        state = AsyncData(CheckoutState(pending: saved, message: _uncertain));
        return;
      }
      await store.save(userId, request);
      if (_active(generation))
        await _submit(request, generation, recover: false);
    } catch (_) {
      if (_active(generation)) {
        state = AsyncData(
          CheckoutState(
            quote: quote,
            message: 'Không lưu được yêu cầu. Chưa gửi lệnh đặt hàng.',
          ),
        );
      }
    } finally {
      _working = false;
    }
  }

  Future<void> recover() async {
    final request = state.asData?.value.pending;
    final generation = _generation;
    if (!_active(generation) || _working || request == null) return;
    _working = true;
    try {
      await _submit(request, generation, recover: true);
    } finally {
      _working = false;
    }
  }

  Future<void> _submit(
    CheckoutRequest request,
    int generation, {
    required bool recover,
  }) async {
    final store = ref.read(checkoutRequestStoreProvider);
    final repository = ref.read(checkoutRepositoryProvider);
    state = AsyncData(CheckoutState(pending: request, busy: true));
    PlacedOrder? placed;
    if (recover) {
      try {
        placed = await repository.lookup(userId, request);
      } catch (_) {
        if (_active(generation))
          state = AsyncData(
            CheckoutState(pending: request, message: _uncertain),
          );
        return;
      }
    }
    if (!_active(generation)) return;
    try {
      placed ??= await repository.place(userId, request);
    } catch (error) {
      if (!_active(generation)) return;
      if (error is OrdersFailure &&
          error.placeRejected &&
          await _clear(store)) {
        if (_active(generation)) {
          ref.invalidate(cartProvider(userId));
          state = AsyncData(CheckoutState(message: error.message));
        }
      } else if (_active(generation)) {
        state = AsyncData(CheckoutState(pending: request, message: _uncertain));
      }
      return;
    }
    if (!_active(generation)) return;
    final cleared = await _clear(store);
    if (!_active(generation)) return;
    ref.invalidate(cartProvider(userId));
    state = AsyncData(
      CheckoutState(
        placed: placed,
        message: cleared ? null : 'Đơn đã được đặt. Thiết bị có thể cần kiểm tra lại biên nhận khi mở thanh toán.',
      ),
    );
  }

  Future<bool> _clear(CheckoutRequestStore store) async {
    try {
      await store.clear(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dismissConfirmation() {
    if (state.asData?.value.placed != null) {
      ref.invalidateSelf();
    }
  }

  String _message(Object error) => error is OrdersFailure
      ? error.message
      : const OrdersFailure('NETWORK').message;
}

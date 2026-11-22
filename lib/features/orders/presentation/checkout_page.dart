import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/services/supabase_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../addresses/presentation/address_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../catalog/data/supabase_catalog_repository.dart';
import '../domain/checkout.dart';
import 'checkout_providers.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authenticatedUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    return _Checkout(userId, key: ValueKey(userId));
  }
}

class _Checkout extends ConsumerWidget {
  const _Checkout(this.userId, {super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = checkoutProvider(userId);
    final value = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final checkout = value.asData?.value;
    final address = ref.watch(addressBookProvider).asData?.value.selected;
    final cart = ref.watch(cartProvider(userId));
    final cartAction = ref.watch(cartActionsProvider(userId));
    final cartReady =
        !cart.isLoading &&
        !cart.hasError &&
        cart.value?.items.isNotEmpty == true &&
        !cartAction.isUpdating &&
        !ref.read(cartActionsProvider(userId).notifier).hasPending;
    final quote = checkout?.quote?.addressId == address?.id
        ? checkout?.quote
        : null;
    final placed = checkout?.placed;

    void back() {
      controller.dismissConfirmation();
      context.canPop() ? context.pop() : context.go('/cart');
    }

    final VoidCallback? action;
    final String label;
    if (placed != null) {
      label = 'Tiếp tục mua sắm';
      action = () {
        controller.dismissConfirmation();
        context.go('/explore');
      };
    } else if (checkout?.pending != null) {
      label = 'Kiểm tra lại đơn hàng';
      action = controller.recover;
    } else if (value.hasError) {
      label = 'Thử đọc lại yêu cầu';
      action = () => ref.invalidate(provider);
    } else if (quote != null) {
      label = 'Đặt hàng COD · ${formatVnd(quote.totals.total)}';
      action = cartReady ? controller.place : null;
    } else {
      label = 'Lấy báo giá';
      action = cartReady && address != null ? controller.loadQuote : null;
    }

    return ShopPageScaffold(
      title: placed == null ? 'Xác nhận & thanh toán' : 'Đã đặt hàng',
      onBack: back,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (value.isLoading || checkout?.busy == true)
            const LinearProgressIndicator(),
          if (value.hasError)
            const ShopNotice(
              'Không đọc được yêu cầu đã lưu. Vui lòng thử lại trước khi đặt hàng.',
              error: true,
            ),
          if (checkout?.message case final message?)
            ShopNotice(message, error: placed == null),
          if (placed != null) ...[
            const ShopNotice('Đơn COD của bạn đã được ghi nhận.'),
            ListTile(
              title: Text(placed.number),
              subtitle: Text(formatVnd(placed.totals.total)),
            ),
          ] else if (checkout?.pending == null && !value.hasError) ...[
            if (quote != null)
              ShopNotice(
                '${quote.delivery.name} · ${quote.delivery.phone}\n${quote.delivery.address}',
              )
            else
              OutlinedButton(
                onPressed: checkout?.busy == true
                    ? null
                    : () => context.push('/addresses/select'),
                child: Text(
                  address == null
                      ? 'Chọn địa chỉ giao hàng'
                      : 'Giao tới ${address.details.recipientName}',
                ),
              ),
            if (!cartReady)
              const ShopNotice('Kiểm tra lại giỏ trước khi đặt hàng.'),
            if (quote != null) ...[
              for (final line in quote.lines) OrderLineTile(line),
              Text(
                'Thanh toán khi nhận hàng',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const ShopNotice('COD · Kiểm tra đơn trước khi xác nhận.'),
              OrderTotalsView(quote.totals),
            ],
          ],
        ],
      ),
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: value.isLoading || checkout?.busy == true ? null : action,
          child: Text(label),
        ),
      ),
    );
  }
}

class OrderLineTile extends ConsumerWidget {
  const OrderLineTile(this.line, {super.key});
  final OrderLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final image = client == null || line.imagePaths.isEmpty
        ? null
        : catalogImageUrl(client, line.imagePaths.first);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: image == null
          ? const Icon(Icons.checkroom_outlined)
          : SizedBox(
              width: 52,
              height: 52,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.checkroom_outlined),
              ),
            ),
      title: Text(line.name),
      subtitle: Text(
        '${line.color} · ${line.size} · SL ${line.quantity}\n${formatVnd(line.total)}',
      ),
    );
  }
}

class OrderTotalsView extends StatelessWidget {
  const OrderTotalsView(this.totals, {super.key});
  final OrderTotals totals;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Tiền sản phẩm'),
        subtitle: Text(formatVnd(totals.subtotal)),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Phí giao hàng'),
        subtitle: Text(formatVnd(totals.shipping)),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Tổng thanh toán'),
        subtitle: Text(formatVnd(totals.total)),
      ),
    ],
  );
}

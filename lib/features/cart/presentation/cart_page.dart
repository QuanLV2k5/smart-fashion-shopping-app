import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../domain/cart.dart';
import 'cart_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentCartUserIdProvider);
    void back() => context.canPop() ? context.pop() : context.go('/explore');
    if (userId == null) {
      return ShopPageScaffold(
        title: 'Giỏ hàng',
        onBack: back,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CatalogMessage(
            title: 'Giỏ hàng dành riêng cho bạn',
            message:
                'Đăng nhập để lưu giỏ và xem lại trên các thiết bị của bạn.',
            action: 'Đăng nhập',
            onAction: () => context.push('/login?next=%2Fcart'),
          ),
        ),
        footer: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/explore'),
            child: const Text('Khám phá sản phẩm'),
          ),
        ),
      );
    }
    final state = ref.watch(cartProvider(userId));
    final cart = state.value;
    final actions = ref.watch(cartActionsProvider(userId));
    final controller = ref.read(cartActionsProvider(userId).notifier);
    final busy = state.isLoading || actions.isUpdating;
    Future<void> reload() async {
      if (busy) return;
      if (controller.hasPending) {
        await controller.retryPending();
        return;
      }
      ref.invalidate(cartProvider(userId));
      try {
        await ref.read(cartProvider(userId).future);
      } catch (_) {
        /* Lỗi hiển thị qua AsyncValue. */
      }
    }

    Widget body;
    if (state.isLoading && cart == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: reload,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (busy) const LinearProgressIndicator(minHeight: 2),
              if (state.hasError || actions.failure != null)
                CatalogMessage(
                  title: 'Giỏ hàng chưa cập nhật',
                  message: actions.failure?.message ?? state.error.toString(),
                  error: true,
                  action: 'Thử lại',
                  onAction: busy ? null : reload,
                ),
              if (cart != null && cart.items.isEmpty)
                CatalogMessage(
                  title: 'Chưa có món nào trong giỏ',
                  message: 'Khám phá một vài món bạn muốn mặc hôm nay.',
                  action: 'Khám phá sản phẩm',
                  onAction: () => context.go('/explore'),
                ),
              if (cart != null && cart.items.isNotEmpty) ...[
                Text(
                  '${cart.totalQuantity} món trong giỏ',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (cart.needsAttention)
                  const ShopNotice(
                    'Một số món đã ngừng bán hoặc không còn đủ số lượng. Bạn hãy điều chỉnh hoặc xóa món đó nhé.',
                    error: true,
                  ),
                ...cart.items.map(
                  (item) => _CartLine(
                    item: item,
                    busy: busy,
                    onChange: (quantity) => controller.change(
                      item.variantId,
                      quantity,
                      CartOperation.set,
                    ),
                    onRemove: () => controller.change(
                      item.variantId,
                      0,
                      CartOperation.remove,
                    ),
                  ),
                ),
                Text(
                  'Tiền sản phẩm: ${formatVnd(cart.subtotalVnd)}',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppColors.primary),
                ),
                Text(
                  cart.items.any((item) => item.product == null)
                      ? 'Tạm tính các món đang bán. Món ngừng bán không được tính.'
                      : 'Phí giao hàng được tính ở bước thanh toán.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ShopPageScaffold(
      title: 'Giỏ hàng',
      onBack: back,
      body: body,
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => context.go('/explore'),
          child: const Text('Tiếp tục mua sắm'),
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.busy,
    required this.onChange,
    required this.onRemove,
  });
  final CartItem item;
  final bool busy;
  final ValueChanged<int> onChange;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final variant = item.variant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        InkWell(
          onTap: product == null
              ? null
              : () => context.push(
                  '/products/${product.id}?variant=${item.variantId}',
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 88,
                child: product == null
                    ? const ColoredBox(
                        color: AppColors.sage,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.muted,
                        ),
                      )
                    : ProductPhoto(product: product),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      product?.name ?? 'Sản phẩm đã ngừng bán',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      variant == null
                          ? 'Vui lòng xóa món này khỏi giỏ.'
                          : '${variant.color} · ${variant.size} · SL ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                    if (product != null)
                      Text(
                        formatVnd(item.lineTotalVnd),
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.primary),
                      ),
                    if (product != null && item.needsAttention)
                      Text(
                        'Hiện còn ${variant!.stock} sản phẩm',
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Giảm số lượng ${product?.name ?? ''}',
                    onPressed:
                        busy || item.quantity <= 1 || item.maximumQuantity <= 0
                        ? null
                        : () => onChange(
                            math.max(
                              1,
                              math.min(item.quantity - 1, item.maximumQuantity),
                            ),
                          ),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Semantics(
                    label: 'Số lượng ${item.quantity}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tăng số lượng ${product?.name ?? ''}',
                    onPressed: busy || item.quantity >= item.maximumQuantity
                        ? null
                        : () => onChange(item.quantity + 1),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: busy ? null : onRemove,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sage,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(100, 48),
              ),
              child: const Text('Xóa'),
            ),
          ],
        ),
        const Divider(height: AppSpacing.md),
      ],
    );
  }
}

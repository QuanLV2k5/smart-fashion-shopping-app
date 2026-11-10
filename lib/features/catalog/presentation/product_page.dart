import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../domain/catalog.dart';
import '../domain/variant_selection.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_widgets.dart';
import 'widgets/product_gallery.dart';
import 'widgets/product_size_guide.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({
    required this.productId,
    this.initialVariantId,
    super.key,
  });
  final String productId;
  final String? initialVariantId;
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  VariantSelection selection = const VariantSelection();
  final selectionKey = GlobalKey();
  final cartErrorKey = GlobalKey();
  bool initialized = false;
  bool selectionError = false;
  bool showCartError = false;

  Future<void> add(CatalogProduct product) async {
    final variant = selection.resolve(product);
    if (variant == null) {
      setState(() => selectionError = true);
      final target = selectionKey.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
          alignment: .1,
        );
      }
      return;
    }
    if (variant.stock <= 0) return;
    final userId = ref.read(currentCartUserIdProvider);
    if (userId == null) {
      final next = Uri(
        path: '/products/${product.id}',
        queryParameters: {'variant': variant.id},
      ).toString();
      context.push('/login?next=${Uri.encodeComponent(next)}');
      return;
    }
    final success = await ref
        .read(cartActionsProvider(userId).notifier)
        .change(variant.id, 1, CartOperation.add);
    if (!mounted || ref.read(currentCartUserIdProvider) != userId) return;
    if (!success) {
      setState(() => showCartError = true);
      final error = ref.read(cartActionsProvider(userId)).failure;
      if (error is CartFailure && error.refreshProduct) {
        ref.invalidate(productProvider(widget.productId));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = cartErrorKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 200),
            alignment: .5,
          );
        }
      });
      return;
    }
    setState(() => showCartError = false);
    final cart = ref.read(cartProvider(userId)).value!;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.ivory,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đã thêm vào giỏ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng thông báo',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              ShopNotice(
                '${product.name} · ${variant.color} / ${variant.size} · +1',
              ),
              Text(
                'Giỏ hiện có ${cart.totalQuantity} món · ${formatVnd(cart.subtotalVnd)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/cart');
                },
                child: const Text('Xem giỏ hàng'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Tiếp tục xem sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider(widget.productId));
    final product = state.value;
    final userId = ref.watch(currentCartUserIdProvider);
    final cartState = userId == null ? null : ref.watch(cartProvider(userId));
    final cartAction = userId == null
        ? null
        : ref.watch(cartActionsProvider(userId));
    Widget body;
    Widget? footer;
    if (state.isLoading && product == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.hasError && product == null) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CatalogMessage(
          title: 'Chưa tải được sản phẩm',
          message: 'Kiểm tra kết nối rồi thử lại.',
          error: true,
          action: 'Thử tải lại',
          onAction: () => ref.invalidate(productProvider(widget.productId)),
        ),
      );
    } else if (product == null) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CatalogMessage(
          title: 'Sản phẩm không còn được bán',
          message: 'Khám phá những lựa chọn khác trong cửa hàng nhé.',
          action: 'Khám phá sản phẩm',
          onAction: () => context.go('/explore'),
        ),
      );
    } else {
      if (!initialized) {
        initialized = true;
        for (final variant in product.variants) {
          if (variant.id == widget.initialVariantId && variant.stock > 0) {
            selection = VariantSelection(
              size: variant.size,
              color: variant.color,
            );
          }
        }
      }
      final selected = selection.resolve(product);
      final busy =
          cartState?.isLoading == true ||
          cartAction?.isUpdating == true ||
          state.isLoading;
      var alreadyInCart = 0;
      for (final item in cartState?.value?.items ?? <CartItem>[]) {
        if (item.variantId == selected?.id) alreadyInCart = item.quantity;
      }
      final limitReached =
          selected != null &&
          selected.stock > 0 &&
          alreadyInCart >= math.min(selected.stock, CartLimits.maximumQuantity);
      final sizes = product.variants.map((v) => v.size).toSet();
      final colors = product.variants.map((v) => v.color).toSet();
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productProvider(widget.productId));
          try {
            await ref.read(productProvider(widget.productId).future);
          } catch (_) {
            /* AsyncValue hiển thị lỗi. */
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (state.hasError)
                CatalogMessage(
                  title: 'Chưa cập nhật được sản phẩm',
                  message: 'Tải lại để kiểm tra giá và tồn kho mới nhất.',
                  action: 'Tải lại sản phẩm',
                  onAction: () =>
                      ref.invalidate(productProvider(widget.productId)),
                  error: true,
                ),
              if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
              ProductGallery(key: ValueKey(product.id), product: product),
              Text(
                product.code,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                formatVnd(product.priceVnd),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              if (product.description.isNotEmpty)
                Text(
                  product.description,
                  style: const TextStyle(color: AppColors.muted),
                ),
              Row(
                key: selectionKey,
                children: [
                  Expanded(
                    child: Text(
                      'Kích thước',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (const {'SF01', 'SF02'}.contains(product.code))
                    TextButton(
                      onPressed: () => showProductSizeGuide(context),
                      child: const Text('Bảng size'),
                    ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: sizes.map((size) {
                  final available = product.variants.any(
                    (v) => v.size == size && v.stock > 0,
                  );
                  return _VariantOption(
                    key: ValueKey('size-$size'),
                    label: size,
                    selected: selection.size == size,
                    available: available,
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            selection = selection.chooseSize(
                              product,
                              selection.size == size ? null : size,
                            );
                            selectionError = false;
                            showCartError = false;
                          }),
                  );
                }).toList(),
              ),
              Text(
                'Màu sắc · ${selection.color ?? 'Chưa chọn'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: colors.map((color) {
                  final available = product.variants.any(
                    (v) => v.color == color && v.stock > 0,
                  );
                  return _VariantOption(
                    key: ValueKey('color-$color'),
                    label: color,
                    selected: selection.color == color,
                    available: available,
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            selection = selection.chooseColor(
                              product,
                              selection.color == color ? null : color,
                            );
                            selectionError = false;
                            showCartError = false;
                          }),
                  );
                }).toList(),
              ),
              if (selectionError)
                const ShopNotice(
                  'Bạn hãy chọn đủ kích thước và màu sắc trước khi thêm giỏ.',
                  error: true,
                ),
              if (!product.inStock)
                const ShopNotice('Sản phẩm hiện đã hết hàng.', error: true)
              else if (selected != null)
                ShopNotice(
                  selected.stock > 0
                      ? 'Còn ${selected.stock} sản phẩm · ${selected.color} / ${selected.size}${alreadyInCart > 0 ? '\nĐã có $alreadyInCart trong giỏ của bạn.' : ''}'
                      : 'Biến thể vừa hết hàng. Vui lòng chọn lại.',
                  error: selected.stock <= 0,
                )
              else
                const Text(
                  'Chọn đủ size và màu để xem tồn kho.',
                  style: TextStyle(color: AppColors.muted),
                ),
              if (showCartError && cartAction?.failure != null)
                ShopNotice(
                  cartAction!.failure!.message,
                  key: cartErrorKey,
                  error: true,
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: const Text('Mô tả & chất liệu'),
                  childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${product.description}\n\nChất liệu: ${product.material.isEmpty ? 'Đang cập nhật' : product.material}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      final label = busy
          ? 'Đang kiểm tra giỏ…'
          : !product.inStock
          ? 'Tạm hết hàng'
          : state.hasError
          ? 'Cần tải lại sản phẩm'
          : selected == null
          ? 'Chọn size và màu'
          : selected.stock <= 0
          ? 'Biến thể đã hết hàng'
          : limitReached
          ? 'Đã đủ số lượng còn hàng trong giỏ'
          : 'Thêm vào giỏ · ${formatVnd(product.priceVnd)}';
      footer = SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed:
              busy ||
                  !product.inStock ||
                  state.hasError ||
                  limitReached ||
                  selected?.stock == 0
              ? null
              : () => add(product),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
    }
    return ShopPageScaffold(
      title: 'Chi tiết sản phẩm',
      onBack: () => context.canPop() ? context.pop() : context.go('/explore'),
      trailing: const CartButton(),
      body: body,
      footer: footer,
    );
  }
}

class _VariantOption extends StatelessWidget {
  const _VariantOption({
    required this.label,
    required this.selected,
    required this.available,
    required this.onPressed,
    super.key,
  });
  final String label;
  final bool selected;
  final bool available;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Tooltip(
      message: available ? label : '$label · Hết hàng',
      child: FilledButton(
        onPressed: available ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(52, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          backgroundColor: selected ? AppColors.primary : AppColors.white,
          foregroundColor: selected ? AppColors.white : AppColors.ink,
          disabledBackgroundColor: AppColors.white,
          disabledForegroundColor: AppColors.disabled,
        ),
        child: Text(available ? label : '$label ×'),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/money.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/catalog.dart';
import '../catalog_providers.dart';

class CatalogBody extends ConsumerWidget {
  const CatalogBody({required this.builder, super.key});
  final Widget Function(CatalogSnapshot) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProvider);
    final catalog = state.value;
    if (catalog != null) {
      return Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CatalogMessage(
                title: 'Chưa cập nhật được sản phẩm',
                message: 'Đang hiển thị dữ liệu đã tải trong phiên này.',
                action: 'Thử lại',
                onAction: () => ref.invalidate(catalogProvider),
                error: true,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(catalogProvider);
                try {
                  await ref.read(catalogProvider.future);
                } catch (_) {
                  /* Lỗi được hiển thị qua AsyncValue. */
                }
              },
              child: builder(catalog),
            ),
          ),
        ],
      );
    }
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            CircularProgressIndicator(),
            Text('Đang tìm những món dành cho bạn…'),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: CatalogMessage(
        title: 'Chưa tải được catalog',
        message: state.error is CatalogFailure
            ? (state.error! as CatalogFailure).message
            : 'Kiểm tra kết nối rồi thử lại.',
        action: 'Thử tải lại',
        onAction: () => ref.invalidate(catalogProvider),
        error: true,
      ),
    );
  }
}

class CatalogMessage extends StatelessWidget {
  const CatalogMessage({
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.error = false,
    super.key,
  });
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Icon(
          error ? Icons.cloud_off_outlined : Icons.search_off_rounded,
          size: 32,
          color: AppColors.primary,
        ),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.muted),
        ),
        if (action != null)
          FilledButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

/// 12 ảnh trong atlas 4×3 của Figma. Chỉ cắt khung lúc render; giữ nguyên file ảnh.
/// Dữ liệu nghiệp vụ không lấy từ atlas hoặc danh sách giá cố định.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({required this.product, this.imageIndex = 0, super.key});
  final CatalogProduct product;
  final int imageIndex;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.sage,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.muted, size: 32),
      ),
    );
    Widget photo;
    if (product.imageUrls.isNotEmpty) {
      photo = Image.network(
        product.imageUrls[imageIndex.clamp(0, product.imageUrls.length - 1)],
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
      );
    } else if (imageIndex == 1 &&
        const {'SF01', 'SF02'}.contains(product.code)) {
      photo = Image.asset(
        'assets/images/catalog/campaign.png',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    } else {
      final number = RegExp(r'^SF(0[1-9]|1[0-2])$').firstMatch(product.code);
      if (number == null) {
        photo = placeholder;
      } else {
        final index = int.parse(number.group(1)!) - 1;
        photo = LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -(index % 4) * width,
                    top: -(index ~/ 4) * height,
                    width: width * 4,
                    height: height * 3,
                    child: Image.asset(
                      'assets/images/catalog/products-atlas.png',
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
    return ExcludeSemantics(child: photo);
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products, super.key});
  final List<CatalogProduct> products;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(14) > 23 ? 1 : 2;
      final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: products
            .map(
              (product) => SizedBox(
                width: width,
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(
                      '/products/${Uri.encodeComponent(product.id)}',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 163 / 190,
                              child: ProductPhoto(product: product),
                            ),
                            if (!product.inStock)
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.ivory,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Hết hàng',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Text(
                                formatVnd(product.priceVnd),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                              Text(
                                [
                                  product.material,
                                  if (product.availableSizes.isNotEmpty)
                                    product.availableSizes.join(' / '),
                                ].where((s) => s.isNotEmpty).join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class CatalogChip extends StatelessWidget {
  const CatalogChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.minWidth = 0,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final double minWidth;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: minWidth),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      labelStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: selected ? AppColors.white : AppColors.ink),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.includeAll = true,
    super.key,
  });
  final List<CatalogCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool includeAll;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 8,
      children: [
        if (includeAll)
          CatalogChip(
            minWidth: 96,
            label: 'Tất cả',
            selected: selectedId == null,
            onSelected: () => onSelected(null),
          ),
        ...categories.map(
          (category) => CatalogChip(
            minWidth: 96,
            label: category.name,
            selected: selectedId == category.id,
            onSelected: () => onSelected(category.id),
          ),
        ),
      ],
    ),
  );
}

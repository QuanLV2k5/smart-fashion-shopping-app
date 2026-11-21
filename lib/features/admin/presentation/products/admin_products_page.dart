import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminProductsPage extends ConsumerStatefulWidget {
  const AdminProductsPage({super.key});

  @override
  ConsumerState<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends ConsumerState<AdminProductsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminProductFilterProvider);
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Quản lý Sản phẩm & Kho',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm'),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã SP (SF01...)',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(adminProductFilterProvider.notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
              onChanged: (val) {
                ref
                    .read(adminProductFilterProvider.notifier)
                    .setSearch(val.trim().isEmpty ? null : val.trim());
              },
            ),
          ),

          // Lọc theo danh mục
          categoriesAsync.maybeWhen(
            data: (categories) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: filter.categoryId == null,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: filter.categoryId == null
                          ? AppColors.white
                          : AppColors.ink,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(adminProductFilterProvider.notifier)
                            .setCategory(null);
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ...categories.map((c) {
                    final isSelected = filter.categoryId == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.ink,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          ref
                              .read(adminProductFilterProvider.notifier)
                              .setCategory(selected ? c.id : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Danh sách sản phẩm
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Không thể tải danh sách sản phẩm',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => ref.invalidate(adminProductsProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Không tìm thấy sản phẩm nào',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Nhấn "Thêm sản phẩm" để đăng sản phẩm mới.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(adminProductsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      88,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return _ProductAdminCard(
                        product: p,
                        formattedPrice: _formatVnd(p.priceVnd),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductAdminCard extends ConsumerWidget {
  const _ProductAdminCard({
    required this.product,
    required this.formattedPrice,
  });

  final AdminProduct product;
  final String formattedPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = product.imagePaths.isNotEmpty
        ? product.imagePaths.first
        : null;

    return InkWell(
      onTap: () =>
          context.push('/admin/products/${product.id}/edit', extra: product),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail ảnh
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.sage,
                child: imagePath != null && imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.muted,
                        ),
                      )
                    : const Icon(
                        Icons.checkroom_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          product.code,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AdminStatusBadge(
                        label: product.isVisible ? 'Đang bán' : 'Đã ẩn',
                        isActive: product.isVisible,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedPrice,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.variants.length} biến thể • Tồn kho: ${product.totalStock}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Nút ẩn/hiện nhanh
            IconButton(
              icon: Icon(
                product.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: product.isVisible ? AppColors.primary : AppColors.muted,
              ),
              tooltip: product.isVisible ? 'Ẩn sản phẩm' : 'Hiện sản phẩm',
              onPressed: () async {
                final controller = ref.read(
                  adminProductControllerProvider.notifier,
                );
                await controller.toggleVisibility(
                  product.id,
                  !product.isVisible,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

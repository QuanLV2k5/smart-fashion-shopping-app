import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import 'admin_providers.dart';
import 'widgets/admin_widgets.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);

    // Kiểm tra trạng thái đang tải role
    if (roleAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          title: const Text('Quản trị Smart Fashion'),
          backgroundColor: AppColors.ivory,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => context.go('/account'),
          ),
        ),
        body: const AdminAccessDeniedView(),
      );
    }

    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final productsAsync = ref.watch(adminProductsProvider);

    final totalCategories = categoriesAsync.asData?.value.length ?? 0;
    final totalProducts = productsAsync.asData?.value.length ?? 0;
    final inStockCount =
        productsAsync.asData?.value.where((p) => p.totalStock > 0).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Quản trị cửa hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.go('/account'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Vào shop'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminCategoriesProvider);
          ref.invalidate(adminProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thẻ chào mừng & Huy hiệu Admin
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bảng điều khiển Admin',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quản lý danh mục, sản phẩm, kho và cài đặt',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Thống kê nhanh
              Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Sản phẩm',
                      value: '$totalProducts',
                      subtext: '$inStockCount còn hàng',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickStatCard(
                      label: 'Danh mục',
                      value: '$totalCategories',
                      subtext: 'Đang hoạt động',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Danh mục quản trị',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Menu quản lý sản phẩm
              AdminMenuCard(
                title: 'Quản lý Sản phẩm & Kho',
                subtitle: 'Thêm mới, sửa, ẩn/hiện, quản lý kích cỡ và màu sắc',
                icon: Icons.inventory_2_outlined,
                badgeText: '$totalProducts SP',
                onTap: () => context.push('/admin/products'),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Menu quản lý danh mục
              AdminMenuCard(
                title: 'Quản lý Danh mục',
                subtitle: 'Thêm, cập nhật tên, slug và kích hoạt danh mục',
                icon: Icons.category_outlined,
                badgeText: '$totalCategories DM',
                onTap: () => context.push('/admin/categories'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Ghi chú module tiếp theo
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Module Quản lý đơn hàng và Báo cáo thống kê sẽ được đồng bộ tích hợp trong Sprint 2 & 3.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Quay lại Cửa hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.outline),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          Text(
            subtext,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

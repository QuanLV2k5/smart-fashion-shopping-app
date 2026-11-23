import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../domain/personalization.dart';
import 'personalization_providers.dart';
import 'favorite_button.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});
  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = ref.read(personalizationUserIdProvider);
      if (userId == null) return;
      final state = ref.read(favoritesProvider(userId));
      if (state.asData?.value.busy.isEmpty == true) {
        ref.invalidate(favoritesProvider(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(personalizationUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final provider = favoritesProvider(userId);
    final state = ref.watch(provider);
    final current = state.asData?.value;
    return StoreScaffold(
      title: 'Yêu thích',
      selectedIndex: 2,
      trailing: const CartButton(),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          try {
            await ref.read(provider.future);
          } catch (_) {
            /* Rendered below. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Món bạn muốn quay lại.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.hasError)
              CatalogMessage(
                title: 'Chưa tải được yêu thích',
                message: personalizationMessage(state.error),
                error: true,
                action: 'Thử lại',
                onAction: () => ref.invalidate(provider),
              ),
            if (current?.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  personalizationMessage(current!.error),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (current != null && current.entries.isEmpty && !state.isLoading)
              CatalogMessage(
                title: 'Chưa có món yêu thích',
                message:
                    'Chạm trái tim trên sản phẩm để lưu những món bạn thích.',
                action: 'Khám phá sản phẩm',
                onAction: () => context.go('/explore'),
              ),
            if (current != null) ...[
              ProductGrid(
                products: current.entries
                    .map((e) => e.product)
                    .nonNulls
                    .toList(),
              ),
              for (final item in current.entries.where(
                (e) => e.product == null,
              ))
                Card(
                  child: ListTile(
                    title: const Text('Sản phẩm không còn được bán'),
                    subtitle: const Text(
                      'Bạn vẫn có thể bỏ khỏi danh sách yêu thích.',
                    ),
                    trailing: FavoriteButton(productId: item.productId),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

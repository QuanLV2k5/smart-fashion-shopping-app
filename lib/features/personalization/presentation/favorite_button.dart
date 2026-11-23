import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/personalization.dart';
import 'personalization_providers.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.productId, super.key});
  final String productId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(personalizationUserIdProvider);
    final value = userId == null ? null : ref.watch(favoritesProvider(userId));
    final current = value?.asData?.value;
    final selected =
        current?.entries.any((e) => e.productId == productId) == true;
    final loading =
        value?.isLoading == true || current?.busy.isNotEmpty == true;
    return IconButton.filledTonal(
      tooltip: selected ? 'Bỏ yêu thích' : 'Thêm yêu thích',
      style: IconButton.styleFrom(backgroundColor: AppColors.ivory),
      icon: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: selected ? AppColors.accent : AppColors.primary,
      ),
      onPressed: loading
          ? null
          : () async {
              if (userId == null) {
                context.push(
                  '/login?next=${Uri.encodeComponent('/products/$productId')}',
                );
                return;
              }
              if (value?.hasError == true) {
                ref.invalidate(favoritesProvider(userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang tải lại danh sách yêu thích.'),
                  ),
                );
                return;
              }
              await ref
                  .read(favoritesProvider(userId).notifier)
                  .setFavorite(productId, !selected);
              if (!context.mounted ||
                  ref.read(personalizationUserIdProvider) != userId) {
                return;
              }
              final error = ref
                  .read(favoritesProvider(userId))
                  .asData
                  ?.value
                  .error;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(personalizationMessage(error))),
                );
              }
            },
    );
  }
}

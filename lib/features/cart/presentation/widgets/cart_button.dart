import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cart_providers.dart';

class CartButton extends ConsumerWidget {
  const CartButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentCartUserIdProvider);
    final count = userId == null
        ? 0
        : ref.watch(cartProvider(userId)).value?.totalQuantity ?? 0;
    return Tooltip(
      message: 'Giỏ hàng',
      child: TextButton(
        onPressed: () => context.push('/cart'),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Text('Giỏ'),
        ),
      ),
    );
  }
}

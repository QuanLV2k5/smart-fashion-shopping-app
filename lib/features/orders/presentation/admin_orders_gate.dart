import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import 'orders_providers.dart';

class AdminOrdersGate extends ConsumerWidget {
  const AdminOrdersGate({required this.builder, super.key});
  final Widget Function(String userId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authenticatedUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final provider = adminOrderAccessProvider(userId);
    final access = ref.watch(provider);
    if (access.asData?.value == true && !access.isLoading) {
      return builder(userId);
    }
    return ShopPageScaffold(
      title: 'Quản lý đơn hàng',
      onBack: () => context.canPop() ? context.pop() : context.go('/account'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (access.isLoading)
            const LinearProgressIndicator()
          else ...[
            ShopNotice(
              access.hasError
                  ? 'Không kiểm tra được quyền quản trị.'
                  : 'Bạn không có quyền quản lý đơn hàng.',
              error: true,
            ),
            if (access.hasError)
              OutlinedButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Kiểm tra lại'),
              ),
          ],
        ],
      ),
    );
  }
}

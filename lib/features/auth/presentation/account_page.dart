import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/store_scaffold.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// Đích sau Auth: chỉ thông tin phiên và đăng xuất, chưa triển khai module Profile.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authSessionProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    return StoreScaffold(
      title: 'Tài khoản',
      selectedIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const AuthStatusIcon(Icons.person_outline_rounded),
            AuthHeading(
              'Xin chào${user?.fullName.isNotEmpty == true ? ', ${user!.fullName}' : ', bạn'}',
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    'EMAIL TÀI KHOẢN',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.muted, letterSpacing: 1.2),
                  ),
                  SelectableText(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    children: [
                      Icon(
                        user?.emailConfirmed == true
                            ? Icons.verified_outlined
                            : Icons.mail_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          user?.emailConfirmed == true
                              ? 'Email đã xác nhận'
                              : 'Email chưa xác nhận',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AuthButton(
              'Địa chỉ giao hàng',
              secondary: true,
              onPressed: () => context.push('/addresses'),
            ),
            AuthButton(
              'Đăng xuất',
              secondary: true,
              onPressed: () => context.go('/logout'),
            ),
            AuthButton(
              'Tiếp tục xem cửa hàng',
              secondary: true,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoutPage extends ConsumerWidget {
  const LogoutPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    final error = authErrorNotice(state);
    return AuthScaffold(
      title: 'Đăng xuất',
      onBack: state.isLoading ? null : () => context.go('/account'),
      action: AuthButton(
        'Đăng xuất',
        loading: state.isLoading,
        onPressed: () async {
          final success = await ref
              .read(logoutControllerProvider.notifier)
              .signOut();
          if (success && context.mounted) context.go('/login');
        },
      ),
      children: [
        const AuthHeading('Bạn muốn đăng xuất?'),
        const AuthBody(
          'Bạn có thể đăng nhập lại để xem đơn và thông tin cá nhân.',
        ),
        ?error,
        AuthButton(
          'Tiếp tục ở lại',
          secondary: true,
          onPressed: state.isLoading ? null : () => context.go('/account'),
        ),
      ],
    );
  }
}

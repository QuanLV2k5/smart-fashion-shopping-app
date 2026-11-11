import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/widgets/avatar_selector_sheet.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// Màn hình Tài khoản (Figma Account 4:265 & GuestAccount 4:304).
/// Hiển thị thông tin hồ sơ người dùng, lối vào chỉnh sửa hồ sơ và đăng xuất.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authSessionProvider).value ??
        ref.read(authRepositoryProvider).currentUser;

    // Trường hợp tài khoản khách (chưa đăng nhập - Figma GuestAccount 4:304)
    if (user == null) {
      return StoreScaffold(
        title: 'Tài khoản',
        selectedIndex: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthStatusIcon(Icons.person_outline_rounded),
              const SizedBox(height: AppSpacing.md),
              const AuthHeading('Chào mừng bạn đến với Smart Fashion'),
              const SizedBox(height: AppSpacing.sm),
              const AuthBody(
                'Đăng nhập để xem hồ sơ cá nhân, lưu địa chỉ giao hàng và quản lý đơn hàng.',
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthButton(
                'Đăng nhập / Đăng ký',
                onPressed: () => context.go(
                  '/login?next=${Uri.encodeComponent('/account')}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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

    final profileAsync = ref.watch(userProfileProvider);
    final loadedProfile = profileAsync.asData?.value;
    final profile = loadedProfile?.id == user.id ? loadedProfile : null;

    final profileName = profile?.fullName.trim() ?? '';
    final authName = user.fullName.trim();
    final displayName = profileName.isNotEmpty
        ? profileName
        : (authName.isNotEmpty ? authName : 'bạn');

    final avatarUrl = profile?.avatarUrl ?? profile?.avatarPath;
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';

    return StoreScaffold(
      title: 'Tài khoản',
      selectedIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề chào mừng (Figma & Test assertion)
            AuthHeading('Xin chào, $displayName'),
            const SizedBox(height: AppSpacing.sm),

            // Thẻ hồ sơ cá nhân (Figma Account 4:265)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      buildAvatarDisplay(
                        avatarPathOrUrl: avatarUrl,
                        initials: initials,
                        size: 52,
                        textStyle: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (profile?.phone?.isNotEmpty == true)
                              Text(
                                profile!.phone!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const ValueKey('edit_profile_button'),
                    onPressed: () => context.go('/account/profile'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Chỉnh sửa hồ sơ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.outline),
                      minimumSize: const Size(double.infinity, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Các mục quản lý (Figma Account 4:265)
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                children: [
                  _AccountMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Sổ địa chỉ',
                    subtitle: 'Quản lý địa chỉ giao hàng',
                    onTap: () => context.push('/addresses'),
                  ),
                  const Divider(height: 1, color: AppColors.outline),
                  _AccountMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn hàng của tôi',
                    subtitle: 'Theo dõi đơn hàng đã đặt',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng đơn hàng sẽ có trong Sprint 2.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AuthButton(
              'Đăng xuất',
              secondary: true,
              onPressed: () => context.go('/logout'),
            ),
            const SizedBox(height: AppSpacing.xs),
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

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
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

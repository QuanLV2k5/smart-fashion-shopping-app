import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/personalization.dart';
import 'personalization_providers.dart';

/// UI feedback complements the database guard; it is never the access control.
class AccountAccessGate extends ConsumerStatefulWidget {
  const AccountAccessGate({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<AccountAccessGate> createState() => _AccountAccessGateState();
}

class _AccountAccessGateState extends ConsumerState<AccountAccessGate>
    with WidgetsBindingObserver {
  Timer? timer;
  bool signingOut = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(supabaseClientProvider) != null) {
      timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    }
  }

  void refresh() {
    if (mounted &&
        ref.read(personalizationUserIdProvider) != null &&
        ref.read(supabaseClientProvider) != null &&
        !ref.read(accountAccessProvider).isLoading) {
      ref.invalidate(accountAccessProvider);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(personalizationUserIdProvider);
    if (userId == null || ref.watch(supabaseClientProvider) == null) {
      return widget.child;
    }
    final access = ref.watch(accountAccessProvider);
    if (access.hasValue &&
        access.value?.userId == userId &&
        access.value?.blocked == false &&
        !access.hasError) {
      return widget.child;
    }
    final blocked =
        access.value?.userId == userId && access.value?.blocked == true;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Icon(
                    blocked
                        ? Icons.lock_outline_rounded
                        : Icons.shield_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  Text(
                    blocked
                        ? 'Tài khoản tạm khóa'
                        : access.isLoading
                        ? 'Đang kiểm tra tài khoản…'
                        : 'Chưa kiểm tra được tài khoản',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (access.isLoading) const LinearProgressIndicator(),
                  if (blocked)
                    const Text(
                      'Quyền truy cập tài khoản đang tạm khóa. Hồ sơ và lịch sử mua hàng được giữ nguyên. Vui lòng liên hệ quản trị viên.',
                    ),
                  if (access.hasError)
                    Text(personalizationMessage(access.error)),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  if (!access.isLoading)
                    OutlinedButton(
                      onPressed: () => ref.invalidate(accountAccessProvider),
                      child: const Text('Kiểm tra lại'),
                    ),
                  OutlinedButton(
                    onPressed: signingOut
                        ? null
                        : () async {
                            setState(() {
                              signingOut = true;
                              error = null;
                            });
                            try {
                              await ref.read(authRepositoryProvider).signOut();
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => error =
                                      'Chưa đăng xuất được. Vui lòng thử lại.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => signingOut = false);
                            }
                          },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

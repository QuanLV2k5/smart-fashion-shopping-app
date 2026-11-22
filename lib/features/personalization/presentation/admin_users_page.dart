import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../domain/personalization.dart';
import 'personalization_providers.dart';

class UsersAdminGate extends ConsumerWidget {
  const UsersAdminGate({required this.builder, super.key});
  final Widget Function(String) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(personalizationUserIdProvider);
    final access = ref.watch(accountAccessProvider);
    if (id != null &&
        !access.hasError &&
        access.value?.userId == id &&
        access.value?.admin == true) {
      return builder(id);
    }
    return ShopPageScaffold(
      title: 'Người dùng',
      onBack: () => context.canPop() ? context.pop() : context.go('/account'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: access.isLoading
            ? const LinearProgressIndicator()
            : CatalogMessage(
                title: 'Chưa thể truy cập',
                message: access.hasError
                    ? personalizationMessage(access.error)
                    : 'Mục này chỉ dành cho quản trị viên.',
                error: true,
                action: 'Kiểm tra lại',
                onAction: () => ref.invalidate(accountAccessProvider),
              ),
      ),
    );
  }
}

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});
  @override
  Widget build(BuildContext context) =>
      UsersAdminGate(builder: (id) => _UsersList(id, key: ValueKey(id)));
}

class _UsersList extends ConsumerStatefulWidget {
  const _UsersList(this.userId, {super.key});
  final String userId;
  @override
  ConsumerState<_UsersList> createState() => _UsersListState();
}

class _UsersListState extends ConsumerState<_UsersList> {
  final search = TextEditingController();
  String query = '';
  int offset = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void findUsers() => setState(() {
    query = search.text.trim();
    offset = 0;
  });
  @override
  Widget build(BuildContext context) {
    final provider = usersProvider((
      userId: widget.userId,
      search: query,
      offset: offset,
    ));
    final state = ref.watch(provider);
    final page = state.asData?.value;
    return ShopPageScaffold(
      title: 'Người dùng',
      onBack: () => context.canPop() ? context.pop() : context.go('/account'),
      trailing: TextButton(
        onPressed: () => context.go('/'),
        child: const Text('Shop'),
      ),
      body: RefreshIndicator(
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
              'Quản lý người dùng',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: search,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => findUsers(),
              decoration: InputDecoration(
                hintText: 'Tìm tên, email hoặc số điện thoại',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: findUsers,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.hasError)
              CatalogMessage(
                title: 'Chưa tải được người dùng',
                message: personalizationMessage(state.error),
                error: true,
                action: 'Thử lại',
                onAction: () => ref.invalidate(provider),
              ),
            if (page?.users.isEmpty == true)
              const CatalogMessage(
                title: 'Không tìm thấy người dùng',
                message: 'Thử tìm bằng tên hoặc email khác.',
              ),
            for (final user in page?.users ?? const <ManagedUser>[])
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Material(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    leading: Icon(
                      user.blocked ? Icons.lock_outline : Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(
                      '${user.email}\n${user.role == 'admin' ? 'Quản trị viên' : 'Khách hàng'} · ${user.blocked ? 'Tạm khóa' : 'Đang hoạt động'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/admin/users/${user.id}');
                      if (mounted) ref.invalidate(provider);
                    },
                  ),
                ),
              ),
            if (offset > 0 || page?.hasMore == true)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: offset > 0
                            ? () => setState(() => offset -= 50)
                            : null,
                        child: const Text('Trang trước'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: page?.hasMore == true
                            ? () => setState(() => offset += 50)
                            : null,
                        child: const Text('Trang sau'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Quay lại cửa hàng'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUserPage extends StatelessWidget {
  const AdminUserPage({required this.targetId, super.key});
  final String targetId;
  @override
  Widget build(BuildContext context) => UsersAdminGate(
    builder: (id) => _UserDetail(id, targetId, key: ValueKey((id, targetId))),
  );
}

class _UserDetail extends ConsumerStatefulWidget {
  const _UserDetail(this.userId, this.targetId, {super.key});
  final String userId, targetId;
  @override
  ConsumerState<_UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends ConsumerState<_UserDetail> {
  bool busy = false;
  String? message;
  bool get active =>
      mounted &&
      ref.read(personalizationUserIdProvider) == widget.userId &&
      ref.read(accountAccessProvider).value?.userId == widget.userId &&
      ref.read(accountAccessProvider).value?.admin == true;
  Future<void> change(ManagedUser user) async {
    if (busy || !active) return;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final sameSession =
              ref.watch(personalizationUserIdProvider) == widget.userId &&
              ref.watch(accountAccessProvider).value?.userId == widget.userId &&
              ref.watch(accountAccessProvider).value?.admin == true;
          return AlertDialog(
            title: Text(
              user.blocked ? 'Mở lại truy cập?' : 'Tạm khóa truy cập?',
            ),
            content: Text(
              sameSession
                  ? '${user.displayName}\n\n${user.blocked ? 'Người dùng có thể truy cập tài khoản trở lại.' : 'Người dùng không thể sử dụng tài khoản khi bị khóa.'} Hồ sơ và lịch sử đơn được giữ nguyên.'
                  : 'Phiên làm việc đã thay đổi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quay lại'),
              ),
              FilledButton(
                onPressed: sameSession
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
      ),
    );
    if (answer != true || !active) return;
    setState(() {
      busy = true;
      message = null;
    });
    final provider = managedUserProvider((
      userId: widget.userId,
      targetId: widget.targetId,
    ));
    try {
      await ref
          .read(personalizationRepositoryProvider)
          .setAccess(widget.userId, user, !user.blocked);
      if (!active) return;
      setState(() => message = 'Đã cập nhật trạng thái truy cập.');
      ref.invalidate(provider);
      ref.invalidate(usersProvider);
    } catch (error) {
      if (active) {
        setState(() => message = personalizationMessage(error));
        ref.invalidate(provider);
      }
    } finally {
      if (active) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = managedUserProvider((
      userId: widget.userId,
      targetId: widget.targetId,
    ));
    final state = ref.watch(provider);
    final user = state.asData?.value;
    return ShopPageScaffold(
      title: 'Chi tiết người dùng',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/admin/users'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.isLoading || busy) const LinearProgressIndicator(),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ShopNotice(message!),
            ),
          if (state.hasError)
            CatalogMessage(
              title: 'Chưa tải được người dùng',
              message: personalizationMessage(state.error),
              error: true,
              action: 'Thử lại',
              onAction: () => ref.invalidate(provider),
            ),
          if (user != null) ...[
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SelectableText(user.email),
            if (user.phone.isNotEmpty) Text(user.phone),
            Text(
              'Vai trò: ${user.role == 'admin' ? 'Quản trị viên' : 'Khách hàng'}',
            ),
            const SizedBox(height: 16),
            ShopNotice(
              user.blocked
                  ? 'Tài khoản đang tạm khóa'
                  : '✓ Tài khoản đang hoạt động',
            ),
            const SizedBox(height: 16),
            const Text(
              'Thay đổi quyền truy cập không xóa dữ liệu hoặc lịch sử đơn hàng.',
              style: TextStyle(color: AppColors.muted),
            ),
            if (user.role == 'admin' || user.id == widget.userId)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Tài khoản quản trị được bảo vệ; không đổi vai trò hoặc khóa tại đây.',
                ),
              ),
          ],
        ],
      ),
      footer: user != null && user.role != 'admin' && user.id != widget.userId
          ? SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy || state.isLoading ? null : () => change(user),
                child: Text(
                  user.blocked ? 'Mở lại truy cập' : 'Tạm khóa truy cập',
                ),
              ),
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/checkout.dart';
import '../domain/orders.dart';
import 'orders_providers.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authenticatedUserIdProvider);
    return userId == null
        ? const SizedBox.shrink()
        : _OrdersList(userId, key: ValueKey(userId));
  }
}

class _OrdersList extends ConsumerStatefulWidget {
  const _OrdersList(this.userId, {super.key});
  final String userId;

  @override
  ConsumerState<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends ConsumerState<_OrdersList> {
  String _filter = 'all';
  OrdersResult? _firstPage, _extended;
  int _revision = 0;
  bool _loadingMore = false;
  String? _error;

  void _resetPages() {
    _revision++;
    _extended = null;
    _loadingMore = false;
    _error = null;
  }

  Future<void> _more(OrdersResult page) async {
    final revision = _revision;
    final filter = _filter;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final next = await ref
          .read(ordersRepositoryProvider)
          .list(widget.userId, filter, page.nextCursor);
      if (mounted &&
          revision == _revision &&
          ref.read(authenticatedUserIdProvider) == widget.userId) {
        setState(() {
          _extended = OrdersResult.append(page, next);
        });
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() {
          _error = 'Không tải được trang tiếp theo. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted && revision == _revision) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ordersListProvider((
      userId: widget.userId,
      filter: _filter,
    ));
    final result = ref.watch(provider);
    final page = result.asData?.value;
    if (page != null && !identical(page, _firstPage)) {
      _firstPage = page;
      _resetPages();
    }
    final current = _extended ?? page;
    return ShopPageScaffold(
      title: 'Đơn hàng của tôi',
      onBack: () => context.canPop() ? context.pop() : context.go('/account'),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_resetPages);
          try {
            await ref.refresh(provider.future);
          } catch (_) {
            /* Rendered below. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final entry in const {
                  'all': 'Tất cả',
                  'processing': 'Đang xử lý',
                  'completed': 'Hoàn tất',
                  'cancelled': 'Đã hủy',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() {
                      _filter = entry.key;
                      _resetPages();
                    }),
                  ),
              ],
            ),
            if (result.isLoading) const LinearProgressIndicator(),
            if (result.hasError) ...[
              ShopNotice(orderLoadMessage(result.error), error: true),
              OutlinedButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Thử lại'),
              ),
            ],
            if (current?.orders.isEmpty == true)
              const ShopNotice('Chưa có đơn hàng trong mục này.'),
            for (final order in current?.orders ?? const <OrderSummary>[])
              Card(
                child: ListTile(
                  title: Text('#${order.number} · ${order.lineCount} sản phẩm'),
                  subtitle: Text(
                    '${order.names.join(' + ')}\n${formatVnd(order.total)} · COD\n${order.status.label}',
                  ),
                  onTap: () => context.push(
                    '/account/orders/${Uri.encodeComponent(order.id)}',
                  ),
                ),
              ),
            if (_error case final error?) ShopNotice(error, error: true),
            if (current?.nextCursor != null)
              OutlinedButton(
                onPressed: _loadingMore ? null : () => _more(current!),
                child: const Text('Tải thêm'),
              ),
          ],
        ),
      ),
    );
  }
}

String orderLoadMessage(Object? error) => switch (error) {
  OrdersFailure(code: 'SF_ORDER_NOT_FOUND') => 'Không tìm thấy đơn hàng.',
  OrdersFailure(code: 'SF_FORBIDDEN') => 'Bạn không có quyền xem mục này.',
  OrdersFailure() => error.message,
  _ => 'Không tải được đơn hàng. Vui lòng kiểm tra kết nối rồi thử lại.',
};

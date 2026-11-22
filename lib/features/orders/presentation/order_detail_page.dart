import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/checkout.dart';
import '../domain/orders.dart';
import 'checkout_page.dart';
import 'my_orders_page.dart';
import 'orders_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, super.key});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authenticatedUserIdProvider);
    return userId == null
        ? const SizedBox.shrink()
        : _Detail((
            userId: userId,
            orderId: orderId,
          ), key: ValueKey((userId, orderId)));
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail(this.orderKey, {super.key});
  final OrderKey orderKey;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;
  OrderChange? _pending;
  String? _message;

  bool get _active =>
      mounted &&
      ref.read(authenticatedUserIdProvider) == widget.orderKey.userId;

  Future<void> _confirmCancellation(OrderDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: Text('Bạn muốn hủy đơn #${detail.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_active) return;
    await _send(
      OrderChange(
        orderId: detail.id,
        target: OrderStatus.cancelled,
        version: detail.version,
        requestId: const Uuid().v4(),
        reason: 'customer_requested',
      ),
    );
  }

  Future<void> _send(OrderChange request) async {
    if (_busy || !_active) return;
    final provider = orderDetailProvider(widget.orderKey);
    setState(() {
      _busy = true;
      _pending = request;
      _message = null;
    });
    try {
      await ref
          .read(ordersRepositoryProvider)
          .change(widget.orderKey.userId, request);
      if (!_active) return;
      _pending = null;
      ref.invalidate(ordersListProvider);
      ref.invalidate(provider);
    } on OrdersFailure catch (error) {
      if (!_active) return;
      switch (error.code) {
        case 'SF_ORDER_VERSION_CONFLICT':
        case 'SF_ORDER_TRANSITION_INVALID':
          _pending = null;
          _message = 'Đơn đã thay đổi. Hãy kiểm tra trạng thái mới trước khi xác nhận lại.';
          ref.invalidate(provider);
        case 'SF_ORDER_NOT_FOUND':
        case 'SF_FORBIDDEN':
        case 'SF_INVALID_CHECKOUT':
        case 'SF_STOCK_CHANGED':
          _pending = null;
          _message = error.code == 'SF_STOCK_CHANGED'
              ? 'Chưa thể hoàn tồn cho đơn này.'
              : orderLoadMessage(error);
          ref.invalidate(provider);
        default:
          _message = 'Chưa xác nhận được kết quả cập nhật. Vui lòng thử lại yêu cầu này.';
      }
    } catch (_) {
      if (_active) _message = 'Chưa xác nhận được kết quả cập nhật. Vui lòng thử lại yêu cầu này.';
    } finally {
      if (_active)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = orderDetailProvider(widget.orderKey);
    final state = ref.watch(provider);
    final detail = state.asData?.value;
    final pending = _pending;
    return ShopPageScaffold(
      title: detail == null ? 'Chi tiết đơn hàng' : 'Đơn #${detail.number}',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/account/orders'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.isLoading || _busy) const LinearProgressIndicator(),
          if (_message case final message?) ShopNotice(message, error: true),
          if (state.hasError) ...[
            ShopNotice(orderLoadMessage(state.error), error: true),
            OutlinedButton(
              onPressed: () => ref.invalidate(provider),
              child: const Text('Thử tải lại'),
            ),
          ],
          if (detail != null) ...[
            ShopNotice(detail.status.label),
            for (final line in detail.lines) OrderLineTile(line),
            ShopNotice(
              '${detail.delivery.name} · ${detail.delivery.phone}\n${detail.delivery.address}',
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Thanh toán khi nhận hàng'),
            OrderTotalsView(detail.totals),
            Text(
              'Tiến trình đơn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final event in detail.events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(event.status.label),
                subtitle: Text(
                  MaterialLocalizations.of(context)
                      .formatShortDate(event.at.toLocal()),
                ),
              ),
          ],
        ],
      ),
      footer: pending != null
          ? FilledButton(
              onPressed: _busy ? null : () => _send(pending),
              child: const Text('Thử lại cập nhật'),
            )
          : detail?.allowed.contains(OrderStatus.cancelled) == true
          ? OutlinedButton(
              onPressed: _busy || state.isLoading
                  ? null
                  : () => _confirmCancellation(detail!),
              child: const Text('Hủy đơn'),
            )
          : null,
    );
  }
}

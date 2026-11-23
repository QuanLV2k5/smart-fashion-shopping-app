import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/checkout.dart';
import '../domain/orders.dart';
import 'admin_orders_gate.dart';
import 'checkout_page.dart';
import 'my_orders_page.dart';
import 'orders_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, this.admin = false, super.key});
  final String orderId;
  final bool admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (admin) {
      return AdminOrdersGate(
        builder: (userId) => _Detail(
          (userId: userId, orderId: orderId),
          admin: true,
          key: ValueKey((userId, orderId)),
        ),
      );
    }
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
  const _Detail(this.orderKey, {this.admin = false, super.key});
  final OrderKey orderKey;
  final bool admin;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;
  OrderChange? _pending;
  String? _message;

  bool get _active =>
      mounted &&
      ref.read(authenticatedUserIdProvider) == widget.orderKey.userId &&
      (!widget.admin ||
          ref
                  .read(adminOrderAccessProvider(widget.orderKey.userId))
                  .asData
                  ?.value ==
              true);

  Future<void> _confirm(OrderDetail detail, OrderStatus target) async {
    final cancel = target == OrderStatus.cancelled;
    final admin = widget.admin;
    final userId = widget.orderKey.userId;
    String reason = 'customer_requested';
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          if (ref.watch(authenticatedUserIdProvider) != userId ||
              (admin &&
                  ref.watch(adminOrderAccessProvider(userId)).asData?.value !=
                      true)) {
            return AlertDialog(
              content: const Text('Phiên làm việc đã thay đổi.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }
          return AlertDialog(
            title: Text(cancel ? 'Hủy đơn hàng?' : _actionLabel(target)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cancel
                      ? 'Bạn muốn hủy đơn #${detail.number}?'
                      : 'Cập nhật đơn #${detail.number} thành ${target.label.toLowerCase()}?',
                ),
                if (cancel && admin)
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(labelText: 'Lý do hủy'),
                    items: const [
                      DropdownMenuItem(
                        value: 'customer_requested',
                        child: Text('Khách yêu cầu'),
                      ),
                      DropdownMenuItem(
                        value: 'cannot_fulfill',
                        child: Text('Không thể giao'),
                      ),
                      DropdownMenuItem(
                        value: 'duplicate_confirmed',
                        child: Text('Đơn trùng'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) reason = value;
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, cancel ? reason : ''),
                child: Text(cancel ? 'Xác nhận hủy' : 'Xác nhận cập nhật'),
              ),
            ],
          );
        },
      ),
    );
    if (answer == null || !_active) return;
    await _send(
      OrderChange(
        orderId: detail.id,
        target: target,
        version: detail.version,
        requestId: const Uuid().v4(),
        reason: cancel ? answer : null,
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
      if (_active) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = orderDetailProvider(widget.orderKey);
    final state = ref.watch(provider);
    final detail = state.asData?.value;
    final pending = _pending;
    final actions =
        detail?.allowed
            .where((status) => widget.admin || status == OrderStatus.cancelled)
            .toList() ??
        const <OrderStatus>[];
    return ShopPageScaffold(
      title: detail == null ? 'Chi tiết đơn hàng' : 'Đơn #${detail.number}',
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(widget.admin ? '/admin/orders' : '/account/orders'),
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
          : actions.isNotEmpty
          ? Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final action in actions)
                  FilledButton(
                    onPressed: _busy || state.isLoading
                        ? null
                        : () => _confirm(detail!, action),
                    child: Text(_actionLabel(action)),
                  ),
              ],
            )
          : null,
    );
  }
}

String _actionLabel(OrderStatus status) => switch (status) {
  OrderStatus.confirmed => 'Xác nhận đơn hàng',
  OrderStatus.shipping => 'Bắt đầu giao hàng',
  OrderStatus.completed => 'Hoàn tất đơn hàng',
  OrderStatus.cancelled => 'Hủy đơn',
  OrderStatus.pending => status.label,
};

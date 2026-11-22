import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/checkout.dart';
import '../domain/orders.dart';
import 'supabase_checkout_repository.dart';

class SupabaseOrdersRepository implements OrdersRepository {
  const SupabaseOrdersRepository(this.client);
  final SupabaseClient? client;

  @override
  Future<OrdersResult> list(
    String userId,
    String filter,
    OrderJson? cursor,
  ) async => OrdersResult.fromJson(
    await ordersRpc(client, userId, 'list_my_orders', {
      'p_filter': filter,
      'p_cursor': cursor,
    }),
  );

  @override
  Future<OrderDetail> detail(String userId, String orderId) async {
    final detail = OrderDetail.fromJson(
      await ordersRpc(client, userId, 'get_order', {'p_order_id': orderId}),
    );
    if (detail.id != orderId)
      throw const FormatException('Unexpected order ID');
    return detail;
  }

  @override
  Future<void> change(String userId, OrderChange change) async {
    final response = await ordersRpc(client, userId, 'change_order_status', {
      'p_order_id': change.orderId,
      'p_target_status': change.target.name,
      'p_expected_version': change.version,
      'p_request_id': change.requestId,
      'p_reason_code': change.reason,
    });
    checkOrdersVersion(response);
    final result = orderObject(response['result']);
    if (result['order_id'] != change.orderId ||
        result['status'] != change.target.name ||
        result['version'] != change.version + 1) {
      throw const FormatException('Unexpected order transition receipt');
    }
  }
}

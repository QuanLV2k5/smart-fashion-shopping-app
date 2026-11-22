import 'checkout.dart';

enum OrderStatus {
  pending('Chờ xác nhận'),
  confirmed('Đã xác nhận'),
  shipping('Đang giao'),
  completed('Hoàn tất'),
  cancelled('Đã hủy');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus parse(String value) => values.byName(value);
}

class OrderSummary {
  OrderSummary.fromJson(OrderJson json)
    : id = orderField<String>(json, 'id'),
      number = orderField<String>(json, 'order_number'),
      status = OrderStatus.parse(orderField<String>(json, 'status')),
      total = orderField<int>(json, 'total_vnd'),
      lineCount = orderField<int>(json, 'distinct_line_count'),
      names = List.unmodifiable(
        orderField<List<dynamic>>(json, 'product_names').cast<String>(),
      );

  final String id, number;
  final OrderStatus status;
  final int total, lineCount;
  final List<String> names;
}

class OrdersResult {
  OrdersResult.fromJson(OrderJson json)
    : orders = List.unmodifiable(
        orderField<List<dynamic>>(
          json,
          'items',
        ).map((item) => OrderSummary.fromJson(orderObject(item))),
      ),
      nextCursor = json['next_cursor'] == null
          ? null
          : Map.unmodifiable(orderObject(json['next_cursor']));

  OrdersResult.append(OrdersResult previous, OrdersResult next)
    : orders = List.unmodifiable([...previous.orders, ...next.orders]),
      nextCursor = next.nextCursor;

  final List<OrderSummary> orders;
  final OrderJson? nextCursor;
}

class OrderEvent {
  OrderEvent.fromJson(OrderJson json)
    : status = OrderStatus.parse(orderField<String>(json, 'to_status')),
      at = DateTime.parse(orderField<String>(json, 'created_at'));

  final OrderStatus status;
  final DateTime at;
}

class OrderDetail {
  OrderDetail.fromJson(OrderJson json)
    : id = orderField<String>(json, 'id'),
      number = orderField<String>(json, 'order_number'),
      status = OrderStatus.parse(orderField<String>(json, 'status')),
      version = orderField<int>(json, 'version'),
      delivery = OrderDelivery.fromJson(orderObject(json['delivery_address'])),
      totals = OrderTotals.fromJson(json),
      lines = List.unmodifiable(
        orderField<List<dynamic>>(
          json,
          'items',
        ).map((item) => OrderLine.fromJson(orderObject(item))),
      ),
      events = List.unmodifiable(
        orderField<List<dynamic>>(
          json,
          'events',
        ).map((event) => OrderEvent.fromJson(orderObject(event))),
      ),
      allowed = List.unmodifiable(
        orderField<List<dynamic>>(
          json,
          'allowed_transitions',
        ).cast<String>().map(OrderStatus.parse),
      ) {
    checkOrdersVersion(json);
  }

  final String id, number;
  final OrderStatus status;
  final int version;
  final OrderDelivery delivery;
  final OrderTotals totals;
  final List<OrderLine> lines;
  final List<OrderEvent> events;
  final List<OrderStatus> allowed;
}

class OrderChange {
  const OrderChange({
    required this.orderId,
    required this.target,
    required this.version,
    required this.requestId,
    this.reason,
  });

  final String orderId, requestId;
  final OrderStatus target;
  final int version;
  final String? reason;
}

abstract interface class OrdersRepository {
  Future<OrdersResult> list(String userId, String filter, OrderJson? cursor);
  Future<OrderDetail> detail(String userId, String orderId);
  Future<void> change(String userId, OrderChange change);
}

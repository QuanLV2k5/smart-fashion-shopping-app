typedef OrderJson = Map<String, dynamic>;

OrderJson orderObject(Object? value) {
  if (value is OrderJson) return value;
  throw const FormatException('Expected an Orders JSON object');
}

T orderField<T>(OrderJson json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Invalid Orders field: $key');
}

void checkOrdersVersion(OrderJson json) {
  if (json['schema_version'] != 1) {
    throw const FormatException('Unsupported Orders response version');
  }
}

class OrderTotals {
  const OrderTotals(this.subtotal, this.shipping, this.total);

  factory OrderTotals.fromJson(OrderJson json) {
    if (json['currency'] != 'VND' || json['payment_method'] != 'cod') {
      throw const FormatException(
        'Unexpected checkout currency or payment method',
      );
    }
    return OrderTotals(
      orderField<int>(json, 'subtotal_vnd'),
      orderField<int>(json, 'shipping_vnd'),
      orderField<int>(json, 'total_vnd'),
    );
  }

  final int subtotal, shipping, total;
}

class OrderDelivery {
  OrderDelivery.fromJson(OrderJson json)
    : name = orderField<String>(json, 'recipient_name'),
      phone = orderField<String>(json, 'phone'),
      address = [
        for (final key in ['address_line', 'ward', 'district', 'city'])
          orderField<String>(json, key),
      ].join(', ');

  final String name, phone, address;
}

class OrderLine {
  OrderLine.fromJson(OrderJson json)
    : name = orderField<String>(json, 'product_name'),
      size = orderField<String>(json, 'size'),
      color = orderField<String>(json, 'color'),
      quantity = orderField<int>(json, 'quantity'),
      total = orderField<int>(json, 'line_total_vnd'),
      imagePaths = List.unmodifiable(
        orderField<List<dynamic>>(json, 'image_paths').cast<String>(),
      );

  final String name, size, color;
  final int quantity, total;
  final List<String> imagePaths;
}

class CheckoutQuote {
  CheckoutQuote.fromJson(OrderJson json)
    : id = orderField<String>(json, 'quote_id'),
      addressId = orderField<String>(json, 'address_id'),
      expiresAt = DateTime.parse(orderField<String>(json, 'expires_at')),
      delivery = OrderDelivery.fromJson(orderObject(json['address'])),
      lines = List.unmodifiable(
        orderField<List<dynamic>>(
          json,
          'items',
        ).map((value) => OrderLine.fromJson(orderObject(value))),
      ),
      totals = OrderTotals.fromJson(json) {
    checkOrdersVersion(json);
  }

  final String id, addressId;
  final DateTime expiresAt;
  final OrderDelivery delivery;
  final List<OrderLine> lines;
  final OrderTotals totals;
}

class CheckoutRequest {
  const CheckoutRequest({required this.quoteId, required this.requestId});

  CheckoutRequest.fromJson(OrderJson json)
    : quoteId = orderField<String>(json, 'quote_id'),
      requestId = orderField<String>(json, 'request_id');

  final String quoteId, requestId;

  OrderJson toJson() => {'quote_id': quoteId, 'request_id': requestId};
}

class PlacedOrder {
  PlacedOrder.fromJson(OrderJson json)
    : id = orderField<String>(json, 'order_id'),
      number = orderField<String>(json, 'order_number'),
      requestId = orderField<String>(json, 'request_id'),
      totals = OrderTotals.fromJson(json);

  final String id, number, requestId;
  final OrderTotals totals;
}

class OrdersFailure implements Exception {
  const OrdersFailure(this.code);
  final String code;

  // These errors come from the transaction after receipt lookup.
  bool get placeRejected => const {
    'SF_QUOTE_EXPIRED',
    'SF_QUOTE_STALE',
    'SF_QUOTE_NOT_FOUND',
    'SF_CART_CHANGED',
    'SF_CART_EMPTY',
    'SF_CART_LIMIT',
    'SF_ADDRESS_UNAVAILABLE',
    'SF_PRODUCT_UNAVAILABLE',
    'SF_STOCK_CHANGED',
    'SF_TOTAL_LIMIT',
  }.contains(code);

  String get message => switch (code) {
    'SF_QUOTE_EXPIRED' => 'Báo giá đã hết hạn. Vui lòng lấy báo giá mới.',
    'SF_QUOTE_STALE' =>
      'Thông tin đơn đã thay đổi. Vui lòng kiểm tra báo giá mới.',
    'SF_CART_CHANGED' ||
    'SF_CART_EMPTY' ||
    'SF_CART_LIMIT' => 'Giỏ hàng cần được kiểm tra lại trước khi đặt.',
    'SF_PRODUCT_UNAVAILABLE' || 'SF_STOCK_CHANGED' =>
      'Một số món đã ngừng bán hoặc không đủ tồn. Vui lòng kiểm tra giỏ.',
    'SF_ADDRESS_UNAVAILABLE' => 'Địa chỉ giao hàng không còn khả dụng.',
    'SF_AUTH_REQUIRED' => 'Vui lòng đăng nhập lại.',
    'SF_QUOTE_LIMIT' =>
      'Đã có quá nhiều báo giá đang hiệu lực. Vui lòng chờ và thử lại.',
    _ =>
      'Không thể tải thông tin đơn hàng. Vui lòng kiểm tra kết nối và thử lại.',
  };
}

abstract interface class CheckoutRepository {
  Future<CheckoutQuote> quote(String userId, String addressId);
  Future<PlacedOrder> place(String userId, CheckoutRequest request);
  Future<PlacedOrder?> lookup(String userId, CheckoutRequest request);
}

abstract interface class CheckoutRequestStore {
  Future<CheckoutRequest?> read(String userId);
  Future<void> save(String userId, CheckoutRequest request);
  Future<void> clear(String userId);
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/orders/domain/checkout.dart';
import 'package:smart_fashion/features/orders/domain/orders.dart';
import 'package:smart_fashion/features/orders/presentation/my_orders_page.dart';
import 'package:smart_fashion/features/orders/presentation/order_detail_page.dart';
import 'package:smart_fashion/features/orders/presentation/orders_providers.dart';

import '../auth/fake_auth_repository.dart';

const customerA = FakeAuthRepository.user;
const customerB = AuthUser(
  id: 'b',
  email: 'b@example.com',
  fullName: 'B',
  emailConfirmed: true,
);

OrdersResult page(String number, {bool more = false}) => OrdersResult.fromJson({
  'items': [
    {
      'id': number,
      'order_number': number,
      'status': 'pending',
      'total_vnd': 224000,
      'distinct_line_count': 1,
      'product_names': ['Áo từ snapshot'],
    },
  ],
  'next_cursor': more
      ? {'created_at': '2026-11-22T03:00:00Z', 'id': number}
      : null,
});

class OrdersBackend implements OrdersRepository {
  Completer<OrdersResult>? nextPage;
  final calls = <(String, String, OrderJson?)>[];
  final changes = <OrderChange>[];
  String status = 'pending';
  int version = 1;

  @override
  Future<OrdersResult> list(
    String userId,
    String filter,
    OrderJson? cursor,
  ) async {
    calls.add((userId, filter, cursor));
    if (cursor != null && nextPage != null) return nextPage!.future;
    return userId == customerA.id ? page('SF-A', more: true) : page('SF-B');
  }

  @override
  Future<OrderDetail> detail(String userId, String orderId) async =>
      OrderDetail.fromJson({
        'schema_version': 1,
        'id': orderId,
        'order_number': 'SF-DETAIL',
        'status': status,
        'version': version,
        'currency': 'VND',
        'payment_method': 'cod',
        'subtotal_vnd': 199000,
        'shipping_vnd': 25000,
        'total_vnd': 224000,
        'delivery_address': {
          'recipient_name': 'Người nhận từ snapshot',
          'phone': '0900000000',
          'address_line': 'Đường thử nghiệm',
          'ward': 'Phường A',
          'district': 'Quận A',
          'city': 'Thành phố A',
        },
        'items': [
          {
            'product_name': 'Áo từ snapshot',
            'color': 'Trắng',
            'size': 'M',
            'quantity': 1,
            'line_total_vnd': 199000,
            'image_paths': <String>[],
          },
        ],
        'events': [
          {'to_status': status, 'created_at': '2026-11-22T03:00:00Z'},
        ],
        'allowed_transitions': status == 'pending' ? ['cancelled'] : <String>[],
      });

  @override
  Future<void> change(String userId, OrderChange change) async {
    changes.add(change);
    status = change.target.name;
    version++;
  }
}

Future<void> open(
  WidgetTester tester,
  FakeAuthRepository auth,
  OrdersBackend backend,
  Widget screen,
) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(auth),
      ordersRepositoryProvider.overrideWithValue(backend),
    ],
  );
  addTearDown(auth.close);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('late history page cannot cross sessions A → B → A', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..setUser(customerA);
    final backend = OrdersBackend()..nextPage = Completer<OrdersResult>();
    await open(tester, auth, backend, const MyOrdersPage());
    expect(find.textContaining('SF-A'), findsOneWidget);
    await tester.tap(find.text('Tải thêm'));
    await tester.pump();
    expect(backend.calls.last.$3?['id'], 'SF-A');
    auth.setUser(customerB);
    await tester.pumpAndSettle();
    expect(find.textContaining('SF-A'), findsNothing);
    expect(find.textContaining('SF-B'), findsOneWidget);
    backend.nextPage!.complete(page('SF-LATE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SF-LATE'), findsNothing);
    auth.setUser(customerA);
    await tester.pumpAndSettle();
    expect(find.textContaining('SF-A'), findsOneWidget);
    expect(find.textContaining('SF-B'), findsNothing);
    expect(find.textContaining('SF-LATE'), findsNothing);
  });

  testWidgets(
    'customer cancellation confirms and uses server version and reason',
    (tester) async {
      final auth = FakeAuthRepository()..setUser(customerA);
      final backend = OrdersBackend();
      await open(
        tester,
        auth,
        backend,
        const OrderDetailPage(orderId: 'detail-a'),
      );
      expect(find.text('Áo từ snapshot'), findsOneWidget);
      expect(find.textContaining('Người nhận từ snapshot'), findsOneWidget);
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      expect(backend.changes, isEmpty);
      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();
      final request = backend.changes.single;
      expect(request.orderId, 'detail-a');
      expect(request.target, OrderStatus.cancelled);
      expect(request.version, 1);
      expect(request.reason, 'customer_requested');
      expect(find.text('Hủy đơn'), findsNothing);
      expect(find.text('Đã hủy'), findsWidgets);
    },
  );
}

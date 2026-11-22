import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/addresses/presentation/address_providers.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/orders/domain/checkout.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_page.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_providers.dart';

import '../addresses/address_fixtures.dart';
import '../auth/fake_auth_repository.dart';
import '../cart/cart_fixtures.dart';

const a = FakeAuthRepository.user;
const b = AuthUser(
  id: 'customer-b',
  email: 'b@example.com',
  fullName: 'B',
  emailConfirmed: true,
);
const totals = {
  'subtotal_vnd': 448000,
  'shipping_vnd': 25000,
  'total_vnd': 473000,
  'currency': 'VND',
  'payment_method': 'cod',
};

class MemoryRequests implements CheckoutRequestStore {
  final pending = <String, CheckoutRequest>{};
  bool failSave = false;

  @override
  Future<CheckoutRequest?> read(String userId) async => pending[userId];

  @override
  Future<void> save(String userId, CheckoutRequest request) async {
    if (failSave) throw StateError('Storage unavailable');
    pending[userId] = request;
  }

  @override
  Future<void> clear(String userId) async => pending.remove(userId);
}

class Backend implements CheckoutRepository {
  Backend(this.store);
  final MemoryRequests store;
  final attempts = <(String, String)>[];
  Object? nextError;
  Completer<PlacedOrder>? nextResponse;
  Duration quoteLifetime = const Duration(minutes: 2);

  @override
  Future<CheckoutQuote> quote(String userId, String addressId) async =>
      CheckoutQuote.fromJson({
        ...totals,
        'schema_version': 1,
        'quote_id': 'quote-$userId',
        'address_id': addressId,
        'expires_at': DateTime.now()
            .add(quoteLifetime)
            .toUtc()
            .toIso8601String(),
        'address': {
          'recipient_name': 'Người nhận $userId',
          'phone': '0900000000',
          'address_line': 'Đường A',
          'ward': 'Phường A',
          'district': 'Quận A',
          'city': 'Thành phố A',
        },
        'items': [
          {
            'product_name': 'Áo từ báo giá',
            'size': 'M',
            'color': 'Trắng',
            'quantity': 1,
            'line_total_vnd': 448000,
            'image_paths': <String>[],
          },
        ],
      });

  PlacedOrder receipt(CheckoutRequest request) => PlacedOrder.fromJson({
    ...totals,
    'order_id': 'order-1',
    'order_number': 'SF-000001',
    'request_id': request.requestId,
  });

  @override
  Future<PlacedOrder> place(String userId, CheckoutRequest request) async {
    expect(store.pending[userId]?.requestId, request.requestId);
    attempts.add((userId, request.requestId));
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    return nextResponse?.future ?? receipt(request);
  }

  @override
  Future<PlacedOrder?> lookup(String userId, CheckoutRequest request) async =>
      null;
}

ProviderContainer providers(
  FakeAuthRepository auth,
  MemoryRequests store,
  Backend backend,
) {
  final addresses = FakeAddressRepository()
    ..rows.addAll([
      fixtureAddress('address-a', a.id, draft),
      fixtureAddress('address-b', b.id, draft),
    ]);
  final selection = MemorySelection()
    ..values.addAll({a.id: 'address-a', b.id: 'address-b'});
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(auth),
      checkoutRequestStoreProvider.overrideWithValue(store),
      checkoutRepositoryProvider.overrideWithValue(backend),
      cartRepositoryProvider.overrideWithValue(
        FakeCartRepository()..quantities[whiteM] = 1,
      ),
      addressRepositoryProvider.overrideWithValue(addresses),
      addressSelectionStoreProvider.overrideWithValue(selection),
    ],
  );
}

Future<void> ready(ProviderContainer container) async {
  container.listen(checkoutProvider(a.id), (_, _) {});
  container.listen(cartProvider(a.id), (_, _) {});
  container.listen(addressBookProvider, (_, _) {});
  await container.read(authSessionProvider.future);
  await container.read(checkoutProvider(a.id).future);
  await container.read(cartProvider(a.id).future);
  await container.read(addressBookProvider.future);
}

void main() {
  test(
    'expired quotes and transaction rejections require a fresh quote',
    () async {
      final auth = FakeAuthRepository()..setUser(a);
      final store = MemoryRequests();
      final backend = Backend(store)
        ..quoteLifetime = const Duration(seconds: -1);
      final container = providers(auth, store, backend);
      addTearDown(auth.close);
      addTearDown(container.dispose);
      await ready(container);
      final provider = checkoutProvider(a.id);
      final controller = container.read(provider.notifier);
      await controller.loadQuote();
      await controller.place();
      expect(backend.attempts, isEmpty);
      expect(
        container.read(provider).requireValue.message,
        contains('hết hạn'),
      );

      backend.quoteLifetime = const Duration(minutes: 2);
      for (final code in ['SF_CART_CHANGED', 'SF_STOCK_CHANGED']) {
        backend.nextError = OrdersFailure(code);
        await controller.loadQuote();
        await controller.place();
        expect(container.read(provider).requireValue.quote, isNull);
        expect(container.read(provider).requireValue.placed, isNull);
        expect(store.pending, isEmpty);
      }
    },
  );

  test('storage failure sends nothing; retry after restart reuses original request', () async {
    final auth = FakeAuthRepository()..setUser(a);
    final store = MemoryRequests();
    final backend = Backend(store);
    addTearDown(auth.close);

    final first = providers(auth, store, backend);
    await ready(first);
    final controller = first.read(checkoutProvider(a.id).notifier);
    await controller.loadQuote();
    store.failSave = true;
    await controller.place();
    expect(backend.attempts, isEmpty);
    store.failSave = false;
    backend.nextError = TimeoutException('no response');
    await controller.place();
    final saved = store.pending[a.id]!;
    expect(first.read(checkoutProvider(a.id)).requireValue.placed, isNull);
    first.dispose();

    final restarted = providers(auth, store, backend);
    addTearDown(restarted.dispose);
    await ready(restarted);
    expect(
      restarted.read(checkoutProvider(a.id)).requireValue.pending?.requestId,
      saved.requestId,
    );
    await restarted.read(checkoutProvider(a.id).notifier).recover();
    expect(backend.attempts, [
      (a.id, saved.requestId),
      (a.id, saved.requestId),
    ]);
    expect(
      restarted.read(checkoutProvider(a.id)).requireValue.placed?.number,
      'SF-000001',
    );
    expect(store.pending, isEmpty);
  });

  testWidgets(
    'checkout uses server quote and isolates pending requests A → B → A',
    (tester) async {
      final auth = FakeAuthRepository()..setUser(a);
      final store = MemoryRequests();
      final backend = Backend(store);
      final container = providers(auth, store, backend);
      addTearDown(auth.close);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CheckoutPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lấy báo giá'));
      await tester.pumpAndSettle();
      expect(find.text('Áo từ báo giá'), findsOneWidget);
      expect(find.textContaining('473.000'), findsWidgets);
      expect(find.textContaining('25.000'), findsWidgets);

      backend.nextResponse = Completer<PlacedOrder>();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Đặt hàng COD · 473.000đ'),
      );
      await tester.pump();
      final saved = store.pending[a.id]!;
      auth.setUser(b);
      await tester.pumpAndSettle();
      expect(find.text('Áo từ báo giá'), findsNothing);
      expect(find.text('Kiểm tra lại đơn hàng'), findsNothing);
      backend.nextResponse!.complete(backend.receipt(saved));
      await tester.pumpAndSettle();
      expect(find.text('SF-000001'), findsNothing);
      auth.setUser(a);
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra lại đơn hàng'), findsOneWidget);
      expect(store.pending[a.id]?.requestId, saved.requestId);
      expect(store.pending[b.id], isNull);
    },
  );
}

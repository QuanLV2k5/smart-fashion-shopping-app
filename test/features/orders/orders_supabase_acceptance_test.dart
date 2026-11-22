import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_fashion/core/services/supabase_provider.dart';
import 'package:smart_fashion/features/addresses/presentation/address_providers.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/orders/data/checkout_request_store_io.dart';
import 'package:smart_fashion/features/orders/data/supabase_orders_repository.dart';
import 'package:smart_fashion/features/orders/domain/checkout.dart';
import 'package:smart_fashion/features/orders/domain/orders.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_providers.dart';

import '../addresses/address_fixtures.dart' show MemorySelection;

class _DropCheckoutReply extends http.BaseClient {
  final _inner = http.Client();
  bool enabled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (enabled && request.url.path == '/rest/v1/rpc/place_cod_order') {
      enabled = false;
      await response.stream.drain<void>();
      if (response.statusCode != 200) {
        throw StateError(
          'Fixture expected checkout to commit before losing its reply',
        );
      }
      throw http.ClientException('Test disconnected after checkout commit');
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

Uri _loopback(String value, Set<String> schemes) {
  final uri = Uri.parse(value);
  if (!schemes.contains(uri.scheme) ||
      !{'localhost', '127.0.0.1', '::1'}.contains(uri.host) ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw ArgumentError(
      'Orders acceptance requires disposable loopback Supabase',
    );
  }
  return uri;
}

Future<void> _sql(Uri database, String statement) async {
  final run = await Process.run('psql', [
    '-X',
    '-q',
    '-v',
    'ON_ERROR_STOP=1',
    '--dbname',
    database.toString(),
    '-c',
    statement,
  ]);
  expect(run.exitCode, 0, reason: 'Local fixture SQL failed');
}

String _uuid(Object? value) {
  if (value is! String || !RegExp(r'^[0-9a-f-]{36}$').hasMatch(value)) {
    throw const FormatException('Expected fixture UUID');
  }
  return value;
}

Matcher _failure(String code) =>
    isA<OrdersFailure>().having((error) => error.code, 'code', code);

void main() {
  final statusFile = Platform.environment['ORDERS_SUPABASE_STATUS'];
  test(
    'real Supabase checkout, recovery, account isolation and state transitions',
    () async {
      final settings = orderObject(
        jsonDecode(await File(statusFile!).readAsString()),
      );
      final api = _loopback(orderField<String>(settings, 'API_URL'), {
        'http',
        'https',
      });
      final db = _loopback(orderField<String>(settings, 'DB_URL'), {
        'postgres',
        'postgresql',
      });
      final anon = orderField<String>(settings, 'ANON_KEY');
      final service = orderField<String>(settings, 'SERVICE_ROLE_KEY');
      final directory = await Directory.systemTemp.createTemp(
        'orders-acceptance-',
      );
      addTearDown(() => directory.delete(recursive: true));

      Future<({String email, String password, String id})> createUser(
        String label,
      ) async {
        final email = 'flutter-orders-$label-${const Uuid().v4()}@example.com';
        final password = const Uuid().v4();
        final response = await http.post(
          api.resolve('/auth/v1/admin/users'),
          headers: {
            'apikey': service,
            'Authorization': 'Bearer $service',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'email_confirm': true,
          }),
        );
        expect(response.statusCode, isIn([200, 201]));
        return (
          email: email,
          password: password,
          id: _uuid(orderObject(jsonDecode(response.body))['id']),
        );
      }

      final a = await createUser('a');
      final b = await createUser('b');
      final admin = await createUser('admin');
      await _sql(
        db,
        "update public.user_roles set role = 'admin' where user_id = '${admin.id}'",
      );
      final adminClient = SupabaseClient(
        api.toString(),
        anon,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(adminClient.dispose);
      await adminClient.auth.signInWithPassword(
        email: admin.email,
        password: admin.password,
      );
      final manager = SupabaseOrdersRepository(adminClient);
      final variant = await adminClient
          .from('product_variants')
          .select('id')
          .eq('sku', 'SF01-WHITE-M')
          .single();
      final variantId = _uuid(variant['id']);

      Future<Map<String, dynamic>> inventory() => adminClient
          .from('product_variants')
          .select('stock,stock_revision')
          .eq('id', variantId)
          .single();

      Future<void> setStock(int value) async {
        final current = await inventory();
        await adminClient.rpc<dynamic>(
          'set_variant_stock',
          params: {
            'p_variant_id': variantId,
            'p_expected_revision': current['stock_revision'],
            'p_new_stock': value,
          },
        );
      }

      final selection = MemorySelection();
      final transport = _DropCheckoutReply();
      final customer = SupabaseClient(
        api.toString(),
        anon,
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(customer.dispose);

      Future<void> login(
        ({String email, String password, String id}) user,
      ) async {
        // Use the same SDK instance so Riverpod sees the actual account events.
        if (customer.auth.currentSession != null) {
          await customer.auth.signOut(scope: SignOutScope.local);
        }
        await customer.auth.signInWithPassword(
          email: user.email,
          password: user.password,
        );
      }

      await login(a);
      final address = await customer
          .from('addresses')
          .insert({
            'recipient_name': 'Flutter Fixture A',
            'phone': '0900000001',
            'address_line': '1 Fixture Street',
            'ward': 'Fixture Ward',
            'district': 'Fixture District',
            'city': 'Fixture City',
          })
          .select('id')
          .single();
      selection.values[a.id] = _uuid(address['id']);

      ProviderContainer start() {
        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(customer),
            checkoutRequestStoreProvider.overrideWithValue(
              FileCheckoutRequestStore(() async => directory),
            ),
            addressSelectionStoreProvider.overrideWithValue(selection),
          ],
        );
        container.listen(authenticatedUserIdProvider, (_, _) {});
        container.listen(addressBookProvider, (_, _) {});
        return container;
      }

      var container = start();
      addTearDown(() => container.dispose());
      Future<void> waitForUser(String id) async {
        for (var attempt = 0; attempt < 50; attempt++) {
          await container.pump();
          if (container.read(authenticatedUserIdProvider) == id) return;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        fail('Unexpected active user');
      }

      Future<void> addCart() async {
        await customer.rpc<dynamic>(
          'mutate_cart',
          params: {
            'p_variant_id': variantId,
            'p_quantity': 1,
            'p_operation': 'add',
            'p_request_id': const Uuid().v4(),
          },
        );
        container.invalidate(cartProvider(a.id));
        await container.read(cartProvider(a.id).future);
      }

      await waitForUser(a.id);
      await setStock(1);
      await addCart();
      await container.read(addressBookProvider.future);
      final checkout = checkoutProvider(a.id);
      await container.read(checkout.future);
      var controller = container.read(checkout.notifier);

      await controller.loadQuote();
      final expiredId = _uuid(container.read(checkout).requireValue.quote?.id);
      await _sql(
        db,
        "update private.checkout_quotes set created_at=now()-interval '2 min', "
        "expires_at=now()-interval '1 min' where id='$expiredId'",
      );
      await controller.place();
      expect(
        container.read(checkout).requireValue.message,
        contains('hết hạn'),
      );

      await controller.loadQuote();
      await setStock(0);
      await controller.place();
      expect(
        container.read(checkout).requireValue.message,
        contains('không đủ tồn'),
      );
      expect(container.read(checkout).requireValue.pending, isNull);

      await setStock(1);
      await container.read(cartProvider(a.id).future);
      await controller.loadQuote();
      final quote = container.read(checkout).requireValue.quote!;
      expect(quote.totals.shipping, 25000);
      expect(quote.totals.total, 224000);
      transport.enabled = true;
      await controller.place();
      final saved = container.read(checkout).requireValue.pending!;
      expect(container.read(checkout).requireValue.placed, isNull);
      expect((await inventory())['stock'], 0);

      // Recreate the Flutter provider container and file store with the same data directory.
      container.dispose();
      container = start();
      await waitForUser(a.id);
      expect(
        (await container.read(checkout.future)).pending?.requestId,
        saved.requestId,
      );
      controller = container.read(checkout.notifier);
      await controller.recover();
      final placed = container.read(checkout).requireValue.placed!;
      final repository = container.read(checkoutRepositoryProvider);
      expect((await repository.place(a.id, saved)).id, placed.id);
      expect((await inventory())['stock'], 0);

      await login(b);
      await waitForUser(b.id);
      final orders = SupabaseOrdersRepository(customer);
      await expectLater(
        orders.detail(b.id, placed.id),
        throwsA(_failure('SF_ORDER_NOT_FOUND')),
      );
      await expectLater(
        orders.list(b.id, 'all', null, admin: true),
        throwsA(_failure('SF_FORBIDDEN')),
      );
      expect((await orders.list(b.id, 'all', null)).orders, isEmpty);
      expect(
        (await container.read(checkoutProvider(b.id).future)).pending,
        isNull,
      );
      await login(a);
      await waitForUser(a.id);
      expect(
        (await orders.list(a.id, 'all', null)).orders.single.id,
        placed.id,
      );
      expect(
        (await manager.list(
          admin.id,
          'pending',
          null,
          admin: true,
        )).orders.map((order) => order.id),
        contains(placed.id),
      );

      final first = OrderChange(
        orderId: placed.id,
        target: OrderStatus.cancelled,
        version: 1,
        requestId: const Uuid().v4(),
        reason: 'customer_requested',
      );
      final second = OrderChange(
        orderId: placed.id,
        target: OrderStatus.cancelled,
        version: 1,
        requestId: const Uuid().v4(),
        reason: 'cannot_fulfill',
      );
      Future<String> outcome(Future<void> action) async {
        try {
          await action;
          return 'ok';
        } on OrdersFailure catch (error) {
          return error.code;
        }
      }

      expect(
        await Future.wait([
          outcome(orders.change(a.id, first)),
          outcome(manager.change(admin.id, second)),
        ]),
        unorderedEquals(['ok', 'SF_ORDER_VERSION_CONFLICT']),
      );
      expect((await inventory())['stock'], 1);
      final detail = await manager.detail(admin.id, placed.id);
      expect(detail.status, OrderStatus.cancelled);
      expect(detail.events, hasLength(2));
    },
    skip: statusFile == null
        ? 'Set ORDERS_SUPABASE_STATUS to a disposable Supabase CLI status file'
        : false,
  );
}

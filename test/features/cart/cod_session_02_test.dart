import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/addresses/domain/address.dart';
import 'package:smart_fashion/features/addresses/presentation/address_providers.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/cart/domain/cart.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../addresses/address_fixtures.dart';
import '../auth/fake_auth_repository.dart';
import 'cart_fixtures.dart';

const customerA = FakeAuthRepository.user;
const customerB = AuthUser(
  id: 'customer-b',
  email: 'customer-b@example.com',
  fullName: 'Khách B',
  emailConfirmed: true,
);

class SessionCartRepository extends FakeCartRepository {
  SessionCartRepository(this.auth);

  final FakeAuthRepository auth;
  final loads = <String>[];
  Future<CartSnapshot>? nextCustomerALoad;

  @override
  Future<CartSnapshot> loadCart() async {
    final userId = auth.currentUser!.id;
    loads.add(userId);
    if (userId == customerA.id) {
      final pending = nextCustomerALoad;
      nextCustomerALoad = null;
      return pending ?? CartSnapshot([fixtureItem(whiteM, 2)]);
    }
    expect(userId, customerB.id);
    return CartSnapshot([fixtureItem(denimM, 1)]);
  }
}

Address customerAddress(String id, AuthUser user, String name) =>
    fixtureAddress(
      id,
      user.id,
      AddressDraft(
        recipientName: name,
        phone: draft.phone,
        addressLine: draft.addressLine,
        ward: draft.ward,
        district: draft.district,
        city: draft.city,
      ),
    );

void main() {
  test('signed-out session takes precedence over cached user', () async {
    final auth = FakeAuthRepository()..setUser(customerA);
    final session = StreamController<AuthUser?>();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authSessionProvider.overrideWith((ref) => session.stream),
      ],
    );
    addTearDown(auth.close);
    addTearDown(session.close);
    addTearDown(container.dispose);

    container.listen(currentCartUserIdProvider, (_, _) {});
    container.listen(addressUserIdProvider, (_, _) {});
    expect(container.read(currentCartUserIdProvider), customerA.id);
    expect(container.read(addressUserIdProvider), customerA.id);

    session.add(null);
    await container.read(authSessionProvider.future);
    expect(auth.currentUser?.id, customerA.id);
    expect(container.read(currentCartUserIdProvider), isNull);
    expect(container.read(addressUserIdProvider), isNull);
  });

  testWidgets('COD-SESSION-02: A → B → A isolates cart and addresses', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final cart = SessionCartRepository(auth);
    final addressA = customerAddress('a1', customerA, 'Người nhận A');
    final addressB = customerAddress('b1', customerB, 'Người nhận B');
    final addresses = FakeAddressRepository()
      ..rows.addAll([addressA, addressB]);
    final selection = MemorySelection()
      ..values[customerA.id] = addressA.id
      ..values[customerB.id] = addressB.id;
    final addressLoads = <String>[];
    Future<List<Address>>? nextCustomerAAddresses;
    addresses.onLoad = (userId) async {
      addressLoads.add(userId);
      if (userId == customerA.id && nextCustomerAAddresses != null) {
        final pending = nextCustomerAAddresses!;
        nextCustomerAAddresses = null;
        return pending;
      }
      return addresses.rows.where((row) => row.userId == userId).toList();
    };
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig()),
        authRepositoryProvider.overrideWithValue(auth),
        cartRepositoryProvider.overrideWithValue(cart),
        addressRepositoryProvider.overrideWithValue(addresses),
        addressSelectionStoreProvider.overrideWithValue(selection),
        catalogRepositoryProvider.overrideWithValue(DetailCatalogRepository()),
      ],
    );
    addTearDown(auth.close);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartFashionApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);

    Future<void> signIn(AuthUser customer) async {
      auth.onSignIn = () async => auth.setUser(customer);
      await tester.enterText(
        find.byKey(const ValueKey('email')),
        customer.email,
      );
      await tester.enterText(
        find.byKey(const ValueKey('password')),
        'test-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(auth.currentUser?.id, customer.id);
      router.go('/cart');
      await tester.pumpAndSettle();
    }

    Future<void> signOut() async {
      router.go('/account');
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Đăng xuất');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
    }

    void expectCart(
      Address own,
      Address other,
      String product,
      String otherProduct,
      int quantity,
    ) {
      expect(find.text(product), findsOneWidget);
      expect(find.text(otherProduct), findsNothing);
      expect(find.text('$quantity món trong giỏ'), findsOneWidget);
      expect(find.textContaining(own.details.recipientName), findsOneWidget);
      expect(find.textContaining(other.details.recipientName), findsNothing);
      final book = container.read(addressBookProvider).requireValue;
      expect(book.addresses.map((address) => address.id), [own.id]);
      expect(book.selected?.id, own.id);
    }

    router.go('/login');
    await tester.pumpAndSettle();
    await signIn(customerA);
    expectCart(addressA, addressB, shirt().name, jeans().name, 2);

    final lateCart = Completer<CartSnapshot>();
    final lateAddresses = Completer<List<Address>>();
    cart.nextCustomerALoad = lateCart.future;
    nextCustomerAAddresses = lateAddresses.future;
    container.invalidate(cartProvider(customerA.id));
    container.invalidate(addressBookProvider);
    await tester.pump();
    expect(cart.nextCustomerALoad, isNull);
    expect(nextCustomerAAddresses, isNull);

    await signOut();
    await signIn(customerB);
    expectCart(addressB, addressA, jeans().name, shirt().name, 1);

    final staleAddress = customerAddress('a-stale', customerA, 'Địa chỉ A cũ');
    lateCart.complete(CartSnapshot([fixtureItem(whiteM, 1)]));
    lateAddresses.complete([addressA, staleAddress]);
    await tester.pumpAndSettle();
    expectCart(addressB, addressA, jeans().name, shirt().name, 1);
    expect(
      find.textContaining(staleAddress.details.recipientName),
      findsNothing,
    );

    final previousCartLoads = cart.loads.length;
    final previousAddressLoads = addressLoads.length;
    await signOut();
    await signIn(customerA);
    expectCart(addressA, addressB, shirt().name, jeans().name, 2);
    expect(cart.loads.skip(previousCartLoads), contains(customerA.id));
    expect(addressLoads.skip(previousAddressLoads), contains(customerA.id));
    expect(selection.values, {
      customerA.id: addressA.id,
      customerB.id: addressB.id,
    });
  });
}

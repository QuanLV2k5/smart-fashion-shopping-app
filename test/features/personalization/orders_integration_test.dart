import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/core/services/supabase_provider.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/auth/presentation/login_page.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_page.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_providers.dart';
import 'package:smart_fashion/features/orders/presentation/my_orders_page.dart';
import 'package:smart_fashion/features/orders/presentation/order_detail_page.dart';
import 'package:smart_fashion/features/orders/presentation/orders_providers.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';
import 'package:smart_fashion/features/personalization/presentation/admin_users_page.dart';
import 'package:smart_fashion/features/personalization/presentation/account_access_gate.dart';
import 'package:smart_fashion/features/personalization/presentation/favorites_page.dart';
import 'package:smart_fashion/features/personalization/presentation/personalization_providers.dart';
import 'package:smart_fashion/features/personalization/presentation/reviews_page.dart';

import '../auth/fake_auth_repository.dart';
import '../catalog/catalog_fixtures.dart';
import '../orders/checkout_test.dart' show MemoryRequests;
import '../orders/my_orders_test.dart' show OrdersBackend;
import 'personalization_fixtures.dart';
import 'personalization_test.dart' show accountA, accountB;
import 'account_access_gate_test.dart' show ConfiguredBackend;

Future<ProviderContainer> mountIntegratedAccount(
  WidgetTester tester,
  FakeAuthRepository auth,
  OrdersBackend orders,
) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(auth),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ordersRepositoryProvider.overrideWithValue(orders),
      checkoutRequestStoreProvider.overrideWithValue(MemoryRequests()),
      personalizationRepositoryProvider.overrideWithValue(
        FakePersonalizationRepository()..page = reviewPage(eligible: true),
      ),
      accountAccessProvider.overrideWith((ref) async {
        final userId = ref.watch(authenticatedUserIdProvider);
        return AccountAccess(userId: userId, admin: userId == accountA.id);
      }),
    ],
  );
  addTearDown(auth.close);
  addTearDown(container.dispose);
  container.read(appRouterProvider).go('/account');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SmartFashionApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'offline private guard can open the public store without signing out',
    (tester) async {
      final auth = FakeAuthRepository()..session = accountA;
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig()),
          supabaseClientProvider.overrideWithValue(ConfiguredBackend()),
          authRepositoryProvider.overrideWithValue(auth),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          personalizationRepositoryProvider.overrideWithValue(
            FakePersonalizationRepository(),
          ),
          accountAccessProvider.overrideWith(
            (ref) async =>
                throw const PersonalizationFailure('SF_REQUEST_FAILED'),
          ),
        ],
      );
      addTearDown(auth.close);
      addTearDown(container.dispose);
      container.read(appRouterProvider).go('/account');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SmartFashionApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa kiểm tra được tài khoản'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Xem cửa hàng'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/');
      expect(find.text('Đơn giản.\nĐúng chất bạn.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('merged Account opens Orders, Favorites and both admin modules', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..session = accountA;
    final backend = OrdersBackend()..admins.add(accountA.id);
    final container = await mountIntegratedAccount(tester, auth, backend);
    final router = container.read(appRouterProvider);
    final destinations = {
      'Đơn hàng của tôi': '/account/orders',
      'Sản phẩm yêu thích': '/favorites',
      'Quản lý đơn hàng': '/admin/orders',
      'Quản lý người dùng': '/admin/users',
    };
    for (final menu in destinations.entries) {
      router.go('/account');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_profile_button')), findsOneWidget);
      expect(find.text('Sổ địa chỉ'), findsOneWidget);
      for (final title in destinations.keys) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.ensureVisible(find.text(menu.key));
      await tester.tap(find.text(menu.key));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, menu.value);
      switch (menu.value) {
        case '/account/orders':
        case '/admin/orders':
          expect(find.byType(MyOrdersPage), findsOneWidget);
        case '/favorites':
          expect(find.byType(FavoritesPage), findsOneWidget);
        case '/admin/users':
          expect(find.byType(AdminUsersPage), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    expect(backend.adminCalls, isNotEmpty);
    router.go('/products/SF01/reviews');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AccountAccessGate>(find.byType(AccountAccessGate))
          .publicCatalog,
      isTrue,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Viết đánh giá'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewFormPage), findsOneWidget);
    expect(
      tester
          .widget<AccountAccessGate>(find.byType(AccountAccessGate))
          .publicCatalog,
      isFalse,
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AccountAccessGate>(find.byType(AccountAccessGate))
          .publicCatalog,
      isTrue,
    );
    for (final entry in {
      '/checkout': CheckoutPage,
      '/account/orders/order-id': OrderDetailPage,
      '/admin/orders/order-id': OrderDetailPage,
      '/products/SF01/reviews': ReviewsPage,
      '/products/SF01/review': ReviewFormPage,
    }.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets(
    'merged protected routes redirect guests without fetching Orders',
    (tester) async {
      final backend = OrdersBackend();
      final container = await mountIntegratedAccount(
        tester,
        FakeAuthRepository(),
        backend,
      );
      final router = container.read(appRouterProvider);
      for (final route in [
        '/checkout',
        '/account/orders',
        '/admin/orders',
        '/favorites',
        '/admin/users',
        '/products/SF01/review',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget, reason: route);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['next'],
          route,
        );
      }
      expect(backend.calls, isEmpty);
      expect(backend.detailReads, isEmpty);
    },
  );

  testWidgets('both admin menus follow the same current account A to B to A', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..session = accountA;
    final backend = OrdersBackend()..admins.add(accountA.id);
    await mountIntegratedAccount(tester, auth, backend);
    expect(find.text('Quản lý đơn hàng'), findsOneWidget);
    expect(find.text('Quản lý người dùng'), findsOneWidget);
    auth.setUser(accountB);
    await tester.pumpAndSettle();
    expect(find.text('Quản lý đơn hàng'), findsNothing);
    expect(find.text('Quản lý người dùng'), findsNothing);
    expect(find.text('Đơn hàng của tôi'), findsOneWidget);
    expect(find.text('Sản phẩm yêu thích'), findsOneWidget);
    auth.setUser(accountA);
    await tester.pumpAndSettle();
    expect(find.text('Quản lý đơn hàng'), findsOneWidget);
    expect(find.text('Quản lý người dùng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

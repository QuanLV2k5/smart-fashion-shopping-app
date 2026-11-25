import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/admin/domain/admin_models.dart';
import 'package:smart_fashion/features/admin/presentation/admin_providers.dart';
import 'package:smart_fashion/features/auth/domain/user_role.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_page.dart';
import 'package:smart_fashion/features/orders/presentation/checkout_providers.dart';
import 'package:smart_fashion/features/orders/presentation/my_orders_page.dart';
import 'package:smart_fashion/features/orders/presentation/orders_providers.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';
import 'package:smart_fashion/features/personalization/presentation/admin_users_page.dart';
import 'package:smart_fashion/features/personalization/presentation/favorites_page.dart';
import 'package:smart_fashion/features/personalization/presentation/personalization_providers.dart';

import '../auth/fake_auth_repository.dart';
import '../catalog/catalog_fixtures.dart';
import '../orders/checkout_test.dart' show MemoryRequests;
import '../orders/my_orders_test.dart' show OrdersBackend;
import '../personalization/personalization_fixtures.dart';
import '../personalization/personalization_test.dart' show accountA, accountB;
import 'admin_flow_test.dart' show FakeAdminRepository;

void main() {
  testWidgets(
    'Merged Router & Account preserve Orders, Favorites, Admin Users and Admin Catalog',
    (tester) async {
      final auth = FakeAuthRepository()..session = accountA;
      final ordersBackend = OrdersBackend()..admins.add(accountA.id);
      final adminRepo = FakeAdminRepository(
        initialCategories: const [
          AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
        ],
        initialProducts: [
          AdminProduct(
            id: 'p1',
            code: 'SF01',
            categoryId: 'c1',
            name: 'Áo Sơ Mi Linen',
            description: 'Mô tả',
            material: 'Linen',
            priceVnd: 249000,
            imagePaths: const [],
            isVisible: true,
            variants: const [
              AdminVariant(
                id: 'v1',
                productId: 'p1',
                sku: 'SF01_M',
                size: 'M',
                color: 'Trắng',
                stock: 10,
                stockRevision: 1,
              ),
            ],
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig()),
          authRepositoryProvider.overrideWithValue(auth),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          ordersRepositoryProvider.overrideWithValue(ordersBackend),
          checkoutRequestStoreProvider.overrideWithValue(MemoryRequests()),
          personalizationRepositoryProvider.overrideWithValue(
            FakePersonalizationRepository()..page = reviewPage(eligible: true),
          ),
          adminRepositoryProvider.overrideWithValue(adminRepo),
          adminRoleForUserProvider.overrideWith(
            (ref, userId) async =>
                userId == accountA.id ? UserRole.admin : UserRole.customer,
          ),
          accountAccessProvider.overrideWith((ref) async {
            final userId = ref.watch(authenticatedUserIdProvider);
            return AccountAccess(userId: userId, admin: userId == accountA.id);
          }),
        ],
      );
      addTearDown(auth.close);
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      router.go('/account');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SmartFashionApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Account hiển thị đủ các lối vào của cả Orders, Personalization và Admin Catalog
      final menuToRoute = {
        'Sổ địa chỉ': '/addresses',
        'Đơn hàng của tôi': '/account/orders',
        'Sản phẩm yêu thích': '/favorites',
        'Quản trị cửa hàng': '/admin',
        'Quản lý đơn hàng': '/admin/orders',
        'Quản lý người dùng': '/admin/users',
      };

      for (final entry in menuToRoute.entries) {
        router.go('/account');
        await tester.pumpAndSettle();
        final item = find.text(entry.key);
        expect(item, findsOneWidget);
        await tester.ensureVisible(item);
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, entry.value);
      }

      // Kiểm tra các route chính sau merge vẫn mở đúng widget
      router.go('/checkout');
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutPage), findsOneWidget);

      router.go('/account/orders');
      await tester.pumpAndSettle();
      expect(find.byType(MyOrdersPage), findsOneWidget);

      router.go('/favorites');
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesPage), findsOneWidget);

      router.go('/admin/users');
      await tester.pumpAndSettle();
      expect(find.byType(AdminUsersPage), findsOneWidget);

      router.go('/admin/products');
      await tester.pumpAndSettle();
      expect(find.text('Quản lý Sản phẩm & Kho'), findsOneWidget);
      expect(find.text('Áo Sơ Mi Linen'), findsOneWidget);

      router.go('/admin/products/p1/edit');
      await tester.pumpAndSettle();
      expect(find.text('Sửa thông tin sản phẩm'), findsOneWidget);
      expect(find.text('SF01'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Customer is blocked from Admin area and switching Admin -> Customer drops admin rights immediately',
    (tester) async {
      final auth = FakeAuthRepository()..session = accountA;
      final ordersBackend = OrdersBackend()..admins.add(accountA.id);
      final adminRepo = FakeAdminRepository();
      final customerRoleCompleter = Completer<UserRole>();

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig()),
          authRepositoryProvider.overrideWithValue(auth),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          ordersRepositoryProvider.overrideWithValue(ordersBackend),
          checkoutRequestStoreProvider.overrideWithValue(MemoryRequests()),
          personalizationRepositoryProvider.overrideWithValue(
            FakePersonalizationRepository(),
          ),
          adminRepositoryProvider.overrideWithValue(adminRepo),
          adminRoleForUserProvider.overrideWith((ref, userId) {
            if (userId == accountA.id) return Future.value(UserRole.admin);
            return customerRoleCompleter.future;
          }),
          accountAccessProvider.overrideWith((ref) async {
            final userId = ref.watch(authenticatedUserIdProvider);
            return AccountAccess(userId: userId, admin: userId == accountA.id);
          }),
        ],
      );
      addTearDown(auth.close);
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      router.go('/account');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SmartFashionApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Ban đầu tài khoản A là Admin -> thấy menu Quản trị cửa hàng
      expect(find.text('Quản trị cửa hàng'), findsOneWidget);
      expect(container.read(isCurrentUserAdminProvider), isTrue);

      // Chuyển sang tài khoản B (Customer) trong khi role của B vẫn đang tải
      auth.setUser(accountB);
      await tester.pump();
      await tester.pump();

      // Ngay lập tức không được giữ quyền Admin của tài khoản A
      expect(container.read(isCurrentUserAdminProvider), isFalse);
      expect(find.text('Quản trị cửa hàng'), findsNothing);

      // Hoàn tất trả về role customer cho tài khoản B
      customerRoleCompleter.complete(UserRole.customer);
      await tester.pumpAndSettle();

      expect(container.read(isCurrentUserAdminProvider), isFalse);
      expect(find.text('Quản trị cửa hàng'), findsNothing);
      expect(find.text('Quản lý đơn hàng'), findsNothing);
      expect(find.text('Quản lý người dùng'), findsNothing);

      // Customer truy cập trực tiếp các route Admin bị chặn
      for (final path in [
        '/admin',
        '/admin/categories',
        '/admin/products',
        '/admin/products/p1/edit',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.text('Quyền truy cập bị giới hạn'), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

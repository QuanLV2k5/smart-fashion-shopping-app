import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/app/router/auth_redirect.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../auth/fake_auth_repository.dart';
import 'cart_fixtures.dart';

Future<ProviderContainer> pumpDetail(
  WidgetTester tester,
  FakeCartRepository cart, {
  bool signedIn = true,
  bool missing = false,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository()
    ..session = signedIn ? FakeAuthRepository.user : null;
  final catalog = DetailCatalogRepository()..missing = missing;
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(auth),
      cartRepositoryProvider.overrideWithValue(cart),
      catalogRepositoryProvider.overrideWithValue(catalog),
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
  container.read(appRouterProvider).go('/products/$shirtId');
  await tester.pumpAndSettle();
  return container;
}

Future<void> selectWhiteM(WidgetTester tester) async {
  for (final key in ['size-M', 'color-Trắng ngà']) {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

void main() {
  test(
    'auth return chấp nhận product/variant và cart, chặn URL ngoài/query lạ',
    () {
      expect(authDestination('/cart'), '/cart');
      expect(
        authDestination('/products/$shirtId?variant=$whiteM'),
        '/products/$shirtId?variant=$whiteM',
      );
      for (final url in [
        '//evil.example/products/id',
        'https://evil.example',
        '/products/../account',
        '/products/$shirtId?next=https://evil.example',
        '/products/$shirtId#fragment',
        '/products/$shirtId?variant=a&variant=b',
      ]) {
        expect(authDestination(url), '/account');
      }
    },
  );
  testWidgets(
    'chặn thiếu lựa chọn/XL hết tồn; thêm, xem giỏ, đổi số lượng và xóa',
    (tester) async {
      final cart = FakeCartRepository();
      await pumpDetail(tester, cart);
      await tester.tap(find.text('Chọn size và màu'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn hãy chọn đủ kích thước và màu sắc trước khi thêm giỏ.'),
        findsOneWidget,
      );
      expect(cart.requests, isEmpty);
      final xl = find.descendant(
        of: find.byKey(const ValueKey('size-XL')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(xl).onPressed, isNull);
      await selectWhiteM(tester);
      await tester.tap(find.text('Thêm vào giỏ · 199.000đ'));
      await tester.pumpAndSettle();
      expect(find.text('Đã thêm vào giỏ'), findsOneWidget);
      expect(cart.requests.single.variantId, whiteM);
      await tester.tap(find.text('Xem giỏ hàng'));
      await tester.pumpAndSettle();
      expect(find.text('1 món trong giỏ'), findsOneWidget);
      await tester.tap(find.byTooltip('Tăng số lượng Áo thun Essential'));
      await tester.pumpAndSettle();
      expect(find.text('Tiền sản phẩm: 398.000đ'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Tăng số lượng Áo thun Essential',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Giảm số lượng Áo thun Essential'));
      await tester.pumpAndSettle();
      expect(find.text('Tiền sản phẩm: 199.000đ'), findsOneWidget);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có món nào trong giỏ'), findsOneWidget);
    },
  );
  testWidgets('khách đăng nhập quay về đúng biến thể và cần bấm thêm lại', (
    tester,
  ) async {
    final cart = FakeCartRepository();
    await pumpDetail(tester, cart, signedIn: false);
    await selectWhiteM(tester);
    await tester.tap(find.text('Thêm vào giỏ · 199.000đ'));
    await tester.pumpAndSettle();
    expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password')),
      'test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
    expect(find.text('Thêm vào giỏ · 199.000đ'), findsOneWidget);
    expect(cart.requests, isEmpty);
    await tester.tap(find.text('Thêm vào giỏ · 199.000đ'));
    await tester.pumpAndSettle();
    expect(cart.requests.single.variantId, whiteM);
    expect(find.text('Đã thêm vào giỏ'), findsOneWidget);
  });
  testWidgets(
    'gallery đổi ảnh, bảng size mở được, hàng ngừng bán có lối quay lại',
    (tester) async {
      final container = await pumpDetail(tester, FakeCartRepository());
      await tester.tap(find.byTooltip('Xem ảnh 2'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2 · Chạm để xem ảnh'), findsOneWidget);
      await tester.ensureVisible(find.text('Bảng size'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bảng size'));
      await tester.pumpAndSettle();
      expect(find.text('Hướng dẫn chọn size'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng bảng size'));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/products/missing');
      await tester.pumpAndSettle();
      expect(find.text('Sản phẩm không còn được bán'), findsOneWidget);
      await tester.tap(find.text('Khám phá sản phẩm'));
      await tester.pumpAndSettle();
      expect(find.text('Tìm món dành cho bạn.'), findsOneWidget);
    },
  );
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('chi tiết/giỏ/bảng size không tràn với chữ lớn ở $width', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final cart = FakeCartRepository()..quantities[whiteM] = 1;
      final container = await pumpDetail(tester, cart, width: width);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Bảng size'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bảng size'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Đóng bảng size'));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/cart');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('1 món trong giỏ'), findsOneWidget);
    });
  }
}

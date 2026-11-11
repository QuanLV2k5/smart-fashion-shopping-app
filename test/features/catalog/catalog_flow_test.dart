import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/catalog/domain/catalog.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import 'catalog_fixtures.dart';

Future<ProviderContainer> pumpCatalog(
  WidgetTester tester,
  FakeCatalogRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      catalogRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SmartFashionApp(),
    ),
  );
  await tester.pump();
  return container;
}

Finder outlined(String text) => find.widgetWithText(OutlinedButton, text);

void main() {
  testWidgets(
    'khách xem Home, mở Explore dùng chung một lần tải và mở chi tiết',
    (tester) async {
      final repository = FakeCatalogRepository();
      final container = await pumpCatalog(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Đơn giản.\nĐúng chất bạn.'), findsOneWidget);
      await tester.tap(find.text('Khám phá bộ sưu tập'));
      await tester.pumpAndSettle();
      expect(find.text('3 sản phẩm · Đề xuất'), findsOneWidget);
      expect(repository.calls, 1);
      await tester.enterText(
        find.byKey(const ValueKey('catalog-search')),
        'ao thun',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 sản phẩm · Đề xuất'), findsOneWidget);
      await tester.ensureVisible(find.text('Áo thun Essential'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áo thun Essential'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
      expect(find.byKey(const ValueKey('size-XL')), findsOneWidget);
      container.read(appRouterProvider).go('/account');
      await tester.pumpAndSettle();
      expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
    },
  );
  testWidgets(
    'bộ lọc chỉ áp dụng sau xác nhận, tìm rỗng và đặt lại hoạt động',
    (tester) async {
      final container = await pumpCatalog(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/explore');
      await tester.pumpAndSettle();
      await tester.tap(outlined('Lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dưới 300k'));
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('3 sản phẩm · Đề xuất'), findsOneWidget);
      await tester.tap(outlined('Lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dưới 300k'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('2 sản phẩm · Đề xuất'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('catalog-search')),
        'xyz',
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa tìm thấy món phù hợp'), findsOneWidget);
      await tester.ensureVisible(find.text('Tìm lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tìm lại'));
      await tester.pumpAndSettle();
      expect(find.text('3 sản phẩm · Đề xuất'), findsOneWidget);
      await tester.tap(outlined('Sắp xếp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giá giảm dần'));
      await tester.pumpAndSettle();
      expect(find.text('3 sản phẩm · Giá giảm dần'), findsOneWidget);
    },
  );
  testWidgets('đang tải, lỗi và thử lại không cần khởi động lại app', (
    tester,
  ) async {
    final pending = Completer<CatalogSnapshot>();
    final repository = FakeCatalogRepository()..onLoad = () => pending.future;
    await pumpCatalog(tester, repository);
    expect(find.text('Đang tìm những món dành cho bạn…'), findsOneWidget);
    pending.completeError(const CatalogFailure('Kiểm tra mạng rồi thử lại.'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được catalog'), findsOneWidget);
    repository.onLoad = null;
    await tester.tap(find.text('Thử tải lại'));
    await tester.pumpAndSettle();
    expect(find.text('Đơn giản.\nĐúng chất bạn.'), findsOneWidget);
    expect(repository.calls, 2);
  });
  testWidgets('làm mới lỗi giữ dữ liệu đã tải và báo đúng trạng thái', (
    tester,
  ) async {
    final repository = FakeCatalogRepository();
    final container = await pumpCatalog(tester, repository);
    await tester.pumpAndSettle();
    repository.onLoad = () async => throw const CatalogFailure('Mất mạng');
    await expectLater(
      container.refresh(catalogProvider.future),
      throwsA(isA<CatalogFailure>()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa cập nhật được sản phẩm'), findsOneWidget);
    expect(find.text('Đơn giản.\nĐúng chất bạn.'), findsOneWidget);
    repository.onLoad = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa cập nhật được sản phẩm'), findsNothing);
  });
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('Home/Explore/bộ lọc không tràn với chữ lớn ở $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await pumpCatalog(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      container.read(appRouterProvider).go('/explore');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(outlined('Lọc'));
      await tester.tap(outlined('Lọc'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

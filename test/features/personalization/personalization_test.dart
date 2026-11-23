import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/app/router/auth_redirect.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';
import 'package:smart_fashion/features/personalization/presentation/personalization_providers.dart';

import '../auth/fake_auth_repository.dart';
import '../catalog/catalog_fixtures.dart';
import 'personalization_fixtures.dart';

const accountA = AuthUser(
  id: 'user-a',
  email: 'a@example.test',
  fullName: 'Quân',
  emailConfirmed: true,
);
const accountB = AuthUser(
  id: 'user-b',
  email: 'b@example.test',
  fullName: 'Hải',
  emailConfirmed: true,
);

Future<ProviderContainer> pumpPersonalization(
  WidgetTester tester,
  FakePersonalizationRepository repository,
  String route, {
  FakeAuthRepository? auth,
  bool admin = false,
  GlobalKey? captureKey,
}) async {
  final authRepo = auth ?? (FakeAuthRepository()..session = accountA);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(authRepo),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      personalizationRepositoryProvider.overrideWithValue(repository),
      accountAccessProvider.overrideWith(
        (ref) async => AccountAccess(
          userId: ref.watch(personalizationUserIdProvider),
          admin:
              admin && ref.watch(personalizationUserIdProvider) == accountA.id,
        ),
      ),
    ],
  );
  addTearDown(authRepo.close);
  addTearDown(container.dispose);
  container.read(appRouterProvider).go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: captureKey, child: const SmartFashionApp()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('return destinations allow only implemented internal pages', () {
    expect(authDestination('/favorites'), '/favorites');
    expect(authDestination('/products/SF01/review'), '/products/SF01/review');
    expect(authDestination('/admin/users/u1'), '/admin/users/u1');
    expect(authDestination('//evil.test/products/SF01/review'), '/account');
    expect(authDestination('/admin/users/u1?role=admin'), '/account');
  });

  testWidgets(
    'favorites add/remove persists and hidden entries remain removable',
    (tester) async {
      final repo = FakePersonalizationRepository();
      final container = await pumpPersonalization(
        tester,
        repo,
        '/products/SF01',
      );
      await tester.ensureVisible(find.byTooltip('Thêm yêu thích'));
      await tester.ensureVisible(find.byTooltip('Thêm yêu thích'));
      await tester.tap(find.byTooltip('Thêm yêu thích'));
      await tester.pumpAndSettle();
      expect(repo.saved['user-a']?.length, 1);
      container.read(appRouterProvider).go('/favorites');
      await tester.pumpAndSettle();
      expect(find.text('Áo thun Essential'), findsOneWidget);
      await tester.tap(find.byTooltip('Bỏ yêu thích'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có món yêu thích'), findsOneWidget);
      repo.saved['user-a'] = [const FavoriteEntry('hidden', null)];
      container.invalidate(favoritesProvider('user-a'));
      await tester.pumpAndSettle();
      expect(find.text('Sản phẩm không còn được bán'), findsOneWidget);
      await tester.tap(find.byTooltip('Bỏ yêu thích'));
      await tester.pumpAndSettle();
      expect(repo.saved['user-a'], isEmpty);
    },
  );

  testWidgets('failed favorite write keeps previous value and supports retry', (
    tester,
  ) async {
    final repo = FakePersonalizationRepository()..failSave = true;
    await pumpPersonalization(tester, repo, '/products/SF01');
    await tester.ensureVisible(find.byTooltip('Thêm yêu thích'));
    await tester.tap(find.byTooltip('Thêm yêu thích'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Thêm yêu thích'), findsOneWidget);
    expect(repo.saved['user-a'], isNull);
    repo.failSave = false;
    await tester.ensureVisible(find.byTooltip('Thêm yêu thích'));
    await tester.tap(find.byTooltip('Thêm yêu thích'));
    await tester.pumpAndSettle();
    expect(repo.saved['user-a']?.length, 1);
  });

  testWidgets(
    'late favorite write from A cannot populate B or the next A session',
    (tester) async {
      final pending = Completer<void>();
      final auth = FakeAuthRepository()..session = accountA;
      final repo = FakePersonalizationRepository()
        ..onFavoriteWrite = () => pending.future;
      final container = await pumpPersonalization(
        tester,
        repo,
        '/products/SF01',
        auth: auth,
      );
      await tester.ensureVisible(find.byTooltip('Thêm yêu thích'));
      await tester.tap(find.byTooltip('Thêm yêu thích'));
      await tester.pump();
      auth.setUser(accountB);
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/favorites');
      await tester.pumpAndSettle();
      expect(find.text('Chưa có món yêu thích'), findsOneWidget);
      auth.setUser(accountA);
      await tester.pumpAndSettle();
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        container.read(favoritesProvider('user-a')).requireValue.entries,
        isEmpty,
      );
      container.invalidate(favoritesProvider('user-a'));
      await tester.pumpAndSettle();
      expect(
        container.read(favoritesProvider('user-a')).requireValue.entries.length,
        1,
      );
    },
  );

  testWidgets('non-buyer sees no enabled review form and sends nothing', (
    tester,
  ) async {
    final repo = FakePersonalizationRepository();
    await pumpPersonalization(tester, repo, '/products/SF01/review');
    expect(find.byType(TextField), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Chọn số sao để gửi đánh giá'),
          )
          .onPressed,
      isNull,
    );
    expect(repo.reviewWrites, 0);
  });

  testWidgets('review stars, failed save, retry and saved result', (
    tester,
  ) async {
    final repo = FakePersonalizationRepository()
      ..page = reviewPage(eligible: true)
      ..failSave = true;
    await pumpPersonalization(tester, repo, '/products/SF01/review');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Chọn số sao để gửi đánh giá'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('5 sao'));
    await tester.enterText(find.byType(TextField), 'Chất liệu tốt, vừa size.');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi đánh giá'));
    await tester.pumpAndSettle();
    expect(find.text('Chất liệu tốt, vừa size.'), findsOneWidget);
    expect(find.text('Cảm ơn bạn đã chia sẻ!'), findsNothing);
    repo.failSave = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi đánh giá'));
    await tester.pumpAndSettle();
    expect(find.text('Cảm ơn bạn đã chia sẻ!'), findsOneWidget);
    expect(repo.page.mine?.rating, 5);
  });

  testWidgets('review edit loads previous text and rating', (tester) async {
    final repo = FakePersonalizationRepository()
      ..page = reviewPage(eligible: true, stars: 4, body: 'Đánh giá trước');
    await pumpPersonalization(tester, repo, '/products/SF01/review');
    expect(find.text('Đánh giá trước'), findsOneWidget);
    expect(find.text('Cập nhật đánh giá'), findsOneWidget);
  });

  testWidgets('changing account clears review draft and ignores late success', (
    tester,
  ) async {
    final pending = Completer<void>();
    final auth = FakeAuthRepository()..session = accountA;
    final repo = FakePersonalizationRepository()
      ..page = reviewPage(eligible: true)
      ..onReviewWrite = () => pending.future;
    await pumpPersonalization(
      tester,
      repo,
      '/products/SF01/review',
      auth: auth,
    );
    await tester.tap(find.byTooltip('5 sao'));
    await tester.enterText(find.byType(TextField), 'Bản nháp riêng của A');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi đánh giá'));
    await tester.pump();
    auth.setUser(accountB);
    await tester.pumpAndSettle();
    expect(find.text('Bản nháp riêng của A'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Cảm ơn bạn đã chia sẻ!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing account invalidates an open admin confirmation', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..session = accountA;
    final repo = FakePersonalizationRepository();
    await pumpPersonalization(
      tester,
      repo,
      '/admin/users/customer-b',
      auth: auth,
      admin: true,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tạm khóa truy cập'));
    await tester.pumpAndSettle();
    auth.setUser(accountB);
    await tester.pumpAndSettle();
    expect(find.text('Phiên làm việc đã thay đổi.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận'))
          .onPressed,
      isNull,
    );
    expect(repo.writes, 0);
  });

  testWidgets('customer cannot open admin deep link or fetch user data', (
    tester,
  ) async {
    final repo = FakePersonalizationRepository();
    await pumpPersonalization(tester, repo, '/admin/users/customer-b');
    expect(find.text('Mục này chỉ dành cho quản trị viên.'), findsOneWidget);
    expect(repo.userReads, 0);
  });

  testWidgets(
    'admin access requires confirmation and handles revision conflict',
    (tester) async {
      final repo = FakePersonalizationRepository()..failSave = true;
      await pumpPersonalization(
        tester,
        repo,
        '/admin/users/customer-b',
        admin: true,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Tạm khóa truy cập'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(find.textContaining('Trạng thái đã thay đổi'), findsOneWidget);
      repo.failSave = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Tạm khóa truy cập'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản đang tạm khóa'), findsOneWidget);
      expect(find.text('Mở lại truy cập'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('personalization screens fit $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = FakePersonalizationRepository()
        ..page = reviewPage(eligible: true);
      repo.saved['user-a'] = [FavoriteEntry('SF01', product())];
      final container = await pumpPersonalization(
        tester,
        repo,
        '/favorites',
        admin: true,
      );
      expect(tester.takeException(), isNull);
      for (final route in [
        '/products/SF01/reviews',
        '/products/SF01/review',
        '/admin/users',
        '/admin/users/customer-b',
      ]) {
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
}

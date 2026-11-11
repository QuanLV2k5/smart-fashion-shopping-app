import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/app/router/auth_redirect.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/addresses/domain/address.dart';
import 'package:smart_fashion/features/addresses/presentation/address_providers.dart';
import 'package:smart_fashion/core/theme/app_tokens.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../auth/fake_auth_repository.dart';
import '../cart/cart_fixtures.dart';
import 'address_fixtures.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  FakeAddressRepository repository, {
  double width = 390,
  double textScale = 1,
  String route = '/addresses',
  bool signedIn = true,
  bool settleRoute = true,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 28);
  tester.view.viewPadding = const FakeViewPadding(top: 28);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository()
    ..session = signedIn ? FakeAuthRepository.user : null;
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
      authRepositoryProvider.overrideWithValue(auth),
      addressRepositoryProvider.overrideWithValue(repository),
      addressSelectionStoreProvider.overrideWithValue(MemorySelection()),
      cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
      catalogRepositoryProvider.overrideWithValue(DetailCatalogRepository()),
    ],
  );
  addTearDown(auth.close);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('p02-review'),
        child: SmartFashionApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go(route);
  if (settleRoute) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
  return container;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('P02_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('p02-review')),
  );
  await tester.runAsync(() async {
    final picture = await boundary.toImage();
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    await Directory('build/p02-ui-review').create(recursive: true);
    await File('build/p02-ui-review/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
  await tester.pump();
}

void main() {
  testWidgets('tích hợp Account giữ cả Profile và Sổ địa chỉ', (tester) async {
    final repo = FakeAddressRepository()
      ..rows.add(fixtureAddress('a', 'test-id'));
    final container = await pumpApp(tester, repo, route: '/account');
    await tester.tap(find.byKey(const ValueKey('edit_profile_button')));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/account/profile',
    );
    container.read(appRouterProvider).go('/account');
    await tester.pumpAndSettle();
    await tapText(tester, 'Sổ địa chỉ');
    expect(find.text('Địa chỉ giao hàng'), findsOneWidget);
    expect(container.read(appRouterProvider).canPop(), isTrue);
    expect(find.text('Sửa địa chỉ'), findsOneWidget);
  });

  testWidgets('guest Profile deep link giữ đúng đích đăng nhập sau tích hợp', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      FakeAddressRepository(),
      route: '/account/profile',
      signedIn: false,
    );
    final uri = container
        .read(appRouterProvider)
        .routeInformationProvider
        .value
        .uri;
    expect(uri.path, '/login');
    expect(uri.queryParameters['next'], '/account/profile');
    expect(authDestination('/account/profile'), '/account/profile');
  });
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'màn thêm không có nút xóa, màn sửa có nút riêng và Hủy giữ bản nháp',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      final container = await pumpApp(tester, repo, route: '/addresses/new');
      expect(find.byKey(const ValueKey('delete-address')), findsNothing);
      container.read(appRouterProvider).go('/addresses/a/edit?from=cart');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Tên đang sửa');
      await tapText(tester, 'Xóa địa chỉ');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      await tapText(tester, 'Hủy');
      expect(repo.writes, 0);
      expect(find.text('Tên đang sửa'), findsOneWidget);
      expect(find.text('Lưu địa chỉ'), findsOneWidget);
    },
  );
  testWidgets(
    'xóa chờ server, khóa Lưu/Xóa, dọn lựa chọn và về đúng danh sách',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      final container = await pumpApp(
        tester,
        repo,
        route: '/addresses/a/edit?from=cart',
      );
      await container.read(addressBookProvider.notifier).select('a');
      await tester.pumpAndSettle();
      final pending = Completer<void>();
      repo.onDelete = (_, _) => pending.future;
      await tapText(tester, 'Xóa địa chỉ');
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Xóa địa chỉ'),
      );
      await tester.tap(confirm);
      await tester.pump();
      expect(repo.writes, 1);
      expect(repo.rows, hasLength(1));
      expect(container.read(addressBookProvider).requireValue.message, isNull);
      expect(find.text('Đã xóa địa chỉ.'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('delete-address')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Lưu địa chỉ'),
            )
            .onPressed,
        isNull,
      );
      expect(
        await container.read(addressBookProvider.notifier).delete('a'),
        isFalse,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(repo.rows, isEmpty);
      expect(find.byType(TextField), findsNothing);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/addresses/select',
      );
      expect(container.read(addressBookProvider).requireValue.selected, isNull);
      expect(find.text('Đã xóa địa chỉ.'), findsWidgets);
      expect(find.textContaining('Bạn chưa có địa chỉ'), findsOneWidget);
    },
  );
  testWidgets(
    'xóa thất bại giữ bản nháp và cho phép thử lại, không báo thành công',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      repo.deleteFailure = const AddressFailure(
        'Không thể xóa địa chỉ. Vui lòng thử lại.',
      );
      await pumpApp(tester, repo, route: '/addresses/a/edit');
      await tester.enterText(find.byType(TextField).first, 'Tên đang sửa');
      await tapText(tester, 'Xóa địa chỉ');
      await tapText(tester, 'Xóa địa chỉ');
      expect(repo.rows, hasLength(1));
      expect(find.text('Tên đang sửa'), findsOneWidget);
      expect(
        find.text('Không thể xóa địa chỉ. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Đã xóa địa chỉ.'), findsNothing);
      repo.deleteFailure = null;
      await tapText(tester, 'Xóa địa chỉ');
      await tapText(tester, 'Xóa địa chỉ');
      expect(repo.rows, isEmpty);
      expect(find.text('Đã xóa địa chỉ.'), findsWidgets);
    },
  );
  testWidgets(
    'đổi tài khoản trong hộp thoại xóa của form khóa xác nhận và ẩn thông tin',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      final container = await pumpApp(tester, repo, route: '/addresses/a/edit');
      await tapText(tester, 'Xóa địa chỉ');
      (container.read(authRepositoryProvider) as FakeAuthRepository).setUser(
        const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Tài khoản đã thay đổi. Vui lòng đóng hộp thoại.'),
        findsOneWidget,
      );
      expect(find.textContaining('12 Nguyễn Văn Linh'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Xóa địa chỉ'),
            )
            .onPressed,
        isNull,
      );
      expect(repo.writes, 0);
    },
  );
  for (final logout in [true, false]) {
    testWidgets(
      'đang xóa trong form rồi ${logout ? 'logout' : 'đổi user'}, không điều hướng/báo thành công phiên cũ',
      (tester) async {
        final repo = FakeAddressRepository()
          ..rows.addAll([
            fixtureAddress('a', 'test-id'),
            fixtureAddress('b', 'B'),
          ]);
        final container = await pumpApp(
          tester,
          repo,
          route: '/addresses/a/edit',
        );
        final pending = Completer<void>();
        repo.onDelete = (_, _) => pending.future;
        await tapText(tester, 'Xóa địa chỉ');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Xóa địa chỉ'),
          ),
        );
        await tester.pump();
        (container.read(authRepositoryProvider) as FakeAuthRepository).setUser(
          logout
              ? null
              : const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
        );
        await tester.pumpAndSettle();
        pending.complete();
        await tester.pumpAndSettle();
        expect(find.text('Đã xóa địa chỉ.'), findsNothing);
        expect(repo.rows.single.userId, 'B');
        expect(
          container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          logout ? '/login' : '/addresses/a/edit',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'server xóa xong, lỗi preferences vẫn rời form và hiển thị cảnh báo',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      final container = await pumpApp(
        tester,
        repo,
        route: '/addresses/a/edit?from=cart',
      );
      await container.read(addressBookProvider.notifier).select('a');
      await tester.pumpAndSettle();
      final store =
          container.read(addressSelectionStoreProvider) as MemorySelection;
      store.fail = true;
      await tapText(tester, 'Xóa địa chỉ');
      await tapText(tester, 'Xóa địa chỉ');
      expect(repo.rows, isEmpty);
      expect(find.byType(TextField), findsNothing);
      expect(container.read(addressBookProvider).requireValue.selected, isNull);
      expect(
        find.textContaining('chưa xóa được lựa chọn trên máy'),
        findsWidgets,
      );
    },
  );
  testWidgets(
    'Account mở sổ địa chỉ, quản lý nhiều địa chỉ không đổi lựa chọn',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.addAll([
          fixtureAddress('a', 'test-id'),
          fixtureAddress(
            'b',
            'test-id',
            const AddressDraft(
              recipientName: 'Hải',
              phone: '0912345678',
              addressLine: '20 Lê Lợi',
              ward: 'Hải Châu',
              district: 'Hải Châu',
              city: 'Đà Nẵng',
            ),
          ),
        ]);
      final container = await pumpApp(tester, repo, route: '/account');
      await tapText(tester, 'Sổ địa chỉ');
      expect(container.read(appRouterProvider).canPop(), isTrue);
      expect(find.text('Thêm địa chỉ'), findsOneWidget);
      expect(find.text('Sửa địa chỉ'), findsNWidgets(2));
      expect(find.text('Xóa'), findsNWidgets(2));
      expect(find.text('Giao tới địa chỉ này'), findsNothing);
      expect(container.read(addressBookProvider).requireValue.selected, isNull);
      await capture(tester, 'address-book-390');
      await tapText(tester, 'Xóa');
      await tapText(tester, 'Xóa địa chỉ');
      expect(repo.rows.single.id, 'a');
    },
  );
  testWidgets('chọn tạm/hủy không lưu; xác nhận lỗi vẫn ở Addresses', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..rows.addAll([
        fixtureAddress('a', 'test-id'),
        fixtureAddress('b', 'test-id'),
      ]);
    final container = await pumpApp(tester, repo, route: '/addresses/select');
    final confirm = find.widgetWithText(FilledButton, 'Giao tới địa chỉ này');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('address-card-a')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(container.read(addressBookProvider).requireValue.selected, isNull);
    await tapText(tester, 'Giỏ');
    expect(container.read(addressBookProvider).requireValue.selected, isNull);
    await tapText(tester, 'Chọn địa chỉ giao hàng');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('address-card-b')));
    await tester.pumpAndSettle();
    repo.onLoad = (_) async =>
        throw const AddressFailure('Không xác minh được địa chỉ');
    await tapText(tester, 'Giao tới địa chỉ này');
    expect(find.text('Địa chỉ giao hàng'), findsOneWidget);
    expect(find.text('Không xác minh được địa chỉ'), findsOneWidget);
    expect(container.read(addressBookProvider).requireValue.selected, isNull);
    expect(repo.writes, 0);
  });
  testWidgets('đổi tài khoản xóa lựa chọn tạm, không thể xác nhận địa chỉ cũ', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..rows.addAll([fixtureAddress('a', 'test-id'), fixtureAddress('b', 'B')]);
    final container = await pumpApp(tester, repo, route: '/addresses/select');
    await tester.tap(find.byKey(const ValueKey('address-card-a')));
    await tester.pumpAndSettle();
    (container.read(authRepositoryProvider) as FakeAuthRepository).setUser(
      const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('address-card-a')), findsNothing);
    expect(find.byKey(const ValueKey('address-card-b')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Giao tới địa chỉ này'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'lỗi chỉ ở trường sai, giữ dữ liệu và không tô đỏ khi server lỗi',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      await pumpApp(tester, repo, route: '/addresses/a/edit');
      final phone = find.byType(TextField).at(1);
      await tester.enterText(phone, 'abc');
      await tapText(tester, 'Lưu địa chỉ');
      expect(repo.writes, 0);
      expect(find.text('abc'), findsOneWidget);
      expect(
        find.text('Nhập 9–15 chữ số, có thể bắt đầu bằng +.'),
        findsOneWidget,
      );
      Color border(String label) =>
          ((tester
                              .widget<Container>(
                                find.byKey(ValueKey('address-input-$label')),
                              )
                              .decoration
                          as BoxDecoration)
                      .border!
                  as Border)
              .top
              .color;
      expect(border('Số điện thoại'), AppColors.error);
      for (final label in [
        'Người nhận',
        'Tỉnh / Thành phố',
        'Quận / Huyện',
        'Phường / Xã',
        'Địa chỉ cụ thể',
      ]) {
        expect(border(label), isNot(AppColors.error));
      }
      await capture(tester, 'address-error-390');
      await tester.enterText(phone, '0901234567');
      await tester.pumpAndSettle();
      repo.onSave = (_, _, _) async =>
          throw const AddressFailure('Máy chủ chưa lưu');
      await tapText(tester, 'Lưu địa chỉ');
      expect(find.text('Máy chủ chưa lưu'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(border('Số điện thoại'), isNot(AppColors.error));
    },
  );
  testWidgets(
    'form theo Figma: thứ tự nhãn, cao 76px, keyboard next/done và Giỏ',
    (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      final container = await pumpApp(tester, repo, route: '/addresses/a/edit');
      final labels = [
        'Người nhận',
        'Số điện thoại',
        'Tỉnh / Thành phố',
        'Quận / Huyện',
        'Phường / Xã',
        'Địa chỉ cụ thể',
      ];
      double previous = -1;
      for (final label in labels) {
        final field = find.byKey(ValueKey('address-input-$label'));
        expect(tester.getSize(field).height, 76);
        expect(tester.getTopLeft(field).dy, greaterThan(previous));
        previous = tester.getTopLeft(field).dy;
      }
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).keyboardType,
        TextInputType.phone,
      );
      await tester.showKeyboard(find.byType(TextField).first);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(1))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.showKeyboard(find.byType(TextField).last);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .focusNode!
            .hasFocus,
        isFalse,
      );
      await capture(tester, 'address-edit-390');
      await tapText(tester, 'Giỏ');
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/cart',
      );
    },
  );
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('thẻ địa chỉ/chọn/footer không tràn ở $width, chữ lớn', (
      tester,
    ) async {
      final repo = FakeAddressRepository()
        ..rows.add(
          fixtureAddress(
            'a',
            'test-id',
            AddressDraft(
              recipientName: 'Người nhận có tên rất dài để kiểm tra xuống dòng',
              phone: '+84901234567',
              addressLine: '470 Trần Đại Nghĩa',
              ward: 'Hòa Quý',
              district: 'Ngũ Hành Sơn',
              city: 'Đà Nẵng',
            ),
          ),
        );
      final container = await pumpApp(
        tester,
        repo,
        width: width,
        textScale: 2,
        route: '/addresses/select',
      );
      await tester.tap(find.byKey(const ValueKey('address-card-a')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Giao tới địa chỉ này'),
            )
            .onPressed,
        isNotNull,
      );
      await tapText(tester, 'Giao tới địa chỉ này');
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/cart',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('ảnh đối chiếu Addresses 390 với lựa chọn và CTA cố định', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..rows.add(
        fixtureAddress(
          'a',
          'test-id',
          const AddressDraft(
            recipientName: 'Lê Văn Quân',
            phone: '0901234567',
            addressLine: '470 Trần Đại Nghĩa',
            ward: 'Hòa Quý',
            district: 'Ngũ Hành Sơn',
            city: 'Đà Nẵng',
          ),
        ),
      );
    await pumpApp(tester, repo, route: '/addresses/select');
    await tester.tap(find.byKey(const ValueKey('address-card-a')));
    await tester.pumpAndSettle();
    await capture(tester, 'addresses-select-390');
    expect(find.text('Lê Văn Quân · 0901234567'), findsOneWidget);
  });
  testWidgets('đổi tài khoản khi xác nhận xóa ẩn dữ liệu của tài khoản cũ', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..rows.add(fixtureAddress('a', 'test-id'));
    final container = await pumpApp(tester, repo);
    await tapText(tester, 'Xóa');
    final auth = container.read(authRepositoryProvider) as FakeAuthRepository;
    auth.setUser(
      const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Tài khoản đã thay đổi. Vui lòng đóng hộp thoại.'),
      findsOneWidget,
    );
    expect(find.textContaining('12 Nguyễn Văn Linh'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Xóa địa chỉ'),
    );
    expect(button.onPressed, isNull);
    expect(repo.writes, 0);
  });
  testWidgets(
    'loading chờ server, chưa có lựa chọn thì không hiện địa chỉ cũ',
    (tester) async {
      final pending = Completer<List<Address>>();
      final repo = FakeAddressRepository()..onLoad = (_) => pending.future;
      await pumpApp(tester, repo, settleRoute: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang chọn'), findsNothing);
      pending.complete([]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn chưa có địa chỉ'), findsOneWidget);
    },
  );
  test('auth destination chỉ cho addresses không query/URL ngoài', () {
    expect(authDestination('/addresses'), '/addresses');
    expect(authDestination('/addresses/select'), '/addresses/select');
    expect(
      authDestination('/addresses/select?next=https://evil.example'),
      '/account',
    );
    expect(authDestination('/addresses?next=https://evil.example'), '/account');
  });
  testWidgets('Cart → Addresses → thêm/validation/sửa/chọn/xóa có hủy', (
    tester,
  ) async {
    final repo = FakeAddressRepository();
    final container = await pumpApp(tester, repo, route: '/cart');
    await tapText(tester, 'Chọn địa chỉ giao hàng');
    expect(find.textContaining('Bạn chưa có địa chỉ'), findsOneWidget);
    await tapText(tester, 'Thêm địa chỉ mới');
    await tapText(tester, 'Lưu địa chỉ');
    expect(repo.writes, 0);
    final values = [
      'Phúc',
      '0901234567',
      'Đà Nẵng',
      'Hải Châu',
      'Hải Châu',
      '12 Nguyễn Văn Linh',
    ];
    for (var i = 0; i < 6; i++) {
      final field = find.byType(TextField).at(i);
      await tester.ensureVisible(field);
      await tester.enterText(field, values[i]);
    }
    await tapText(tester, 'Lưu địa chỉ');
    expect(repo.rows, hasLength(1));
    await tapText(tester, 'Sửa địa chỉ');
    await tester.enterText(find.byType(TextField).first, 'Phúc mới');
    await tapText(tester, 'Lưu địa chỉ');
    expect(repo.rows.single.details.recipientName, 'Phúc mới');
    await tester.tap(
      find.byKey(ValueKey('address-card-${repo.rows.single.id}')),
    );
    await tester.pumpAndSettle();
    expect(container.read(addressBookProvider).requireValue.selected, isNull);
    await tapText(tester, 'Giao tới địa chỉ này');
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/cart',
    );
    expect(
      container
          .read(addressBookProvider)
          .requireValue
          .selected
          ?.details
          .recipientName,
      'Phúc mới',
    );
    container.read(appRouterProvider).go('/addresses');
    await tester.pumpAndSettle();
    await tapText(tester, 'Xóa');
    await tapText(tester, 'Hủy');
    expect(repo.rows, hasLength(1));
    await tapText(tester, 'Xóa');
    await tapText(tester, 'Xóa địa chỉ');
    expect(repo.rows, isEmpty);
  });
  testWidgets('form giữ nội dung sau lỗi ghi và có thể thử lại', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..rows.add(fixtureAddress('a', 'test-id'));
    repo.onSave = (_, _, _) async =>
        throw const AddressFailure('Không lưu được địa chỉ');
    await pumpApp(tester, repo, route: '/addresses/a/edit');
    await tester.enterText(find.byType(TextField).first, 'Tên đã sửa');
    await tapText(tester, 'Lưu địa chỉ');
    expect(find.text('Không lưu được địa chỉ'), findsOneWidget);
    expect(find.text('Tên đã sửa'), findsOneWidget);
    repo.onSave = null;
    await tapText(tester, 'Lưu địa chỉ');
    expect(repo.rows.single.details.recipientName, 'Tên đã sửa');
  });
  testWidgets('lỗi tải có thử lại; loading không hiện địa chỉ giả', (
    tester,
  ) async {
    final repo = FakeAddressRepository()
      ..onLoad = (_) async =>
          throw const AddressFailure('Không tải được địa chỉ');
    await pumpApp(tester, repo);
    expect(find.text('Không tải được địa chỉ'), findsOneWidget);
    repo.onLoad = null;
    await tapText(tester, 'Thử lại');
    expect(find.textContaining('Bạn chưa có địa chỉ'), findsOneWidget);
  });
  testWidgets('guest deep link chuyển login, không lộ địa chỉ', (tester) async {
    final repo = FakeAddressRepository();
    final container = await pumpApp(
      tester,
      repo,
      route: '/addresses/a/edit',
      signedIn: false,
    );
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
    expect(repo.loads, 0);
  });
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('form cuộn ở $width với chữ lớn và bàn phím', (tester) async {
      final repo = FakeAddressRepository()
        ..rows.add(fixtureAddress('a', 'test-id'));
      await pumpApp(
        tester,
        repo,
        width: width,
        textScale: 2,
        route: '/addresses/a/edit',
      );
      await tester.showKeyboard(find.byType(TextField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('delete-address')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('delete-address')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Lưu địa chỉ'), findsOneWidget);
    });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/app/router/auth_redirect.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/auth/domain/auth_failure.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/auth/presentation/confirm_email_page.dart';

import 'fake_auth_repository.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      appConfigProvider.overrideWithValue(const AppConfig()),
    ],
  );
  addTearDown(repository.close);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SmartFashionApp(),
    ),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go('/login');
  await tester.pumpAndSettle();
  return container;
}

Future<void> fillLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('email')),
    'test@example.com',
  );
  await tester.enterText(
    find.byKey(const ValueKey('password')),
    'test-password',
  );
}

Finder button(String label) => find.widgetWithText(FilledButton, label);

void main() {
  test('next chỉ chấp nhận route nội bộ đã triển khai', () {
    expect(authDestination('/'), '/');
    expect(authDestination('/account'), '/account');
    for (final destination in [
      'https://evil.example',
      '//evil.example',
      '/missing',
      null,
    ]) {
      expect(authDestination(destination), '/account');
    }
  });

  testWidgets('form sai không gọi server, tên/email/password có lỗi riêng', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final container = await pumpApp(tester, repository);
    container.read(appRouterProvider).go('/register');
    await tester.pumpAndSettle();
    await tester.tap(button('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets(
    'đang gửi thì khóa submit, double tap chỉ gọi đăng nhập một lần',
    (tester) async {
      final pending = Completer<void>();
      final repository = FakeAuthRepository()..onSignIn = () => pending.future;
      await pumpApp(tester, repository);
      await fillLogin(tester);
      await tester.tap(button('Đăng nhập'));
      await tester.pump();
      expect(find.text('Đang xử lý…'), findsOneWidget);
      final submitting = tester.widget<FilledButton>(button('Đang xử lý…'));
      expect(submitting.onPressed, isNull);
      await tester.tap(button('Đang xử lý…'));
      expect(repository.loginCalls, 1);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'lỗi xác thực giữ email/mật khẩu và hiển thị thông báo tiếng Việt',
    (tester) async {
      final repository = FakeAuthRepository()
        ..onSignIn = () async {
          throw const AuthFailure(
            'Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.',
          );
        };
      await pumpApp(tester, repository);
      await fillLogin(tester);
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(
        find.text('Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('email')))
            .controller!
            .text,
        'test@example.com',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('password')))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('password')))
            .obscureText,
        isFalse,
      );
    },
  );

  testWidgets('đăng ký cần email confirmation không được vào tài khoản', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final container = await pumpApp(tester, repository);
    container.read(appRouterProvider).go('/register');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fullName')),
      'Người kiểm thử',
    );
    await fillLogin(tester);
    await tester.enterText(
      find.byKey(const ValueKey('confirmPassword')),
      'test-password',
    );
    await tester.tap(button('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm một bước nữa.'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsOneWidget);
    expect(find.text('Gửi lại sau 60s'), findsOneWidget);
    expect(repository.currentUser, isNull);
    expect(find.byKey(const ValueKey('password')), findsNothing);
    await tester.tap(button('Đã xác nhận · Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('email')))
          .controller!
          .text,
      'test@example.com',
    );
  });

  testWidgets('mật khẩu nhập lại không khớp thì không gửi đăng ký', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final container = await pumpApp(tester, repository);
    container.read(appRouterProvider).go('/register');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fullName')),
      'Người kiểm thử',
    );
    await fillLogin(tester);
    await tester.enterText(
      find.byKey(const ValueKey('confirmPassword')),
      'another-password',
    );
    await tester.tap(button('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('gửi lại email có cooldown, không gửi liên tục', (tester) async {
    final repository = FakeAuthRepository();
    final container = await pumpApp(tester, repository);
    container
        .read(appRouterProvider)
        .go(
          '/confirm-email',
          extra: const ConfirmationDetails(email: 'test@example.com'),
        );
    await tester.pumpAndSettle();
    await tester.ensureVisible(button('Gửi lại email'));
    await tester.pumpAndSettle();
    await tester.tap(button('Gửi lại email'));
    await tester.pumpAndSettle();
    expect(repository.resendCalls, 1);
    expect(
      tester.widget<FilledButton>(button('Gửi lại sau 60s')).onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(button('Gửi lại email'), findsOneWidget);
  });

  testWidgets('session đăng nhập/đăng xuất điều khiển route bảo vệ', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final container = await pumpApp(tester, repository);
    container.read(appRouterProvider).go('/account');
    await tester.pumpAndSettle();
    expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
    await fillLogin(tester);
    await tester.tap(button('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Xin chào, Người kiểm thử'), findsOneWidget);
    await tester.tap(button('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(button('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
    container.read(appRouterProvider).go('/account');
    await tester.pumpAndSettle();
    expect(find.text('Rất vui được gặp bạn.'), findsOneWidget);
  });

  testWidgets('phiên đã khôi phục bỏ qua form đăng nhập', (tester) async {
    await pumpApp(
      tester,
      FakeAuthRepository()..session = FakeAuthRepository.user,
    );
    expect(find.text('Xin chào, Người kiểm thử'), findsOneWidget);
    expect(find.text('Rất vui được gặp bạn.'), findsNothing);
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('đăng ký cuộn khi bàn phím mở, text scale 2 ở $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await pumpApp(tester, FakeAuthRepository());
      container.read(appRouterProvider).go('/register');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('password')));
      await tester.ensureVisible(find.byKey(const ValueKey('confirmPassword')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/profile/domain/profile.dart';
import 'package:smart_fashion/features/profile/presentation/profile_providers.dart';

import '../auth/fake_auth_repository.dart';
import 'fake_profile_repository.dart';

Future<ProviderContainer> pumpProfileApp(
  WidgetTester tester, {
  required FakeAuthRepository authRepository,
  required FakeProfileRepository profileRepository,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      appConfigProvider.overrideWithValue(const AppConfig()),
    ],
  );
  addTearDown(authRepository.close);
  addTearDown(profileRepository.close);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SmartFashionApp(),
    ),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go('/account/profile');
  await tester.pumpAndSettle();
  return container;
}

Finder saveButton() => find.widgetWithText(FilledButton, 'Lưu thay đổi');

void main() {
  const loggedUser = AuthUser(
    id: 'user-hai',
    email: 'hai@vku.udn.vn',
    fullName: 'Trần Lê Nguyên Hải',
    emailConfirmed: true,
  );

  const initialProfile = UserProfile(
    id: 'user-hai',
    email: 'hai@vku.udn.vn',
    fullName: 'Trần Lê Nguyên Hải',
    phone: '0985525413',
  );

  testWidgets('màn hình Profile hiển thị đầy đủ thông tin ban đầu', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository()..session = loggedUser;
    final profileRepo = FakeProfileRepository(initialProfile: initialProfile);

    await pumpProfileApp(
      tester,
      authRepository: authRepo,
      profileRepository: profileRepo,
    );

    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('Trần Lê Nguyên Hải'), findsWidgets);
    expect(find.text('0985525413'), findsOneWidget);
    expect(find.text('hai@vku.udn.vn'), findsOneWidget);
    expect(saveButton(), findsOneWidget);
  });

  testWidgets(
    'báo lỗi validation khi để trống họ tên và không gọi repository',
    (tester) async {
      final authRepo = FakeAuthRepository()..session = loggedUser;
      final profileRepo = FakeProfileRepository(initialProfile: initialProfile);

      await pumpProfileApp(
        tester,
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      final nameField = find.byKey(const ValueKey('profile_full_name'));
      await tester.enterText(nameField, '');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
      expect(profileRepo.updateCalls, 0);
    },
  );

  testWidgets('báo lỗi validation khi nhập số điện thoại sai định dạng', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository()..session = loggedUser;
    final profileRepo = FakeProfileRepository(initialProfile: initialProfile);

    await pumpProfileApp(
      tester,
      authRepository: authRepo,
      profileRepository: profileRepo,
    );

    final phoneField = find.byKey(const ValueKey('profile_phone'));
    await tester.enterText(phoneField, '1234');
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(
      find.text('Số điện thoại không hợp lệ (từ 9 đến 15 chữ số)'),
      findsOneWidget,
    );
    expect(profileRepo.updateCalls, 0);
  });

  testWidgets(
    'cập nhật thành công họ tên & SĐT hiển thị thông báo ProfileSaved',
    (tester) async {
      final authRepo = FakeAuthRepository()..session = loggedUser;
      final profileRepo = FakeProfileRepository(initialProfile: initialProfile);

      await pumpProfileApp(
        tester,
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      final nameField = find.byKey(const ValueKey('profile_full_name'));
      await tester.enterText(nameField, 'Nguyên Hải VKU');

      final phoneField = find.byKey(const ValueKey('profile_phone'));
      await tester.enterText(phoneField, '0905123456');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(profileRepo.updateCalls, 1);
      expect(profileRepo.currentProfile?.fullName, 'Nguyên Hải VKU');
      expect(profileRepo.currentProfile?.phone, '0905123456');
      expect(
        find.text('Đã cập nhật hồ sơ cá nhân thành công.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'khi repository báo lỗi thì hiển thị banner thông báo ProfileError',
    (tester) async {
      final authRepo = FakeAuthRepository()..session = loggedUser;
      final profileRepo = FakeProfileRepository(initialProfile: initialProfile)
        ..onUpdate = (name, phone, avatar) async {
          throw const ProfileFailure(
            'Không có kết nối mạng. Vui lòng kiểm tra lại.',
          );
        };

      await pumpProfileApp(
        tester,
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(
        find.text('Không có kết nối mạng. Vui lòng kiểm tra lại.'),
        findsOneWidget,
      );
      expect(find.text('Đã cập nhật hồ sơ cá nhân thành công.'), findsNothing);
    },
  );

  testWidgets('mở bottom sheet chọn avatar và chọn một preset avatar', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository()..session = loggedUser;
    final profileRepo = FakeProfileRepository(initialProfile: initialProfile);

    await pumpProfileApp(
      tester,
      authRepository: authRepo,
      profileRepository: profileRepo,
    );

    // Chạm vào nút icon camera
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Chọn ảnh đại diện'), findsOneWidget);
    expect(
      find.text('Chọn một phong cách đại diện từ bộ sưu tập Smart Fashion:'),
      findsOneWidget,
    );

    // Chọn avatar Emerald Chic trong grid
    await tester.tap(find.text('Emerald Chic'));
    await tester.pumpAndSettle();

    // Bottom sheet đã đóng
    expect(find.text('Chọn ảnh đại diện'), findsNothing);
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
      'giao diện Profile không tràn màn hình ở chiều rộng $width với text scale 2',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final authRepo = FakeAuthRepository()..session = loggedUser;
        final profileRepo = FakeProfileRepository(
          initialProfile: initialProfile,
        );

        await pumpProfileApp(
          tester,
          authRepository: authRepo,
          profileRepository: profileRepo,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

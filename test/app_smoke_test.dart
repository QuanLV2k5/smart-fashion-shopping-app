import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/app.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/core/config/app_config.dart';
import 'package:smart_fashion/core/config/app_config_provider.dart';

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('boots offline without credentials at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(const AppConfig())],
          child: const SmartFashionApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SMART FASHION'), findsOneWidget);
      expect(find.text('Chưa tải được catalog'), findsOneWidget);
      final context = tester.element(find.text('SMART FASHION'));
      expect(Localizations.localeOf(context), const Locale('vi', 'VN'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unknown route provides a working way back', (tester) async {
    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(const AppConfig())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartFashionApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/missing-page');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quay lại Smart Fashion'));
    await tester.pumpAndSettle();
    expect(find.text('SMART FASHION'), findsOneWidget);
  });
}

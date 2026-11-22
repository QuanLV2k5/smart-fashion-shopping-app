// Fixture screenshots for visual QA only. They are not live backend evidence.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/app/router/app_router.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';

import '../test/features/catalog/catalog_fixtures.dart';
import '../test/features/personalization/personalization_fixtures.dart';
import '../test/features/personalization/personalization_test.dart'
    show pumpPersonalization;

void main() {
  testWidgets('capture personalization Figma screens at 390', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fonts = FontLoader('BeVietnamPro');
    for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$name.ttf'));
    }
    await tester.runAsync(fonts.load);
    final fallback = FontLoader('Ahem')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'));
    await tester.runAsync(fallback.load);
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(icons.load);
    final key = GlobalKey();
    final repo = FakePersonalizationRepository()
      ..page = reviewPage(eligible: true);
    repo.saved['user-a'] = [FavoriteEntry('SF01', product())];
    final container = await pumpPersonalization(
      tester,
      repo,
      '/favorites',
      admin: true,
      captureKey: key,
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/catalog/products-atlas.png'),
        key.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    final output = Directory('docs/screenshots/personalization');
    await tester.runAsync(() => output.create(recursive: true));
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${output.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('favorites-fixture-390');
    for (final entry in {
      'reviews-empty-fixture-390': '/products/SF01/reviews',
      'review-form-fixture-390': '/products/SF01/review',
      'admin-user-fixture-390': '/admin/users/customer-b',
    }.entries) {
      container.read(appRouterProvider).go(entry.value);
      await tester.pumpAndSettle();
      await capture(entry.key);
      expect(tester.takeException(), isNull);
    }
  });
}

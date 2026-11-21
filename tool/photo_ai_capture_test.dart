// Manual visual QA. Fixture repositories; not evidence of a live Gemini call.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/theme/app_theme.dart';
import 'package:smart_fashion/features/ai/presentation/ai_page.dart';
import 'package:smart_fashion/features/ai/presentation/photo_outfit_page.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../test/features/ai/photo_outfit_page_test.dart'
    show PhotoPickerFixture, VisionFixture, OutfitFixture, chooseAndAnalyze;
import '../test/features/cart/cart_fixtures.dart';

void main() {
  testWidgets('capture photo flow fixture at 390px', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final family in ['BeVietnamPro', 'Ahem']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
      await tester.runAsync(loader.load);
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(icons.load);
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          garmentPhotoPickerProvider.overrideWithValue(PhotoPickerFixture()),
          garmentRepositoryProvider.overrideWithValue(VisionFixture()),
          aiRepositoryProvider.overrideWithValue(OutfitFixture()),
          currentCartUserIdProvider.overrideWithValue('fixture'),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          catalogRepositoryProvider.overrideWithValue(
            DetailCatalogRepository(),
          ),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const PhotoOutfitPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/screenshots/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('ai-photo-upload-390');
    await chooseAndAnalyze(tester);
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(find.byType(Image).first).image,
        key.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    await capture('ai-photo-review-fixture-390');
    await tester.tap(find.text('Xác nhận món đồ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tìm món phối cùng'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/catalog/products-atlas.png'),
        key.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    await capture('ai-photo-result-fixture-390');
    await tester.ensureVisible(find.text('Xem sản phẩm'));
    await tester.pumpAndSettle();
    await capture('ai-photo-result-items-fixture-390');
  });
}

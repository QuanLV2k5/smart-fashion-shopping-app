// Manual visual QA only: renders fixture content, never calls Gemini.
// Run: flutter test tool/ai_capture_test.dart --no-pub
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/theme/app_theme.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';
import 'package:smart_fashion/features/ai/presentation/ai_page.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';

import '../test/features/cart/cart_fixtures.dart';

class PreviewAi implements AiRepository {
  final result = Completer<AiOutfit>();
  @override
  Future<AiOutfit> recommend(AiRequest request) => result.future;
}

void main() {
  testWidgets('capture AI form and fixture result at 390px', (tester) async {
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
    final ai = PreviewAi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiRepositoryProvider.overrideWithValue(ai),
          currentCartUserIdProvider.overrideWithValue('fixture'),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const AiPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/catalog/products-atlas.png'),
        key.currentContext!,
      ),
    );
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/screenshots/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('ai-form-390');
    await tester.tap(find.text('Gợi ý trang phục'));
    await tester.pump();
    await capture('ai-loading-390');
    ai.result.complete(
      AiOutfit(
        products: [shirt(), jeans()],
        explanation: 'Áo thun cotton trắng ngà và jeans xanh tạo bộ casual thoải mái, dễ mặc khi đi chơi.',
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await capture('ai-result-fixture-390');
  });
}

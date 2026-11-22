import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/theme/app_theme.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';
import 'package:smart_fashion/features/ai/presentation/ai_conversation.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../cart/cart_fixtures.dart';

void main() {
  testWidgets(
    'chat sends current outfit and locks, applies only verified live catalog prices',
    (tester) async {
      Map<String, dynamic>? sent;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatTransportProvider.overrideWithValue((payload) async {
              sent = payload;
              return {
                'provider': 'gemini',
                'chatVersion': 1,
                'message': 'Đã giữ quần và đổi áo.',
                'request': {...payload, 'notes': 'Giữ quần'},
                'outfit': {
                  'products': [
                    {'id': shirtId},
                    {'id': jeansId},
                  ],
                  'explanation': 'Áo và jeans',
                  'totalVnd': 1,
                },
              };
            }),
            currentCartUserIdProvider.overrideWithValue('user-a'),
            catalogRepositoryProvider.overrideWithValue(
              DetailCatalogRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AiConversation(
                request: const AiRequest(
                  style: 'Casual',
                  occasion: 'Đi chơi',
                  budget: 500000,
                  keepIds: [jeansId],
                ),
                outfit: AiOutfit(
                  products: [shirt(), jeans()],
                  explanation: 'Bộ hiện tại',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Giữ quần, đổi áo');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(sent!['action'], 'chat');
      expect(sent!['keepIds'], [jeansId]);
      expect(find.text('Đã giữ quần và đổi áo.'), findsOneWidget);
      expect(find.textContaining('448.000đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('AI bottom navigation exposes all four destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: AiBottomNavigation()),
      ),
    );
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('AI Stylist'), findsOneWidget);
    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label)
        .toList();
    expect(labels, ['Trang chủ', 'Khám phá', 'AI Stylist', 'Tài khoản']);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });
}

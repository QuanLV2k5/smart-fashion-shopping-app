import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';
import 'package:smart_fashion/features/ai/presentation/ai_page.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/core/theme/app_theme.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';
import 'package:smart_fashion/features/cart/domain/cart.dart';

import '../cart/cart_fixtures.dart';

class FakeAi implements AiRepository {
  final pending = Completer<AiOutfit>();
  int calls = 0;
  @override
  Future<AiOutfit> recommend(AiRequest request) {
    calls++;
    return pending.future;
  }
}

void main() {
  testWidgets(
    'partial outfit add retries only the unconfirmed item with the same request ID',
    (tester) async {
      final cart = FakeCartRepository();
      cart.onMutate = (mutation) async {
        if (mutation.variantId == denimM) {
          throw const CartFailure('Mất phản hồi', uncertain: true);
        }
        cart.quantities[mutation.variantId] = 1;
        return cart.snapshot;
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCartUserIdProvider.overrideWithValue('user-a'),
            cartRepositoryProvider.overrideWithValue(cart),
            catalogRepositoryProvider.overrideWithValue(
              DetailCatalogRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: OutfitCartSheet(
                products: [shirt(), jeans()],
                budget: 500000,
              ),
            ),
          ),
        ),
      );
      for (final option in ['M · Trắng ngà', 'M · Xanh denim']) {
        await tester.tap(
          find
              .byType(DropdownButtonFormField<String>)
              .at(option.contains('denim') ? 1 : 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Thêm bộ vào giỏ'));
      await tester.pumpAndSettle();
      expect(cart.requests.map((m) => m.variantId), [whiteM, denimM]);
      await tester.tap(find.text('Thêm bộ vào giỏ'));
      await tester.pumpAndSettle();
      expect(cart.requests.map((m) => m.variantId), [whiteM, denimM, denimM]);
      expect(cart.requests[1].requestId, cart.requests[2].requestId);
      expect(cart.quantities[whiteM], 1);
    },
  );
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('form and result fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeAi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(repo),
            currentCartUserIdProvider.overrideWithValue('user-a'),
            cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const AiPage()),
        ),
      );
      await tester.tap(find.text('Gợi ý trang phục'));
      await tester.pump();
      repo.pending.complete(
        AiOutfit(
          products: [shirt(), jeans()],
          explanation: 'Áo cotton và jeans cho buổi đi chơi.',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Một bộ đồ,\nnhiều cuộc hẹn.'), findsOneWidget);
      await tester.tap(find.text('Chọn size & thêm bộ · 448.000đ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm bộ vào giỏ'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn size và màu cho từng món.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('no match remains empty and can return to form', (tester) async {
    final repo = FakeAi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
          currentCartUserIdProvider.overrideWithValue('user-a'),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AiPage()),
      ),
    );
    await tester.tap(find.text('Gợi ý trang phục'));
    await tester.pump();
    repo.pending.complete(AiOutfit(products: [], explanation: ''));
    await tester.pumpAndSettle();
    expect(find.text('Ngân sách chưa đủ cho bộ này'), findsOneWidget);
    await tester.tap(find.text('Điều chỉnh nhu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bạn\nmuốn mặc gì?'), findsOneWidget);
  });
  testWidgets(
    'sheet rejects a fresh total above budget before any cart mutation',
    (tester) async {
      final cart = FakeCartRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentCartUserIdProvider.overrideWithValue('user-a'),
            cartRepositoryProvider.overrideWithValue(cart),
            catalogRepositoryProvider.overrideWithValue(
              DetailCatalogRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: OutfitCartSheet(
                products: [shirt(), jeans()],
                budget: 300000,
              ),
            ),
          ),
        ),
      );
      for (final option in ['M · Trắng ngà', 'M · Xanh denim']) {
        final dropdowns = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdowns.at(option.contains('denim') ? 1 : 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Thêm bộ vào giỏ'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Giá sản phẩm vừa thay đổi, vượt ngân sách. Vui lòng tư vấn lại.',
        ),
        findsOneWidget,
      );
      expect(cart.requests, isEmpty);
    },
  );
  testWidgets(
    'invalid budget never calls AI; cancellation ignores late result',
    (tester) async {
      final repo = FakeAi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(repo),
            currentCartUserIdProvider.overrideWithValue('user-a'),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const AiPage()),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, '1');
      await tester.tap(find.text('Gợi ý trang phục'));
      await tester.pump();
      expect(repo.calls, 0);
      expect(find.text('Nhập từ 50.000 đến 20.000.000đ.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '500000');
      await tester.tap(find.text('Gợi ý trang phục'));
      await tester.pump();
      expect(repo.calls, 1);
      await tester.ensureVisible(find.text('Hủy tư vấn'));
      await tester.tap(find.text('Hủy tư vấn'));
      await tester.pump();
      repo.pending.complete(AiOutfit(products: [], explanation: ''));
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay bạn\nmuốn mặc gì?'), findsOneWidget);
    },
  );
}

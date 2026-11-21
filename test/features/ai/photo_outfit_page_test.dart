import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/theme/app_theme.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';
import 'package:smart_fashion/features/ai/domain/owned_garment.dart';
import 'package:smart_fashion/features/ai/presentation/ai_page.dart';
import 'package:smart_fashion/features/ai/presentation/photo_outfit_page.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';
import 'package:smart_fashion/features/catalog/presentation/catalog_providers.dart';

import '../cart/cart_fixtures.dart';

const blueShirt = OwnedGarment(
  category: GarmentCategory.top,
  name: 'Áo sơ mi xanh',
  color: 'Xanh nhạt',
  pattern: 'Trơn',
  fit: 'Suông',
  details: 'Cổ bẻ, tay dài',
);
GarmentPhoto photoFixture() => GarmentPhoto.fromBytes(
  File('test/fixtures/owned-blue-shirt.jpg').readAsBytesSync(),
);

class PhotoPickerFixture implements GarmentPhotoPicker {
  bool cancel = false;
  @override
  Future<GarmentPhoto?> pick({required bool camera}) async =>
      cancel ? null : photoFixture();
  @override
  Future<GarmentPhoto?> recover() async => null;
}

class VisionFixture implements GarmentRepository {
  Completer<OwnedGarment>? pending;
  @override
  Future<OwnedGarment> analyze(GarmentPhoto photo) async =>
      pending == null ? blueShirt : pending!.future;
}

class OutfitFixture implements AiRepository {
  final requests = <AiRequest>[];
  @override
  Future<AiOutfit> recommend(AiRequest request) async {
    requests.add(request);
    return AiOutfit(
      products: [jeans()],
      explanation: 'Phối áo xanh có sẵn với jeans; chỉ mua thêm quần.',
    );
  }
}

Future<ProviderContainer> mountPhoto(
  WidgetTester tester, {
  VisionFixture? vision,
  OutfitFixture? ai,
  PhotoPickerFixture? picker,
  ValueNotifier<String?>? user,
  double scale = 1,
}) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        garmentPhotoPickerProvider.overrideWithValue(
          picker ?? PhotoPickerFixture(),
        ),
        garmentRepositoryProvider.overrideWithValue(vision ?? VisionFixture()),
        aiRepositoryProvider.overrideWithValue(ai ?? OutfitFixture()),
        currentCartUserIdProvider.overrideWith(
          (ref) =>
              user == null ? 'user-a' : ref.watch(ownerFixtureProvider(user)),
        ),
        cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        catalogRepositoryProvider.overrideWithValue(DetailCatalogRepository()),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const PhotoOutfitPage(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

final ownerFixtureProvider = Provider.family<String?, ValueNotifier<String?>>((
  ref,
  owner,
) {
  void notify() => ref.invalidateSelf();
  owner.addListener(notify);
  ref.onDispose(() => owner.removeListener(notify));
  return owner.value;
});
Future<void> chooseAndAnalyze(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Chọn ảnh'));
  await tester.tap(find.text('Chọn ảnh'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nhận diện món đồ'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
      'photo -> corrected attributes -> one purchasable item at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final ai = OutfitFixture();
        await mountPhoto(tester, ai: ai);
        await chooseAndAnalyze(tester);
        expect(find.text('AI đã nhìn thấy gì?'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextFormField).at(1));
        await tester.enterText(find.byType(TextFormField).at(1), 'Xanh navy');
        await tester.tap(find.text('Xác nhận món đồ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tìm món phối cùng'));
        await tester.pumpAndSettle();
        expect(ai.requests.single.ownedGarment!.color, 'Xanh navy');
        expect(find.text('BẠN ĐÃ CÓ'), findsOneWidget);
        expect(find.text('Mua thêm: 249.000đ'), findsOneWidget);
        await tester.tap(find.text('Chọn món mua thêm · 249.000đ'));
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('Áo thun Essential'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('canceling the system photo picker preserves current photo', (
    tester,
  ) async {
    final picker = PhotoPickerFixture();
    await mountPhoto(tester, picker: picker);
    await tester.ensureVisible(find.text('Chọn ảnh'));
    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    picker.cancel = true;
    await tester.ensureVisible(find.text('Đổi ảnh'));
    await tester.tap(find.text('Đổi ảnh'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Nhận diện món đồ'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('cancel analysis ignores a late Gemini response', (tester) async {
    final vision = VisionFixture()..pending = Completer<OwnedGarment>();
    await mountPhoto(tester, vision: vision);
    await tester.ensureVisible(find.text('Chọn ảnh'));
    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhận diện món đồ'));
    await tester.pump();
    await tester.tap(find.text('Hủy thao tác'));
    await tester.pump();
    vision.pending!.complete(blueShirt);
    await tester.pumpAndSettle();
    expect(find.text('AI đã nhìn thấy gì?'), findsNothing);
    expect(find.text('Nhận diện món đồ'), findsOneWidget);
  });
  testWidgets(
    'account change clears private photo and ignores pending result',
    (tester) async {
      final user = ValueNotifier<String?>('user-a');
      addTearDown(user.dispose);
      final vision = VisionFixture()..pending = Completer<OwnedGarment>();
      await mountPhoto(tester, vision: vision, user: user);
      await tester.ensureVisible(find.text('Chọn ảnh'));
      await tester.tap(find.text('Chọn ảnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhận diện món đồ'));
      await tester.pump();
      user.value = 'user-b';
      await tester.pump();
      vision.pending!.complete(blueShirt);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('AI đã nhìn thấy gì?'), findsNothing);
    },
  );
  testWidgets('large text and keyboard leave photo form scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mountPhoto(tester, scale: 1.4);
    await chooseAndAnalyze(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

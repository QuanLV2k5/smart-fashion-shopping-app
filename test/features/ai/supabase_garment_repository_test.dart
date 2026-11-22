import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_fashion/features/ai/data/supabase_garment_repository.dart';
import 'package:smart_fashion/features/ai/data/supabase_ai_repository.dart';
import 'package:smart_fashion/features/ai/domain/ai_outfit.dart';
import 'package:smart_fashion/features/ai/domain/owned_garment.dart';

import '../cart/cart_fixtures.dart';
import 'photo_outfit_page_test.dart' show blueShirt, photoFixture;
import 'supabase_ai_repository_test.dart' show clientFor, outfit;

http.Response analysis({
  String status = 'ok',
  String provider = 'gemini',
  int version = 2,
}) => http.Response(
  jsonEncode({
    'provider': provider,
    'apiVersion': version,
    'status': status,
    'garment': blueShirt.toJson(),
  }),
  200,
  headers: {'content-type': 'application/json'},
);
void main() {
  test(
    'analysis transmits image bytes to authenticated function, not filename',
    () async {
      final photo = photoFixture();
      final client = await clientFor((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['action'], 'analyze');
        expect(body['image']['mimeType'], 'image/jpeg');
        expect(base64Decode(body['image']['data'] as String), photo.bytes);
        return analysis();
      });
      expect(
        (await SupabaseGarmentRepository(client).analyze(photo)).color,
        'Xanh nhạt',
      );
    },
  );
  test('non-garment and old backend never yield a confirmed garment', () async {
    for (final response in [
      analysis(status: 'no_garment'),
      analysis(status: 'multiple_garments'),
      analysis(status: 'unclear'),
      analysis(provider: 'mock'),
      analysis(version: 1),
    ]) {
      final client = await clientFor((_) async => response);
      await expectLater(
        SupabaseGarmentRepository(client).analyze(photoFixture()),
        throwsA(isA<AiFailure>()),
      );
    }
  });
  test('logout during analysis drops response', () async {
    final pending = Completer<http.Response>();
    final client = await clientFor((_) => pending.future);
    final future = SupabaseGarmentRepository(client).analyze(photoFixture());
    final assertion = expectLater(future, throwsA(isA<AiFailure>()));
    await client.auth.signOut();
    pending.complete(analysis());
    await assertion;
  });
  test(
    'one purchased item is allowed only with an owned garment and real price',
    () async {
      final client = await clientFor((_) async {
        final original = outfit([jeansId]);
        return http.Response(
          jsonEncode({
            ...jsonDecode(original.body) as Map<String, dynamic>,
            'apiVersion': 2,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = SupabaseAiRepository(client, DetailCatalogRepository());
      final result = await repo.recommend(
        const AiRequest(
          style: 'Casual',
          occasion: 'Đi chơi',
          budget: 300000,
          ownedGarment: blueShirt,
        ),
      );
      expect(result.totalVnd, 249000);
      expect(result.products.single.id, jeansId);
      await expectLater(
        repo.recommend(
          const AiRequest(style: 'Casual', occasion: 'Đi chơi', budget: 300000),
        ),
        throwsA(isA<AiFailure>()),
      );
    },
  );
  test('image size and format validation reject untrusted input', () {
    expect(
      () => GarmentPhoto.fromBytes(Uint8List(GarmentPhoto.maxBytes + 1)),
      throwsA(isA<AiFailure>()),
    );
    expect(
      () => GarmentPhoto.fromBytes(Uint8List(40)),
      throwsA(isA<AiFailure>()),
    );
    expect(
      () => OwnedGarment.fromJson({...blueShirt.toJson(), 'name': ''}),
      throwsFormatException,
    );
  });
}

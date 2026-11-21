import '../../catalog/domain/catalog.dart';
import 'owned_garment.dart';

class AiRequest {
  const AiRequest({
    required this.style,
    required this.occasion,
    required this.budget,
    this.notes = '',
    this.excludeIds = const [],
    this.keepIds = const [],
    this.ownedGarment,
    this.audience = 'Unisex',
  });
  final String style, occasion, notes;
  final String audience;
  final int budget;
  final List<String> excludeIds;
  final List<String> keepIds;
  final OwnedGarment? ownedGarment;
  Map<String, dynamic> toJson() => {
    'style': style,
    'audience': audience,
    'occasion': occasion,
    'budget': budget,
    'notes': notes,
    'excludeIds': excludeIds,
    'keepIds': keepIds,
    if (ownedGarment != null) 'ownedGarment': ownedGarment!.toJson(),
  };
}

class AiOutfit {
  AiOutfit({required List<CatalogProduct> products, required this.explanation})
    : products = List.unmodifiable(products);
  final List<CatalogProduct> products;
  final String explanation;
  int get totalVnd => products.fold(0, (sum, p) => sum + p.priceVnd);
}

class AiFailure implements Exception {
  const AiFailure(this.message);
  final String message;
}

abstract interface class AiRepository {
  Future<AiOutfit> recommend(AiRequest request);
}

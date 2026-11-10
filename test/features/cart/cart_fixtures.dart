import 'package:smart_fashion/features/cart/domain/cart.dart';
import 'package:smart_fashion/features/catalog/domain/catalog.dart';

const shirtId = '20000000-0000-0000-0000-000000000001';
const jeansId = '20000000-0000-0000-0000-000000000002';
const whiteM = '30000000-0000-0000-0000-000000000001';
const blackS = '30000000-0000-0000-0000-000000000002';
const whiteXl = '30000000-0000-0000-0000-000000000003';
const denimM = '30000000-0000-0000-0000-000000000004';

CatalogProduct shirt() => CatalogProduct(
  id: shirtId,
  code: 'SF01',
  categoryId: 'ao',
  name: 'Áo thun Essential',
  description: 'Phom regular.',
  material: 'Cotton',
  priceVnd: 199000,
  imageUrls: [],
  variants: const [
    ProductVariant(
      id: whiteM,
      sku: 'WHITE-M',
      size: 'M',
      color: 'Trắng ngà',
      stock: 2,
    ),
    ProductVariant(
      id: blackS,
      sku: 'BLACK-S',
      size: 'S',
      color: 'Đen',
      stock: 3,
    ),
    ProductVariant(
      id: whiteXl,
      sku: 'WHITE-XL',
      size: 'XL',
      color: 'Trắng ngà',
      stock: 0,
    ),
  ],
);
CatalogProduct jeans() => CatalogProduct(
  id: jeansId,
  code: 'SF02',
  categoryId: 'quan',
  name: 'Jeans Straight',
  description: 'Phom straight.',
  material: 'Denim cotton',
  priceVnd: 249000,
  imageUrls: [],
  variants: const [
    ProductVariant(
      id: denimM,
      sku: 'DENIM-M',
      size: 'M',
      color: 'Xanh denim',
      stock: 8,
    ),
  ],
);

class DetailCatalogRepository implements CatalogRepository {
  int detailCalls = 0;
  bool missing = false;
  @override
  Future<CatalogSnapshot> loadCatalog() async => CatalogSnapshot(
    categories: const [CatalogCategory(id: 'ao', name: 'Áo', slug: 'ao')],
    products: [shirt(), jeans()],
  );
  @override
  Future<CatalogProduct?> loadProduct(String id) async {
    detailCalls++;
    if (missing) return null;
    return id == shirtId
        ? shirt()
        : id == jeansId
        ? jeans()
        : null;
  }
}

CartItem fixtureItem(String variantId, int quantity) {
  final product = variantId == denimM ? jeans() : shirt();
  final variant = product.variants.singleWhere((v) => v.id == variantId);
  final selected = CatalogProduct(
    id: product.id,
    code: product.code,
    categoryId: product.categoryId,
    name: product.name,
    description: product.description,
    material: product.material,
    priceVnd: product.priceVnd,
    imageUrls: [],
    variants: [variant],
  );
  return CartItem(variantId: variantId, quantity: quantity, product: selected);
}

class FakeCartRepository implements CartRepository {
  final quantities = <String, int>{};
  final receipts = <String>{};
  final requests = <CartMutation>[];
  int reads = 0;
  Future<CartSnapshot> Function(CartMutation)? onMutate;
  CartSnapshot get snapshot => CartSnapshot(
    quantities.entries.map((e) => fixtureItem(e.key, e.value)).toList(),
  );
  @override
  Future<CartSnapshot> loadCart() async {
    reads++;
    return snapshot;
  }

  @override
  Future<CartSnapshot> mutate(CartMutation mutation) async {
    requests.add(mutation);
    if (onMutate != null) return onMutate!(mutation);
    if (receipts.add(mutation.requestId)) {
      switch (mutation.operation) {
        case CartOperation.add:
          quantities.update(
            mutation.variantId,
            (old) => old + mutation.quantity,
            ifAbsent: () => mutation.quantity,
          );
        case CartOperation.set:
          quantities[mutation.variantId] = mutation.quantity;
        case CartOperation.remove:
          quantities.remove(mutation.variantId);
      }
    }
    return snapshot;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/cart/data/supabase_cart_repository.dart';
import 'package:smart_fashion/features/cart/domain/cart.dart';
import 'package:smart_fashion/features/catalog/domain/variant_selection.dart';

import 'cart_fixtures.dart';

Map<String, dynamic> cartRow({int quantity = 1}) => {
  'variant_id': whiteM,
  'quantity': quantity,
  'product': {
    'id': shirtId,
    'code': 'SF01',
    'category_id': 'ao',
    'name': 'Áo thun Essential',
    'description': '',
    'material': 'Cotton',
    'price_vnd': 199000,
    'image_paths': <String>[],
    'product_variants': [
      {
        'id': whiteM,
        'sku': 'WHITE-M',
        'size': 'M',
        'color': 'Trắng ngà',
        'stock': 2,
      },
    ],
  },
};

void main() {
  test('chọn lại size/màu xóa lựa chọn không còn ghép được cùng SKU', () {
    final product = shirt();
    var choice = const VariantSelection()
        .chooseSize(product, 'M')
        .chooseColor(product, 'Trắng ngà');
    expect(choice.resolve(product)?.id, whiteM);
    choice = choice.chooseColor(product, 'Đen');
    expect(choice.size, isNull);
    expect(choice.resolve(product), isNull);
    choice = choice.chooseSize(product, 'S');
    expect(choice.resolve(product)?.id, blackS);
    choice = choice.chooseSize(product, 'M');
    expect(choice.color, isNull);
  });
  test('giỏ tổng theo số lượng, phân biệt biến thể và cảnh báo stock giảm', () {
    final cart = CartSnapshot([
      fixtureItem(whiteM, 2),
      fixtureItem(blackS, 1),
      fixtureItem(denimM, 1),
    ]);
    expect(cart.totalQuantity, 4);
    expect(cart.subtotalVnd, 846000);
    expect(cart.needsAttention, isFalse);
    expect(fixtureItem(whiteM, 3).needsAttention, isTrue);
  });
  test('sản phẩm ẩn giữ dòng xóa được và không đưa giá giả vào tổng', () {
    final cart = cartFromJson({
      'items': [
        {'variant_id': whiteM, 'quantity': 2, 'product': null},
      ],
    }, imageUrl: (p) => p);
    expect(cart.items.single.product, isNull);
    expect(cart.needsAttention, isTrue);
    expect(cart.subtotalVnd, 0);
    expect(cart.totalQuantity, 2);
  });
  test('từ chối JSON sai số lượng, trùng SKU hoặc metadata khác biến thể', () {
    for (final quantity in [0, -1, 100]) {
      expect(
        () => cartFromJson({
          'items': [cartRow(quantity: quantity)],
        }, imageUrl: (p) => p),
        throwsFormatException,
      );
    }
    expect(
      () => cartFromJson({
        'items': [cartRow(), cartRow()],
      }, imageUrl: (p) => p),
      throwsFormatException,
    );
    final row = cartRow()..['variant_id'] = blackS;
    expect(
      () => cartFromJson({
        'items': [row],
      }, imageUrl: (p) => p),
      throwsFormatException,
    );
  });
}

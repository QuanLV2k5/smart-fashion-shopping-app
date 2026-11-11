import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/formatters/money.dart';

void main() {
  test('VNĐ formatting matches the checkout scenario', () {
    expect(formatVnd(199000 + 249000), '448.000đ');
    expect(formatVnd(199000 + 249000 + 25000), '473.000đ');
    expect(formatVnd(0), '0đ');
  });
}

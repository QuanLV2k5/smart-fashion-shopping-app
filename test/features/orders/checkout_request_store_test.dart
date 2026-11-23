import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/orders/data/checkout_request_store_io.dart';
import 'package:smart_fashion/features/orders/domain/checkout.dart';

void main() {
  test(
    'file store reopens saved request by account and only removes its own file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'checkout-request-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = FileCheckoutRequestStore(() async => directory);
      const a = CheckoutRequest(quoteId: 'quote-a', requestId: 'request-a');
      const b = CheckoutRequest(quoteId: 'quote-b', requestId: 'request-b');
      await store.save('A', a);
      await store.save('B', b);

      final reopened = FileCheckoutRequestStore(() async => directory);
      expect((await reopened.read('A'))?.toJson(), a.toJson());
      expect((await reopened.read('B'))?.toJson(), b.toJson());
      await reopened.clear('A');
      expect(await store.read('A'), isNull);
      expect((await store.read('B'))?.toJson(), b.toJson());
    },
  );
}

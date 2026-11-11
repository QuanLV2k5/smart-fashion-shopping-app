import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/cart/domain/cart.dart';
import 'package:smart_fashion/features/cart/presentation/cart_providers.dart';

import '../auth/fake_auth_repository.dart';
import 'cart_fixtures.dart';

Future<ProviderContainer> setup(
  FakeCartRepository repository,
  FakeAuthRepository auth,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cartRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(auth.close);
  addTearDown(container.dispose);
  container.listen(authSessionProvider, (_, _) {});
  container.listen(cartProvider(FakeAuthRepository.user.id), (_, _) {});
  await container.read(authSessionProvider.future);
  await container.read(cartProvider(FakeAuthRepository.user.id).future);
  return container;
}

void main() {
  test('double submit chỉ một request; lỗi ghi không làm mất giỏ', () async {
    final pending = Completer<CartSnapshot>();
    final repository = FakeCartRepository()..quantities[whiteM] = 1;
    repository.onMutate = (_) => pending.future;
    final container = await setup(
      repository,
      FakeAuthRepository()..session = FakeAuthRepository.user,
    );
    final action = container.read(
      cartActionsProvider(FakeAuthRepository.user.id).notifier,
    );
    final first = action.change(whiteM, 1, CartOperation.add);
    expect(await action.change(whiteM, 1, CartOperation.add), isFalse);
    expect(repository.requests, hasLength(1));
    expect(
      container
          .read(cartProvider(FakeAuthRepository.user.id))
          .value!
          .totalQuantity,
      1,
    );
    pending.completeError(const CartFailure('Tồn kho đổi'));
    expect(await first, isFalse);
    expect(
      container
          .read(cartProvider(FakeAuthRepository.user.id))
          .value!
          .totalQuantity,
      1,
    );
    expect(
      container
          .read(cartActionsProvider(FakeAuthRepository.user.id))
          .failure
          ?.message,
      'Tồn kho đổi',
    );
  });
  test('retry lỗi không chắc chắn dùng lại requestId; không cho thao tác mới chen vào', () async {
    final repository = FakeCartRepository()
      ..onMutate = (_) async =>
          throw const CartFailure('Chưa xác nhận', uncertain: true);
    final container = await setup(
      repository,
      FakeAuthRepository()..session = FakeAuthRepository.user,
    );
    final action = container.read(
      cartActionsProvider(FakeAuthRepository.user.id).notifier,
    );
    expect(await action.change(whiteM, 1, CartOperation.add), isFalse);
    expect(await action.change(blackS, 1, CartOperation.add), isFalse);
    expect(repository.requests, hasLength(1));
    repository.onMutate = null;
    expect(await action.retryPending(), isTrue);
    expect(repository.requests[0].requestId, repository.requests[1].requestId);
    expect(
      container
          .read(cartProvider(FakeAuthRepository.user.id))
          .value!
          .totalQuantity,
      1,
    );
    expect(await action.change(whiteM, 1, CartOperation.add), isTrue);
    expect(
      repository.requests.last.requestId,
      isNot(repository.requests.first.requestId),
    );
  });
  test(
    'phản hồi đang ghi sau đổi tài khoản không lộ hoặc thay giỏ tài khoản mới',
    () async {
      final pending = Completer<CartSnapshot>();
      final repository = FakeCartRepository()..onMutate = (_) => pending.future;
      final auth = FakeAuthRepository()..session = FakeAuthRepository.user;
      final container = await setup(repository, auth);
      final action = container.read(
        cartActionsProvider(FakeAuthRepository.user.id).notifier,
      );
      final request = action.change(whiteM, 1, CartOperation.add);
      auth.setUser(
        const AuthUser(id: 'user-b', email: 'b@example.com', fullName: 'B'),
      );
      await container.pump();
      expect(container.read(currentCartUserIdProvider), 'user-b');
      pending.complete(CartSnapshot([fixtureItem(whiteM, 1)]));
      expect(await request, isFalse);
      expect(
        (await container.read(cartProvider('user-b').future)).items,
        isEmpty,
      );
      expect(
        (await container.read(cartProvider(FakeAuthRepository.user.id).future))
            .items,
        isEmpty,
      );
    },
  );
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/addresses/domain/address.dart';
import 'package:smart_fashion/features/addresses/presentation/address_providers.dart';
import 'package:smart_fashion/features/auth/domain/auth_user.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';

import '../auth/fake_auth_repository.dart';
import 'address_fixtures.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeAddressRepository repository;
  late MemorySelection store;
  late ProviderContainer container;
  const userId = 'test-id';
  setUp(() async {
    auth = FakeAuthRepository()..session = FakeAuthRepository.user;
    repository = FakeAddressRepository();
    store = MemorySelection();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        addressRepositoryProvider.overrideWithValue(repository),
        addressSelectionStoreProvider.overrideWithValue(store),
      ],
    );
    container.listen(authSessionProvider, (_, _) {});
    await container.read(authSessionProvider.future);
    container.listen(addressBookProvider, (_, _) {});
    await container.read(addressBookProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await auth.close();
  });
  AddressBookController controller() =>
      container.read(addressBookProvider.notifier);
  AddressBookState book() => container.read(addressBookProvider).requireValue;

  test('xóa chờ server, chặn lặp và chỉ dọn lựa chọn A sau xác nhận', () async {
    repository.rows.add(fixtureAddress('a', userId));
    await controller().reload();
    await controller().select('a');
    store.values['B'] = 'b';
    final pending = Completer<void>();
    repository.onDelete = (_, _) => pending.future;
    final first = controller().delete('a');
    expect(book().busy, isTrue);
    expect(book().addresses.single.id, 'a');
    expect(book().selected?.id, 'a');
    expect(book().message, isNull);
    expect(store.values[userId], 'a');
    expect(await controller().delete('a'), isFalse);
    expect(repository.writes, 1);
    pending.complete();
    expect(await first, isTrue);
    expect(book().addresses, isEmpty);
    expect(book().selected, isNull);
    expect(store.values[userId], isNull);
    expect(store.values['B'], 'b');
    expect(book().message, 'Đã xóa địa chỉ.');
  });
  test('xóa địa chỉ khác giữ lựa chọn hiện tại', () async {
    repository.rows.addAll([
      fixtureAddress('a', userId),
      fixtureAddress('b', userId),
    ]);
    await controller().reload();
    await controller().select('a');
    expect(await controller().delete('b'), isTrue);
    expect(book().selected?.id, 'a');
    expect(store.values[userId], 'a');
  });
  test('server đã xóa nhưng storage lỗi: bỏ chọn trong RAM, cảnh báo và xác minh lại', () async {
    repository.rows.add(fixtureAddress('a', userId));
    await controller().reload();
    await controller().select('a');
    store.fail = true;
    expect(await controller().delete('a'), isTrue);
    expect(book().addresses, isEmpty);
    expect(book().selected, isNull);
    expect(book().failure?.message, contains('chưa xóa được lựa chọn'));
    store.fail = false;
    await controller().reload();
    expect(store.values[userId], isNull);
    expect(book().selected, isNull);
  });
  test(
    'timeout xóa giữ dữ liệu, không báo thành công và không tự gửi lại',
    () async {
      repository.rows.add(fixtureAddress('a', userId));
      await controller().reload();
      await controller().select('a');
      repository.onDelete = (_, _) async =>
          throw const AddressFailure('Chưa xác nhận được xóa', uncertain: true);
      expect(await controller().delete('a'), isFalse);
      expect(book().addresses.single.id, 'a');
      expect(book().message, isNull);
      expect(book().requiresRefresh, isTrue);
      expect(store.values[userId], 'a');
      expect(await controller().delete('a'), isFalse);
      expect(repository.writes, 1);
    },
  );
  for (final nextId in <String?>['B', null]) {
    test('đang xóa A rồi chuyển sang $nextId, bỏ kết quả phiên cũ', () async {
      repository.rows.addAll([
        fixtureAddress('a', userId),
        fixtureAddress('b', 'B'),
      ]);
      await controller().reload();
      await controller().select('a');
      store.values['B'] = 'b';
      final pending = Completer<void>();
      repository.onDelete = (_, _) => pending.future;
      final request = controller().delete('a');
      auth.setUser(
        nextId == null
            ? null
            : const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
      );
      await container.pump();
      await container.read(addressBookProvider.future);
      pending.complete();
      expect(await request, isFalse);
      expect(
        book().addresses.map((a) => a.id),
        nextId == null ? isEmpty : ['b'],
      );
      expect(book().message, isNull);
      expect(store.values['B'], 'b');
      auth.setUser(FakeAuthRepository.user);
      await container.pump();
      await container.read(addressBookProvider.future);
      expect(book().addresses, isEmpty);
      expect(store.values[userId], isNull);
    });
  }

  test('CRUD/chọn/xóa lựa chọn; khôi phục phải kiểm tra server', () async {
    expect(book().addresses, isEmpty);
    expect(await controller().save('a', draft, editing: false), isTrue);
    expect(await controller().select('a'), isTrue);
    expect(store.values[userId], 'a');
    container.invalidate(addressBookProvider);
    expect(
      (await container.read(addressBookProvider.future)).selected?.id,
      'a',
    );
    expect(await controller().save('a', draft, editing: true), isTrue);
    expect(book().addresses, hasLength(1));
    expect(await controller().delete('a'), isTrue);
    expect(book().selected, isNull);
    expect(store.values[userId], isNull);
    store.values[userId] = 'removed-on-other-device';
    await controller().reload();
    expect(store.values[userId], isNull);
  });
  test('double submit chỉ ghi một lần, lỗi không mất danh sách', () async {
    repository.rows.add(fixtureAddress('a', userId));
    await controller().reload();
    final pending = Completer<Address>();
    repository.onSave = (_, _, _) => pending.future;
    final first = controller().save('b', draft, editing: false);
    expect(book().busy, isTrue);
    expect(await controller().save('b', draft, editing: false), isFalse);
    expect(repository.writes, 1);
    pending.completeError(const AddressFailure('Không có quyền'));
    expect(await first, isFalse);
    expect(book().addresses.single.id, 'a');
    expect(book().failure?.message, 'Không có quyền');
  });
  test('timeout ghi chặn ghi mới đến khi tải server thành công', () async {
    repository.onSave = (_, _, _) async =>
        throw const AddressFailure('Mạng', uncertain: true);
    expect(await controller().save('a', draft, editing: false), isFalse);
    expect(book().requiresRefresh, isTrue);
    expect(await controller().save('b', draft, editing: false), isFalse);
    repository.onLoad = (_) async => throw const AddressFailure('Mạng');
    expect(await controller().reload(), isFalse);
    expect(book().requiresRefresh, isTrue);
    repository.onLoad = null;
    expect(await controller().reload(), isTrue);
    expect(book().requiresRefresh, isFalse);
  });
  test('đổi A → B → logout, phản hồi ghi A bị bỏ qua', () async {
    final pending = Completer<Address>();
    repository.onSave = (_, _, _) => pending.future;
    final request = controller().save('a', draft, editing: false);
    repository.rows.add(fixtureAddress('b', 'B'));
    store.values['B'] = 'b';
    auth.setUser(
      const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
    );
    await container.pump();
    expect(
      (await container.read(addressBookProvider.future)).selected?.id,
      'b',
    );
    pending.complete(fixtureAddress('a', userId));
    expect(await request, isFalse);
    expect(book().addresses.single.userId, 'B');
    auth.setUser(null);
    await container.pump();
    expect(
      (await container.read(addressBookProvider.future)).addresses,
      isEmpty,
    );
    expect(book().selected, isNull);
  });
  test('phản hồi đọc cũ không thay state sau đổi tài khoản', () async {
    final pending = Completer<List<Address>>();
    repository.onLoad = (id) =>
        id == userId ? pending.future : Future.value([]);
    container.invalidate(addressBookProvider);
    container.read(addressBookProvider);
    auth.setUser(
      const AuthUser(id: 'B', email: 'b@example.com', fullName: 'B'),
    );
    await container.pump();
    await container.read(addressBookProvider.future);
    pending.complete([fixtureAddress('a', userId)]);
    await container.pump();
    expect(book().addresses, isEmpty);
  });
  test('địa chỉ biến mất lúc chọn; lỗi storage không báo thành công', () async {
    store.values[userId] = 'a';
    expect(await controller().select('a'), isFalse);
    expect(store.values[userId], isNull);
    repository.rows.add(fixtureAddress('a', userId));
    store.fail = true;
    expect(await controller().select('a'), isFalse);
    expect(book().selected, isNull);
  });
  test('xóa lỗi giữ dữ liệu và lựa chọn', () async {
    repository.rows.add(fixtureAddress('a', userId));
    await controller().reload();
    await controller().select('a');
    repository.deleteFailure = const AddressFailure('Không thể xóa');
    expect(await controller().delete('a'), isFalse);
    expect(book().selected?.id, 'a');
    expect(store.values[userId], 'a');
  });
  test(
    'A đăng xuất rồi đăng nhập lại A, bỏ phản hồi ghi của phiên cũ',
    () async {
      final pending = Completer<Address>();
      repository.onSave = (_, _, _) => pending.future;
      final request = controller().save('old', draft, editing: false);
      auth.setUser(null);
      await container.pump();
      await container.read(addressBookProvider.future);
      auth.setUser(FakeAuthRepository.user);
      await container.pump();
      await container.read(addressBookProvider.future);
      pending.complete(fixtureAddress('old', userId));
      expect(await request, isFalse);
      expect(book().addresses, isEmpty);
    },
  );
}

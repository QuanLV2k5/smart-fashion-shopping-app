import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../../core/storage/preferences_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/address_selection_store.dart';
import '../data/supabase_address_repository.dart';
import '../domain/address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => SupabaseAddressRepository(ref.watch(supabaseClientProvider)),
);
final addressSelectionStoreProvider = Provider<AddressSelectionStore>(
  (ref) => PreferencesAddressSelectionStore(ref.watch(preferencesProvider)),
);
final addressUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.hasValue
      ? session.value?.id
      : ref.watch(authRepositoryProvider).currentUser?.id;
});

class AddressBookState {
  AddressBookState({
    List<Address> addresses = const [],
    this.selectedId,
    this.busy = false,
    this.failure,
    this.message,
    this.requiresRefresh = false,
  }) : addresses = List.unmodifiable(addresses);
  final List<Address> addresses;
  final String? selectedId, message;
  final bool busy, requiresRefresh;
  final AddressFailure? failure;
  Address? get selected {
    if (requiresRefresh) return null;
    for (final address in addresses) {
      if (address.id == selectedId) return address;
    }
    return null;
  }
}

final addressBookProvider =
    AsyncNotifierProvider.autoDispose<AddressBookController, AddressBookState>(
      AddressBookController.new,
      retry: (_, _) => null,
    );

/// Dữ liệu của phiên cũ không được dùng lại khi đăng xuất/đổi tài khoản.
class AddressBookController extends AsyncNotifier<AddressBookState> {
  int _revision = 0;
  bool _writing = false;
  String? _userId;

  @override
  Future<AddressBookState> build() async {
    final userId = ref.watch(addressUserIdProvider);
    final repository = ref.watch(addressRepositoryProvider);
    final store = ref.watch(addressSelectionStoreProvider);
    _userId = userId;
    final revision = ++_revision;
    if (userId == null) return AddressBookState();
    final addresses = await repository.load(userId);
    if (!_active(userId, revision)) return AddressBookState();
    return _restore(addresses, userId, store);
  }

  bool _active(String userId, int revision) =>
      ref.mounted &&
      revision == _revision &&
      ref.read(addressUserIdProvider) == userId;

  Future<AddressBookState> _restore(
    List<Address> addresses,
    String userId,
    AddressSelectionStore store,
  ) async {
    try {
      final saved = await store.read(userId);
      final valid = addresses.any((a) => a.id == saved);
      if (saved != null && !valid) await store.write(userId, null);
      return AddressBookState(
        addresses: addresses,
        selectedId: valid ? saved : null,
      );
    } catch (_) {
      return AddressBookState(
        addresses: addresses,
        failure: const AddressFailure(
          'Không đọc được lựa chọn đã lưu. Bạn có thể chọn lại địa chỉ.',
        ),
      );
    }
  }

  Future<bool> reload() => _run((userId, old, repository, store) async {
    final revision = _revision;
    final addresses = await repository.load(userId);
    if (!_active(userId, revision)) return AddressBookState();
    return _restore(addresses, userId, store);
  }, allowRefresh: true);

  Future<bool> select(String id) => _run((
    userId,
    old,
    repository,
    store,
  ) async {
    final revision = _revision;
    // Đối chiếu lại server, kể cả địa chỉ bị xóa từ thiết bị khác.
    final addresses = await repository.load(userId);
    if (!_active(userId, revision)) return AddressBookState();
    if (!addresses.any((a) => a.id == id)) {
      await store.write(userId, null);
      return AddressBookState(
        addresses: addresses,
        failure: const AddressFailure(
          'Địa chỉ đã bị xóa. Vui lòng chọn địa chỉ khác.',
        ),
      );
    }
    if (ref.read(addressUserIdProvider) != userId) return AddressBookState();
    await store.write(userId, id);
    return AddressBookState(
      addresses: addresses,
      selectedId: id,
      message: 'Đã chọn địa chỉ giao hàng.',
    );
  });

  Future<bool> save(String id, AddressDraft draft, {required bool editing}) =>
      _run((userId, old, repository, store) async {
        final address = editing
            ? await repository.update(userId, id, draft)
            : await repository.create(userId, id, draft);
        return AddressBookState(
          addresses: [...old.addresses.where((a) => a.id != id), address],
          selectedId: old.selectedId,
          message: 'Đã lưu địa chỉ.',
        );
      });

  Future<bool> delete(String id) =>
      _run((userId, old, repository, store) async {
        final revision = _revision;
        await repository.delete(userId, id);
        if (!_active(userId, revision)) return AddressBookState();
        final selectedId = old.selectedId == id ? null : old.selectedId;
        AddressFailure? failure;
        if (old.selectedId == id) {
          try {
            await store.write(userId, null);
          } catch (_) {
            failure = const AddressFailure(
              'Đã xóa địa chỉ nhưng chưa xóa được lựa chọn trên máy. Lựa chọn sẽ được kiểm tra lại khi mở ứng dụng.',
            );
          }
        }
        return AddressBookState(
          addresses: old.addresses.where((a) => a.id != id).toList(),
          selectedId: selectedId,
          failure: failure,
          message: 'Đã xóa địa chỉ.',
        );
      }, successWithWarning: true);

  Future<bool> _run(
    Future<AddressBookState> Function(
      String,
      AddressBookState,
      AddressRepository,
      AddressSelectionStore,
    )
    action, {
    bool allowRefresh = false,
    bool successWithWarning = false,
  }) async {
    final userId = _userId;
    final old = state.asData?.value;
    if (_writing ||
        userId == null ||
        old == null ||
        ref.read(addressUserIdProvider) != userId ||
        (old.requiresRefresh && !allowRefresh)) {
      return false;
    }
    final revision = _revision;
    final repository = ref.read(addressRepositoryProvider);
    final store = ref.read(addressSelectionStoreProvider);
    _writing = true;
    state = AsyncData(
      AddressBookState(
        addresses: old.addresses,
        selectedId: old.selectedId,
        busy: true,
        requiresRefresh: old.requiresRefresh,
      ),
    );
    try {
      final result = await action(userId, old, repository, store);
      if (!_active(userId, revision)) return false;
      state = AsyncData(result);
      // Xóa đã được server xác nhận vẫn thành công nếu chỉ lỗi dọn lựa chọn
      // local; state giữ cảnh báo để UI thông báo đúng, không gửi xóa lần nữa.
      return result.failure == null || successWithWarning;
    } catch (error) {
      if (_active(userId, revision)) {
        final failure = error is AddressFailure
            ? error
            : const AddressFailure(
                'Không thể cập nhật địa chỉ. Vui lòng tải lại.',
                uncertain: true,
              );
        state = AsyncData(
          AddressBookState(
            addresses: old.addresses,
            selectedId: old.selectedId,
            failure: failure,
            requiresRefresh:
                allowRefresh || failure.uncertain || old.requiresRefresh,
          ),
        );
      }
      return false;
    } finally {
      _writing = false;
    }
  }
}

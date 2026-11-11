import 'package:smart_fashion/features/addresses/domain/address.dart';

const draft = AddressDraft(
  recipientName: ' Phúc ',
  phone: '0901234567',
  addressLine: '12 Nguyễn Văn Linh',
  ward: 'Hải Châu',
  district: 'Hải Châu',
  city: 'Đà Nẵng',
);
Address fixtureAddress(
  String id,
  String userId, [
  AddressDraft details = draft,
]) => Address(
  id: id,
  userId: userId,
  details: details,
  createdAt: DateTime.utc(2026, 11, 11),
  updatedAt: DateTime.utc(2026, 11, 11),
);

class MemorySelection implements AddressSelectionStore {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String userId) async {
    if (fail) throw Exception('storage');
    return values[userId];
  }

  @override
  Future<void> write(String userId, String? id) async {
    if (fail) throw Exception('storage');
    if (id == null) {
      values.remove(userId);
    } else {
      values[userId] = id;
    }
  }
}

class FakeAddressRepository implements AddressRepository {
  final rows = <Address>[];
  int writes = 0, loads = 0;
  Future<List<Address>> Function(String)? onLoad;
  Future<Address> Function(String, String, AddressDraft)? onSave;
  AddressFailure? deleteFailure;
  Future<void> Function(String, String)? onDelete;
  @override
  Future<List<Address>> load(String userId) async {
    loads++;
    if (onLoad != null) return onLoad!(userId);
    return rows.where((a) => a.userId == userId).toList();
  }

  Future<Address> _save(String userId, String id, AddressDraft draft) async {
    writes++;
    if (onSave != null) return onSave!(userId, id, draft);
    final address = fixtureAddress(id, userId, draft);
    rows.removeWhere((a) => a.id == id && a.userId == userId);
    rows.add(address);
    return address;
  }

  @override
  Future<Address> create(String userId, String id, AddressDraft draft) =>
      _save(userId, id, draft);
  @override
  Future<Address> update(String userId, String id, AddressDraft draft) =>
      _save(userId, id, draft);
  @override
  Future<void> delete(String userId, String id) async {
    writes++;
    if (onDelete != null) await onDelete!(userId, id);
    if (deleteFailure != null) throw deleteFailure!;
    rows.removeWhere((a) => a.id == id && a.userId == userId);
  }
}

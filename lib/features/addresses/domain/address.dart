/// Các trường nghiệp vụ tương ứng public.addresses; không có is_default.
class AddressDraft {
  const AddressDraft({
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
  });
  final String recipientName, phone, addressLine, ward, district, city;

  Map<String, String> get fields => {
    'recipient_name': recipientName.trim(),
    'phone': phone.trim(),
    'address_line': addressLine.trim(),
    'ward': ward.trim(),
    'district': district.trim(),
    'city': city.trim(),
  };

  Map<String, String> validate() {
    final errors = <String, String>{};
    for (final entry in fields.entries) {
      if (entry.key == 'phone') {
        if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(entry.value)) {
          errors[entry.key] = 'Nhập 9–15 chữ số, có thể bắt đầu bằng +.';
        }
      } else {
        final max = entry.key == 'address_line' ? 250 : 100;
        if (entry.value.isEmpty || entry.value.runes.length > max) {
          errors[entry.key] = 'Vui lòng nhập từ 1 đến $max ký tự.';
        }
      }
    }
    return errors;
  }
}

class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, userId;
  final AddressDraft details;
  final DateTime createdAt, updatedAt;
}

class AddressFailure implements Exception {
  const AddressFailure(this.message, {this.uncertain = false});
  final String message;
  final bool uncertain;
  @override
  String toString() => message;
}

abstract interface class AddressRepository {
  Future<List<Address>> load(String userId);
  Future<Address> create(String userId, String id, AddressDraft draft);
  Future<Address> update(String userId, String id, AddressDraft draft);
  Future<void> delete(String userId, String id);
}

abstract interface class AddressSelectionStore {
  Future<String?> read(String userId);
  Future<void> write(String userId, String? addressId);
}

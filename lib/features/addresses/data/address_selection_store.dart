import 'package:shared_preferences/shared_preferences.dart';

import '../domain/address.dart';

class PreferencesAddressSelectionStore implements AddressSelectionStore {
  const PreferencesAddressSelectionStore(this.preferences);
  final SharedPreferencesAsync preferences;
  String _key(String userId) => 'addresses.selected.v1.$userId';
  @override
  Future<String?> read(String userId) => preferences.getString(_key(userId));
  @override
  Future<void> write(String userId, String? addressId) async {
    if (addressId == null) {
      await preferences.remove(_key(userId));
    } else {
      await preferences.setString(_key(userId), addressId);
    }
  }
}

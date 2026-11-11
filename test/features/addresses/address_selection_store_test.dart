import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fashion/features/addresses/data/address_selection_store.dart';

class RecordingPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  test(
    'lựa chọn được lưu riêng A/B, chỉ lưu ID; bỏ chọn A không xóa B',
    () async {
      final preferences = RecordingPreferences();
      final store = PreferencesAddressSelectionStore(preferences);
      await store.write('A', 'address-a');
      await store.write('B', 'address-b');
      expect(await store.read('A'), 'address-a');
      expect(await store.read('B'), 'address-b');
      expect(
        preferences.values.values,
        unorderedEquals(['address-a', 'address-b']),
      );
      await store.write('A', null);
      expect(await store.read('A'), isNull);
      expect(await store.read('B'), 'address-b');
    },
  );
}

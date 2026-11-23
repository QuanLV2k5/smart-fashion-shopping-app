import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/checkout.dart';

CheckoutRequestStore createCheckoutRequestStore(
  SharedPreferencesAsync preferences,
) => _BrowserCheckoutRequestStore(preferences);

// The shared_preferences web implementation writes to browser localStorage.
class _BrowserCheckoutRequestStore implements CheckoutRequestStore {
  const _BrowserCheckoutRequestStore(this.preferences);
  final SharedPreferencesAsync preferences;

  String _key(String userId) => 'orders.pending.checkout.v1.$userId';

  @override
  Future<CheckoutRequest?> read(String userId) async {
    final value = await preferences.getString(_key(userId));
    return value == null
        ? null
        : CheckoutRequest.fromJson(orderObject(jsonDecode(value)));
  }

  @override
  Future<void> save(String userId, CheckoutRequest request) async {
    final key = _key(userId);
    final payload = jsonEncode(request.toJson());
    await preferences.setString(key, payload);
    if (await preferences.getString(key) != payload) {
      throw StateError('Pending checkout was not stored');
    }
  }

  @override
  Future<void> clear(String userId) => preferences.remove(_key(userId));
}

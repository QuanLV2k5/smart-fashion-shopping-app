import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/checkout.dart';

class SupabaseCheckoutRepository implements CheckoutRepository {
  const SupabaseCheckoutRepository(this.client);
  final SupabaseClient? client;

  @override
  Future<CheckoutQuote> quote(String userId, String addressId) async {
    final response = await ordersRpc(client, userId, 'create_checkout_quote', {
      'p_address_id': addressId,
    });
    final quote = CheckoutQuote.fromJson(response);
    if (quote.addressId != addressId)
      throw const FormatException('Unexpected quote address');
    return quote;
  }

  @override
  Future<PlacedOrder> place(String userId, CheckoutRequest request) async {
    final response = await ordersRpc(client, userId, 'place_cod_order', {
      'p_quote_id': request.quoteId,
      'p_request_id': request.requestId,
    });
    checkOrdersVersion(response);
    return _placed(response, request);
  }

  @override
  Future<PlacedOrder?> lookup(String userId, CheckoutRequest request) async {
    final response = await ordersRpc(client, userId, 'lookup_order_request', {
      'p_request_id': request.requestId,
    });
    if (!orderField<bool>(response, 'found')) return null;
    if (response['operation'] != 'place_cod_order') {
      throw const OrdersFailure('SF_REQUEST_CONFLICT');
    }
    return _placed(response, request);
  }

  PlacedOrder _placed(OrderJson response, CheckoutRequest request) {
    final placed = PlacedOrder.fromJson(orderObject(response['result']));
    if (placed.requestId != request.requestId)
      throw const FormatException('Unexpected Orders receipt');
    return placed;
  }
}

Future<OrderJson> ordersRpc(
  SupabaseClient? client,
  String userId,
  String name,
  OrderJson params,
) async {
  if (client == null) throw const OrdersFailure('OFFLINE');
  final session = client.auth.currentSession;
  if (session == null || session.user.id != userId) {
    throw const OrdersFailure('SF_AUTH_REQUIRED');
  }
  try {
    // Bind this request to the account that initiated it even if the SDK
    // changes its default token before sending the HTTP request.
    final data = await client
        .rpc<dynamic>(name, params: params)
        .setHeader('Authorization', 'Bearer ${session.accessToken}')
        .retry(enabled: false)
        .timeout(const Duration(seconds: 25));
    return orderObject(data);
  } on PostgrestException catch (error) {
    if (error.code?.startsWith('PT') == true &&
        error.message.startsWith('SF_')) {
      throw OrdersFailure(error.message);
    }
    rethrow;
  }
}

class PreferencesCheckoutRequestStore implements CheckoutRequestStore {
  const PreferencesCheckoutRequestStore(this.preferences);
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

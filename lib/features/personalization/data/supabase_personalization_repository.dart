import 'package:supabase_flutter/supabase_flutter.dart';

import '../../catalog/data/supabase_catalog_repository.dart';
import '../domain/personalization.dart';

class SupabasePersonalizationRepository implements PersonalizationRepository {
  const SupabasePersonalizationRepository(this.client);
  final SupabaseClient? client;

  Future<dynamic> _rpc(
    String? userId,
    String name, [
    Json params = const {},
  ]) async {
    final backend = client;
    if (backend == null) {
      throw const PersonalizationFailure('SF_BACKEND_NOT_READY');
    }
    final session = backend.auth.currentSession;
    if (session?.user.id != userId) {
      throw const PersonalizationFailure('SF_SESSION_CHANGED');
    }
    try {
      var request = backend.rpc<dynamic>(name, params: params);
      // Capture the initiating token: a delayed write cannot run as the next user.
      if (session != null) {
        request = request.setHeader(
          'Authorization',
          'Bearer ${session.accessToken}',
        );
      }
      return await request
          .retry(enabled: false)
          .timeout(const Duration(seconds: 25));
    } on PostgrestException catch (error) {
      throw PersonalizationFailure(
        error.message.startsWith('SF_')
            ? error.message
            : error.code == 'PGRST202'
            ? 'SF_BACKEND_NOT_READY'
            : 'SF_REQUEST_FAILED',
      );
    }
  }

  @override
  Future<AccountAccess> access(String userId) async {
    try {
      final json = Map<String, dynamic>.from(
        await _rpc(userId, 'get_my_access') as Map,
      );
      return AccountAccess(
        userId: userId,
        blocked: json['state'] == 'blocked',
        admin: json['is_admin'] == true,
      );
    } on PersonalizationFailure catch (error) {
      if (error.code == 'SF_ACCESS_BLOCKED') {
        return AccountAccess(userId: userId, blocked: true);
      }
      rethrow;
    }
  }

  @override
  Future<List<FavoriteEntry>> favorites(String userId) async {
    final json = Map<String, dynamic>.from(
      await _rpc(userId, 'get_favorites') as Map,
    );
    return (json['items'] as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FavoriteEntry(
        row['product_id'] as String,
        row['product'] == null
            ? null
            : productFromJson(
                Map<String, dynamic>.from(row['product'] as Map),
                imageUrl: (path) => catalogImageUrl(client!, path),
              ),
      );
    }).toList();
  }

  @override
  Future<void> setFavorite(
    String userId,
    String productId,
    bool selected,
  ) async {
    await _rpc(userId, 'set_favorite', {
      'p_product_id': productId,
      'p_favorite': selected,
    });
  }

  @override
  Future<ReviewPage> reviews(
    String? userId,
    String productId,
    int offset,
  ) async => ReviewPage.fromJson(
    Map<String, dynamic>.from(
      await _rpc(userId, 'get_product_reviews', {
        'p_product_id': productId,
        'p_offset': offset,
      }) as Map,
    ),
  );
  @override
  Future<void> submitReview(
    String userId,
    String productId,
    int rating,
    String body,
  ) async {
    await _rpc(userId, 'submit_product_review', {
      'p_product_id': productId,
      'p_rating': rating,
      'p_body': body,
    });
  }

  @override
  Future<UsersPage> users(String userId, String search, int offset) async =>
      UsersPage.fromJson(
        Map<String, dynamic>.from(
          await _rpc(userId, 'list_app_users', {
            'p_search': search,
            'p_offset': offset,
          }) as Map,
        ),
      );
  @override
  Future<ManagedUser> user(String userId, String targetId) async =>
      ManagedUser.fromJson(
        Map<String, dynamic>.from(
          await _rpc(userId, 'get_app_user', {'p_user_id': targetId}) as Map,
        ),
      );
  @override
  Future<void> setAccess(
    String userId,
    ManagedUser target,
    bool blocked,
  ) async {
    await _rpc(userId, 'set_user_access', {
      'p_user_id': target.id,
      'p_blocked': blocked,
      'p_expected_version': target.version,
    });
  }
}

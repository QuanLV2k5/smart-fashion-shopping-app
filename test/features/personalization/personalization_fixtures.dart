import 'package:smart_fashion/features/personalization/domain/personalization.dart';

import '../catalog/catalog_fixtures.dart';

ReviewPage reviewPage({
  bool eligible = false,
  int stars = 0,
  String body = '',
  bool more = false,
}) => ReviewPage.fromJson({
  'product_name': 'Áo thun Essential',
  'can_review': eligible,
  'orders_ready': true,
  'my_review': stars == 0
      ? null
      : {
          'id': 'r1',
          'rating': stars,
          'body': body,
          'created_at': '2026-11-22T00:00:00Z',
        },
  'count': stars == 0 ? 0 : 1,
  'average': stars,
  'has_more': more,
  'items': stars == 0
      ? <Json>[]
      : [
          {
            'id': 'r1',
            'rating': stars,
            'body': body,
            'created_at': '2026-11-22T00:00:00Z',
            'author_name': 'Người mua hàng',
          },
        ],
});
ManagedUser managedUser({
  String id = 'customer-b',
  bool blocked = false,
  int version = 0,
}) => ManagedUser.fromJson({
  'id': id,
  'full_name': 'Ngọc Linh',
  'email': 'fixture@example.test',
  'phone': '0901234567',
  'role': 'customer',
  'access_state': blocked ? 'blocked' : 'active',
  'access_version': version,
});

class FakePersonalizationRepository implements PersonalizationRepository {
  final saved = <String, List<FavoriteEntry>>{};
  ReviewPage page = reviewPage();
  ManagedUser target = managedUser();
  bool failSave = false;
  int writes = 0, userReads = 0, reviewWrites = 0;
  Future<void> Function()? onFavoriteWrite;
  Future<void> Function()? onReviewWrite;
  Future<List<FavoriteEntry>> Function(String)? onFavoriteRead;
  @override
  Future<AccountAccess> access(String userId) async =>
      AccountAccess(userId: userId);
  @override
  Future<List<FavoriteEntry>> favorites(String userId) async =>
      onFavoriteRead == null
      ? List.of(saved[userId] ?? [])
      : onFavoriteRead!(userId);
  @override
  Future<void> setFavorite(
    String userId,
    String productId,
    bool selected,
  ) async {
    writes++;
    if (onFavoriteWrite != null) await onFavoriteWrite!();
    if (failSave) throw const PersonalizationFailure('SF_REQUEST_FAILED');
    final items = saved.putIfAbsent(userId, () => []);
    items.removeWhere((e) => e.productId == productId);
    if (selected) items.add(FavoriteEntry(productId, product()));
  }

  @override
  Future<ReviewPage> reviews(
    String? userId,
    String productId,
    int offset,
  ) async => page;
  @override
  Future<void> submitReview(
    String userId,
    String productId,
    int rating,
    String body,
  ) async {
    reviewWrites++;
    if (onReviewWrite != null) await onReviewWrite!();
    if (failSave) throw const PersonalizationFailure('SF_REQUEST_FAILED');
    page = reviewPage(eligible: true, stars: rating, body: body);
  }

  @override
  Future<UsersPage> users(String userId, String search, int offset) async {
    userReads++;
    return UsersPage.fromJson({'items': <Json>[], 'has_more': false});
  }

  @override
  Future<ManagedUser> user(String userId, String targetId) async {
    userReads++;
    return target;
  }

  @override
  Future<void> setAccess(
    String userId,
    ManagedUser target,
    bool blocked,
  ) async {
    writes++;
    if (failSave) {
      throw const PersonalizationFailure('SF_ACCESS_VERSION_CONFLICT');
    }
    this.target = managedUser(blocked: blocked, version: target.version + 1);
  }
}

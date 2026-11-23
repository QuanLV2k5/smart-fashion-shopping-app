import '../../catalog/domain/catalog.dart';

typedef Json = Map<String, dynamic>;

class FavoriteEntry {
  const FavoriteEntry(this.productId, this.product);
  final String productId;
  // Hidden products remain removable without leaking their catalog metadata.
  final CatalogProduct? product;
}

class ProductReview {
  ProductReview.fromJson(Json json)
    : id = json['id'] as String,
      rating = json['rating'] as int,
      body = json['body'] as String,
      author = json['author_name'] as String? ?? 'Người mua hàng',
      createdAt = DateTime.parse(json['created_at'] as String);
  final String id, body, author;
  final int rating;
  final DateTime createdAt;
}

class ReviewPage {
  ReviewPage.fromJson(Json json)
    : productName = json['product_name'] as String,
      canReview = json['can_review'] as bool,
      ordersReady = json['orders_ready'] as bool,
      mine = json['my_review'] == null
          ? null
          : ProductReview.fromJson(
              Map<String, dynamic>.from(json['my_review'] as Map),
            ),
      count = json['count'] as int,
      average = (json['average'] as num).toDouble(),
      hasMore = json['has_more'] as bool,
      reviews = List.unmodifiable(
        (json['items'] as List).map(
          (v) => ProductReview.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
  final String productName;
  final bool canReview, ordersReady, hasMore;
  final ProductReview? mine;
  final int count;
  final double average;
  final List<ProductReview> reviews;
}

class AccountAccess {
  const AccountAccess({this.userId, this.blocked = false, this.admin = false});
  final String? userId;
  final bool blocked, admin;
}

class ManagedUser {
  ManagedUser.fromJson(Json json)
    : id = json['id'] as String,
      name = json['full_name'] as String,
      email = json['email'] as String? ?? '',
      phone = json['phone'] as String? ?? '',
      role = json['role'] as String,
      blocked = json['access_state'] == 'blocked',
      version = json['access_version'] as int;
  final String id, name, email, phone, role;
  final bool blocked;
  final int version;
  String get displayName => name.trim().isEmpty ? 'Chưa có tên' : name;
}

class UsersPage {
  UsersPage.fromJson(Json json)
    : users = List.unmodifiable(
        (json['items'] as List).map(
          (v) => ManagedUser.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      hasMore = json['has_more'] as bool;
  final List<ManagedUser> users;
  final bool hasMore;
}

abstract interface class PersonalizationRepository {
  Future<AccountAccess> access(String userId);
  Future<List<FavoriteEntry>> favorites(String userId);
  Future<void> setFavorite(String userId, String productId, bool selected);
  Future<ReviewPage> reviews(String? userId, String productId, int offset);
  Future<void> submitReview(
    String userId,
    String productId,
    int rating,
    String body,
  );
  Future<UsersPage> users(String userId, String search, int offset);
  Future<ManagedUser> user(String userId, String targetId);
  Future<void> setAccess(String userId, ManagedUser target, bool blocked);
}

class PersonalizationFailure implements Exception {
  const PersonalizationFailure(this.code);
  final String code;
  String get message => switch (code) {
    'SF_ACCESS_BLOCKED' =>
      'Tài khoản đang tạm khóa. Vui lòng liên hệ quản trị viên.',
    'SF_AUTH_REQUIRED' ||
    'SF_SESSION_CHANGED' => 'Phiên đã thay đổi. Vui lòng đăng nhập lại.',
    'SF_FORBIDDEN' => 'Bạn không có quyền thực hiện thao tác này.',
    'SF_PROTECTED_ACCOUNT' =>
      'Không thể khóa tài khoản quản trị viên hoặc chính mình.',
    'SF_ACCESS_VERSION_CONFLICT' =>
      'Trạng thái đã thay đổi. Hãy tải lại trước khi xác nhận lại.',
    'SF_USER_NOT_FOUND' => 'Không tìm thấy người dùng.',
    'SF_PRODUCT_UNAVAILABLE' => 'Sản phẩm hiện không còn được bán.',
    'SF_REVIEW_PURCHASE_REQUIRED' =>
      'Bạn chỉ được đánh giá sản phẩm trong đơn đã hoàn tất của mình.',
    'SF_INVALID_REVIEW' => 'Chọn từ 1 đến 5 sao; nhận xét tối đa 1.000 ký tự.',
    'SF_FAVORITES_LIMIT' =>
      'Danh sách đã có 200 sản phẩm. Hãy bỏ bớt trước khi thêm.',
    'SF_BACKEND_NOT_READY' =>
      'Dịch vụ đang chờ cập nhật. Vui lòng thử lại sau.',
    _ => 'Chưa thực hiện được. Kiểm tra kết nối rồi thử lại.',
  };
  @override
  String toString() => message;
}

String personalizationMessage(Object? error) => error is PersonalizationFailure
    ? error.message
    : 'Chưa tải được dữ liệu. Kiểm tra kết nối rồi thử lại.';

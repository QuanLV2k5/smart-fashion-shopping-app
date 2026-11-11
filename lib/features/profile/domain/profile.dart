import 'package:flutter/foundation.dart';

/// Entity đại diện cho hồ sơ người dùng trong ứng dụng.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarPath,
    this.avatarUrl,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarPath;
  final String? avatarUrl;
  final DateTime? updatedAt;

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarPath,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          phone == other.phone &&
          avatarPath == other.avatarPath &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      Object.hash(id, email, fullName, phone, avatarPath, avatarUrl);

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, fullName: $fullName, phone: $phone, avatarPath: $avatarPath)';
}

/// Quy tắc kiểm tra dữ liệu hồ sơ cá nhân.
abstract final class ProfileValidation {
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length > 100) {
      return 'Họ và tên không được vượt quá 100 ký tự';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Số điện thoại là trường tùy chọn trong schema
    }
    final trimmed = value.trim();
    if (trimmed.length > 20) {
      return 'Số điện thoại không được vượt quá 20 ký tự';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Số điện thoại không hợp lệ (từ 9 đến 15 chữ số)';
    }
    return null;
  }
}

/// Thông báo lỗi nghiệp vụ hồ sơ.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message, {this.isNetwork = false});

  final String message;
  final bool isNetwork;

  static const network = ProfileFailure(
    'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng rồi thử lại.',
    isNetwork: true,
  );

  static const unavailable = ProfileFailure(
    'Dịch vụ hồ sơ chưa sẵn sàng. Vui lòng thử lại sau.',
  );

  static const storageUpload = ProfileFailure(
    'Không thể tải ảnh đại diện lên máy chủ. Vui lòng thử lại sau.',
  );

  static const invalidData = ProfileFailure(
    'Thông tin hồ sơ chưa hợp lệ. Vui lòng kiểm tra lại.',
  );

  static const unknown = ProfileFailure(
    'Có lỗi xảy ra khi cập nhật hồ sơ. Vui lòng thử lại.',
  );

  @override
  String toString() => message;
}

/// Hợp đồng Repository quản lý hồ sơ người dùng.
abstract interface class ProfileRepository {
  /// Lấy thông tin hồ sơ của tài khoản hiện tại.
  Future<UserProfile?> fetchProfile();

  /// Cập nhật họ tên, số điện thoại hoặc đường dẫn avatar.
  Future<UserProfile> updateProfile({
    required String fullName,
    String? phone,
    String? avatarPath,
  });

  /// Tải file ảnh đại diện lên Supabase Storage và trả về đường dẫn lưu trữ.
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  /// Theo dõi thay đổi hồ sơ (nếu có).
  Stream<UserProfile?> watchProfile();
}

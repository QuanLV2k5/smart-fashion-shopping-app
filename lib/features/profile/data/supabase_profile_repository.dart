import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

/// Triển khai ProfileRepository giao tiếp với Supabase Cloud.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _backend {
    final client = _client;
    if (client == null) {
      throw ProfileFailure.unavailable;
    }
    return client;
  }

  String? _resolveAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    // Presets are local identifiers, not objects in the avatars bucket.
    if (avatarPath.startsWith('preset:')) return null;
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }
    try {
      return _backend.storage.from('avatars').getPublicUrl(avatarPath);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfile?> fetchProfile() async {
    final currentUser = _client?.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final data = await _backend
          .from('profiles')
          .select('id, full_name, phone, avatar_path, updated_at')
          .eq('id', currentUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 25));

      if (data == null) {
        final metaName = switch (currentUser.userMetadata?['full_name']) {
          final String name => name,
          _ => '',
        };
        return UserProfile(
          id: currentUser.id,
          email: currentUser.email ?? '',
          fullName: metaName,
        );
      }

      final avatarPath = data['avatar_path'] as String?;
      return UserProfile(
        id: currentUser.id,
        email: currentUser.email ?? '',
        fullName: (data['full_name'] as String?) ?? '',
        phone: data['phone'] as String?,
        avatarPath: avatarPath,
        avatarUrl: _resolveAvatarUrl(avatarPath),
        updatedAt: data['updated_at'] != null
            ? DateTime.tryParse(data['updated_at'].toString())
            : null,
      );
    } on ProfileFailure {
      rethrow;
    } on TimeoutException {
      throw ProfileFailure.network;
    } on PostgrestException catch (e) {
      throw _translatePostgrestError(e);
    } catch (_) {
      throw ProfileFailure.unknown;
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    String? phone,
    String? avatarPath,
  }) async {
    final nameError = ProfileValidation.validateFullName(fullName);
    if (nameError != null) throw ProfileFailure(nameError);

    final phoneError = ProfileValidation.validatePhone(phone);
    if (phoneError != null) throw ProfileFailure(phoneError);

    final currentUser = _backend.auth.currentUser;
    if (currentUser == null) throw ProfileFailure.unavailable;

    try {
      final updatePayload = <String, dynamic>{
        'full_name': fullName.trim(),
        'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
        // The form submits a complete profile; null explicitly resets an avatar.
        'avatar_path': avatarPath,
      };

      final data = await _backend
          .from('profiles')
          .update(updatePayload)
          .eq('id', currentUser.id)
          .select('id, full_name, phone, avatar_path, updated_at')
          .single()
          .timeout(const Duration(seconds: 25));

      if (_backend.auth.currentUser?.id != currentUser.id) {
        throw const ProfileFailure(
          'Phiên đăng nhập đã thay đổi. Vui lòng mở lại hồ sơ.',
        );
      }

      // Đồng bộ họ tên sang metadata của AuthUser để header/session khớp ngay
      try {
        await _backend.auth
            .updateUser(UserAttributes(data: {'full_name': fullName.trim()}))
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Không chặn cập nhật profile nếu sync metadata gặp timeout
      }

      final finalAvatarPath = data['avatar_path'] as String?;
      return UserProfile(
        id: currentUser.id,
        email: currentUser.email ?? '',
        fullName: (data['full_name'] as String?) ?? fullName.trim(),
        phone: data['phone'] as String?,
        avatarPath: finalAvatarPath,
        avatarUrl: _resolveAvatarUrl(finalAvatarPath),
        updatedAt: data['updated_at'] != null
            ? DateTime.tryParse(data['updated_at'].toString())
            : null,
      );
    } on ProfileFailure {
      rethrow;
    } on TimeoutException {
      throw ProfileFailure.network;
    } on PostgrestException catch (e) {
      throw _translatePostgrestError(e);
    } catch (_) {
      throw ProfileFailure.unknown;
    }
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final currentUser = _backend.auth.currentUser;
    if (currentUser == null) throw ProfileFailure.unavailable;

    if (bytes.length > 2 * 1024 * 1024) {
      throw const ProfileFailure('Dung lượng ảnh vượt quá giới hạn 2MB.');
    }

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${currentUser.id}/avatar_$timestamp.$ext';

    try {
      await _backend.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          )
          .timeout(const Duration(seconds: 25));

      return filePath;
    } on TimeoutException {
      throw ProfileFailure.network;
    } on StorageException catch (_) {
      throw ProfileFailure.storageUpload;
    } catch (_) {
      throw ProfileFailure.storageUpload;
    }
  }

  @override
  Stream<UserProfile?> watchProfile() {
    final client = _client;
    if (client == null) return Stream.value(null);

    return client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) return null;
      try {
        return await fetchProfile();
      } catch (_) {
        return null;
      }
    });
  }

  ProfileFailure _translatePostgrestError(PostgrestException error) {
    if (error.code == '42501') {
      return const ProfileFailure('Bạn không có quyền thực hiện thao tác này.');
    }
    if (error.code == '23514') {
      return const ProfileFailure(
        'Thông tin họ tên hoặc số điện thoại chưa đúng định dạng.',
      );
    }
    return ProfileFailure.unknown;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile.dart';

/// Provider cung cấp ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client);
});

final profileUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.hasValue
      ? session.value?.id
      : ref.watch(authRepositoryProvider).currentUser?.id;
});

/// Provider tải và quản lý thông tin hồ sơ của tài khoản đang đăng nhập.
/// Tự động trả về null khi người dùng đăng xuất để bảo mật dữ liệu.
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  if (ref.watch(profileUserIdProvider) == null) return null;

  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchProfile();
}, retry: (_, _) => null);

/// Controller quản lý luồng lưu/cập nhật hồ sơ và upload ảnh đại diện.
class ProfileController extends AsyncNotifier<void> {
  int _revision = 0;
  @override
  void build() {
    ref.watch(profileUserIdProvider);
    _revision++;
  }

  bool _active(String userId, int revision) =>
      ref.mounted &&
      revision == _revision &&
      ref.read(profileUserIdProvider) == userId;

  /// Cập nhật họ tên, số điện thoại hoặc đường dẫn avatar.
  /// Trả về true nếu thành công, false nếu có lỗi.
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? avatarPath,
  }) async {
    final userId = ref.read(profileUserIdProvider);
    if (state.isLoading || userId == null) return false;
    final revision = _revision;
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarPath: avatarPath,
      );
      if (_active(userId, revision)) {
        state = const AsyncData(null);
        ref.invalidate(userProfileProvider);
      }
      return _active(userId, revision);
    } catch (e, st) {
      if (_active(userId, revision)) state = AsyncError(e, st);
      return false;
    }
  }

  /// Tải avatar lên Storage.
  Future<String?> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final userId = ref.read(profileUserIdProvider);
    if (state.isLoading || userId == null) return null;
    final revision = _revision;
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final path = await repo.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (!_active(userId, revision)) return null;
      state = const AsyncData(null);
      return path;
    } catch (e, st) {
      if (_active(userId, revision)) state = AsyncError(e, st);
      return null;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, void>(
      ProfileController.new,
    );

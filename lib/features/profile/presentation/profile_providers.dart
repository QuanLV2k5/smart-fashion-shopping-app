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

/// Provider tải và quản lý thông tin hồ sơ của tài khoản đang đăng nhập.
/// Tự động trả về null khi người dùng đăng xuất để bảo mật dữ liệu.
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final session = ref.watch(authSessionProvider);
  final user = session.value ?? ref.read(authRepositoryProvider).currentUser;
  if (user == null) return null;

  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchProfile();
});

/// Controller quản lý luồng lưu/cập nhật hồ sơ và upload ảnh đại diện.
class ProfileController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Cập nhật họ tên, số điện thoại hoặc đường dẫn avatar.
  /// Trả về true nếu thành công, false nếu có lỗi.
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? avatarPath,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarPath: avatarPath,
      );
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(userProfileProvider);
      }
      return true;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
  }

  /// Tải avatar lên Storage.
  Future<String?> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final path = await repo.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (ref.mounted) state = const AsyncData(null);
      return path;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return null;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, void>(
      ProfileController.new,
    );

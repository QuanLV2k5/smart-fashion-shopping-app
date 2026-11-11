import 'dart:async';

import 'package:smart_fashion/features/profile/domain/profile.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({UserProfile? initialProfile})
    : _profile = initialProfile;

  UserProfile? _profile;
  final _controller = StreamController<UserProfile?>.broadcast();

  int fetchCalls = 0;
  int updateCalls = 0;
  int uploadCalls = 0;

  Future<UserProfile> Function(
    String fullName,
    String? phone,
    String? avatarPath,
  )?
  onUpdate;

  UserProfile? get currentProfile => _profile;
  set currentProfile(UserProfile? value) {
    _profile = value;
    _controller.add(value);
  }

  @override
  Future<UserProfile?> fetchProfile() async {
    fetchCalls++;
    return _profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    String? phone,
    String? avatarPath,
  }) async {
    updateCalls++;
    if (onUpdate != null) {
      final updated = await onUpdate!(fullName, phone, avatarPath);
      _profile = updated;
      _controller.add(_profile);
      return updated;
    }
    _profile =
        (_profile ??
                const UserProfile(
                  id: 'test-user-id',
                  email: 'test@example.com',
                  fullName: '',
                ))
            .copyWith(
              fullName: fullName,
              phone: phone,
              avatarPath: avatarPath,
              avatarUrl: avatarPath,
              updatedAt: DateTime.now(),
            );
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    uploadCalls++;
    final path =
        'test-user-id/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return path;
  }

  @override
  Stream<UserProfile?> watchProfile() => _controller.stream;

  void close() {
    _controller.close();
  }
}

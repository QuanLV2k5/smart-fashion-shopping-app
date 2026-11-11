import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../domain/profile.dart';
import 'profile_providers.dart';
import 'widgets/avatar_selector_sheet.dart';

/// Màn hình Chỉnh sửa hồ sơ cá nhân theo Figma (Profile 4:337, Saved 4:383, Error 6:1434).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String? _avatarPathOrUrl;
  bool _initialized = false;
  bool _savedSuccess = false;
  String? _profileOwnerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateUserData(
    UserProfile? profile,
    String email,
    String fallbackName,
  ) {
    if (_initialized) return;
    _nameController.text = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : fallbackName;
    _phoneController.text = profile?.phone ?? '';
    // Keep the stored identifier; a public URL is only for rendering.
    _avatarPathOrUrl = profile?.avatarPath ?? profile?.avatarUrl;
    _initialized = true;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() => _savedSuccess = false);

    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(profileControllerProvider.notifier);
    final ok = await controller.updateProfile(
      fullName: _nameController.text,
      phone: _phoneController.text,
      avatarPath: _avatarPathOrUrl,
    );

    if (mounted && ok) {
      setState(() => _savedSuccess = true);
    }
  }

  void _openAvatarSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectorSheet(
        currentAvatarUrl: _avatarPathOrUrl,
        onSelected: (newUrl) {
          setState(() {
            _avatarPathOrUrl = newUrl;
            _savedSuccess = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser =
        ref.watch(authSessionProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(userProfileProvider);
    final profileState = ref.watch(profileControllerProvider);

    if (_profileOwnerId != sessionUser?.id) {
      _profileOwnerId = sessionUser?.id;
      _initialized = false;
      _savedSuccess = false;
      _nameController.clear();
      _phoneController.clear();
      _avatarPathOrUrl = null;
    }
    final profile = profileAsync.asData?.value;
    final loaded = profile != null && profile.id == sessionUser?.id;

    // Điền dữ liệu từ profile hoặc fallback từ auth session
    profileAsync.whenData((profile) {
      if (profile?.id != sessionUser?.id) return;
      _populateUserData(
        profile,
        sessionUser?.email ?? '',
        sessionUser?.fullName ?? '',
      );
    });

    final isLoading = profileState.isLoading;
    final blocked = isLoading || !loaded;
    final errorMessage = profileState.hasError
        ? (profileState.error is ProfileFailure
              ? (profileState.error! as ProfileFailure).message
              : profileState.error.toString())
        : null;

    final trimmedName = _nameController.text.trim();
    final fallbackName = sessionUser?.fullName.trim() ?? '';
    final initialsName = trimmedName.isNotEmpty ? trimmedName : fallbackName;
    final initials = initialsName.isEmpty
        ? 'U'
        : initialsName.characters.first.toUpperCase();
    final avatarDisplay =
        _avatarPathOrUrl != null && _avatarPathOrUrl == profile?.avatarPath
        ? profile?.avatarUrl ?? _avatarPathOrUrl
        : _avatarPathOrUrl;

    return AuthScaffold(
      title: 'Hồ sơ cá nhân',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/account');
        }
      },
      action: AuthButton(
        'Lưu thay đổi',
        loading: isLoading,
        onPressed: blocked ? null : _handleSave,
      ),
      children: [
        if (profileAsync.isLoading) const LinearProgressIndicator(),
        if (profileAsync.hasError) ...[
          const AuthNotice(
            'Chưa tải được hồ sơ. Vui lòng thử lại trước khi chỉnh sửa.',
            error: true,
          ),
          TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Tải lại hồ sơ'),
          ),
        ],
        // Khung thông báo thành công (Figma ProfileSaved 4:383)
        if (_savedSuccess)
          const AuthNotice(
            'Đã cập nhật hồ sơ cá nhân thành công.',
            error: false,
          ),

        // Khung thông báo lỗi (Figma ProfileError 6:1434)
        if (errorMessage != null && !_savedSuccess)
          AuthNotice(errorMessage, error: true),

        // Khu vực Avatar (Figma Avatar 4:363)
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                child: buildAvatarDisplay(
                  avatarPathOrUrl: avatarDisplay,
                  initials: initials,
                  size: 96,
                  textStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              InkWell(
                onTap: blocked ? null : _openAvatarSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Form thông tin hồ sơ
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'HỌ VÀ TÊN',
                hint: 'Nguyễn Văn A',
                controller: _nameController,
                inputKey: const ValueKey('profile_full_name'),
                enabled: !blocked,
                validator: ProfileValidation.validateFullName,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'SỐ ĐIỆN THOẠI',
                hint: '0912345678',
                controller: _phoneController,
                inputKey: const ValueKey('profile_phone'),
                keyboardType: TextInputType.phone,
                enabled: !blocked,
                validator: ProfileValidation.validatePhone,
              ),
              const SizedBox(height: AppSpacing.md),

              // Email là thông tin định danh, chỉ đọc
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMAIL TÀI KHOẢN (KHÔNG THỂ THAY ĐỔI)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            sessionUser?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

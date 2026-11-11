import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Đại diện cho một mẫu avatar phong cách Smart Fashion (Figma Avatar 4:363).
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String id;
  final String name;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}

const avatarPresets = [
  AvatarPreset(
    id: 'preset:emerald',
    name: 'Emerald Chic',
    backgroundColor: Color(0xFF254D40),
    foregroundColor: Color(0xFFFFFFFF),
    icon: Icons.person_rounded,
  ),
  AvatarPreset(
    id: 'preset:terracotta',
    name: 'Terracotta',
    backgroundColor: Color(0xFFA54932),
    foregroundColor: Color(0xFFFFFFFF),
    icon: Icons.face_rounded,
  ),
  AvatarPreset(
    id: 'preset:navy',
    name: 'Classic Navy',
    backgroundColor: Color(0xFF1E3A5F),
    foregroundColor: Color(0xFFFFFFFF),
    icon: Icons.account_circle_rounded,
  ),
  AvatarPreset(
    id: 'preset:sage',
    name: 'Pastel Sage',
    backgroundColor: Color(0xFFE2E9DF),
    foregroundColor: Color(0xFF254D40),
    icon: Icons.face_3_rounded,
  ),
  AvatarPreset(
    id: 'preset:noir',
    name: 'Modern Noir',
    backgroundColor: Color(0xFF242A27),
    foregroundColor: Color(0xFFFFFFFF),
    icon: Icons.person_outline_rounded,
  ),
  AvatarPreset(
    id: 'preset:amber',
    name: 'Warm Amber',
    backgroundColor: Color(0xFFD97706),
    foregroundColor: Color(0xFFFFFFFF),
    icon: Icons.sentiment_satisfied_alt_rounded,
  ),
];

/// BottomSheet chọn ảnh đại diện từ mẫu phong cách hoặc gỡ ảnh.
class AvatarSelectorSheet extends StatelessWidget {
  const AvatarSelectorSheet({
    required this.currentAvatarUrl,
    required this.onSelected,
    super.key,
  });

  final String? currentAvatarUrl;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn ảnh đại diện',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn một phong cách đại diện từ bộ sưu tập Smart Fashion:',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.9,
                ),
                itemCount: avatarPresets.length,
                itemBuilder: (context, index) {
                  final preset = avatarPresets[index];
                  final isSelected = currentAvatarUrl == preset.id;
                  return InkWell(
                    onTap: () {
                      onSelected(preset.id);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sage.withValues(alpha: 0.5)
                            : AppColors.ivory,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: preset.backgroundColor,
                            child: Icon(
                              preset.icon,
                              color: preset.foregroundColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            preset.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.ink,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (currentAvatarUrl != null)
                OutlinedButton.icon(
                  onPressed: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Đặt lại ảnh mặc định'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper hiển thị avatar từ URL, preset hoặc initials.
Widget buildAvatarDisplay({
  required String? avatarPathOrUrl,
  required String initials,
  required double size,
  TextStyle? textStyle,
}) {
  if (avatarPathOrUrl != null) {
    // Trường hợp là preset
    final presetMatch = avatarPresets.where((p) => p.id == avatarPathOrUrl);
    if (presetMatch.isNotEmpty) {
      final preset = presetMatch.first;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: preset.backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          preset.icon,
          color: preset.foregroundColor,
          size: size * 0.55,
        ),
      );
    }

    // Trường hợp là link HTTP(S)
    if (avatarPathOrUrl.startsWith('http')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.sage,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          avatarPathOrUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              initials,
              style:
                  textStyle ??
                  const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      );
    }
  }

  // Mặc định hiển thị chữ cái đầu (initials) trên nền sage
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.sage,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style:
          textStyle ??
          const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
    ),
  );
}

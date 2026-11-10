import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/auth_failure.dart';

/// Khung chung: nội dung cuộn được, CTA nằm cuối và tránh bàn phím/notch.
/// Thanh giờ/pin dùng hệ điều hành thật, không vẽ status bar giả của Figma.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.onBack,
    required this.children,
    this.action,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.primary,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        // Vị trí thao tác Giỏ dành cho module giỏ hàng ở bước sau.
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.md,
                      children: children,
                    ),
                  ),
                ),
                if (action != null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      math.max(26, MediaQuery.paddingOf(context).bottom),
                    ),
                    child: action,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhận diện thương hiệu bằng chữ, cùng màu và typography của Figma.
class AuthIntro extends StatelessWidget {
  const AuthIntro({
    required this.heading,
    required this.description,
    super.key,
  });
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              'SF',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'SMART FASHION',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      AuthHeading(heading),
      const SizedBox(height: AppSpacing.xs),
      AuthBody(description),
      const SizedBox(height: AppSpacing.xs),
    ],
  );
}

class AuthStatusIcon extends StatelessWidget {
  const AuthStatusIcon(this.icon, {super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Icon(icon, size: 30, color: AppColors.primary),
    ),
  );
}

class AuthHeading extends StatelessWidget {
  const AuthHeading(this.text, {this.display = false, super.key});
  final String text;
  final bool display;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: display
        ? Theme.of(context).textTheme.displaySmall
              ?.copyWith(color: AppColors.primary)
        : Theme.of(context).textTheme.headlineSmall,
  );
}

class AuthBody extends StatelessWidget {
  const AuthBody(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.muted),
  );
}

class AuthButton extends StatelessWidget {
  const AuthButton(
    this.label, {
    required this.onPressed,
    this.secondary = false,
    this.loading = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? AppColors.sage : AppColors.primary,
        foregroundColor: secondary ? AppColors.primary : AppColors.white,
        minimumSize: Size(48, secondary ? 48 : 52),
        disabledBackgroundColor: secondary
            ? AppColors.sage
            : AppColors.primary.withValues(alpha: 0.55),
        disabledForegroundColor: secondary ? AppColors.muted : AppColors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: secondary ? AppColors.primary : AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              loading ? 'Đang xử lý…' : label,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class AuthNotice extends StatelessWidget {
  const AuthNotice(this.message, {this.error = true, super.key});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: error ? AppColors.error.withValues(alpha: 0.07) : AppColors.sage,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 20,
            color: error ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: error ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget? authErrorNotice(AsyncValue<void> state) {
  if (!state.hasError) return null;
  final error = state.error;
  return AuthNotice(
    error is AuthFailure ? error.message : AuthFailure.unknown.message,
  );
}

/// Label nằm trong ô như SF/Input; lỗi đặt bên dưới và giữ nguyên nội dung nhập.
class AuthField extends StatefulWidget {
  const AuthField({
    required this.label,
    required this.controller,
    required this.validator,
    required this.hint,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.onSubmitted,
    this.enabled = true,
    this.inputKey,
    super.key,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool password;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final VoidCallback? onSubmitted;
  final Key? inputKey;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;
  late final FocusNode _focusNode = FocusNode()..addListener(_focusChanged);

  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_focusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    enabled: widget.enabled,
    validator: (_) => widget.validator(widget.controller.text),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: field.hasError
                  ? AppColors.error
                  : _focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.outline,
              width: _focusNode.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  widget.password ? 52 : AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      label: widget.label,
                      child: TextField(
                        key: widget.inputKey,
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        keyboardType: widget.keyboardType,
                        textCapitalization:
                            widget.password ||
                                widget.keyboardType ==
                                    TextInputType.emailAddress
                            ? TextCapitalization.none
                            : TextCapitalization.words,
                        obscureText: widget.password && _obscure,
                        autocorrect:
                            !widget.password &&
                            widget.keyboardType != TextInputType.emailAddress,
                        enableSuggestions: !widget.password,
                        autofillHints: widget.autofillHints,
                        textInputAction: widget.onSubmitted == null
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) => widget.onSubmitted?.call(),
                        onChanged: field.didChange,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.password)
                IconButton(
                  tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: widget.enabled
                      ? () => setState(() => _obscure = !_obscure)
                      : null,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xxs,
              left: AppSpacing.sm,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ),
          ),
      ],
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/auth_validation.dart';
import 'auth_controller.dart';
import 'widgets/auth_widgets.dart';

class ConfirmationDetails {
  const ConfirmationDetails({
    required this.email,
    this.destination = '/account',
    this.justRegistered = false,
  });
  final String email;
  final String destination;
  final bool justRegistered;
}

class ConfirmEmailPage extends ConsumerStatefulWidget {
  const ConfirmEmailPage({this.details, super.key});
  final ConfirmationDetails? details;
  @override
  ConsumerState<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends ConsumerState<ConfirmEmailPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.details?.email ?? '');
  Timer? _timer;
  int _seconds = 0;
  bool _resent = false;

  @override
  void initState() {
    super.initState();
    if (widget.details?.justRegistered ?? false) _startCooldown();
  }

  void _startCooldown() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_seconds > 0 || ref.read(confirmationControllerProvider).isLoading) {
      return;
    }
    if (widget.details == null && !_form.currentState!.validate()) return;
    final success = await ref
        .read(confirmationControllerProvider.notifier)
        .resend(_email.text);
    if (success && mounted) {
      setState(() {
        _resent = true;
        _startCooldown();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(confirmationControllerProvider);
    final error = authErrorNotice(state);
    final destination = widget.details?.destination ?? '/account';
    return AuthScaffold(
      title: 'Kiểm tra email',
      onBack: state.isLoading
          ? null
          : () => context.go(
              '/register?next=${Uri.encodeComponent(destination)}',
              extra: _email.text.trim(),
            ),
      action: AuthButton(
        'Đã xác nhận · Đăng nhập',
        onPressed: state.isLoading
            ? null
            : () => context.go(
                '/login?next=${Uri.encodeComponent(destination)}',
                extra: _email.text.trim(),
              ),
      ),
      children: [
        const AuthStatusIcon(Icons.mark_email_unread_outlined),
        const AuthHeading('Thêm một bước nữa.', display: true),
        if (widget.details != null) ...[
          const AuthBody(
            'Mở liên kết trong email để hoàn tất đăng ký tài khoản.',
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: SelectableText(
              _email.text,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppColors.primary),
            ),
          ),
          const AuthBody(
            'Nếu chưa thấy thư, hãy kiểm tra mục Spam. Với email đã có tài khoản, bạn có thể quay lại đăng nhập.',
          ),
        ] else ...[
          const AuthBody(
            'Nhập email đã đăng ký để yêu cầu lại liên kết xác nhận.',
          ),
          Form(
            key: _form,
            child: AuthField(
              label: 'Email',
              hint: 'Nhập email đã đăng ký',
              controller: _email,
              validator: AuthValidation.email,
              keyboardType: TextInputType.emailAddress,
              enabled: !state.isLoading,
              onSubmitted: _resend,
            ),
          ),
        ],
        if (_resent)
          const AuthNotice(
            'Đã yêu cầu gửi lại email xác nhận. Hãy kiểm tra cả thư mục spam.',
            error: false,
          ),
        ?error,
        AuthButton(
          _seconds > 0 ? 'Gửi lại sau ${_seconds}s' : 'Gửi lại email',
          onPressed: _seconds > 0 || state.isLoading ? null : _resend,
          secondary: true,
          loading: state.isLoading,
        ),
        TextButton(
          onPressed: state.isLoading
              ? null
              : () => context.go(
                  '/register?next=${Uri.encodeComponent(destination)}',
                  extra: _email.text.trim(),
                ),
          child: const Text('Dùng email khác'),
        ),
        const AuthBody(
          'Nếu đã mở liên kết trên thiết bị khác, hãy quay lại đây và đăng nhập bằng email, mật khẩu của bạn.',
        ),
      ],
    );
  }
}

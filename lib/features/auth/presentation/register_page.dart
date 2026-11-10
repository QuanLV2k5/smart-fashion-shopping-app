import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/auth_user.dart';
import '../domain/auth_validation.dart';
import 'auth_controller.dart';
import 'confirm_email_page.dart';
import 'widgets/auth_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({
    this.destination = '/account',
    this.initialEmail = '',
    super.key,
  });
  final String destination;
  final String initialEmail;
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(registrationControllerProvider).isLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(registrationControllerProvider.notifier)
        .signUp(_name.text, _email.text, _password.text);
    if (result == null || !mounted) return;
    TextInput.finishAutofillContext(shouldSave: false);
    // Không giữ mật khẩu ở route, SharedPreferences hoặc trang xác nhận.
    _password.clear();
    _confirmPassword.clear();
    if (result == RegistrationResult.signedIn) {
      context.go(widget.destination);
    } else {
      context.go(
        '/confirm-email',
        extra: ConfirmationDetails(
          email: _email.text.trim(),
          destination: widget.destination,
          justRegistered: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final error = authErrorNotice(state);
    return AuthScaffold(
      title: 'Tạo tài khoản',
      onBack: state.isLoading
          ? null
          : () => context.go(
              '/login?next=${Uri.encodeComponent(widget.destination)}',
              extra: _email.text.trim(),
            ),
      action: AuthButton(
        'Đăng ký',
        onPressed: _submit,
        loading: state.isLoading,
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                const AuthIntro(
                  heading: 'Bắt đầu phong cách của bạn.',
                  description:
                      'Tạo tài khoản để lưu lựa chọn và theo dõi đơn hàng.',
                ),
                AuthField(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  controller: _name,
                  inputKey: const ValueKey('fullName'),
                  validator: AuthValidation.fullName,
                  autofillHints: const [AutofillHints.name],
                  enabled: !state.isLoading,
                ),
                AuthField(
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  controller: _email,
                  inputKey: const ValueKey('email'),
                  validator: AuthValidation.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !state.isLoading,
                ),
                AuthField(
                  label: 'Mật khẩu',
                  hint: 'Ít nhất 8 ký tự',
                  controller: _password,
                  inputKey: const ValueKey('password'),
                  validator: (value) =>
                      AuthValidation.password(value, registering: true),
                  password: true,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !state.isLoading,
                ),
                AuthField(
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  controller: _confirmPassword,
                  inputKey: const ValueKey('confirmPassword'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Vui lòng nhập lại mật khẩu'
                      : value != _password.text
                      ? 'Mật khẩu nhập lại chưa khớp'
                      : null,
                  password: true,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: _submit,
                  enabled: !state.isLoading,
                ),
                ?error,
                Text(
                  'Bằng việc đăng ký, bạn đồng ý sử dụng tài khoản để mua sắm và quản lý đơn hàng.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

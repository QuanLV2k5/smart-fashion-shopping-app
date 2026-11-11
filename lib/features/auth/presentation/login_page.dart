import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_validation.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';
import 'confirm_email_page.dart';
import 'widgets/auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    this.destination = '/account',
    this.initialEmail = '',
    super.key,
  });
  final String destination;
  final String initialEmail;
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(loginControllerProvider).isLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(loginControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (success && mounted) {
      TextInput.finishAutofillContext();
      context.go(widget.destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final error = authErrorNotice(state);
    final sessionError = ref.watch(authSessionProvider).hasError;
    return AuthScaffold(
      title: 'Đăng nhập',
      onBack: state.isLoading ? null : () => context.go('/'),
      action: AuthButton(
        'Đăng nhập',
        onPressed: _submit,
        loading: state.isLoading,
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                const AuthIntro(
                  heading: 'Rất vui được gặp bạn.',
                  description: 'Đăng nhập để quản lý đơn hàng và yêu thích.',
                ),
                AuthField(
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  controller: _email,
                  inputKey: const ValueKey('email'),
                  validator: AuthValidation.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  enabled: !state.isLoading,
                ),
                AuthField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  controller: _password,
                  inputKey: const ValueKey('password'),
                  validator: AuthValidation.password,
                  password: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: _submit,
                  enabled: !state.isLoading,
                ),
                ?error,
                if (sessionError && error == null)
                  const AuthNotice(
                    'Chưa xử lý được liên kết đăng nhập. Bạn có thể đăng nhập bằng email và mật khẩu; nếu email chưa xác nhận, hãy yêu cầu liên kết mới.',
                  ),
                if (state.error is AuthFailure &&
                    (state.error! as AuthFailure).needsConfirmation)
                  AuthButton(
                    'Kiểm tra email xác nhận',
                    secondary: true,
                    onPressed: () => context.go(
                      '/confirm-email',
                      extra: ConfirmationDetails(
                        email: _email.text.trim(),
                        destination: widget.destination,
                      ),
                    ),
                  ),
                AuthButton(
                  'Tạo tài khoản',
                  secondary: true,
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(
                          '/register?next=${Uri.encodeComponent(widget.destination)}',
                          extra: _email.text.trim(),
                        ),
                ),
                AuthButton(
                  'Tiếp tục xem cửa hàng',
                  secondary: true,
                  onPressed: state.isLoading ? null : () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';

class AddressCartLink extends StatelessWidget {
  const AddressCartLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    onPressed: () => context.go('/cart'),
    child: const Text('Giỏ'),
  );
}

class AddressSecondaryButton extends StatelessWidget {
  const AddressSecondaryButton({
    required this.label,
    this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.sage,
      foregroundColor: AppColors.primary,
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

class AddressPrimaryButton extends StatelessWidget {
  const AddressPrimaryButton({required this.label, this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// SF/Input: nhãn luôn trong ô, cao tối thiểu 76px, tự giãn khi chữ/lỗi dài.
/// Lỗi nằm trong khung đỏ, dữ liệu nhập vẫn được giữ nguyên.
class AddressInput extends StatefulWidget {
  const AddressInput({
    required this.label,
    required this.controller,
    required this.validator,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  @override
  State<AddressInput> createState() => _AddressInputState();
}

class _AddressInputState extends State<AddressInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: widget.controller.text,
    enabled: widget.enabled,
    validator: widget.validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    builder: (field) {
      final borderColor = field.hasError
          ? AppColors.error
          : _focus.hasFocus
          ? AppColors.primary
          : AppColors.outline;
      return Container(
        key: ValueKey('address-input-${widget.label}'),
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: widget.label,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                style: Theme.of(context).textTheme.bodyMedium,
                scrollPadding: const EdgeInsets.all(AppSpacing.lg),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: field.didChange,
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: AppSpacing.xxs),
              Semantics(
                liveRegion: true,
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

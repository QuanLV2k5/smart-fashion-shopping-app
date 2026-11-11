import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../domain/address.dart';
import 'address_providers.dart';
import 'widgets/address_widgets.dart';

class AddressFormPage extends ConsumerWidget {
  const AddressFormPage({
    this.addressId,
    this.returnToSelection = false,
    super.key,
  });
  final String? addressId;
  final bool returnToSelection;
  String get _listPath =>
      returnToSelection ? '/addresses/select' : '/addresses';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(addressUserIdProvider);
    final state = ref.watch(addressBookProvider);
    final book = state.asData?.value;
    Address? address;
    for (final item in book?.addresses ?? <Address>[]) {
      if (item.id == addressId) address = item;
    }
    if (userId != null &&
        book != null &&
        (addressId == null || address != null)) {
      return _AddressForm(
        key: ValueKey('$userId/$addressId'),
        userId: userId,
        address: address,
        returnToSelection: returnToSelection,
        onDeleted: () {
          if (!context.mounted || ref.read(addressUserIdProvider) != userId) {
            return;
          }
          final result = ref.read(addressBookProvider).asData?.value;
          final message =
              result?.failure?.message ?? result?.message ?? 'Đã xóa địa chỉ.';
          final messenger = ScaffoldMessenger.of(context);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(_listPath);
          }
          messenger.showSnackBar(SnackBar(content: Text(message)));
        },
      );
    }
    return ShopPageScaffold(
      title: 'Địa chỉ',
      trailing: const AddressCartLink(),
      onBack: () => context.canPop() ? context.pop() : context.go(_listPath),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userId == null
                          ? 'Phiên đăng nhập đã kết thúc.'
                          : state.hasError
                          ? state.error.toString()
                          : 'Địa chỉ không còn tồn tại hoặc không thuộc tài khoản này.',
                    ),
                    TextButton(
                      onPressed: () => context.go(_listPath),
                      child: const Text('Về danh sách địa chỉ'),
                    ),
                    if (state.hasError)
                      TextButton(
                        onPressed: () => ref.invalidate(addressBookProvider),
                        child: const Text('Thử lại'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({
    required this.userId,
    required this.returnToSelection,
    required this.onDeleted,
    this.address,
    super.key,
  });
  final String userId;
  final Address? address;
  final bool returnToSelection;
  final VoidCallback onDeleted;
  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _form = GlobalKey<FormState>();
  late final String _id;
  late final Map<String, TextEditingController> _inputs;
  bool _confirmingDelete = false;
  static const _labels = {
    'recipient_name': 'Người nhận',
    'phone': 'Số điện thoại',
    'city': 'Tỉnh / Thành phố',
    'district': 'Quận / Huyện',
    'ward': 'Phường / Xã',
    'address_line': 'Địa chỉ cụ thể',
  };
  @override
  void initState() {
    super.initState();
    _id = widget.address?.id ?? const Uuid().v4();
    final fields = widget.address?.details.fields;
    _inputs = {
      for (final key in _labels.keys)
        key: TextEditingController(text: fields?[key] ?? ''),
    };
  }

  AddressDraft get _draft => AddressDraft(
    recipientName: _inputs['recipient_name']!.text,
    phone: _inputs['phone']!.text,
    addressLine: _inputs['address_line']!.text,
    ward: _inputs['ward']!.text,
    district: _inputs['district']!.text,
    city: _inputs['city']!.text,
  );

  Future<void> _delete() async {
    final address = widget.address;
    final book = ref.read(addressBookProvider).asData?.value;
    if (_confirmingDelete ||
        address == null ||
        book == null ||
        book.busy ||
        book.requiresRefresh) {
      return;
    }
    final ownerId = widget.userId;
    final onDeleted = widget.onDeleted;
    final controller = ref.read(addressBookProvider.notifier);
    FocusScope.of(context).unfocus();
    setState(() => _confirmingDelete = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final sameUser = dialogRef.watch(addressUserIdProvider) == ownerId;
          return AlertDialog(
            title: const Text('Xóa địa chỉ?'),
            content: Text(
              sameUser
                  ? '${address.details.recipientName}\n${address.details.addressLine}, ${address.details.ward}, ${address.details.district}, ${address.details.city}'
                  : 'Tài khoản đã thay đổi. Vui lòng đóng hộp thoại.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Hủy'),
              ),
              AddressPrimaryButton(
                label: 'Xóa địa chỉ',
                onPressed: sameUser ? () => context.pop(true) : null,
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    setState(() => _confirmingDelete = false);
    if (confirmed != true || ref.read(addressUserIdProvider) != ownerId) return;
    final deleted = await controller.delete(address.id);
    // State của form có thể đã bị hủy khi dòng biến mất. Đích điều hướng nằm
    // ở AddressFormPage bên ngoài, nơi vẫn còn mounted và kiểm tra tài khoản.
    if (deleted) onDeleted();
  }

  @override
  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressBookProvider);
    final book = state.asData?.value;
    final controller = ref.read(addressBookProvider.notifier);
    final busy =
        book == null || book.busy || book.requiresRefresh || _confirmingDelete;
    return ShopPageScaffold(
      title: widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ',
      trailing: const AddressCartLink(),
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(
              widget.returnToSelection ? '/addresses/select' : '/addresses',
            ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (book?.busy ?? false) const LinearProgressIndicator(),
              if (book?.failure != null) ...[
                ShopNotice(book!.failure!.message, error: true),
                TextButton(
                  onPressed: book.busy ? null : controller.reload,
                  child: const Text('Tải lại danh sách'),
                ),
              ],
              for (final entry in _labels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AddressInput(
                    key: ValueKey('address-field-${entry.key}'),
                    label: entry.value,
                    controller: _inputs[entry.key]!,
                    enabled: !busy,
                    keyboardType: entry.key == 'phone'
                        ? TextInputType.phone
                        : entry.key == 'recipient_name'
                        ? TextInputType.name
                        : entry.key == 'address_line'
                        ? TextInputType.streetAddress
                        : TextInputType.text,
                    textInputAction: entry.key == 'address_line'
                        ? TextInputAction.done
                        : TextInputAction.next,
                    validator: (_) => _draft.validate()[entry.key],
                  ),
                ),
              if (widget.address != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: OutlinedButton(
                    key: const ValueKey('delete-address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    onPressed: busy ? null : _delete,
                    child: const Text('Xóa địa chỉ'),
                  ),
                ),
            ],
          ),
        ),
      ),
      footer: SizedBox(
        width: double.infinity,
        child: AddressPrimaryButton(
          onPressed: busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  FocusScope.of(context).unfocus();
                  final saved = await controller.save(
                    _id,
                    _draft,
                    editing:
                        widget.address != null ||
                        book.addresses.any((a) => a.id == _id),
                  );
                  if (saved &&
                      context.mounted &&
                      ref.read(addressUserIdProvider) == widget.userId) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        widget.returnToSelection
                            ? '/addresses/select'
                            : '/addresses',
                      );
                    }
                  }
                },
          label: 'Lưu địa chỉ',
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../domain/address.dart';
import 'address_providers.dart';
import 'widgets/address_widgets.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({this.selecting = false, super.key});
  final bool selecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(addressUserIdProvider);
    // Đổi tài khoản sẽ hủy cả lựa chọn tạm của UI.
    return _AddressList(
      key: ValueKey('$userId/$selecting'),
      userId: userId,
      selecting: selecting,
    );
  }
}

class _AddressList extends ConsumerStatefulWidget {
  const _AddressList({
    required this.userId,
    required this.selecting,
    super.key,
  });
  final String? userId;
  final bool selecting;

  @override
  ConsumerState<_AddressList> createState() => _AddressListState();
}

class _AddressListState extends ConsumerState<_AddressList> {
  String? _candidateId;
  bool _touchedSelection = false;

  String get _formSuffix => widget.selecting ? '?from=cart' : '';

  Future<void> _delete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final sameUser =
              dialogRef.watch(addressUserIdProvider) == widget.userId;
          return AlertDialog(
            title: const Text('Xóa địa chỉ?'),
            content: Text(
              sameUser
                  ? '${address.details.recipientName}\n${addressText(address)}'
                  : 'Tài khoản đã thay đổi. Vui lòng đóng hộp thoại.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Hủy'),
              ),
              AddressPrimaryButton(
                onPressed: sameUser ? () => context.pop(true) : null,
                label: 'Xóa địa chỉ',
              ),
            ],
          );
        },
      ),
    );
    if (confirmed == true &&
        mounted &&
        ref.read(addressUserIdProvider) == widget.userId) {
      await ref.read(addressBookProvider.notifier).delete(address.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(addressBookProvider);
    final book = value.asData?.value;
    final controller = ref.read(addressBookProvider.notifier);
    final busy = value.isLoading || (book?.busy ?? false);
    final blocked =
        busy || book == null || book.requiresRefresh || widget.userId == null;
    final proposedId = _touchedSelection ? _candidateId : book?.selected?.id;
    final candidateId = book?.addresses.any((a) => a.id == proposedId) == true
        ? proposedId
        : null;
    void add() => context.push('/addresses/new$_formSuffix');

    return ShopPageScaffold(
      title: 'Địa chỉ giao hàng',
      trailing: const AddressCartLink(),
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(widget.selecting ? '/cart' : '/account'),
      body: widget.userId == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem địa chỉ.'))
          : value.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (value.hasError) {
                  ref.invalidate(addressBookProvider);
                } else {
                  await controller.reload();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (busy) const LinearProgressIndicator(),
                  if (value.hasError) ...[
                    ShopNotice(value.error.toString(), error: true),
                    TextButton(
                      onPressed: () => ref.invalidate(addressBookProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                  if (book?.failure != null) ...[
                    ShopNotice(book!.failure!.message, error: true),
                    TextButton(
                      onPressed: busy ? null : controller.reload,
                      child: const Text('Tải lại danh sách'),
                    ),
                  ],
                  if (book?.message != null && !widget.selecting) ...[
                    ShopNotice(book!.message!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (book != null && book.addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        'Bạn chưa có địa chỉ. Thêm địa chỉ nhận hàng đầu tiên nhé.',
                      ),
                    ),
                  for (final address in book?.addresses ?? <Address>[]) ...[
                    _AddressCard(
                      address: address,
                      selected: widget.selecting
                          ? candidateId == address.id
                          : book!.selected?.id == address.id,
                      onTap: widget.selecting && !blocked
                          ? () => setState(() {
                              _candidateId = address.id;
                              _touchedSelection = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AddressSecondaryButton(
                      label: 'Sửa địa chỉ',
                      onPressed: blocked
                          ? null
                          : () => context.push(
                              '/addresses/${address.id}/edit$_formSuffix',
                            ),
                    ),
                    if (!widget.selecting)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: blocked ? null : () => _delete(address),
                          child: const Text('Xóa'),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (book != null)
                    AddressSecondaryButton(
                      label: 'Thêm địa chỉ mới',
                      onPressed: blocked ? null : add,
                    ),
                ],
              ),
            ),
      footer: SizedBox(
        width: double.infinity,
        child: AddressPrimaryButton(
          onPressed: blocked || (widget.selecting && candidateId == null)
              ? null
              : () async {
                  if (!widget.selecting) {
                    add();
                    return;
                  }
                  final confirmed = await controller.select(candidateId!);
                  if (confirmed &&
                      context.mounted &&
                      ref.read(addressUserIdProvider) == widget.userId) {
                    context.go('/cart');
                  }
                },
          label: widget.selecting ? 'Giao tới địa chỉ này' : 'Thêm địa chỉ',
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    this.onTap,
  });
  final Address address;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: onTap != null,
    child: Material(
      color: AppColors.sage,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        key: ValueKey('address-card-${address.id}'),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 138),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  '${address.details.recipientName.trim()} · ${address.details.phone}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '${address.details.addressLine}, ${address.details.ward}\n${address.details.district}, ${address.details.city}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
                Row(
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    Expanded(
                      child: Text(
                        selected
                            ? 'Giao tới địa chỉ này'
                            : onTap != null
                            ? 'Chạm để chọn địa chỉ này'
                            : 'Địa chỉ đã lưu',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String addressText(Address address) => [
  address.details.addressLine,
  address.details.ward,
  address.details.district,
  address.details.city,
].join(', ');

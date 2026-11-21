import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/admin_models.dart';

/// Hộp thoại thêm/chỉnh sửa một biến thể sản phẩm (Size, Màu, Tồn kho, SKU)
class AdminVariantDialog extends StatefulWidget {
  const AdminVariantDialog({
    super.key,
    this.initialVariant,
    this.productCode = 'SP',
  });

  final AdminVariant? initialVariant;
  final String productCode;

  @override
  State<AdminVariantDialog> createState() => _AdminVariantDialogState();
}

class _AdminVariantDialogState extends State<AdminVariantDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _sizeController;
  late final TextEditingController _colorController;
  late final TextEditingController _stockController;
  bool _autoSku = true;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVariant;
    _skuController = TextEditingController(text: v?.sku ?? '');
    _sizeController = TextEditingController(text: v?.size ?? '');
    _colorController = TextEditingController(text: v?.color ?? '');
    _stockController = TextEditingController(
      text: v != null ? v.stock.toString() : '50',
    );

    if (v != null) {
      _autoSku = false;
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _generateSku() {
    if (!_autoSku) return;
    final code = widget.productCode.trim().toUpperCase();
    final size = _sizeController.text.trim().toUpperCase();
    final color = _colorController.text.trim().toLowerCase();
    if (size.isNotEmpty || color.isNotEmpty) {
      _skuController.text = '${code}_${size}_$color';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final variant = AdminVariant(
      id: widget.initialVariant?.id ?? '',
      productId: widget.initialVariant?.productId ?? '',
      sku: _skuController.text.trim(),
      size: _sizeController.text.trim(),
      color: _colorController.text.trim(),
      stock: int.parse(_stockController.text.trim()),
    );

    Navigator.of(context).pop(variant);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVariant != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Sửa Biến thể' : 'Thêm Biến thể mới',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Kích cỡ (Size)
                Text(
                  'Kích cỡ (Size) *',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    hintText: 'S, M, L, XL hoặc 29, 30, 31...',
                    isDense: true,
                  ),
                  validator: AdminValidation.validateVariantSize,
                  onChanged: (_) {
                    _generateSku();
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // Màu sắc (Color)
                Text(
                  'Màu sắc *',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    hintText: 'Đen, Trắng, Xanh rêu, Be...',
                    isDense: true,
                  ),
                  validator: AdminValidation.validateVariantColor,
                  onChanged: (_) {
                    _generateSku();
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // Tồn kho (Stock)
                Text(
                  'Số lượng tồn kho *',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Số lượng tồn (vd: 50)',
                    isDense: true,
                  ),
                  validator: AdminValidation.validateVariantStock,
                ),

                const SizedBox(height: AppSpacing.sm),

                // SKU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã SKU *',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (!isEditing)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _autoSku = !_autoSku;
                            if (_autoSku) _generateSku();
                          });
                        },
                        child: Text(
                          _autoSku ? 'Tự tạo' : 'Nhập tay',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    hintText: 'Mã SKU duy nhất (vd: SF01_M_den)',
                    isDense: true,
                  ),
                  validator: AdminValidation.validateVariantSku,
                  onChanged: (_) => _autoSku = false,
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(isEditing ? 'Lưu' : 'Thêm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

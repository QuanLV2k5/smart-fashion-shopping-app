import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_variants_sheet.dart';

class AdminProductFormPage extends ConsumerStatefulWidget {
  const AdminProductFormPage({super.key, this.productId, this.initialProduct});

  final String? productId;
  final AdminProduct? initialProduct;

  @override
  ConsumerState<AdminProductFormPage> createState() =>
      _AdminProductFormPageState();
}

class _AdminProductFormPageState extends ConsumerState<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _materialController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  late bool _isVisible;
  final List<String> _imagePaths = [];
  final List<AdminVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _codeController = TextEditingController(text: p?.code ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.priceVnd.toString() : '',
    );
    _materialController = TextEditingController(text: p?.material ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController();

    _selectedCategoryId = p?.categoryId;
    _isVisible = p?.isVisible ?? true;

    if (p != null) {
      _imagePaths.addAll(p.imagePaths);
      _variants.addAll(p.variants);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _materialController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addImage(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _imagePaths.add(trimmed);
      _imageUrlController.clear();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _openVariantDialog([AdminVariant? existing, int? index]) async {
    final result = await showDialog<AdminVariant>(
      context: context,
      builder: (_) => AdminVariantDialog(
        initialVariant: existing,
        productCode: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : 'SP',
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null && index >= 0 && index < _variants.length) {
          _variants[index] = result;
        } else {
          _variants.add(result);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục cho sản phẩm.'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    final sanitizedPrice = _priceController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final priceVnd = int.parse(sanitizedPrice);

    final controller = ref.read(adminProductControllerProvider.notifier);
    final savedProductId = await controller.saveProduct(
      id: widget.productId ?? widget.initialProduct?.id,
      code: _codeController.text.trim().toUpperCase(),
      categoryId: _selectedCategoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      material: _materialController.text.trim(),
      priceVnd: priceVnd,
      imagePaths: _imagePaths,
      isVisible: _isVisible,
    );

    if (savedProductId == null) return;

    // Lưu các biến thể cho sản phẩm
    for (final variant in _variants) {
      final initialVariant = widget.initialProduct?.variants
          .cast<AdminVariant?>()
          .firstWhere((v) => v?.id == variant.id, orElse: () => null);
      final stockChanged =
          initialVariant == null || initialVariant.stock != variant.stock;

      await controller.saveVariant(
        id: variant.id.isNotEmpty ? variant.id : null,
        productId: savedProductId,
        sku: variant.sku,
        size: variant.size,
        color: variant.color,
        stock: variant.stock,
        updateStock: stockChanged,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productId != null || widget.initialProduct != null
                ? 'Đã cập nhật sản phẩm thành công.'
                : 'Đã tạo sản phẩm và cập nhật biến thể thành công.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null || widget.initialProduct != null;
    final state = ref.watch(adminProductControllerProvider);
    final isLoading = state.isLoading;
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return AdminGuard(
      title: isEditing ? 'Sửa thông tin sản phẩm' : 'Đăng sản phẩm mới',
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          title: Text(
            isEditing ? 'Sửa thông tin sản phẩm' : 'Đăng sản phẩm mới',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          backgroundColor: AppColors.ivory,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.error.toString(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Mã sản phẩm (Code) & Trạng thái
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã sản phẩm (Code) *',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              hintText: 'VD: SF01, SF02...',
                              isDense: true,
                            ),
                            validator: AdminValidation.validateProductCode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Danh mục *',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          categoriesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => const Text('Lỗi tải danh mục'),
                            data: (categories) {
                              if (_selectedCategoryId == null &&
                                  categories.isNotEmpty) {
                                _selectedCategoryId = categories.first.id;
                              }
                              return DropdownButtonFormField<String>(
                                initialValue: _selectedCategoryId,
                                isDense: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                items: categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedCategoryId = val);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Tên sản phẩm
                Text(
                  'Tên sản phẩm *',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Áo Sơ Mi Cổ Trụ Vải Linen',
                    isDense: true,
                  ),
                  validator: AdminValidation.validateProductName,
                ),

                const SizedBox(height: AppSpacing.md),

                // Giá bán VNĐ
                Text(
                  'Giá bán (VNĐ) *',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 199000 hoặc 249000',
                    suffixText: 'VNĐ',
                    isDense: true,
                  ),
                  validator: AdminValidation.validatePrice,
                ),

                const SizedBox(height: AppSpacing.md),

                // Chất liệu
                Text(
                  'Chất liệu',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _materialController,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 100% Cotton, Vải Linen tự nhiên...',
                    isDense: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Mô tả chi tiết
                Text(
                  'Mô tả sản phẩm',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Mô tả kiểu dáng, hướng dẫn phối đồ và bảo quản...',
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Switch hiển thị
                Material(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    side: const BorderSide(color: AppColors.outline),
                  ),
                  child: SwitchListTile(
                    value: _isVisible,
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Trạng thái mở bán (is_visible)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Bật để sản phẩm xuất hiện trên Catalog, tắt để tạm ẩn ngừng bán.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    onChanged: (val) => setState(() => _isVisible = val),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Danh sách ảnh sản phẩm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hình ảnh sản phẩm (${_imagePaths.length})',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          hintText:
                              'Nhập đường dẫn ảnh (URL hoặc Storage path)...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: () => _addImage(_imageUrlController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Thêm ảnh'),
                    ),
                  ],
                ),

                if (_imagePaths.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final path = _imagePaths[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: AppColors.sage,
                                child: path.startsWith('http')
                                    ? Image.network(
                                        path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.checkroom_outlined,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Danh sách biến thể (Variants)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biến thể & Tồn kho (${_variants.length})',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => _openVariantDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm biến thể'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                if (_variants.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Center(
                      child: Text(
                        'Chưa có biến thể nào. Nhấn "+ Thêm biến thể" để tạo kích cỡ, màu sắc và tồn kho.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ..._variants.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final v = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      color: AppColors.white,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          'Size ${v.size} - Màu ${v.color}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'SKU: ${v.sku} • Tồn: ${v.stock} chiếc${v.stock == 0 ? ' (Hết hàng/Ngừng bán)' : ''}',
                          style: TextStyle(
                            color: v.stock == 0
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _openVariantDialog(v, idx),
                            ),
                            IconButton(
                              icon: Icon(
                                v.id.isEmpty
                                    ? Icons.delete_outline
                                    : Icons.block_outlined,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              tooltip: v.id.isEmpty
                                  ? 'Xóa biến thể'
                                  : 'Ngừng bán (đặt tồn kho về 0)',
                              onPressed: () {
                                setState(() {
                                  if (v.id.isEmpty) {
                                    _variants.removeAt(idx);
                                  } else {
                                    _variants[idx] = v.copyWith(stock: 0);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: AppSpacing.xl),

                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Lưu sản phẩm' : 'Đăng bán sản phẩm',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

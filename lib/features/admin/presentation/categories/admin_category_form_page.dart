import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';

class AdminCategoryFormPage extends ConsumerStatefulWidget {
  const AdminCategoryFormPage({
    super.key,
    this.categoryId,
    this.initialCategory,
  });

  final String? categoryId;
  final AdminCategory? initialCategory;

  @override
  ConsumerState<AdminCategoryFormPage> createState() =>
      _AdminCategoryFormPageState();
}

class _AdminCategoryFormPageState extends ConsumerState<AdminCategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late bool _isActive;
  bool _autoSlug = true;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCategory;
    _nameController = TextEditingController(text: c?.name ?? '');
    _slugController = TextEditingController(text: c?.slug ?? '');
    _isActive = c?.isActive ?? true;

    if (c != null) {
      _autoSlug = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  String _toSlug(String input) {
    var str = input.toLowerCase().trim();
    // Thay thế ký tự tiếng Việt có dấu
    const vietnamese = {
      'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ': 'a',
      'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ': 'e',
      'ì|í|ị|ỉ|ĩ': 'i',
      'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ': 'o',
      'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ': 'u',
      'ỳ|ý|ỵ|ỷ|ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in vietnamese.entries) {
      str = str.replaceAll(RegExp(entry.key), entry.value);
    }
    // Xóa ký tự đặc biệt, thay khoảng trắng bằng gạch nối
    str = str.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    str = str.replaceAll(RegExp(r'\s+'), '-');
    str = str.replaceAll(RegExp(r'-+'), '-');
    return str;
  }

  void _onNameChanged(String val) {
    if (_autoSlug) {
      final generated = _toSlug(val);
      _slugController.text = generated;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(adminCategoryControllerProvider.notifier);
    final success = await controller.saveCategory(
      id: widget.categoryId ?? widget.initialCategory?.id,
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      isActive: _isActive,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.categoryId != null || widget.initialCategory != null
                ? 'Đã cập nhật danh mục thành công.'
                : 'Đã thêm danh mục mới thành công.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.categoryId != null || widget.initialCategory != null;
    final state = ref.watch(adminCategoryControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Chỉnh sửa Danh mục' : 'Thêm Danh mục mới',
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

              // Tên danh mục
              Text(
                'Tên danh mục *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Áo Sơ Mi, Quần Jeans, Váy...',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
                validator: AdminValidation.validateCategoryName,
                onChanged: _onNameChanged,
              ),

              const SizedBox(height: AppSpacing.md),

              // Slug danh mục
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đường dẫn tĩnh (Slug) *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (!isEditing)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _autoSlug = !_autoSlug;
                          if (_autoSlug) {
                            _slugController.text = _toSlug(
                              _nameController.text,
                            );
                          }
                        });
                      },
                      child: Text(
                        _autoSlug ? 'Tự tạo từ tên' : 'Nhập thủ công',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _slugController,
                decoration: InputDecoration(
                  hintText: 'vi-du-ao-so-mi',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
                validator: AdminValidation.validateCategorySlug,
                onChanged: (_) => _autoSlug = false,
              ),

              const SizedBox(height: AppSpacing.md),

              // Switch kích hoạt
              Material(
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: SwitchListTile(
                  value: _isActive,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'Kích hoạt hiển thị',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: const Text(
                    'Hiển thị danh mục này cho khách hàng trên Trang chủ và Khám phá.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),

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
                        isEditing ? 'Lưu thay đổi' : 'Tạo danh mục',
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
    );
  }
}

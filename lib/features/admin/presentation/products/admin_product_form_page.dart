import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/supabase_provider.dart';
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
  bool _isVisible = true;
  final List<String> _imagePaths = [];
  final List<AdminVariant> _variants = [];

  String? _currentProductId;
  AdminProduct? _loadedProduct;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _materialController = TextEditingController();
    _descriptionController = TextEditingController();
    _imageUrlController = TextEditingController();

    _currentProductId = widget.productId ?? widget.initialProduct?.id;

    if (widget.initialProduct != null) {
      _populateFromProduct(widget.initialProduct!);
      _isInitialized = true;
    }
  }

  void _populateFromProduct(AdminProduct p) {
    _loadedProduct = p;
    _currentProductId = p.id;
    _codeController.text = p.code;
    _nameController.text = p.name;
    _priceController.text = p.priceVnd.toString();
    _materialController.text = p.material;
    _descriptionController.text = p.description;
    _selectedCategoryId = p.categoryId;
    _isVisible = p.isVisible;

    _imagePaths.clear();
    _imagePaths.addAll(p.imagePaths);

    _variants.clear();
    _variants.addAll(p.variants);
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

  Future<void> _pickAndUploadImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    // Giới hạn 2MB (2097152 bytes) theo cấu hình bucket product-images
    if (bytes.length > 2097152) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dung lượng ảnh vượt quá giới hạn 2MB của bucket product-images.',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
      return;
    }

    final ext = file.name.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (ext == 'png') mimeType = 'image/png';
    if (ext == 'webp') mimeType = 'image/webp';

    setState(() => _isUploadingImage = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final path = await repo.uploadProductImage(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      if (mounted) {
        setState(() {
          _imagePaths.add(path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh lên thành công.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh lên: $e'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chụp ảnh mới bằng camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addManualImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _imagePaths.add(trimmed);
      _imageUrlController.clear();
    });
  }

  void _removeImage(int index) {
    // Chỉ gỡ khỏi danh sách hiển thị của sản phẩm, không xóa file storage vật lý
    // để bảo toàn tham chiếu của các đơn hàng đã tạo trước đó.
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Widget _buildImageThumbnail(String path, int index) {
    Widget imageContent;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageContent = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.accent,
        ),
      );
    } else if (path.startsWith('assets/')) {
      imageContent = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.accent,
        ),
      );
    } else {
      String? publicUrl;
      try {
        final client = ref.read(supabaseClientProvider);
        if (client != null) {
          publicUrl = client.storage.from('product-images').getPublicUrl(path);
        }
      } catch (_) {}

      if (publicUrl != null) {
        imageContent = Image.network(
          publicUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(path),
        );
      } else {
        imageContent = _buildFallbackThumbnail(path);
      }
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Container(
            width: 80,
            height: 80,
            color: AppColors.sage,
            child: imageContent,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail(String path) {
    final fileName = path.split('/').last;
    return Container(
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      color: AppColors.sage,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.checkroom_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: AppColors.ink),
          ),
        ],
      ),
    );
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
    if (_isSubmitting) return;

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

    setState(() => _isSubmitting = true);

    final sanitizedPrice = _priceController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final priceVnd = int.parse(sanitizedPrice);

    final controller = ref.read(adminProductControllerProvider.notifier);

    // Lưu thông tin chung của sản phẩm trước
    final savedProductId = await controller.saveProduct(
      id: _currentProductId,
      code: _codeController.text.trim().toUpperCase(),
      categoryId: _selectedCategoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      material: _materialController.text.trim(),
      priceVnd: priceVnd,
      imagePaths: _imagePaths,
      isVisible: _isVisible,
    );

    if (savedProductId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    // Cập nhật ID sản phẩm hiện tại để các lần thử lại sau không tạo thêm sản phẩm mới
    _currentProductId = savedProductId;

    // Lưu từng biến thể sản phẩm và theo dõi kết quả thực tế
    final baseProduct = _loadedProduct ?? widget.initialProduct;
    final List<String> failedVariants = [];
    String? firstErrorMessage;

    for (var i = 0; i < _variants.length; i++) {
      final variant = _variants[i];
      final initialVariant = baseProduct?.variants
          .cast<AdminVariant?>()
          .firstWhere((v) => v?.id == variant.id, orElse: () => null);

      final stockChanged =
          initialVariant == null || initialVariant.stock != variant.stock;

      try {
        final savedVariantId = await controller.saveVariant(
          id: variant.id.isNotEmpty ? variant.id : null,
          productId: savedProductId,
          sku: variant.sku,
          size: variant.size,
          color: variant.color,
          stock: variant.stock,
          expectedStockRevision:
              initialVariant?.stockRevision ?? variant.stockRevision,
          updateStock: stockChanged,
        );

        if (savedVariantId == null) {
          failedVariants.add(variant.sku);
        } else {
          // Gán lại ID đã lưu cho biến thể để nếu người dùng thử lại sau lỗi ở biến thể khác,
          // biến thể này đã có ID và sẽ UPDATE thay vì INSERT gây lỗi trùng SKU.
          _variants[i] = variant.copyWith(id: savedVariantId);
        }
      } on AdminStockConflictFailure catch (e) {
        failedVariants.add('${variant.sku} (xung đột tồn kho)');
        firstErrorMessage = e.message;
      } catch (e) {
        failedVariants.add(variant.sku);
        firstErrorMessage ??= e.toString();
      }
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    // Nếu có biến thể lưu thất bại: KHÔNG đóng form, giữ nguyên thông tin đang nhập để người dùng thử lại
    if (failedVariants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstErrorMessage ??
                'Đã lưu thông tin sản phẩm nhưng gặp lỗi khi lưu biến thể: ${failedVariants.join(", ")}. Vui lòng kiểm tra và bấm Lưu để thử lại.',
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Tất cả đều thành công
    final isEditing = widget.productId != null || widget.initialProduct != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Đã cập nhật sản phẩm thành công.'
              : 'Đã tạo sản phẩm và lưu toàn bộ biến thể thành công.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
    if (mounted) {
      try {
        context.pop();
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null || widget.initialProduct != null;

    // Nếu mở trực tiếp route /admin/products/:id/edit mà chưa có initialProduct
    if (widget.productId != null && widget.initialProduct == null) {
      final detailAsync = ref.watch(
        adminProductDetailProvider(widget.productId!),
      );

      return detailAsync.when(
        loading: () => const AdminGuard(
          title: 'Sửa thông tin sản phẩm',
          child: Scaffold(
            backgroundColor: AppColors.ivory,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
        error: (err, _) => AdminGuard(
          title: 'Sửa thông tin sản phẩm',
          child: Scaffold(
            backgroundColor: AppColors.ivory,
            appBar: AppBar(
              title: const Text('Sửa thông tin sản phẩm'),
              backgroundColor: AppColors.ivory,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Lỗi tải thông tin sản phẩm: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => ref.refresh(
                        adminProductDetailProvider(widget.productId!),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        data: (loadedProduct) {
          if (loadedProduct == null) {
            return AdminGuard(
              title: 'Không tìm thấy sản phẩm',
              child: Scaffold(
                backgroundColor: AppColors.ivory,
                appBar: AppBar(
                  title: const Text('Không tìm thấy sản phẩm'),
                  backgroundColor: AppColors.ivory,
                  elevation: 0,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Sản phẩm không tồn tại hoặc đã bị xóa.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context.pop(),
                          child: const Text('Quay lại danh sách'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (!_isInitialized) {
            _populateFromProduct(loadedProduct);
            _isInitialized = true;
          }

          return _buildFormScaffold(isEditing: true);
        },
      );
    }

    return _buildFormScaffold(isEditing: isEditing);
  }

  Widget _buildFormScaffold({required bool isEditing}) {
    final state = ref.watch(adminProductControllerProvider);
    final isLoading = state.isLoading || _isSubmitting;
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
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
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
                    isDense: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Switch hiển thị (is_visible)
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
                      'Mở bán sản phẩm trên Catalog (is_visible)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Bật để sản phẩm xuất hiện cho khách mua. Tắt để tạm ẩn khỏi Catalog (bảo toàn lịch sử đơn hàng cũ).',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    onChanged: (val) => setState(() => _isVisible = val),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Danh sách ảnh sản phẩm & Upload
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hình ảnh sản phẩm (${_imagePaths.length})',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isUploadingImage
                          ? null
                          : _showImageSourcePicker,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                      label: Text(
                        _isUploadingImage
                            ? 'Đang tải lên...'
                            : 'Tải ảnh từ máy',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
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
                          hintText: 'Hoặc nhập URL / Storage path trực tiếp...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: () =>
                          _addManualImageUrl(_imageUrlController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Thêm'),
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
                        return _buildImageThumbnail(_imagePaths[i], i);
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
                          'SKU: ${v.sku} • Tồn: ${v.stock} chiếc${v.stock == 0 ? ' (Hết hàng)' : ''}',
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
                            if (v.id.isEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                                tooltip: 'Gỡ biến thể chưa lưu khỏi danh sách',
                                onPressed: () {
                                  setState(() {
                                    _variants.removeAt(idx);
                                  });
                                },
                              )
                            else
                              const IconButton(
                                icon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                tooltip: 'Biến thể đã lưu không thể xóa để bảo toàn lịch sử đơn hàng. Để ngừng bán, hãy tắt hiển thị sản phẩm (is_visible).',
                                onPressed: null,
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

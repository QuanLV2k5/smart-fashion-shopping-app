import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

class SupabaseAdminRepository implements AdminRepository {
  const SupabaseAdminRepository(this.client);
  final SupabaseClient? client;

  SupabaseClient _requireClient() {
    final backend = client;
    if (backend == null) {
      throw const AdminFailure(
        'Hệ thống chưa kết nối được máy chủ. Vui lòng thử lại sau.',
      );
    }
    return backend;
  }

  @override
  Future<List<AdminCategory>> fetchCategories() async {
    final backend = _requireClient();
    try {
      final rows = await backend
          .from('categories')
          .select('id, name, slug, is_active, created_at, updated_at')
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 25));

      return (rows as List).map((row) {
        final r = row as Map<String, dynamic>;
        return AdminCategory(
          id: r['id'] as String,
          name: r['name'] as String,
          slug: r['slug'] as String,
          isActive: r['is_active'] as bool? ?? true,
          createdAt: r['created_at'] != null
              ? DateTime.tryParse(r['created_at'] as String)
              : null,
          updatedAt: r['updated_at'] != null
              ? DateTime.tryParse(r['updated_at'] as String)
              : null,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw AdminFailure('Lỗi tải danh mục: ${e.message}');
    } on TimeoutException {
      throw const AdminFailure('Kết nối quá hạn. Vui lòng kiểm tra lại mạng.');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể tải danh sách danh mục: $e');
    }
  }

  @override
  Future<void> saveCategory({
    String? id,
    required String name,
    required String slug,
    required bool isActive,
  }) async {
    final backend = _requireClient();
    final trimmedName = name.trim();
    final trimmedSlug = slug.trim();

    final data = {
      'name': trimmedName,
      'slug': trimmedSlug,
      'is_active': isActive,
    };

    try {
      if (id != null && id.isNotEmpty) {
        await backend
            .from('categories')
            .update(data)
            .eq('id', id)
            .timeout(const Duration(seconds: 25));
      } else {
        await backend
            .from('categories')
            .insert(data)
            .timeout(const Duration(seconds: 25));
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        if (e.message.contains('categories_name_key')) {
          throw const AdminFailure('Tên danh mục này đã tồn tại.');
        }
        if (e.message.contains('categories_slug_key')) {
          throw const AdminFailure('Slug danh mục này đã tồn tại.');
        }
      }
      throw AdminFailure('Lỗi lưu danh mục: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể lưu danh mục: $e');
    }
  }

  @override
  Future<List<AdminProduct>> fetchProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    final backend = _requireClient();
    try {
      var query = backend
          .from('products')
          .select(
            'id, code, category_id, name, description, material, price_vnd, '
            'image_paths, is_visible, created_at, updated_at, '
            'categories(id, name), '
            'product_variants(*)',
          );

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 25));

      final products = (rows as List).map((row) {
        final r = row as Map<String, dynamic>;
        final categoryMap = r['categories'] as Map<String, dynamic>?;
        final rawVariants = r['product_variants'] as List? ?? [];
        final rawImages = r['image_paths'] as List? ?? [];

        final variants = rawVariants.map((v) {
          final vm = v as Map<String, dynamic>;
          return AdminVariant(
            id: vm['id'] as String,
            productId: vm['product_id'] as String,
            sku: vm['sku'] as String,
            size: vm['size'] as String,
            color: vm['color'] as String,
            stock: (vm['stock'] as num?)?.toInt() ?? 0,
            stockRevision: (vm['stock_revision'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        final imagePaths = rawImages.map((img) => img.toString()).toList();

        return AdminProduct(
          id: r['id'] as String,
          code: r['code'] as String,
          categoryId: r['category_id'] as String,
          categoryName: categoryMap?['name'] as String? ?? '',
          name: r['name'] as String,
          description: r['description'] as String? ?? '',
          material: r['material'] as String? ?? '',
          priceVnd: (r['price_vnd'] as num?)?.toInt() ?? 0,
          imagePaths: imagePaths,
          isVisible: r['is_visible'] as bool? ?? true,
          variants: variants,
          createdAt: r['created_at'] != null
              ? DateTime.tryParse(r['created_at'] as String)
              : null,
          updatedAt: r['updated_at'] != null
              ? DateTime.tryParse(r['updated_at'] as String)
              : null,
        );
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return products.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.code.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q);
        }).toList();
      }

      return products;
    } on PostgrestException catch (e) {
      throw AdminFailure('Lỗi tải sản phẩm: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể tải danh sách sản phẩm: $e');
    }
  }

  @override
  Future<AdminProduct?> fetchProductById(String id) async {
    final backend = _requireClient();
    try {
      final row = await backend
          .from('products')
          .select(
            'id, code, category_id, name, description, material, price_vnd, '
            'image_paths, is_visible, created_at, updated_at, '
            'categories(id, name), '
            'product_variants(*)',
          )
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 25));

      if (row == null) return null;

      final categoryMap = row['categories'] as Map<String, dynamic>?;
      final rawVariants = row['product_variants'] as List? ?? [];
      final rawImages = row['image_paths'] as List? ?? [];

      final variants = rawVariants.map((v) {
        final vm = v as Map<String, dynamic>;
        return AdminVariant(
          id: vm['id'] as String,
          productId: vm['product_id'] as String,
          sku: vm['sku'] as String,
          size: vm['size'] as String,
          color: vm['color'] as String,
          stock: (vm['stock'] as num?)?.toInt() ?? 0,
          stockRevision: (vm['stock_revision'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      final imagePaths = rawImages.map((img) => img.toString()).toList();

      return AdminProduct(
        id: row['id'] as String,
        code: row['code'] as String,
        categoryId: row['category_id'] as String,
        categoryName: categoryMap?['name'] as String? ?? '',
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        material: row['material'] as String? ?? '',
        priceVnd: (row['price_vnd'] as num?)?.toInt() ?? 0,
        imagePaths: imagePaths,
        isVisible: row['is_visible'] as bool? ?? true,
        variants: variants,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
        updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
      );
    } on PostgrestException catch (e) {
      throw AdminFailure('Lỗi tải thông tin sản phẩm: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể tải thông tin sản phẩm: $e');
    }
  }

  @override
  Future<String> saveProduct({
    String? id,
    required String code,
    required String categoryId,
    required String name,
    required String description,
    required String material,
    required int priceVnd,
    required List<String> imagePaths,
    required bool isVisible,
  }) async {
    final backend = _requireClient();
    final data = {
      'code': code.trim(),
      'category_id': categoryId,
      'name': name.trim(),
      'description': description.trim(),
      'material': material.trim(),
      'price_vnd': priceVnd,
      'image_paths': imagePaths,
      'is_visible': isVisible,
    };

    try {
      if (id != null && id.isNotEmpty) {
        await backend
            .from('products')
            .update(data)
            .eq('id', id)
            .timeout(const Duration(seconds: 25));
        return id;
      } else {
        final inserted = await backend
            .from('products')
            .insert(data)
            .select('id')
            .single()
            .timeout(const Duration(seconds: 25));
        return inserted['id'] as String;
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AdminFailure('Mã sản phẩm (Code) này đã tồn tại.');
      }
      throw AdminFailure('Lỗi lưu sản phẩm: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể lưu sản phẩm: $e');
    }
  }

  @override
  Future<void> toggleProductVisibility(String id, bool isVisible) async {
    final backend = _requireClient();
    try {
      await backend
          .from('products')
          .update({'is_visible': isVisible})
          .eq('id', id)
          .timeout(const Duration(seconds: 25));
    } on PostgrestException catch (e) {
      throw AdminFailure('Lỗi cập nhật hiển thị sản phẩm: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể cập nhật hiển thị: $e');
    }
  }

  @override
  Future<AdminVariant> saveVariant({
    String? id,
    required String productId,
    required String sku,
    required String size,
    required String color,
    required int stock,
    int expectedStockRevision = 0,
    bool updateMetadata = true,
    bool updateStock = true,
  }) async {
    final backend = _requireClient();
    final trimmedSku = sku.trim();
    final trimmedSize = size.trim();
    final trimmedColor = color.trim();

    try {
      if (id != null && id.isNotEmpty) {
        // Cập nhật metadata biến thể: sku, size, color (tách riêng, tuyệt đối không cập nhật cột stock)
        if (updateMetadata) {
          await backend
              .from('product_variants')
              .update({
                'sku': trimmedSku,
                'size': trimmedSize,
                'color': trimmedColor,
              })
              .eq('id', id)
              .timeout(const Duration(seconds: 25));
        }

        var confirmedStock = stock;
        var confirmedRevision = expectedStockRevision;

        // Mọi thao tác điều chỉnh tồn kho của biến thể đã tồn tại BẮT BUỘC dùng RPC set_variant_stock
        if (updateStock) {
          try {
            final rpcResult = await backend
                .rpc<dynamic>(
                  'set_variant_stock',
                  params: {
                    'p_variant_id': id,
                    'p_expected_revision': expectedStockRevision,
                    'p_new_stock': stock,
                  },
                )
                .timeout(const Duration(seconds: 25));

            if (rpcResult is! Map) {
              throw const AdminFailure(
                'Phản hồi từ RPC set_variant_stock không hợp lệ (thiếu stock_revision).',
              );
            }
            final rpcMap = Map<String, dynamic>.from(rpcResult);
            final returnedStock = (rpcMap['stock'] as num?)?.toInt();
            final returnedRevision = (rpcMap['stock_revision'] as num?)
                ?.toInt();
            if (returnedStock == null || returnedRevision == null) {
              throw const AdminFailure(
                'Phản hồi từ RPC set_variant_stock thiếu tồn kho hoặc stock_revision.',
              );
            }
            confirmedStock = returnedStock;
            confirmedRevision = returnedRevision;
          } on PostgrestException catch (e) {
            if (e.code == 'PT409' ||
                e.message.contains('SF_STOCK_VERSION_CONFLICT')) {
              throw AdminStockConflictFailure(
                'Tồn kho của biến thể $trimmedSku đã bị thay đổi bởi đơn hàng hoặc phiên khác (xung đột phiên bản tồn). Vui lòng tải lại và xác nhận số lượng tồn mới.',
                variantId: id,
                currentStock: stock,
                currentRevision: expectedStockRevision,
              );
            }
            if (e.code == '42883' ||
                e.code == 'PGRST202' ||
                e.message.contains('function public.set_variant_stock')) {
              // Báo lỗi cấu hình backend; tuyệt đối không bỏ qua kiểm tra revision hoặc fallback update stock trực tiếp
              throw const AdminFailure(
                'Lỗi cấu hình backend: RPC set_variant_stock chưa được cài đặt. Không thể điều chỉnh tồn kho mà không kiểm tra phiên bản (revision).',
              );
            } else {
              rethrow;
            }
          }
        }
        return AdminVariant(
          id: id,
          productId: productId,
          sku: trimmedSku,
          size: trimmedSize,
          color: trimmedColor,
          stock: confirmedStock,
          stockRevision: confirmedRevision,
        );
      } else {
        // Thêm biến thể mới có khai báo tồn ban đầu theo schema và đọc lại trạng thái từ server
        final inserted = await backend
            .from('product_variants')
            .insert({
              'product_id': productId,
              'sku': trimmedSku,
              'size': trimmedSize,
              'color': trimmedColor,
              'stock': stock,
            })
            .select('id, product_id, sku, size, color, stock, stock_revision')
            .single()
            .timeout(const Duration(seconds: 25));
        return AdminVariant(
          id: inserted['id'] as String,
          productId: inserted['product_id'] as String? ?? productId,
          sku: inserted['sku'] as String? ?? trimmedSku,
          size: inserted['size'] as String? ?? trimmedSize,
          color: inserted['color'] as String? ?? trimmedColor,
          stock: (inserted['stock'] as num?)?.toInt() ?? stock,
          stockRevision: (inserted['stock_revision'] as num?)?.toInt() ?? 0,
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        if (e.message.contains('product_variants_sku_key')) {
          throw const AdminFailure('Mã SKU biến thể này đã tồn tại.');
        }
        if (e.message.contains('product_variants_product_id_size_color_key')) {
          throw const AdminFailure(
            'Sản phẩm đã có biến thể cùng kích cỡ và màu sắc này.',
          );
        }
      }
      throw AdminFailure('Lỗi lưu biến thể: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể lưu biến thể: $e');
    }
  }

  @override
  Future<void> deleteVariant(
    String variantId, {
    int expectedStockRevision = 0,
  }) async {
    // Vô hiệu hóa thao tác xóa cứng biến thể để bảo đảm toàn vẹn khóa ngoại (on delete restrict)
    // với bảng order_items và chính sách RLS hiện hành (không có quyền DELETE).
    throw const AdminFailure(
      'Thao tác xóa biến thể đã lưu tạm thời bị vô hiệu hóa để bảo đảm toàn vẹn dữ liệu đơn hàng. Để ngừng bán sản phẩm, vui lòng tắt tùy chọn hiển thị sản phẩm (is_visible).',
    );
  }

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final backend = _requireClient();
    try {
      final sanitizedName = fileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .toLowerCase();
      final path =
          'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      await backend.storage
          .from('product-images')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          )
          .timeout(const Duration(seconds: 30));

      return path;
    } on StorageException catch (e) {
      throw AdminFailure('Lỗi tải ảnh lên Storage: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể tải ảnh sản phẩm: $e');
    }
  }
}

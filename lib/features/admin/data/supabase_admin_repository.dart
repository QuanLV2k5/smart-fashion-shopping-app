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
  @override
  Future<void> saveVariant({
    String? id,
    required String productId,
    required String sku,
    required String size,
    required String color,
    required int stock,
    int expectedStockRevision = 0,
    bool updateStock = true,
  }) async {
    final backend = _requireClient();

    try {
      if (id != null && id.isNotEmpty) {
        // Cập nhật metadata biến thể: sku, size, color (tách riêng, không bao gồm stock)
        await backend
            .from('product_variants')
            .update({
              'sku': sku.trim(),
              'size': size.trim(),
              'color': color.trim(),
            })
            .eq('id', id)
            .timeout(const Duration(seconds: 25));

        // Nếu có điều chỉnh tồn kho, gọi RPC set_variant_stock có kiểm tra expected revision
        if (updateStock) {
          try {
            await backend
                .rpc<dynamic>(
                  'set_variant_stock',
                  params: {
                    'p_variant_id': id,
                    'p_expected_revision': expectedStockRevision,
                    'p_new_stock': stock,
                  },
                )
                .timeout(const Duration(seconds: 25));
          } on PostgrestException catch (e) {
            if (e.code == 'PT409' ||
                e.message.contains('SF_STOCK_VERSION_CONFLICT')) {
              throw AdminStockConflictFailure(
                'Tồn kho của biến thể $sku đã bị thay đổi bởi đơn hàng hoặc phiên khác (xung đột phiên bản tồn). Vui lòng tải lại và xác nhận số lượng tồn mới.',
                variantId: id,
                currentStock: stock,
                currentRevision: expectedStockRevision,
              );
            }
            if (e.code == '42883' ||
                e.message.contains('function public.set_variant_stock')) {
              // Fallback khi migration chưa nạp RPC
              await backend
                  .from('product_variants')
                  .update({'stock': stock})
                  .eq('id', id)
                  .timeout(const Duration(seconds: 25));
            } else {
              rethrow;
            }
          }
        }
      } else {
        // Thêm biến thể mới có khai báo tồn ban đầu
        await backend
            .from('product_variants')
            .insert({
              'product_id': productId,
              'sku': sku.trim(),
              'size': size.trim(),
              'color': color.trim(),
              'stock': stock,
            })
            .timeout(const Duration(seconds: 25));
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
    final backend = _requireClient();
    try {
      try {
        await backend
            .rpc<dynamic>(
              'set_variant_stock',
              params: {
                'p_variant_id': variantId,
                'p_expected_revision': expectedStockRevision,
                'p_new_stock': 0,
              },
            )
            .timeout(const Duration(seconds: 25));
      } on PostgrestException catch (e) {
        if (e.code == 'PT409' ||
            e.message.contains('SF_STOCK_VERSION_CONFLICT')) {
          throw AdminStockConflictFailure(
            'Tồn kho biến thể đã bị thay đổi bởi đơn hàng. Vui lòng tải lại trước khi đặt tồn về 0.',
            variantId: variantId,
            currentRevision: expectedStockRevision,
          );
        }
        if (e.code == '42883' ||
            e.message.contains('function public.set_variant_stock')) {
          await backend
              .from('product_variants')
              .update({'stock': 0})
              .eq('id', variantId)
              .timeout(const Duration(seconds: 25));
        } else {
          rethrow;
        }
      }
    } on PostgrestException catch (e) {
      throw AdminFailure('Lỗi cập nhật tồn kho biến thể: ${e.message}');
    } catch (e) {
      if (e is AdminFailure) rethrow;
      throw AdminFailure('Không thể cập nhật biến thể: $e');
    }
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

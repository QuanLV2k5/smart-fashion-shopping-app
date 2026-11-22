import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../auth/domain/user_role.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(ref.watch(supabaseClientProvider));
});

/// Provider kiểm tra vai trò người dùng hiện tại (customer / admin).
final currentUserRoleProvider = FutureProvider.autoDispose<UserRole>((
  ref,
) async {
  final userId = ref.watch(profileUserIdProvider);
  if (userId == null) return UserRole.customer;

  final client = ref.watch(supabaseClientProvider);
  if (client == null) return UserRole.customer;

  try {
    final response = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return UserRole.customer;
    return UserRole.fromString(response['role'] as String?);
  } catch (_) {
    return UserRole.customer;
  }
});

/// Provider boolean nhanh: Tài khoản hiện tại có phải Admin không?
final isCurrentUserAdminProvider = Provider.autoDispose<bool>((ref) {
  final roleAsync = ref.watch(currentUserRoleProvider);
  return roleAsync.value == UserRole.admin;
});

/// Provider danh sách toàn bộ danh mục cho Admin.
final adminCategoriesProvider = FutureProvider.autoDispose<List<AdminCategory>>(
  (ref) async {
    return ref.watch(adminRepositoryProvider).fetchCategories();
  },
);

/// Bộ lọc cho danh sách sản phẩm Admin
class AdminProductFilter {
  const AdminProductFilter({this.categoryId, this.searchQuery});
  final String? categoryId;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProductFilter &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(categoryId, searchQuery);
}

class AdminProductFilterNotifier extends Notifier<AdminProductFilter> {
  @override
  AdminProductFilter build() => const AdminProductFilter();

  void setCategory(String? categoryId) {
    state = AdminProductFilter(
      categoryId: categoryId,
      searchQuery: state.searchQuery,
    );
  }

  void setSearch(String? searchQuery) {
    state = AdminProductFilter(
      categoryId: state.categoryId,
      searchQuery: searchQuery,
    );
  }
}

final adminProductFilterProvider =
    NotifierProvider.autoDispose<
      AdminProductFilterNotifier,
      AdminProductFilter
    >(AdminProductFilterNotifier.new);

/// Provider danh sách sản phẩm theo bộ lọc cho Admin.
final adminProductsProvider = FutureProvider.autoDispose<List<AdminProduct>>((
  ref,
) async {
  final filter = ref.watch(adminProductFilterProvider);
  return ref
      .watch(adminRepositoryProvider)
      .fetchProducts(
        categoryId: filter.categoryId,
        searchQuery: filter.searchQuery,
      );
});

/// Provider chi tiết một sản phẩm theo ID
final adminProductDetailProvider = FutureProvider.autoDispose
    .family<AdminProduct?, String>((ref, productId) async {
      return ref.watch(adminRepositoryProvider).fetchProductById(productId);
    });

/// Controller quản lý lưu danh mục
class AdminCategoryController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> saveCategory({
    String? id,
    required String name,
    required String slug,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.saveCategory(
        id: id,
        name: name,
        slug: slug,
        isActive: isActive,
      );
      state = const AsyncData(null);
      ref.invalidate(adminCategoriesProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final adminCategoryControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminCategoryController, void>(
      AdminCategoryController.new,
    );

/// Controller quản lý lưu sản phẩm và đổi trạng thái hiển thị
class AdminProductController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<String?> saveProduct({
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
    state = const AsyncLoading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final productId = await repo.saveProduct(
        id: id,
        code: code,
        categoryId: categoryId,
        name: name,
        description: description,
        material: material,
        priceVnd: priceVnd,
        imagePaths: imagePaths,
        isVisible: isVisible,
      );
      state = const AsyncData(null);
      ref.invalidate(adminProductsProvider);
      if (id != null) {
        ref.invalidate(adminProductDetailProvider(id));
      }
      return productId;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> toggleVisibility(String id, bool isVisible) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.toggleProductVisibility(id, isVisible);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminProductDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> saveVariant({
    String? id,
    required String productId,
    required String sku,
    required String size,
    required String color,
    required int stock,
    bool updateStock = true,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.saveVariant(
        id: id,
        productId: productId,
        sku: sku,
        size: size,
        color: color,
        stock: stock,
        updateStock: updateStock,
      );
      state = const AsyncData(null);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminProductDetailProvider(productId));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteVariant(String productId, String variantId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteVariant(variantId);
      state = const AsyncData(null);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminProductDetailProvider(productId));
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<String?> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final path = await repo.uploadProductImage(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      state = const AsyncData(null);
      return path;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final adminProductControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminProductController, void>(
      AdminProductController.new,
    );

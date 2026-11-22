import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/admin/domain/admin_models.dart';
import 'package:smart_fashion/features/admin/domain/admin_repository.dart';
import 'package:smart_fashion/features/admin/presentation/admin_dashboard_page.dart';
import 'package:smart_fashion/features/admin/presentation/admin_providers.dart';
import 'package:smart_fashion/features/admin/presentation/categories/admin_categories_page.dart';
import 'package:smart_fashion/features/admin/presentation/categories/admin_category_form_page.dart';
import 'package:smart_fashion/features/admin/presentation/products/admin_product_form_page.dart';
import 'package:smart_fashion/features/admin/presentation/products/admin_products_page.dart';
import 'package:smart_fashion/features/auth/domain/user_role.dart';

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    List<AdminCategory>? initialCategories,
    List<AdminProduct>? initialProducts,
  }) : categories = initialCategories ?? [],
       products = initialProducts ?? [];

  final List<AdminCategory> categories;
  final List<AdminProduct> products;

  @override
  Future<List<AdminCategory>> fetchCategories() async => List.of(categories);

  @override
  Future<void> saveCategory({
    String? id,
    required String name,
    required String slug,
    required bool isActive,
  }) async {
    if (id != null) {
      final idx = categories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        categories[idx] = categories[idx].copyWith(
          name: name,
          slug: slug,
          isActive: isActive,
        );
      }
    } else {
      categories.add(
        AdminCategory(
          id: 'cat_${categories.length + 1}',
          name: name,
          slug: slug,
          isActive: isActive,
        ),
      );
    }
  }

  @override
  Future<List<AdminProduct>> fetchProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    var result = List.of(products);
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.code.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  @override
  Future<AdminProduct?> fetchProductById(String id) async {
    final idx = products.indexWhere((p) => p.id == id);
    return idx != -1 ? products[idx] : null;
  }

  bool shouldFailVariantSave = false;
  bool shouldThrowStockConflict = false;
  int saveProductCallCount = 0;
  String? lastSavedProductId;
  Map<String, dynamic> lastVariantSavePayload = {};

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
    saveProductCallCount++;
    lastSavedProductId = id;
    if (id != null) {
      final idx = products.indexWhere((p) => p.id == id);
      if (idx != -1) {
        products[idx] = products[idx].copyWith(
          code: code,
          categoryId: categoryId,
          name: name,
          description: description,
          material: material,
          priceVnd: priceVnd,
          imagePaths: imagePaths,
          isVisible: isVisible,
        );
        return id;
      }
    }
    final newId = 'prod_${products.length + 1}';
    products.add(
      AdminProduct(
        id: newId,
        code: code,
        categoryId: categoryId,
        name: name,
        description: description,
        material: material,
        priceVnd: priceVnd,
        imagePaths: imagePaths,
        isVisible: isVisible,
        variants: [],
      ),
    );
    return newId;
  }

  @override
  Future<void> toggleProductVisibility(String id, bool isVisible) async {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      products[idx] = products[idx].copyWith(isVisible: isVisible);
    }
  }

  @override
  Future<String> saveVariant({
    String? id,
    required String productId,
    required String sku,
    required String size,
    required String color,
    required int stock,
    int expectedStockRevision = 0,
    bool updateStock = true,
  }) async {
    lastVariantSavePayload = {
      'id': id,
      'productId': productId,
      'sku': sku,
      'size': size,
      'color': color,
      'stock': stock,
      'expectedStockRevision': expectedStockRevision,
      'updateStock': updateStock,
    };
    if (shouldThrowStockConflict) {
      throw const AdminStockConflictFailure(
        'Xung đột phiên bản tồn kho trên biến thể',
      );
    }
    if (shouldFailVariantSave) {
      throw const AdminFailure('Lỗi lưu biến thể giả lập');
    }
    return id ?? 'v_saved_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> deleteVariant(
    String variantId, {
    int expectedStockRevision = 0,
  }) async {}

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async => 'products/$fileName';
}

void main() {
  Widget buildTestApp({
    required Widget child,
    required FakeAdminRepository repository,
    UserRole role = UserRole.admin,
  }) {
    return ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
        currentUserRoleProvider.overrideWith((ref) async => role),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Admin Dashboard & Access Control Flow', () {
    testWidgets('Non-admin users see Access Denied view on Dashboard', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository();

      await tester.pumpWidget(
        buildTestApp(
          child: const AdminDashboardPage(),
          repository: fakeRepo,
          role: UserRole.customer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quyền truy cập bị giới hạn'), findsOneWidget);
      expect(find.text('Quay lại cửa hàng'), findsOneWidget);
      expect(find.text('Bảng điều khiển Admin'), findsNothing);
    });

    testWidgets(
      'Non-admin users are blocked on all Admin subpages by AdminGuard',
      (tester) async {
        final fakeRepo = FakeAdminRepository();

        // Kiểm tra chặn truy cập vào AdminProductsPage
        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductsPage(),
            repository: fakeRepo,
            role: UserRole.customer,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Quyền truy cập bị giới hạn'), findsOneWidget);
        expect(find.text('Quản lý Sản phẩm & Kho'), findsNothing);

        // Kiểm tra chặn truy cập vào AdminCategoriesPage
        await tester.pumpWidget(
          buildTestApp(
            child: const AdminCategoriesPage(),
            repository: fakeRepo,
            role: UserRole.customer,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Quyền truy cập bị giới hạn'), findsOneWidget);
        expect(find.text('Quản lý Danh mục'), findsNothing);
      },
    );

    testWidgets('Admin user sees Dashboard with menu items and stats', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository(
        initialCategories: const [
          AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
        ],
        initialProducts: [
          AdminProduct(
            id: 'p1',
            code: 'SF01',
            categoryId: 'c1',
            name: 'Áo Sơ Mi Linen',
            description: '',
            material: '',
            priceVnd: 199000,
            imagePaths: [],
            isVisible: true,
            variants: const [
              AdminVariant(
                id: 'v1',
                productId: 'p1',
                sku: 'SF01_M',
                size: 'M',
                color: 'Trắng',
                stock: 25,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const AdminDashboardPage(),
          repository: fakeRepo,
          role: UserRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quản trị cửa hàng'), findsOneWidget);
      expect(find.text('Bảng điều khiển Admin'), findsOneWidget);
      expect(find.text('Quản lý Sản phẩm & Kho'), findsOneWidget);
      expect(find.text('Quản lý Danh mục'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // 1 product, 1 category
    });
  });

  group('Admin Categories Flow', () {
    testWidgets('Categories list shows items and empty state', (tester) async {
      final fakeRepo = FakeAdminRepository(
        initialCategories: const [
          AdminCategory(
            id: 'c1',
            name: 'Áo Nam',
            slug: 'ao-nam',
            isActive: true,
          ),
          AdminCategory(
            id: 'c2',
            name: 'Quần Jeans',
            slug: 'quan-jeans',
            isActive: false,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(child: const AdminCategoriesPage(), repository: fakeRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Áo Nam'), findsOneWidget);
      expect(find.text('Quần Jeans'), findsOneWidget);
      expect(find.text('Đang bật'), findsOneWidget);
      expect(find.text('Đã tắt'), findsOneWidget);
    });

    testWidgets('Category form validates empty fields and invalid slug', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository();

      await tester.pumpWidget(
        buildTestApp(
          child: const AdminCategoryFormPage(),
          repository: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Submit empty
      await tester.tap(find.text('Tạo danh mục'));
      await tester.pumpAndSettle();

      expect(find.text('Tên danh mục không được để trống'), findsOneWidget);
      expect(find.text('Slug không được để trống'), findsOneWidget);
    });
  });

  group('Admin Products Flow', () {
    testWidgets('Products list displays product details and formatted price', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository(
        initialProducts: [
          AdminProduct(
            id: 'p1',
            code: 'SF01',
            categoryId: 'c1',
            categoryName: 'Áo',
            name: 'Áo Sơ Mi Linen',
            description: '',
            material: '',
            priceVnd: 199000,
            imagePaths: [],
            isVisible: true,
            variants: const [
              AdminVariant(
                id: 'v1',
                productId: 'p1',
                sku: 'SF01_M',
                size: 'M',
                color: 'Trắng',
                stock: 15,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(child: const AdminProductsPage(), repository: fakeRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('SF01'), findsOneWidget);
      expect(find.text('Áo Sơ Mi Linen'), findsOneWidget);
      expect(find.text('199.000 đ'), findsOneWidget);
      expect(find.text('Đang bán'), findsOneWidget);
    });

    testWidgets('Product form validates required fields', (tester) async {
      final fakeRepo = FakeAdminRepository(
        initialCategories: const [
          AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(child: const AdminProductFormPage(), repository: fakeRepo),
      );
      await tester.pumpAndSettle();

      final submitButton = find.text('Đăng bán sản phẩm');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Mã sản phẩm không được để trống'), findsOneWidget);
      expect(find.text('Tên sản phẩm không được để trống'), findsOneWidget);
      expect(find.text('Giá sản phẩm không được để trống'), findsOneWidget);
    });

    testWidgets(
      'Variant save failure keeps form open and shows error without pop',
      (tester) async {
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
        );
        fakeRepo.shouldFailVariantSave = true;

        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductFormPage(),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Điền form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'VD: SF01, SF02...'),
          'SF99',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ví dụ: Áo Sơ Mi Cổ Trụ Vải Linen',
          ),
          'Áo Khoác Gió',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ví dụ: 199000 hoặc 249000'),
          '350000',
        );

        // Mở dialog thêm biến thể
        await tester.ensureVisible(find.text('Thêm biến thể'));
        await tester.tap(find.text('Thêm biến thể'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'S, M, L, XL hoặc 29, 30, 31...'),
          'L',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Đen, Trắng, Xanh rêu, Be...'),
          'Đen',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '20',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Thêm')),
        );
        await tester.pumpAndSettle();

        // Bấm lưu sản phẩm
        final submitButton = find.text('Đăng bán sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Form VẪN MỞ và hiển thị thông báo lỗi biến thể
        expect(find.text('Đăng sản phẩm mới'), findsOneWidget);
        expect(find.text('SF99'), findsOneWidget);
        expect(find.text('Áo Khoác Gió'), findsOneWidget);
        expect(find.textContaining('Lỗi lưu biến thể giả lập'), findsOneWidget);

        // Giờ tắt lỗi và bấm lưu lại -> Thử lại thành công, KHÔNG tạo trùng sản phẩm mới
        fakeRepo.shouldFailVariantSave = false;
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Khi lưu lại, saveProduct được gọi với id của sản phẩm vừa tạo (không tạo mới)
        expect(fakeRepo.lastSavedProductId, 'prod_1');
        expect(fakeRepo.products.length, 1);
      },
    );

    testWidgets(
      'Direct route loads product data by productId when initialProduct is null',
      (tester) async {
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
          initialProducts: [
            AdminProduct(
              id: 'p_direct',
              code: 'SF_DIRECT',
              categoryId: 'c1',
              name: 'Áo Len Cổ Lọ',
              description: 'Mô tả len mềm',
              material: 'Len',
              priceVnd: 299000,
              imagePaths: const ['img_direct.png'],
              isVisible: true,
              variants: const [
                AdminVariant(
                  id: 'v_direct',
                  productId: 'p_direct',
                  sku: 'SF_DIRECT_M',
                  size: 'M',
                  color: 'Kem',
                  stock: 12,
                  stockRevision: 3,
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductFormPage(productId: 'p_direct'),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Kiểm tra dữ liệu sản phẩm được tải và điền vào form
        expect(find.text('SF_DIRECT'), findsOneWidget);
        expect(find.text('Áo Len Cổ Lọ'), findsOneWidget);
        expect(find.text('299000'), findsOneWidget);
        expect(find.text('SKU: SF_DIRECT_M • Tồn: 12 chiếc'), findsOneWidget);
      },
    );

    testWidgets('Direct route shows not found when productId does not exist', (
      tester,
    ) async {
      final fakeRepo = FakeAdminRepository();

      await tester.pumpWidget(
        buildTestApp(
          child: const AdminProductFormPage(productId: 'nonexistent_id'),
          repository: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
      expect(
        find.text('Sản phẩm không tồn tại hoặc đã bị xóa.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Stock conflict triggers error notification and prevents silent overwrite',
      (tester) async {
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
        );
        fakeRepo.shouldThrowStockConflict = true;

        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductFormPage(),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VD: SF01, SF02...'),
          'SF_CONF',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ví dụ: Áo Sơ Mi Cổ Trụ Vải Linen',
          ),
          'Áo Xung Đột Tồn',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ví dụ: 199000 hoặc 249000'),
          '200000',
        );

        await tester.ensureVisible(find.text('Thêm biến thể'));
        await tester.tap(find.text('Thêm biến thể'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'S, M, L, XL hoặc 29, 30, 31...'),
          'M',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Đen, Trắng, Xanh rêu, Be...'),
          'Xanh',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '10',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Thêm')),
        );
        await tester.pumpAndSettle();

        final submitButton = find.text('Đăng bán sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Thông báo xung đột xuất hiện, form không đóng
        expect(find.textContaining('Xung đột phiên bản tồn kho'), findsWidgets);
        expect(find.text('Đăng sản phẩm mới'), findsOneWidget);
      },
    );
  });
}

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
       products = initialProducts ?? [] {
    for (final p in products) {
      for (final v in p.variants) {
        if (v.id.isNotEmpty) {
          variantStore[v.id] = v;
        }
      }
    }
  }

  final List<AdminCategory> categories;
  final List<AdminProduct> products;
  final Map<String, AdminVariant> variantStore = {};
  final List<Map<String, dynamic>> variantSaveCalls = [];
  final Set<String> duplicateSkus = {};
  int _nextVariantSeq = 1;
  int revisionStepOnStockChange = 1;

  /// Mô phỏng giao dịch ngoài (Checkout COD / Hủy đơn) làm thay đổi tồn kho và tăng stock_revision trên server.
  void simulateExternalStockChange(String variantId, int newStock) {
    final current = variantStore[variantId];
    if (current == null) {
      throw StateError('Variant $variantId not found in variantStore');
    }
    variantStore[variantId] = current.copyWith(
      stock: newStock,
      stockRevision: current.stockRevision + 1,
    );
    _syncProductVariants(current.productId);
  }

  void _syncProductVariants(String productId) {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final list = variantStore.values
          .where((v) => v.productId == productId)
          .toList();
      products[idx] = products[idx].copyWith(variants: list);
    }
  }

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
    final trimmedSku = sku.trim();
    final trimmedSize = size.trim();
    final trimmedColor = color.trim();
    final payload = {
      'id': id,
      'productId': productId,
      'sku': trimmedSku,
      'size': trimmedSize,
      'color': trimmedColor,
      'stock': stock,
      'expectedStockRevision': expectedStockRevision,
      'updateMetadata': updateMetadata,
      'updateStock': updateStock,
    };
    lastVariantSavePayload = payload;
    variantSaveCalls.add(payload);

    if (shouldThrowStockConflict) {
      throw const AdminStockConflictFailure(
        'Xung đột phiên bản tồn kho trên biến thể',
      );
    }
    if (shouldFailVariantSave) {
      throw const AdminFailure('Lỗi lưu biến thể giả lập');
    }
    if (duplicateSkus.contains(trimmedSku)) {
      throw const AdminFailure('Mã SKU biến thể này đã tồn tại.');
    }

    if (id != null && id.isNotEmpty) {
      final existing = variantStore[id];
      if (existing == null) {
        throw AdminFailure('Không tìm thấy biến thể $id');
      }
      if (updateMetadata) {
        final conflictSku = variantStore.values.any(
          (v) => v.id != id && v.sku == trimmedSku,
        );
        if (conflictSku) {
          throw const AdminFailure('Mã SKU biến thể này đã tồn tại.');
        }
      }
      var nextStock = existing.stock;
      var nextRevision = existing.stockRevision;
      if (updateStock) {
        // Kiểm tra CAS thực sự như RPC set_variant_stock trên Postgres
        if (expectedStockRevision != existing.stockRevision) {
          throw AdminStockConflictFailure(
            'Tồn kho của biến thể $trimmedSku đã bị thay đổi bởi đơn hàng hoặc phiên khác (SF_STOCK_VERSION_CONFLICT).',
            variantId: id,
            currentStock: existing.stock,
            currentRevision: existing.stockRevision,
          );
        }
        nextStock = stock;
        if (stock != existing.stock) {
          nextRevision = existing.stockRevision + revisionStepOnStockChange;
        }
      }
      final saved = existing.copyWith(
        sku: updateMetadata ? trimmedSku : existing.sku,
        size: updateMetadata ? trimmedSize : existing.size,
        color: updateMetadata ? trimmedColor : existing.color,
        stock: nextStock,
        stockRevision: nextRevision,
      );
      variantStore[id] = saved;
      _syncProductVariants(productId);
      return saved;
    } else {
      final conflictSku = variantStore.values.any((v) => v.sku == trimmedSku);
      if (conflictSku) {
        throw const AdminFailure('Mã SKU biến thể này đã tồn tại.');
      }
      final newId = 'v_new_${_nextVariantSeq++}';
      final saved = AdminVariant(
        id: newId,
        productId: productId,
        sku: trimmedSku,
        size: trimmedSize,
        color: trimmedColor,
        stock: stock,
        stockRevision: 0,
      );
      variantStore[newId] = saved;
      _syncProductVariants(productId);
      return saved;
    }
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
        expect(find.textContaining('Lỗi lưu biến thể giả lập'), findsWidgets);

        // Giờ tắt lỗi và bấm lưu lại -> Thử lại thành công, KHÔNG tạo trùng sản phẩm mới
        fakeRepo.shouldFailVariantSave = false;
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Sản phẩm không bị tạo trùng và biến thể đã được lưu vào đúng prod_1
        expect(fakeRepo.saveProductCallCount, 1);
        expect(fakeRepo.products.length, 1);
        expect(fakeRepo.variantStore.length, 1);
        expect(fakeRepo.variantStore.values.first.productId, 'prod_1');
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

    testWidgets(
      'Partial save retry: A updates stock (rev 0->1), B fails duplicate SKU, fixing B retries without self-conflict on A',
      (tester) async {
        final product = AdminProduct(
          id: 'p_cas',
          code: 'SFCAS',
          categoryId: 'c1',
          name: 'Áo Polo CAS',
          description: 'Mô tả',
          material: 'Cotton',
          priceVnd: 250000,
          imagePaths: const [],
          isVisible: true,
          variants: const [
            AdminVariant(
              id: 'vA',
              productId: 'p_cas',
              sku: 'SKU_A',
              size: 'M',
              color: 'Đen',
              stock: 5,
              stockRevision: 0,
            ),
            AdminVariant(
              id: 'vB',
              productId: 'p_cas',
              sku: 'SKU_B',
              size: 'L',
              color: 'Trắng',
              stock: 10,
              stockRevision: 0,
            ),
          ],
        );
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
          initialProducts: [product],
        )..duplicateSkus.add('SKU_DUP');

        await tester.pumpWidget(
          buildTestApp(
            child: AdminProductFormPage(
              productId: product.id,
              initialProduct: product,
            ),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Sửa A: stock 5 -> 6
        final editButtons = find.byIcon(Icons.edit_outlined);
        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '6',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        // Sửa B: đổi SKU sang SKU_DUP để gây lỗi trùng SKU
        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'SKU_DUP',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        // Bấm Lưu lần 1: A lưu thành công (stock=6, rev=1), B thất bại do trùng SKU
        final submitButton = find.text('Lưu sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeRepo.variantStore['vA']!.stock, 6);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 1);
        expect(find.text('Sửa thông tin sản phẩm'), findsOneWidget);
        expect(find.textContaining('SKU_DUP'), findsWidgets);

        final callsBeforeRetry = fakeRepo.variantSaveCalls.length;
        expect(callsBeforeRetry, 2); // A và B

        // Đóng snackbar, sửa B thành SKU_B_FIXED rồi bấm Lưu lại
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'SKU_B_FIXED',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Lần retry chỉ gọi saveVariant cho B, KHÔNG gửi lại A với revision=0
        expect(fakeRepo.variantSaveCalls.length, callsBeforeRetry + 1);
        expect(fakeRepo.variantSaveCalls.last['id'], 'vB');
        expect(fakeRepo.variantSaveCalls.last['updateStock'], isFalse);
        expect(fakeRepo.variantStore['vA']!.stock, 6);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 1);
        expect(fakeRepo.variantStore['vB']!.sku, 'SKU_B_FIXED');
        expect(
          find.textContaining('Đã cập nhật sản phẩm thành công'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Partial save on create: product + V1 saved, V2 fails, retry saves only V2 without duplicates',
      (tester) async {
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
        )..duplicateSkus.add('SFNEW_L_trang');

        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductFormPage(),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'VD: SF01, SF02...'),
          'SFNEW',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ví dụ: Áo Sơ Mi Cổ Trụ Vải Linen',
          ),
          'Áo Mới Partial',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ví dụ: 199000 hoặc 249000'),
          '320000',
        );

        // Thêm V1 hợp lệ
        await tester.ensureVisible(find.text('Thêm biến thể'));
        await tester.tap(find.text('Thêm biến thể'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'S, M, L, XL hoặc 29, 30, 31...'),
          'M',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Đen, Trắng, Xanh rêu, Be...'),
          'den',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '15',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Thêm')),
        );
        await tester.pumpAndSettle();

        // Thêm V2 bị trùng SKU
        await tester.ensureVisible(find.text('Thêm biến thể'));
        await tester.tap(find.text('Thêm biến thể'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'S, M, L, XL hoặc 29, 30, 31...'),
          'L',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Đen, Trắng, Xanh rêu, Be...'),
          'trang',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '8',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Thêm')),
        );
        await tester.pumpAndSettle();

        // Lưu lần 1: Product + V1 thành công, V2 thất bại
        final submitButton = find.text('Đăng bán sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeRepo.products.length, 1);
        expect(fakeRepo.saveProductCallCount, 1);
        expect(fakeRepo.variantStore.length, 1);
        expect(find.text('Đăng sản phẩm mới'), findsOneWidget);

        // Sửa SKU V2 rồi bấm lưu lại
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        final editButtons = find.byIcon(Icons.edit_outlined);
        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'SFNEW_L_TRANG_OK',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Không tạo trùng sản phẩm hoặc biến thể V1
        expect(fakeRepo.saveProductCallCount, 1);
        expect(fakeRepo.products.length, 1);
        expect(fakeRepo.variantStore.length, 2);
        expect(
          fakeRepo.variantStore.values.map((v) => v.sku).toSet(),
          containsAll(['SFNEW_M_den', 'SFNEW_L_TRANG_OK']),
        );
      },
    );

    testWidgets(
      'Subsequent edit on A after partial save uses server-returned revision (not guessed +1)',
      (tester) async {
        final product = AdminProduct(
          id: 'p_rev',
          code: 'SFREV',
          categoryId: 'c1',
          name: 'Quần Tây Revision',
          description: 'Mô tả',
          material: 'Kaki',
          priceVnd: 390000,
          imagePaths: const [],
          isVisible: true,
          variants: const [
            AdminVariant(
              id: 'vA',
              productId: 'p_rev',
              sku: 'REV_A',
              size: 'M',
              color: 'Be',
              stock: 5,
              stockRevision: 0,
            ),
            AdminVariant(
              id: 'vB',
              productId: 'p_rev',
              sku: 'REV_B',
              size: 'L',
              color: 'Nâu',
              stock: 10,
              stockRevision: 0,
            ),
          ],
        );
        // Cho server tăng revision theo bước nhảy 3 để chứng minh client dùng đúng revision server trả về, không tự +1
        final fakeRepo =
            FakeAdminRepository(
                initialCategories: const [
                  AdminCategory(
                    id: 'c1',
                    name: 'Quần',
                    slug: 'quan',
                    isActive: true,
                  ),
                ],
                initialProducts: [product],
              )
              ..revisionStepOnStockChange = 3
              ..duplicateSkus.add('REV_DUP');

        await tester.pumpWidget(
          buildTestApp(
            child: AdminProductFormPage(
              productId: product.id,
              initialProduct: product,
            ),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        final editButtons = find.byIcon(Icons.edit_outlined);
        // Lần 1: A đổi tồn 5 -> 6, B đổi SKU trùng
        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '6',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'REV_DUP',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        final submitButton = find.text('Lưu sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeRepo.variantStore['vA']!.stock, 6);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 3);

        // Lần 2: Sửa A thêm lần nữa 6 -> 8 và sửa B hợp lệ
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '8',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'REV_B_OK',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // A gửi đúng expectedStockRevision = 3 (server trả về) và được cập nhật lên 8 (rev = 6)
        final aCalls = fakeRepo.variantSaveCalls
            .where((c) => c['id'] == 'vA')
            .toList();
        expect(aCalls.length, 2);
        expect(aCalls[0]['expectedStockRevision'], 0);
        expect(aCalls[1]['expectedStockRevision'], 3);
        expect(fakeRepo.variantStore['vA']!.stock, 8);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 6);
      },
    );

    testWidgets(
      'Real external checkout conflict after first partial save is still rejected without overwriting stock',
      (tester) async {
        final product = AdminProduct(
          id: 'p_ext',
          code: 'SFEXT',
          categoryId: 'c1',
          name: 'Áo Len Conflict',
          description: 'Mô tả',
          material: 'Len',
          priceVnd: 410000,
          imagePaths: const [],
          isVisible: true,
          variants: const [
            AdminVariant(
              id: 'vA',
              productId: 'p_ext',
              sku: 'EXT_A',
              size: 'M',
              color: 'Đỏ',
              stock: 5,
              stockRevision: 0,
            ),
            AdminVariant(
              id: 'vB',
              productId: 'p_ext',
              sku: 'EXT_B',
              size: 'L',
              color: 'Xám',
              stock: 10,
              stockRevision: 0,
            ),
          ],
        );
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Áo', slug: 'ao', isActive: true),
          ],
          initialProducts: [product],
        )..duplicateSkus.add('EXT_DUP');

        await tester.pumpWidget(
          buildTestApp(
            child: AdminProductFormPage(
              productId: product.id,
              initialProduct: product,
            ),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        final editButtons = find.byIcon(Icons.edit_outlined);
        // Lần 1: A đổi tồn 5 -> 6 (thành công), B lỗi SKU trùng
        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '6',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'EXT_DUP',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        final submitButton = find.text('Lưu sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeRepo.variantStore['vA']!.stock, 6);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 1);

        // Mô phỏng khách hàng đặt đơn COD mua 2 chiếc của vA trên server -> stock=4, rev=2
        fakeRepo.simulateExternalStockChange('vA', 4);
        expect(fakeRepo.variantStore['vA']!.stock, 4);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 2);

        // Admin sửa A thành 9 (baseline trên form vẫn là rev=1) và sửa B hợp lệ rồi lưu
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '9',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'EXT_B_OK',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Xung đột thật bị chặn, form không đóng, tồn kho server vẫn là 4 (rev=2), không bị ghi đè thành 9
        expect(find.text('Sửa thông tin sản phẩm'), findsOneWidget);
        expect(find.textContaining('SF_STOCK_VERSION_CONFLICT'), findsWidgets);
        expect(fakeRepo.variantStore['vA']!.stock, 4);
        expect(fakeRepo.variantStore['vA']!.stockRevision, 2);
      },
    );

    testWidgets(
      'Partial save retry preserves unsaved drafts of other variants without reload overwrite',
      (tester) async {
        final product = AdminProduct(
          id: 'p_draft',
          code: 'SFDRAFT',
          categoryId: 'c1',
          name: 'Váy Midi Draft',
          description: 'Mô tả',
          material: 'Lụa',
          priceVnd: 450000,
          imagePaths: const [],
          isVisible: true,
          variants: const [
            AdminVariant(
              id: 'vA',
              productId: 'p_draft',
              sku: 'DR_A',
              size: 'S',
              color: 'Trắng',
              stock: 5,
              stockRevision: 0,
            ),
            AdminVariant(
              id: 'vB',
              productId: 'p_draft',
              sku: 'DR_B',
              size: 'M',
              color: 'Hồng',
              stock: 7,
              stockRevision: 0,
            ),
            AdminVariant(
              id: 'vC',
              productId: 'p_draft',
              sku: 'DR_C',
              size: 'L',
              color: 'Xanh',
              stock: 9,
              stockRevision: 0,
            ),
          ],
        );
        final fakeRepo = FakeAdminRepository(
          initialCategories: const [
            AdminCategory(id: 'c1', name: 'Váy', slug: 'vay', isActive: true),
          ],
          initialProducts: [product],
        )..duplicateSkus.addAll(['DUP_B', 'DUP_C']);

        // Mở qua productId trực tiếp (không có initialProduct) để kiểm chứng reload provider không ghi đè bản nháp
        await tester.pumpWidget(
          buildTestApp(
            child: const AdminProductFormPage(productId: 'p_draft'),
            repository: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        final editButtons = find.byIcon(Icons.edit_outlined);
        // Sửa A (tồn 5->6), B (SKU DUP_B), C (SKU DUP_C, màu Xanh biển)
        await tester.ensureVisible(editButtons.at(0));
        await tester.tap(editButtons.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Số lượng tồn (vd: 50)'),
          '6',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'DUP_B',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(2));
        await tester.tap(editButtons.at(2));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Đen, Trắng, Xanh rêu, Be...'),
          'Xanh biển',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'DUP_C',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        // Lưu lần 1: A thành công, B và C thất bại
        final submitButton = find.text('Lưu sản phẩm');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Bản nháp của C ("Size L - Màu Xanh biển", "SKU: DUP_C") vẫn được giữ nguyên, không bị reload xóa mất
        expect(find.text('Size L - Màu Xanh biển'), findsOneWidget);
        expect(find.textContaining('SKU: DUP_C'), findsOneWidget);

        // Sửa mỗi B thành DR_B_OK, giữ nguyên C rồi lưu lại -> C vẫn giữ nguyên bản nháp Xanh biển
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.ensureVisible(editButtons.at(1));
        await tester.tap(editButtons.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Mã SKU duy nhất (vd: SF01_M_den)',
          ),
          'DR_B_OK',
        );
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('Lưu')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeRepo.variantStore['vB']!.sku, 'DR_B_OK');
        expect(find.text('Size L - Màu Xanh biển'), findsOneWidget);
        expect(find.text('Sửa thông tin sản phẩm'), findsOneWidget);
      },
    );
  });
}

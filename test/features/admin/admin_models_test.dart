import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/admin/domain/admin_models.dart';
import 'package:smart_fashion/features/auth/domain/user_role.dart';

void main() {
  group('UserRole', () {
    test('fromString parses admin and customer correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString(null), UserRole.customer);
      expect(UserRole.fromString('unknown'), UserRole.customer);
    });
  });

  group('AdminValidation', () {
    test('validateCategoryName rejects empty or too long names', () {
      expect(AdminValidation.validateCategoryName(''), isNotNull);
      expect(AdminValidation.validateCategoryName('   '), isNotNull);
      expect(AdminValidation.validateCategoryName(null), isNotNull);
      expect(AdminValidation.validateCategoryName('A' * 81), isNotNull);
      expect(AdminValidation.validateCategoryName('Áo sơ mi'), isNull);
    });

    test('validateCategorySlug requires lowercase, numbers and hyphens', () {
      expect(AdminValidation.validateCategorySlug(''), isNotNull);
      expect(AdminValidation.validateCategorySlug('Áo Sơ Mi'), isNotNull);
      expect(AdminValidation.validateCategorySlug('ao_so_mi'), isNotNull);
      expect(AdminValidation.validateCategorySlug('ao--so-mi'), isNotNull);
      expect(AdminValidation.validateCategorySlug('ao-so-mi'), isNull);
      expect(AdminValidation.validateCategorySlug('quan-jeans-2026'), isNull);
    });

    test('validateProductCode rejects empty or over 40 chars', () {
      expect(AdminValidation.validateProductCode(''), isNotNull);
      expect(AdminValidation.validateProductCode('   '), isNotNull);
      expect(AdminValidation.validateProductCode('SF' * 21), isNotNull);
      expect(AdminValidation.validateProductCode('SF01'), isNull);
    });

    test('validateProductName rejects empty or over 160 chars', () {
      expect(AdminValidation.validateProductName(''), isNotNull);
      expect(AdminValidation.validateProductName('A' * 161), isNotNull);
      expect(AdminValidation.validateProductName('Áo Polo Phối Bo Cổ'), isNull);
    });

    test(
      'validatePrice accepts positive integers and rejects zero or negative',
      () {
        expect(AdminValidation.validatePrice(''), isNotNull);
        expect(AdminValidation.validatePrice('0'), isNotNull);
        expect(AdminValidation.validatePrice('-1000'), isNotNull);
        expect(AdminValidation.validatePrice('abc'), isNotNull);
        expect(AdminValidation.validatePrice('199000'), isNull);
        expect(AdminValidation.validatePrice('199.000'), isNull);
      },
    );

    test('validateVariant fields', () {
      expect(AdminValidation.validateVariantSku(''), isNotNull);
      expect(AdminValidation.validateVariantSku('SKU_01'), isNull);

      expect(AdminValidation.validateVariantSize(''), isNotNull);
      expect(AdminValidation.validateVariantSize('XL'), isNull);

      expect(AdminValidation.validateVariantColor(''), isNotNull);
      expect(AdminValidation.validateVariantColor('Xanh rêu'), isNull);

      expect(AdminValidation.validateVariantStock(''), isNotNull);
      expect(AdminValidation.validateVariantStock('-1'), isNotNull);
      expect(AdminValidation.validateVariantStock('0'), isNull);
      expect(AdminValidation.validateVariantStock('50'), isNull);
    });
  });

  group('AdminProduct & AdminCategory models', () {
    test('AdminCategory copyWith updates fields', () {
      const cat = AdminCategory(
        id: 'cat_1',
        name: 'Áo',
        slug: 'ao',
        isActive: true,
      );
      final updated = cat.copyWith(name: 'Áo Nam', isActive: false);
      expect(updated.id, 'cat_1');
      expect(updated.name, 'Áo Nam');
      expect(updated.slug, 'ao');
      expect(updated.isActive, false);
    });

    test('AdminProduct totalStock calculates sum of variant stocks', () {
      final product = AdminProduct(
        id: 'p1',
        code: 'SF01',
        categoryId: 'cat_1',
        name: 'Áo Sơ Mi',
        description: 'Mô tả',
        material: 'Linen',
        priceVnd: 199000,
        imagePaths: ['img1.png'],
        isVisible: true,
        variants: const [
          AdminVariant(
            id: 'v1',
            productId: 'p1',
            sku: 'SF01_M',
            size: 'M',
            color: 'Trắng',
            stock: 20,
          ),
          AdminVariant(
            id: 'v2',
            productId: 'p1',
            sku: 'SF01_L',
            size: 'L',
            color: 'Trắng',
            stock: 35,
          ),
        ],
      );

      expect(product.totalStock, 55);
    });

    test('AdminVariant copyWith updates stockRevision and other fields', () {
      const variant = AdminVariant(
        id: 'v1',
        productId: 'p1',
        sku: 'SKU_01',
        size: 'M',
        color: 'Đen',
        stock: 10,
        stockRevision: 2,
      );
      final updated = variant.copyWith(
        stock: 15,
        stockRevision: 3,
        color: 'Trắng',
      );
      expect(updated.stock, 15);
      expect(updated.stockRevision, 3);
      expect(updated.color, 'Trắng');
      expect(updated.sku, 'SKU_01');
    });

    test('AdminStockConflictFailure stores conflict metadata', () {
      const failure = AdminStockConflictFailure(
        'Xung đột phiên bản',
        variantId: 'v123',
        currentStock: 5,
        currentRevision: 4,
      );
      expect(failure.message, 'Xung đột phiên bản');
      expect(failure.variantId, 'v123');
      expect(failure.currentStock, 5);
      expect(failure.currentRevision, 4);
    });

    test('stock concurrency: stale revision rejected when order changes revision', () {
      // Mô phỏng: Ban đầu biến thể có stock = 20, revision = 1
      var remoteVariant = const AdminVariant(
        id: 'v_sync',
        productId: 'p1',
        sku: 'SF01_L',
        size: 'L',
        color: 'Đen',
        stock: 20,
        stockRevision: 1,
      );

      // Admin mở form đọc dữ liệu tại thời điểm revision = 1
      final adminSnapshotRevision = remoteVariant.stockRevision;

      // Khách hàng đặt đơn hàng hoặc hủy đơn làm tồn kho và revision thay đổi trên server
      // (Checkout COD trừ 2 sản phẩm, revision tăng lên 2)
      remoteVariant = remoteVariant.copyWith(
        stock: 18,
        stockRevision: remoteVariant.stockRevision + 1,
      );

      // Hàm giả lập RPC set_variant_stock kiểm tra revision
      void setVariantStockRPC({
        required String variantId,
        required int expectedRevision,
        required int newStock,
      }) {
        if (expectedRevision != remoteVariant.stockRevision) {
          throw AdminStockConflictFailure(
            'SF_STOCK_VERSION_CONFLICT: Tồn kho đã bị thay đổi.',
            variantId: variantId,
            currentStock: remoteVariant.stock,
            currentRevision: remoteVariant.stockRevision,
          );
        }
      }

      // Admin gửi yêu cầu cập nhật với revision cũ (1) trong khi server đã là 2
      expect(
        () => setVariantStockRPC(
          variantId: remoteVariant.id,
          expectedRevision: adminSnapshotRevision,
          newStock: 25,
        ),
        throwsA(isA<AdminStockConflictFailure>()),
      );

      // Đảm bảo tồn kho server không bị ghi đè dữ liệu cũ
      expect(remoteVariant.stock, 18);
      expect(remoteVariant.stockRevision, 2);
    });

    test('stock concurrency: stale revision rejected when order changes revision', () {
      // Mô phỏng: Ban đầu biến thể có stock = 20, revision = 1
      var remoteVariant = const AdminVariant(
        id: 'v_sync',
        productId: 'p1',
        sku: 'SF01_L',
        size: 'L',
        color: 'Đen',
        stock: 20,
        stockRevision: 1,
      );

      // Admin mở form đọc dữ liệu tại thời điểm revision = 1
      final adminSnapshotRevision = remoteVariant.stockRevision;

      // Khách hàng đặt đơn hàng hoặc hủy đơn làm tồn kho và revision thay đổi trên server
      // (Checkout COD trừ 2 sản phẩm, revision tăng lên 2)
      remoteVariant = remoteVariant.copyWith(
        stock: 18,
        stockRevision: remoteVariant.stockRevision + 1,
      );

      // Hàm giả lập RPC set_variant_stock kiểm tra revision
      void setVariantStockRPC({
        required String variantId,
        required int expectedRevision,
        required int newStock,
      }) {
        if (expectedRevision != remoteVariant.stockRevision) {
          throw AdminStockConflictFailure(
            'SF_STOCK_VERSION_CONFLICT: Tồn kho đã bị thay đổi.',
            variantId: variantId,
            currentStock: remoteVariant.stock,
            currentRevision: remoteVariant.stockRevision,
          );
        }
      }

      // Admin gửi yêu cầu cập nhật với revision cũ (1) trong khi server đã là 2
      expect(
        () => setVariantStockRPC(
          variantId: remoteVariant.id,
          expectedRevision: adminSnapshotRevision,
          newStock: 25,
        ),
        throwsA(isA<AdminStockConflictFailure>()),
      );

      // Đảm bảo tồn kho server không bị ghi đè dữ liệu cũ
      expect(remoteVariant.stock, 18);
      expect(remoteVariant.stockRevision, 2);
    });
  });
}

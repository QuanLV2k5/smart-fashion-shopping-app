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
  });
}

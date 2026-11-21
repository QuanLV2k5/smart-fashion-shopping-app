/// Model nghiệp vụ quản trị danh mục, sản phẩm và biến thể cho Admin.
class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminCategory copyWith({
    String? id,
    String? name,
    String? slug,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdminVariant {
  const AdminVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.size,
    required this.color,
    required this.stock,
  });

  final String id;
  final String productId;
  final String sku;
  final String size;
  final String color;
  final int stock;

  AdminVariant copyWith({
    String? id,
    String? productId,
    String? sku,
    String? size,
    String? color,
    int? stock,
  }) {
    return AdminVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      size: size ?? this.size,
      color: color ?? this.color,
      stock: stock ?? this.stock,
    );
  }
}

class AdminProduct {
  AdminProduct({
    required this.id,
    required this.code,
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    required this.description,
    required this.material,
    required this.priceVnd,
    required List<String> imagePaths,
    required this.isVisible,
    required List<AdminVariant> variants,
    this.createdAt,
    this.updatedAt,
  }) : imagePaths = List.unmodifiable(imagePaths),
       variants = List.unmodifiable(variants);

  final String id;
  final String code;
  final String categoryId;
  final String categoryName;
  final String name;
  final String description;
  final String material;
  final int priceVnd;
  final List<String> imagePaths;
  final bool isVisible;
  final List<AdminVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  AdminProduct copyWith({
    String? id,
    String? code,
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    String? material,
    int? priceVnd,
    List<String>? imagePaths,
    bool? isVisible,
    List<AdminVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      code: code ?? this.code,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      material: material ?? this.material,
      priceVnd: priceVnd ?? this.priceVnd,
      imagePaths: imagePaths ?? this.imagePaths,
      isVisible: isVisible ?? this.isVisible,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminValidation {
  static final RegExp _slugRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  static String? validateCategoryName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Tên danh mục không được để trống';
    }
    final trimmed = name.trim();
    if (trimmed.length > 80) {
      return 'Tên danh mục tối đa 80 ký tự';
    }
    return null;
  }

  static String? validateCategorySlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) {
      return 'Slug không được để trống';
    }
    final trimmed = slug.trim();
    if (!_slugRegex.hasMatch(trimmed)) {
      return 'Slug chỉ gồm chữ thường không dấu, số và dấu gạch nối (vd: ao-so-mi)';
    }
    return null;
  }

  static String? validateProductCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return 'Mã sản phẩm không được để trống';
    }
    final trimmed = code.trim();
    if (trimmed.length > 40) {
      return 'Mã sản phẩm tối đa 40 ký tự';
    }
    return null;
  }

  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Tên sản phẩm không được để trống';
    }
    final trimmed = name.trim();
    if (trimmed.length > 160) {
      return 'Tên sản phẩm tối đa 160 ký tự';
    }
    return null;
  }

  static String? validatePrice(String? priceStr) {
    if (priceStr == null || priceStr.trim().isEmpty) {
      return 'Giá sản phẩm không được để trống';
    }
    final sanitized = priceStr.replaceAll('.', '').replaceAll(',', '').trim();
    final value = int.tryParse(sanitized);
    if (value == null || value <= 0) {
      return 'Giá sản phẩm phải là số nguyên dương lớn hơn 0';
    }
    return null;
  }

  static String? validateVariantSku(String? sku) {
    if (sku == null || sku.trim().isEmpty) {
      return 'SKU biến thể không được để trống';
    }
    final trimmed = sku.trim();
    if (trimmed.length > 80) {
      return 'SKU tối đa 80 ký tự';
    }
    return null;
  }

  static String? validateVariantSize(String? size) {
    if (size == null || size.trim().isEmpty) {
      return 'Kích cỡ (size) không được để trống';
    }
    if (size.trim().length > 30) {
      return 'Kích cỡ tối đa 30 ký tự';
    }
    return null;
  }

  static String? validateVariantColor(String? color) {
    if (color == null || color.trim().isEmpty) {
      return 'Màu sắc không được để trống';
    }
    if (color.trim().length > 50) {
      return 'Màu sắc tối đa 50 ký tự';
    }
    return null;
  }

  static String? validateVariantStock(String? stockStr) {
    if (stockStr == null || stockStr.trim().isEmpty) {
      return 'Số lượng tồn kho không được để trống';
    }
    final value = int.tryParse(stockStr.trim());
    if (value == null || value < 0) {
      return 'Tồn kho phải là số nguyên không âm (>= 0)';
    }
    return null;
  }
}

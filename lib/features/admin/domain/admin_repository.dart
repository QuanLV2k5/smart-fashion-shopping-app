import 'admin_models.dart';

abstract interface class AdminRepository {
  /// Lấy danh sách toàn bộ danh mục (bao gồm cả danh mục tạm ẩn).
  Future<List<AdminCategory>> fetchCategories();

  /// Thêm mới hoặc cập nhật danh mục.
  Future<void> saveCategory({
    String? id,
    required String name,
    required String slug,
    required bool isActive,
  });

  /// Lấy danh sách toàn bộ sản phẩm (kèm biến thể và trạng thái ẩn/hiện).
  Future<List<AdminProduct>> fetchProducts({
    String? categoryId,
    String? searchQuery,
  });

  /// Lấy chi tiết một sản phẩm theo ID để chỉnh sửa.
  Future<AdminProduct?> fetchProductById(String id);

  /// Thêm mới hoặc cập nhật sản phẩm. Trả về ID của sản phẩm.
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
  });

  /// Bật/tắt trạng thái hiển thị của sản phẩm (is_visible).
  Future<void> toggleProductVisibility(String id, bool isVisible);

  /// Thêm hoặc cập nhật biến thể (size, color, stock, sku).
  /// Trả về [AdminVariant] đã được server xác nhận (bao gồm id, stock và stockRevision thực tế).
  /// [updateMetadata] = false khi chỉ điều chỉnh tồn kho.
  /// [updateStock] = false khi chỉ sửa metadata để tránh xung đột tồn kho với đơn hàng.
  /// [expectedStockRevision] kiểm tra phiên bản tồn khi gọi RPC set_variant_stock.
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
  });

  /// Ngừng bán / đặt tồn kho biến thể về 0 (để bảo toàn lịch sử đơn hàng, không DELETE cứng).
  Future<void> deleteVariant(String variantId, {int expectedStockRevision = 0});

  /// Tải ảnh sản phẩm lên bucket Storage 'product-images'. Trả về storage path.
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });
}

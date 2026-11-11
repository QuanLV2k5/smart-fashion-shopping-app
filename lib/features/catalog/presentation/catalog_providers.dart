import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../data/supabase_catalog_repository.dart';
import '../domain/catalog.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => SupabaseCatalogRepository(ref.watch(supabaseClientProvider)),
);

/// Dùng chung kết quả giữa Trang chủ và Khám phá. Kéo xuống để tải lại từ server.
final catalogProvider = FutureProvider<CatalogSnapshot>(
  (ref) => ref.watch(catalogRepositoryProvider).loadCatalog(),
  retry: (_, _) => null,
);

/// Chi tiết đọc lại server, không dùng tồn kho cũ của màn danh sách để quyết định mua.
final productProvider = FutureProvider.autoDispose
    .family<CatalogProduct?, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).loadProduct(id),
      retry: (_, _) => null,
    );

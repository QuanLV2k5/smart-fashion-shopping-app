import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../catalog/domain/catalog.dart';
import '../domain/ai_outfit.dart';

class SupabaseAiRepository implements AiRepository {
  const SupabaseAiRepository(this.client, this.catalog);
  final SupabaseClient? client;
  final CatalogRepository catalog;
  @override
  Future<AiOutfit> recommend(AiRequest request) async {
    final c = client;
    if (c == null) throw const AiFailure('Tư vấn AI chưa được cấu hình.');
    final user = c.auth.currentUser?.id;
    if (user == null) {
      throw const AiFailure('Vui lòng đăng nhập để nhận tư vấn.');
    }
    try {
      final res = await c.functions
          .invoke('ai-outfits', body: request.toJson())
          .timeout(const Duration(seconds: 75));
      if (c.auth.currentUser?.id != user) {
        throw const AiFailure('Phiên đăng nhập đã thay đổi.');
      }
      if (res.status != 200) {
        throw AiFailure(messageForCode((res.data as Map?)?['code']));
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['provider'] != 'gemini' ||
          data['products'] is! List ||
          data['explanation'] is! String) {
        throw const FormatException();
      }
      final ids = (data['products'] as List)
          .map((p) => (p as Map)['id'] as String)
          .toList();
      if (ids.length == 1 ||
          ids.length > 4 ||
          ids.toSet().length != ids.length ||
          ids.any(request.excludeIds.contains) ||
          (ids.isNotEmpty && request.keepIds.any((id) => !ids.contains(id)))) {
        throw const FormatException();
      }
      final snapshot = ids.isEmpty ? null : await catalog.loadCatalog();
      final products = ids
          .map((id) => snapshot!.products.firstWhere((p) => p.id == id))
          .toList();
      final outfit = AiOutfit(
        products: products,
        explanation: data['explanation'] as String,
      );
      if (products.any((p) => !p.inStock) || outfit.totalVnd > request.budget) {
        throw const AiFailure(
          'Sản phẩm vừa thay đổi giá hoặc tồn kho. Hãy tư vấn lại.',
        );
      }
      if (c.auth.currentUser?.id != user) {
        throw const AiFailure('Phiên đăng nhập đã thay đổi.');
      }
      return outfit;
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure('Tư vấn quá thời gian. Bạn hãy thử lại.');
    } on FunctionException catch (e) {
      throw AiFailure(
        messageForCode(e.details is Map ? (e.details as Map)['code'] : null),
      );
    } on FormatException {
      throw const AiFailure('Chưa nhận được bộ đồ hợp lệ. Bạn hãy thử lại.');
    } on StateError {
      throw const AiFailure('Sản phẩm vừa ngừng bán. Bạn hãy tư vấn lại.');
    } catch (_) {
      throw const AiFailure(
        'Chưa kết nối được dịch vụ. Kiểm tra mạng rồi thử lại.',
      );
    }
  }

  static String messageForCode(Object? code) => switch (code) {
    'UNAUTHORIZED' => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
    'AI_NOT_CONFIGURED' =>
      'Dịch vụ tư vấn chưa sẵn sàng. Vui lòng thử lại sau.',
    'AI_KEY_REJECTED' =>
      'Dịch vụ tư vấn chưa xác thực được với Gemini. Vui lòng thử lại sau.',
    'AI_MODEL_UNAVAILABLE' || 'AI_PROVIDER_REJECTED' =>
      'Cấu hình dịch vụ tư vấn cần được kiểm tra. Vui lòng thử lại sau.',
    'CATALOG_UNAVAILABLE' =>
      'Chưa đọc được sản phẩm để tư vấn. Vui lòng thử lại.',
    'AI_QUOTA' || 'RATE_LIMITED' =>
      'Đã tới giới hạn tư vấn. Vui lòng chờ một lát rồi thử lại.',
    'AI_TIMEOUT' => 'Tư vấn quá thời gian. Bạn hãy thử lại.',
    'INVALID_AI_RESPONSE' =>
      'Chưa tìm được kết quả hợp lệ. Bạn hãy thử điều chỉnh nhu cầu.',
    _ => 'Dịch vụ đang bận. Kiểm tra kết nối rồi thử lại.',
  };
}

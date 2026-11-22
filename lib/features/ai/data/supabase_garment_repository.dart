import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ai_outfit.dart';
import '../domain/owned_garment.dart';
import 'supabase_ai_repository.dart';

class SupabaseGarmentRepository implements GarmentRepository {
  const SupabaseGarmentRepository(this.client);
  final SupabaseClient? client;
  @override
  Future<OwnedGarment> analyze(GarmentPhoto photo) async {
    final c = client;
    if (c == null) throw const AiFailure('Dịch vụ AI chưa được cấu hình.');
    final user = c.auth.currentUser?.id;
    if (user == null) {
      throw const AiFailure('Vui lòng đăng nhập để phân tích ảnh.');
    }
    try {
      final res = await c.functions
          .invoke(
            'ai-outfits',
            body: {
              'action': 'analyze',
              'image': {
                'mimeType': photo.mimeType,
                'data': base64Encode(photo.bytes),
              },
            },
          )
          .timeout(const Duration(seconds: 75));
      if (c.auth.currentUser?.id != user) {
        throw const AiFailure('Phiên đăng nhập đã thay đổi.');
      }
      if (res.status != 200) {
        throw AiFailure(
          SupabaseAiRepository.messageForCode((res.data as Map?)?['code']),
        );
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['provider'] != 'gemini' || data['apiVersion'] != 2) {
        throw const AiFailure(
          'Phân tích ảnh chưa sẵn sàng. Hãy cập nhật dịch vụ rồi thử lại.',
        );
      }
      switch (data['status']) {
        case 'no_garment':
          throw const AiFailure(
            'Chưa thấy quần áo hoặc phụ kiện trong ảnh. Hãy chọn ảnh món đồ.',
          );
        case 'multiple_garments':
          throw const AiFailure(
            'Ảnh có nhiều món đồ. Hãy chụp riêng một món bạn muốn phối.',
          );
        case 'unclear':
          throw const AiFailure(
            'Ảnh chưa đủ rõ. Hãy chụp gần hơn ở nơi đủ sáng.',
          );
        case 'ok':
          return OwnedGarment.fromJson(
            Map<String, dynamic>.from(data['garment'] as Map),
          );
        default:
          throw const FormatException();
      }
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure('Phân tích ảnh quá thời gian. Bạn hãy thử lại.');
    } on FunctionException catch (e) {
      throw AiFailure(
        SupabaseAiRepository.messageForCode(
          e.details is Map ? (e.details as Map)['code'] : null,
        ),
      );
    } on FormatException {
      throw const AiFailure(
        'Chưa nhận diện được món đồ hợp lệ. Hãy chọn ảnh rõ hơn.',
      );
    } on StateError {
      throw const AiFailure(
        'Chưa xác định được loại món đồ. Hãy thử ảnh khác.',
      );
    } catch (_) {
      throw const AiFailure(
        'Chưa kết nối được dịch vụ. Kiểm tra mạng rồi thử lại.',
      );
    }
  }
}

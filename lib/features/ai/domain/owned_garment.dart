import 'dart:typed_data';

import 'ai_outfit.dart';

enum GarmentCategory {
  top('Áo'),
  bottom('Quần / chân váy'),
  dress('Đầm / váy liền'),
  outerwear('Áo khoác'),
  shoes('Giày / dép'),
  bag('Túi / balo'),
  accessory('Mũ / phụ kiện');

  const GarmentCategory(this.label);
  final String label;
}

class OwnedGarment {
  const OwnedGarment({
    required this.category,
    required this.name,
    required this.color,
    required this.pattern,
    required this.fit,
    required this.details,
  });
  final GarmentCategory category;
  final String name, color, pattern, fit, details;

  factory OwnedGarment.fromJson(Map<String, dynamic> data) {
    String field(String key, int max) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty || value.length > max) {
        throw const FormatException('Invalid garment');
      }
      return value.trim();
    }

    return OwnedGarment(
      category: GarmentCategory.values.firstWhere(
        (v) => v.name == data['category'],
      ),
      name: field('name', 80),
      color: field('color', 40),
      pattern: field('pattern', 50),
      fit: field('fit', 50),
      details: field('details', 220),
    );
  }
  Map<String, dynamic> toJson() => {
    'category': category.name,
    'name': name,
    'color': color,
    'pattern': pattern,
    'fit': fit,
    'details': details,
  };
}

class GarmentPhoto {
  GarmentPhoto._(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
  static const maxBytes = 2 * 1024 * 1024;
  factory GarmentPhoto.fromBytes(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const AiFailure(
        'Ảnh lớn hơn 2 MB. Hãy chọn ảnh nhỏ hơn hoặc chụp lại.',
      );
    }
    if (bytes.length < 32) throw const AiFailure('File ảnh không hợp lệ.');
    final png = [137, 80, 78, 71, 13, 10, 26, 10];
    final type = bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255
        ? 'image/jpeg'
        : List.generate(8, (i) => bytes[i] == png[i]).every((v) => v)
        ? 'image/png'
        : String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
              String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP'
        ? 'image/webp'
        : null;
    if (type == null) {
      throw const AiFailure(
        'Chọn ảnh JPG, PNG hoặc WebP. Ảnh HEIC cần đổi sang JPG.',
      );
    }
    return GarmentPhoto._(Uint8List.fromList(bytes), type);
  }
}

abstract interface class GarmentRepository {
  Future<OwnedGarment> analyze(GarmentPhoto photo);
}

abstract interface class GarmentPhotoPicker {
  Future<GarmentPhoto?> pick({required bool camera});
  Future<GarmentPhoto?> recover();
}

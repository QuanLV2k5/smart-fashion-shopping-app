import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/ai_outfit.dart';
import '../domain/owned_garment.dart';

class DeviceGarmentPhotoPicker implements GarmentPhotoPicker {
  final ImagePicker picker = ImagePicker();
  Future<GarmentPhoto> _read(XFile file) async {
    if (await file.length() > GarmentPhoto.maxBytes) {
      throw const AiFailure(
        'Ảnh lớn hơn 2 MB. Hãy chọn ảnh nhỏ hơn hoặc chụp lại.',
      );
    }
    return GarmentPhoto.fromBytes(await file.readAsBytes());
  }

  @override
  Future<GarmentPhoto?> pick({required bool camera}) async {
    final file = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<GarmentPhoto?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await picker.retrieveLostData();
    if (response.exception != null) {
      throw const AiFailure('Chưa khôi phục được ảnh. Bạn hãy chọn ảnh lại.');
    }
    final files = response.files;
    return files == null || files.isEmpty ? null : _read(files.first);
  }
}

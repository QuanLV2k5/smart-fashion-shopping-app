import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu thiết lập/snapshot nhỏ, không dùng để xác nhận một đơn hàng đã được tạo.
final preferencesProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

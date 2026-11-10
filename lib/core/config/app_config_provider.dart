import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

// Điểm lấy cấu hình dùng chung; main.dart và test có thể truyền giá trị vào.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

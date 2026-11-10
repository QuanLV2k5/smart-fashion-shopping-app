import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';

Future<void> main() async {
  // Chuẩn bị Flutter trước khi gọi các plugin bất đồng bộ.
  WidgetsFlutterBinding.ensureInitialized();
  // Cấu hình được truyền lúc build/run bằng --dart-define-from-file.
  final config = AppConfig.fromEnvironment();
  config.validate();
  // Chạy UI local không cần kết nối cloud. Chỉ khởi tạo khi đã bật backend.
  if (config.useSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  runApp(
    ProviderScope(
      // Các màn dùng cùng cấu hình đã kiểm tra ở trên thông qua Riverpod.
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const SmartFashionApp(),
    ),
  );
}

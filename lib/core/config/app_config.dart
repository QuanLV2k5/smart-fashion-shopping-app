import 'development_backend.dart';

/// Cấu hình client được truyền khi build/run, không phải nơi giữ khóa bí mật.
class AppConfig {
  const AppConfig({
    this.environment = 'development',
    this.useSupabase = false,
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
  });

  factory AppConfig.fromEnvironment() => AppConfig.forEnvironment(
    environment: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    ),
    useSupabase: const bool.fromEnvironment('USE_SUPABASE', defaultValue: true),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  );

  /// Build/run bình thường dùng backend dev, tránh APK có form nhưng Auth bị tắt.
  /// Chỉ dùng mặc định khi CẢ URL và key đều trống, không trộn hai project.
  factory AppConfig.forEnvironment({
    String environment = 'development',
    bool useSupabase = true,
    String supabaseUrl = '',
    String supabasePublishableKey = '',
  }) {
    final useDevelopmentDefaults =
        environment == 'development' &&
        useSupabase &&
        supabaseUrl.isEmpty &&
        supabasePublishableKey.isEmpty;
    return AppConfig(
      environment: environment,
      useSupabase: useSupabase,
      supabaseUrl: useDevelopmentDefaults
          ? DevelopmentBackend.url
          : supabaseUrl,
      supabasePublishableKey: useDevelopmentDefaults
          ? DevelopmentBackend.publishableKey
          : supabasePublishableKey,
    );
  }

  final String environment;
  final bool useSupabase;
  final String supabaseUrl;
  final String supabasePublishableKey;

  void validate() {
    if (!{'development', 'staging', 'production'}.contains(environment)) {
      throw const FormatException('APP_ENV không hợp lệ.');
    }
    if (!useSupabase) {
      if (environment != 'development') {
        throw const FormatException(
          'Staging/production cần USE_SUPABASE=true.',
        );
      }
      return;
    }
    final uri = Uri.tryParse(supabaseUrl);
    final isLocal =
        uri != null &&
        {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !(uri.scheme == 'https' ||
            (environment == 'development' &&
                isLocal &&
                uri.scheme == 'http'))) {
      throw const FormatException('Cần SUPABASE_URL hợp lệ.');
    }
    if (supabasePublishableKey.trim().isEmpty ||
        supabasePublishableKey.startsWith('sb_secret_')) {
      throw const FormatException(
        'Cần Supabase publishable key dành cho client.',
      );
    }
  }
}

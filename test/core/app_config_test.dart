import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/core/config/app_config.dart';

void main() {
  test('build phát triển không truyền flag vẫn có backend thật', () {
    final config = AppConfig.forEnvironment();
    expect(config.useSupabase, isTrue);
    expect(config.supabaseUrl, 'https://xvpdkbzdyevjbvvfeksc.supabase.co');
    expect(config.supabasePublishableKey, startsWith('sb_publishable_'));
    expect(config.validate, returnsNormally);
  });

  test('offline là lựa chọn tường minh', () {
    final config = AppConfig.forEnvironment(useSupabase: false);
    expect(config.useSupabase, isFalse);
    expect(config.supabaseUrl, isEmpty);
    expect(config.validate, returnsNormally);
  });

  test('không trộn URL/key của hai project', () {
    for (final config in [
      AppConfig.forEnvironment(supabaseUrl: 'https://other.supabase.co'),
      AppConfig.forEnvironment(supabasePublishableKey: 'sb_publishable_other'),
    ]) {
      expect(config.validate, throwsFormatException);
    }
  });

  test('staging/production không tự rơi về project dev', () {
    for (final env in ['staging', 'production']) {
      final config = AppConfig.forEnvironment(environment: env);
      expect(config.supabaseUrl, isEmpty);
      expect(config.validate, throwsFormatException);
    }
  });

  test('local UI boots without backend credentials', () {
    expect(const AppConfig().validate, returnsNormally);
  });

  test('live backend requires a URL and a client key', () {
    expect(const AppConfig(useSupabase: true).validate, throwsFormatException);
    expect(
      const AppConfig(
        useSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
      ).validate,
      throwsFormatException,
    );
  });

  test('staging cannot silently start without its backend', () {
    expect(
      const AppConfig(environment: 'staging').validate,
      throwsFormatException,
    );
  });

  test('production rejects remote HTTP and secret keys', () {
    for (final config in [
      const AppConfig(
        environment: 'production',
        useSupabase: true,
        supabaseUrl: 'http://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_demo',
      ),
      const AppConfig(
        environment: 'production',
        useSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_secret_demo',
      ),
    ]) {
      expect(config.validate, throwsFormatException);
    }
  });

  test('local backend supports Android emulator loopback', () {
    expect(
      const AppConfig(
        useSupabase: true,
        supabaseUrl: 'http://10.0.2.2:54321',
        supabasePublishableKey: 'sb_publishable_demo',
      ).validate,
      returnsNormally,
    );
  });
}

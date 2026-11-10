/// Cấu hình CÔNG KHAI dành cho client của project phát triển Smart Fashion.
/// Publishable key không phải secret/service-role; dữ liệu được bảo vệ bằng RLS.
/// Staging/production phải truyền cấu hình riêng, không dùng mặc định này.
abstract final class DevelopmentBackend {
  static const url = 'https://xvpdkbzdyevjbvvfeksc.supabase.co';
  static const publishableKey =
      'sb_publishable_mkSjrrQdTJZxFDl3JldZWA_PGTwc2LH';
}

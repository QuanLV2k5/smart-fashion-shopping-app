import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config_provider.dart';

/// Trả null khi đang làm UI local. Repository cần xử lý rõ khi chưa có backend.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!ref.watch(appConfigProvider).useSupabase) return null;
  return Supabase.instance.client;
});

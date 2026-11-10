import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

const androidAuthRedirect = 'vn.edu.vku.smartfashion://auth-callback/';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    ref.watch(supabaseClientProvider),
    emailRedirectTo: kIsWeb ? '${Uri.base.origin}/' : androidAuthRedirect,
  );
});

/// SDK khôi phục phiên lúc khởi động và phát sự kiện đăng nhập/đăng xuất.
final authSessionProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

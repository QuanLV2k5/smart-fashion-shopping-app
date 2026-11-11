import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/presentation/home_page.dart';
import '../../features/catalog/presentation/explore_page.dart';
import '../../features/catalog/presentation/product_page.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/auth/presentation/account_page.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/confirm_email_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import 'auth_redirect.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  // Phiên thay đổi thì chạy lại redirect, không tạo router mới/mất lịch sử.
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user =
          ref.read(authSessionProvider).value ??
          ref.read(authRepositoryProvider).currentUser;
      final path = state.matchedLocation;
      final protected = path == '/account' || path == '/logout';
      final authForm = const {
        '/login',
        '/register',
        '/confirm-email',
      }.contains(path);
      if (user == null && protected) {
        return '/login?next=${Uri.encodeComponent('/account')}';
      }
      if (user != null && authForm) {
        return authDestination(state.uri.queryParameters['next']);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          destination: authDestination(state.uri.queryParameters['next']),
          initialEmail: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(
          destination: authDestination(state.uri.queryParameters['next']),
          initialEmail: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: '/confirm-email',
        builder: (context, state) => ConfirmEmailPage(
          details: state.extra is ConfirmationDetails
              ? state.extra! as ConfirmationDetails
              : null,
        ),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(path: '/logout', builder: (context, state) => const LogoutPage()),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => ExplorePage(
          key: ValueKey(state.uri.toString()),
          categoryId: state.uri.queryParameters['category'],
          weekendCollection:
              state.uri.queryParameters['collection'] == 'weekend',
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductPage(
          key: ValueKey(state.uri.toString()),
          productId: state.pathParameters['id']!,
          initialVariantId: state.uri.queryParameters['variant'],
        ),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Quay lại Smart Fashion'),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

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
import '../../features/profile/presentation/profile_page.dart';
import 'auth_redirect.dart';
import '../../features/ai/presentation/ai_page.dart';
import '../../features/ai/presentation/photo_outfit_page.dart';
import '../../features/addresses/presentation/addresses_page.dart';
import '../../features/addresses/presentation/address_form_page.dart';
import '../../features/orders/presentation/checkout_page.dart';
import '../../features/orders/presentation/my_orders_page.dart';
import '../../features/orders/presentation/order_detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  // Phiên thay đổi thì chạy lại redirect, không tạo router mới/mất lịch sử.
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authenticatedUserIdProvider);
      final path = state.matchedLocation;
      final protected =
          path == '/ai' ||
          path.startsWith('/ai/') ||
          path == '/account' ||
          path.startsWith('/account/') ||
          path == '/logout' ||
          path == '/checkout' ||
          path == '/addresses' ||
          path.startsWith('/addresses/');
      final authForm = const {
        '/login',
        '/register',
        '/confirm-email',
      }.contains(path);
      if (user == null && protected) {
        final destination =
            path == '/ai' || path == '/ai/photo' || path == '/checkout'
            ? path
            : path == '/addresses/select' ||
                  (path.startsWith('/addresses/') &&
                      state.uri.queryParameters['from'] == 'cart')
            ? '/addresses/select'
            : path.startsWith('/addresses')
            ? '/addresses'
            : path == '/account/profile'
            ? '/account/profile'
            : path == '/account/orders' || path.startsWith('/account/orders/')
            ? '/account/orders'
            : '/account';
        return '/login?next=${Uri.encodeComponent(destination)}';
      }
      if (user != null && authForm) {
        return authDestination(state.uri.queryParameters['next']);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/account/orders',
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: '/account/orders/:orderId',
        builder: (context, state) =>
            OrderDetailPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(path: '/ai', builder: (context, state) => const AiPage()),
      GoRoute(
        path: '/ai/photo',
        builder: (context, state) => const PhotoOutfitPage(),
      ),
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
      GoRoute(
        path: '/account/profile',
        builder: (context, state) => const ProfilePage(),
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
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesPage(),
      ),
      GoRoute(
        path: '/addresses/select',
        builder: (context, state) => const AddressesPage(selecting: true),
      ),
      GoRoute(
        path: '/addresses/new',
        builder: (context, state) => AddressFormPage(
          returnToSelection: state.uri.queryParameters['from'] == 'cart',
        ),
      ),
      GoRoute(
        path: '/addresses/:id/edit',
        builder: (context, state) => AddressFormPage(
          addressId: state.pathParameters['id'],
          returnToSelection: state.uri.queryParameters['from'] == 'cart',
        ),
      ),
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

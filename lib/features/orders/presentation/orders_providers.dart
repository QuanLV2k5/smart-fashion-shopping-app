import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/supabase_orders_repository.dart';
import '../domain/checkout.dart';
import '../domain/orders.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => SupabaseOrdersRepository(ref.watch(supabaseClientProvider)),
);

typedef OrdersQuery = ({String userId, String filter});
typedef OrderKey = ({String userId, String orderId});

final ordersListProvider = FutureProvider.autoDispose
    .family<OrdersResult, OrdersQuery>((ref, query) {
      if (ref.watch(authenticatedUserIdProvider) != query.userId) {
        throw const OrdersFailure('SF_AUTH_REQUIRED');
      }
      return ref
          .watch(ordersRepositoryProvider)
          .list(query.userId, query.filter, null);
    }, retry: (_, _) => null);

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderDetail, OrderKey>((ref, key) {
      if (ref.watch(authenticatedUserIdProvider) != key.userId) {
        throw const OrdersFailure('SF_AUTH_REQUIRED');
      }
      return ref
          .watch(ordersRepositoryProvider)
          .detail(key.userId, key.orderId);
    }, retry: (_, _) => null);

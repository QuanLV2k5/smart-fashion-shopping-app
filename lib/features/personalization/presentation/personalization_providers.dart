import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/supabase_personalization_repository.dart';
import '../domain/personalization.dart';

final personalizationRepositoryProvider = Provider<PersonalizationRepository>(
  (ref) => SupabasePersonalizationRepository(ref.watch(supabaseClientProvider)),
);

final personalizationUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authenticatedUserIdProvider),
);

final accountAccessProvider = FutureProvider.autoDispose<AccountAccess>((ref) {
  final userId = ref.watch(personalizationUserIdProvider);
  // UI-only mode does not claim to have a real backend or admin rights.
  if (userId == null || ref.watch(supabaseClientProvider) == null) {
    return AccountAccess(userId: userId);
  }
  return ref.watch(personalizationRepositoryProvider).access(userId);
}, retry: (_, _) => null);

class FavoritesState {
  const FavoritesState({
    this.entries = const [],
    this.busy = const {},
    this.error,
  });
  final List<FavoriteEntry> entries;
  final Set<String> busy;
  final Object? error;
}

final favoritesProvider =
    AsyncNotifierProvider.family<FavoritesController, FavoritesState, String>(
      FavoritesController.new,
      retry: (_, _) => null,
    );

class FavoritesController extends AsyncNotifier<FavoritesState> {
  FavoritesController(this.userId);
  final String userId;
  int _generation = 0;
  @override
  Future<FavoritesState> build() async {
    final generation = ++_generation;
    if (ref.watch(personalizationUserIdProvider) != userId) {
      return const FavoritesState();
    }
    final entries = await ref
        .watch(personalizationRepositoryProvider)
        .favorites(userId);
    return _active(generation)
        ? FavoritesState(entries: entries)
        : const FavoritesState();
  }

  bool _active(int generation) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(personalizationUserIdProvider) == userId;
  Future<void> setFavorite(String productId, bool selected) async {
    final generation = _generation;
    final current = state.asData?.value;
    if (!_active(generation) || current == null || current.busy.isNotEmpty) {
      return;
    }
    state = AsyncData(
      FavoritesState(entries: current.entries, busy: {productId}),
    );
    try {
      final repository = ref.read(personalizationRepositoryProvider);
      await repository.setFavorite(userId, productId, selected);
      if (!_active(generation)) return;
      final entries = await repository.favorites(userId);
      if (_active(generation)) {
        state = AsyncData(FavoritesState(entries: entries));
      }
    } catch (error) {
      if (_active(generation)) {
        state = AsyncData(
          FavoritesState(entries: current.entries, error: error),
        );
      }
    }
  }
}

typedef ReviewKey = ({String? userId, String productId, int offset});
final reviewsProvider = FutureProvider.autoDispose
    .family<ReviewPage, ReviewKey>((ref, key) {
      if (ref.watch(personalizationUserIdProvider) != key.userId) {
        throw const PersonalizationFailure('SF_SESSION_CHANGED');
      }
      return ref
          .watch(personalizationRepositoryProvider)
          .reviews(key.userId, key.productId, key.offset);
    }, retry: (_, _) => null);

typedef UsersKey = ({String userId, String search, int offset});
final usersProvider = FutureProvider.autoDispose.family<UsersPage, UsersKey>((
  ref,
  key,
) {
  if (ref.watch(personalizationUserIdProvider) != key.userId) {
    throw const PersonalizationFailure('SF_SESSION_CHANGED');
  }
  return ref
      .watch(personalizationRepositoryProvider)
      .users(key.userId, key.search, key.offset);
}, retry: (_, _) => null);

typedef UserKey = ({String userId, String targetId});
final managedUserProvider = FutureProvider.autoDispose
    .family<ManagedUser, UserKey>((ref, key) {
      if (ref.watch(personalizationUserIdProvider) != key.userId) {
        throw const PersonalizationFailure('SF_SESSION_CHANGED');
      }
      return ref
          .watch(personalizationRepositoryProvider)
          .user(key.userId, key.targetId);
    }, retry: (_, _) => null);

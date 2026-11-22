import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_fashion/core/services/supabase_provider.dart';
import 'package:smart_fashion/features/auth/presentation/auth_providers.dart';
import 'package:smart_fashion/features/personalization/domain/personalization.dart';
import 'package:smart_fashion/features/personalization/presentation/account_access_gate.dart';
import 'package:smart_fashion/features/personalization/presentation/personalization_providers.dart';

import '../auth/fake_auth_repository.dart';
import 'personalization_test.dart' show accountA, accountB;

class ConfiguredBackend extends Fake implements SupabaseClient {}

void main() {
  testWidgets('access from A cannot authorize B while B status is loading', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..session = accountA;
    final client = ConfiguredBackend();
    final pending = Completer<AccountAccess>();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        supabaseClientProvider.overrideWithValue(client),
        accountAccessProvider.overrideWith((ref) async {
          final id = ref.watch(personalizationUserIdProvider);
          return id == accountB.id ? pending.future : AccountAccess(userId: id);
        }),
      ],
    );
    addTearDown(auth.close);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AccountAccessGate(child: Text('PRIVATE CONTENT')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE CONTENT'), findsOneWidget);
    auth.setUser(accountB);
    await tester.pump();
    await tester.pump();
    expect(find.text('PRIVATE CONTENT'), findsNothing);
    pending.complete(AccountAccess(userId: accountB.id, blocked: true));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản tạm khóa'), findsOneWidget);
    expect(find.text('PRIVATE CONTENT'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

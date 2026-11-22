import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/personalization/presentation/account_access_gate.dart';
import 'router/app_router.dart';

class SmartFashionApp extends ConsumerWidget {
  const SmartFashionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Đây là vỏ chung của app: tên, theme, tiếng Việt và điều hướng.
    return MaterialApp.router(
      title: 'Smart Fashion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => ListenableBuilder(
        listenable: router.routeInformationProvider,
        builder: (context, _) {
          final path = router.routeInformationProvider.value.uri.path;
          final publicCatalog =
              path == '/' ||
              path == '/explore' ||
              RegExp(r'^/products/[^/]+(?:/reviews)?$').hasMatch(path);
          return AccountAccessGate(
            publicCatalog: publicCatalog,
            onBrowseCatalog: () => router.go('/'),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

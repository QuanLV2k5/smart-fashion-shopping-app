import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class SmartFashionApp extends ConsumerWidget {
  const SmartFashionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đây là vỏ chung của app: tên, theme, tiếng Việt và điều hướng.
    return MaterialApp.router(
      title: 'Smart Fashion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

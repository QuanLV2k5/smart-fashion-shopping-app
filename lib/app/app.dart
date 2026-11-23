import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      builder: (context, child) => _RoutedAccessGate(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _RoutedAccessGate extends StatefulWidget {
  const _RoutedAccessGate({required this.router, required this.child});
  final GoRouter router;
  final Widget child;
  @override
  State<_RoutedAccessGate> createState() => _RoutedAccessGateState();
}

class _RoutedAccessGateState extends State<_RoutedAccessGate> {
  bool _scheduled = false;
  bool _openingCatalog = false;
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    _openingCatalog = false;
    if (_scheduled) return;
    _scheduled = true;
    // The initial route can be reported while Navigator is building below us.
    // Rebuild after the frame rather than marking an ancestor dirty during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _browseCatalog() {
    // A failed account check can temporarily hide Navigator. Mount the public
    // destination so Router can process go('/'), then resume normal route checks.
    setState(() => _openingCatalog = true);
    widget.router.go('/');
  }

  @override
  void didUpdateWidget(covariant _RoutedAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_routeChanged);
      widget.router.routerDelegate.addListener(_routeChanged);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = widget.router;
    // push/pop may leave the browser URL unchanged. Guard the visible page.
    final path = router.routerDelegate.currentConfiguration.isEmpty
        ? router.routeInformationProvider.value.uri.path
        : router.state.uri.path;
    final publicCatalog =
        _openingCatalog ||
        path == '/' ||
        path == '/explore' ||
        RegExp(r'^/products/[^/]+(?:/reviews)?$').hasMatch(path);
    return AccountAccessGate(
      publicCatalog: publicCatalog,
      onBrowseCatalog: _browseCatalog,
      child: widget.child,
    );
  }
}

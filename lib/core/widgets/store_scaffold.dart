import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';

/// Ba điểm đến đã hoạt động; dùng chung cho cửa hàng và tài khoản.
class StoreScaffold extends StatelessWidget {
  const StoreScaffold({
    required this.title,
    required this.selectedIndex,
    required this.child,
    this.trailing,
    super.key,
  });
  final String title;
  final int selectedIndex;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 56),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      SizedBox(width: 56, child: trailing),
                    ],
                  ),
                ),
              ),
              Expanded(child: child),
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  labelTextStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.bodySmall,
                  ),
                  onDestinationSelected: (index) {
                    if (index != selectedIndex) {
                      context.go(const ['/', '/explore', '/account'][index]);
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Trang chủ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_rounded),
                      label: 'Khám phá',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Tài khoản',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

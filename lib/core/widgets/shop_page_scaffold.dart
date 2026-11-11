import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Khung chi tiết/giỏ: header và CTA cố định, phần giữa do màn tự cuộn.
class ShopPageScaffold extends StatelessWidget {
  const ShopPageScaffold({
    required this.title,
    required this.onBack,
    required this.body,
    this.trailing,
    this.footer,
    super.key,
  });
  final String title;
  final VoidCallback onBack;
  final Widget body;
  final Widget? trailing;
  final Widget? footer;
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Quay lại',
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                      ),
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
              Expanded(child: body),
              if (footer != null)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.ivory,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      math.max(26, MediaQuery.paddingOf(context).bottom),
                    ),
                    child: footer!,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ShopNotice extends StatelessWidget {
  const ShopNotice(this.message, {this.error = false, super.key});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.info_outline : Icons.check_circle_outline,
            size: 20,
            color: error ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: error ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

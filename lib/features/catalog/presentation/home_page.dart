import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import 'widgets/catalog_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => StoreScaffold(
    title: 'SMART FASHION',
    trailing: const CartButton(),
    selectedIndex: 0,
    child: CatalogBody(
      builder: (catalog) {
        final featured = catalog.products
            .where(
              (p) => const {'SF01', 'SF02', 'SF05', 'SF07'}.contains(p.code),
            )
            .toList();
        final casual = catalog.products
            .where((p) => const {'SF01', 'SF02'}.contains(p.code))
            .toList();
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                'BỘ SƯU TẬP HẰNG NGÀY',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.accent),
              ),
              Text(
                'Đơn giản.\nĐúng chất bạn.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Image.asset(
                'assets/images/catalog/campaign.png',
                height: 230,
                fit: BoxFit.cover,
                semanticLabel: 'Bộ sưu tập casual với tông màu tự nhiên',
              ),
              FilledButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Khám phá bộ sưu tập'),
              ),
              CategoryStrip(
                categories: catalog.categories,
                selectedId: null,
                includeAll: false,
                onSelected: (id) =>
                    context.go('/explore?category=${Uri.encodeComponent(id!)}'),
              ),
              if (casual.length == 2)
                Material(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go('/explore?collection=weekend'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Text(
                            'Bộ casual cuối tuần',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const Text('Cotton thoáng + denim dễ phối.'),
                          Text(
                            '${formatVnd(casual.fold<int>(0, (sum, p) => sum + p.priceVnd))} cho 2 món',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lựa chọn hôm nay',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/explore'),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              if (catalog.products.isEmpty)
                const CatalogMessage(
                  title: 'Chưa có sản phẩm',
                  message: 'Những lựa chọn mới sẽ sớm có mặt tại đây.',
                )
              else
                ProductGrid(
                  products: featured.isEmpty
                      ? catalog.products.take(4).toList()
                      : featured,
                ),
            ],
          ),
        );
      },
    ),
  );
}

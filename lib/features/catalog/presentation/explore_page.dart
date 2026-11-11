import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/store_scaffold.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../domain/catalog_query.dart';
import 'catalog_filter_sheet.dart';
import 'widgets/catalog_widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    this.categoryId,
    this.weekendCollection = false,
    super.key,
  });
  final String? categoryId;
  final bool weekendCollection;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final search = TextEditingController();
  late CatalogFilters filters = CatalogFilters(categoryId: widget.categoryId);
  CatalogSort sort = CatalogSort.recommended;
  late bool weekendCollection = widget.weekendCollection;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    filters = const CatalogFilters();
    search.clear();
    weekendCollection = false;
    sort = CatalogSort.recommended;
  });

  @override
  Widget build(BuildContext context) => StoreScaffold(
    title: 'Khám phá',
    trailing: const CartButton(),
    selectedIndex: 1,
    child: CatalogBody(
      builder: (catalog) {
        final products = queryCatalog(
          catalog,
          search: search.text,
          filters: filters,
          sort: sort,
          collectionCodes: weekendCollection ? const {'SF01', 'SF02'} : null,
        );
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              TextField(
                key: const ValueKey('catalog-search'),
                controller: search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm, phong cách…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa từ khóa',
                          onPressed: () => setState(search.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              Text(
                'Tìm món dành cho bạn.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              CategoryStrip(
                categories: catalog.categories,
                selectedId: filters.categoryId,
                onSelected: (id) =>
                    setState(() => filters = filters.withCategory(id)),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        side: BorderSide.none,
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final result = await showCatalogFilters(
                          context,
                          catalog,
                          filters,
                        );
                        if (result != null && mounted) {
                          setState(() => filters = result);
                        }
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(
                        filters.count > 0 ? 'Lọc (${filters.count})' : 'Lọc',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        side: BorderSide.none,
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final result = await showModalBottomSheet<CatalogSort>(
                          context: context,
                          useSafeArea: true,
                          showDragHandle: true,
                          backgroundColor: AppColors.ivory,
                          constraints: const BoxConstraints(maxWidth: 600),
                          builder: (context) => SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Sắp xếp',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  ...CatalogSort.values.map(
                                    (option) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(option.label),
                                      trailing: sort == option
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                      onTap: () =>
                                          Navigator.pop(context, option),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() => sort = result);
                        }
                      },
                      icon: const Icon(Icons.swap_vert, size: 18),
                      label: const Text('Sắp xếp'),
                    ),
                  ),
                ],
              ),
              if (weekendCollection)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Bộ casual cuối tuần')),
                      IconButton(
                        tooltip: 'Bỏ bộ sưu tập',
                        onPressed: () =>
                            setState(() => weekendCollection = false),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${products.length} sản phẩm · ${sort.label}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                  if (filters.count > 0 ||
                      search.text.isNotEmpty ||
                      weekendCollection)
                    TextButton(onPressed: reset, child: const Text('Đặt lại')),
                ],
              ),
              if (products.isEmpty)
                CatalogMessage(
                  title: 'Chưa tìm thấy món phù hợp',
                  message: 'Thử từ khóa khác hoặc mở rộng bộ lọc.',
                  action: 'Tìm lại',
                  onAction: reset,
                )
              else
                ProductGrid(products: products),
            ],
          ),
        );
      },
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/catalog.dart';
import '../domain/catalog_query.dart';
import 'widgets/catalog_widgets.dart';

Future<CatalogFilters?> showCatalogFilters(
  BuildContext context,
  CatalogSnapshot catalog,
  CatalogFilters filters,
) => showModalBottomSheet<CatalogFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.ivory,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (_) => CatalogFilterSheet(catalog: catalog, initial: filters),
);

class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({
    required this.catalog,
    required this.initial,
    super.key,
  });
  final CatalogSnapshot catalog;
  final CatalogFilters initial;
  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late CatalogFilters draft = widget.initial;
  @override
  Widget build(BuildContext context) {
    final variants = widget.catalog.products.expand((p) => p.variants);
    final sizes = variants.map((v) => v.size).toSet().toList();
    final colors = variants.map((v) => v.color).toSet().toList()..sort();
    Widget heading(String text) =>
        Text(text, style: Theme.of(context).textTheme.labelLarge);
    void update({
      String? category,
      PriceRange? price,
      String? size,
      String? color,
      bool? stock,
      String? clear,
    }) => setState(
      () => draft = CatalogFilters(
        categoryId: clear == 'category' ? null : category ?? draft.categoryId,
        priceRange: clear == 'price' ? null : price ?? draft.priceRange,
        size: clear == 'size' ? null : size ?? draft.size,
        color: clear == 'color' ? null : color ?? draft.color,
        onlyInStock: stock ?? draft.onlyInStock,
      ),
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Lọc sản phẩm',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  heading('Khoảng giá'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: PriceRange.values
                        .map(
                          (range) => CatalogChip(
                            label: range.label,
                            selected: draft.priceRange == range,
                            onSelected: () => update(
                              price: range,
                              clear: draft.priceRange == range ? 'price' : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  heading('Danh mục'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      CatalogChip(
                        label: 'Tất cả',
                        selected: draft.categoryId == null,
                        onSelected: () => update(clear: 'category'),
                      ),
                      ...widget.catalog.categories.map(
                        (c) => CatalogChip(
                          label: c.name,
                          selected: draft.categoryId == c.id,
                          onSelected: () => update(
                            category: c.id,
                            clear: draft.categoryId == c.id ? 'category' : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  heading('Kích thước'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: sizes
                        .map(
                          (size) => CatalogChip(
                            label: size,
                            selected: draft.size == size,
                            onSelected: () => update(
                              size: size,
                              clear: draft.size == size ? 'size' : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  heading('Màu sắc'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: colors
                        .map(
                          (color) => CatalogChip(
                            label: color,
                            selected: draft.color == color,
                            onSelected: () => update(
                              color: color,
                              clear: draft.color == color ? 'color' : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ sản phẩm còn hàng'),
                    subtitle: const Text('Size và màu đã chọn phải còn hàng.'),
                    value: draft.onlyInStock,
                    onChanged: (value) => update(stock: value),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context, draft),
                    child: const Text('Áp dụng bộ lọc'),
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        setState(() => draft = const CatalogFilters()),
                    child: const Text('Xóa bộ lọc'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

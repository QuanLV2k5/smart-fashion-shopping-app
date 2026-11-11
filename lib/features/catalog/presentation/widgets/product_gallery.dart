import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/catalog.dart';
import 'catalog_widgets.dart';

class ProductGallery extends StatefulWidget {
  const ProductGallery({required this.product, super.key});
  final CatalogProduct product;
  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final controller = PageController();
  int index = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final count = product.imageUrls.isNotEmpty
        ? product.imageUrls.length
        : const {'SF01', 'SF02'}.contains(product.code)
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Semantics(
          label: 'Ảnh ${index + 1} trên $count của ${product.name}',
          child: SizedBox(
            height: 300,
            child: PageView.builder(
              controller: controller,
              itemCount: count,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (_, position) =>
                  ProductPhoto(product: product, imageIndex: position),
            ),
          ),
        ),
        if (count > 1)
          Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: AppSpacing.xs,
                    children: List.generate(
                      count,
                      (position) => Semantics(
                        selected: index == position,
                        child: Tooltip(
                          message: 'Xem ảnh ${position + 1}',
                          child: InkWell(
                            onTap: () => controller.animateToPage(
                              position,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: index == position
                                      ? AppColors.primary
                                      : AppColors.outline,
                                ),
                              ),
                              child: ProductPhoto(
                                product: product,
                                imageIndex: position,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  '${index + 1} / $count · Chạm để xem ảnh',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

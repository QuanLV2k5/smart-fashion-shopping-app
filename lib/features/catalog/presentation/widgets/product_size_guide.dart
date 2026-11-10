import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Bảng tham khảo từ Figma cho SF01/SF02, không tự suy đoán số đo cho món khác.
Future<void> showProductSizeGuide(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.ivory,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hướng dẫn chọn size',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng bảng size',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [
                    Text(
                      'Áo thun Essential · cm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const _SizeTable(
                      headers: ['Size', 'Ngực áo', 'Dài áo'],
                      values: [
                        ['S', '96', '64'],
                        ['M', '100', '67'],
                        ['L', '104', '70'],
                        ['XL', '108', '73'],
                      ],
                    ),
                    Text(
                      'Jeans Straight · cm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const _SizeTable(
                      headers: ['Size', 'Vòng eo', 'Dài quần'],
                      values: [
                        ['S', '68', '96'],
                        ['M', '72', '98'],
                        ['L', '76', '100'],
                      ],
                    ),
                    const Text(
                      'Bảng size tham khảo. Đo trang phục đang mặc vừa để so sánh. Sai số sản phẩm có thể khoảng 1–2cm.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

class _SizeTable extends StatelessWidget {
  const _SizeTable({required this.headers, required this.values});
  final List<String> headers;
  final List<List<String>> values;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      horizontalMargin: 0,
      columnSpacing: AppSpacing.lg,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 80,
      columns: headers.map((text) => DataColumn(label: Text(text))).toList(),
      rows: values
          .map(
            (row) => DataRow(
              cells: row.map((text) => DataCell(Text(text))).toList(),
            ),
          )
          .toList(),
    ),
  );
}

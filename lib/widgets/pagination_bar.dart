import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int size;
  final ValueChanged<int> onPageChange;
  final ValueChanged<int> onSizeChange;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.size,
    required this.onPageChange,
    required this.onSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Строк: '),
                DropdownButton<int>(
                  value: size,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                  onChanged: (val) {
                    if (val != null) onSizeChange(val);
                  },
                ),
                const SizedBox(width: 16),
                Text('Всего: $totalItems'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  tooltip: 'Первая',
                  onPressed: page > 1 ? () => onPageChange(1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Предыдущая',
                  onPressed: page > 1 ? () => onPageChange(page - 1) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Стр. $page из $totalPages'),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Следующая',
                  onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  tooltip: 'Последняя',
                  onPressed: page < totalPages ? () => onPageChange(totalPages) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
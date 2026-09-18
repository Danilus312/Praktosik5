import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: onToggleSelect != null,
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                sortColumnIndex: _calculateSortColumnIndex(),
                sortAscending: sortAscending,
                columns: [
                  ...columns.map((c) {
                    return DataColumn(
                      label: Text(c.label,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      numeric: c.numeric,
                      onSort: c.sortField != null && onSort != null
                          ? (_, __) => onSort!(c.sortField!)
                          : null,
                    );
                  }),
                  if (actions != null)
                    const DataColumn(
                      label: Text('Действия',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
                rows: items.map((item) {
                  final id = idOf(item);
                  final isSelected = selected.contains(id);

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: onToggleSelect != null
                        ? (_) => onToggleSelect!(id)
                        : null,
                    cells: [
                      ...columns.map((c) => DataCell(c.build(item))),
                      if (actions != null)
                        DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!(item))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _calculateSortColumnIndex() {
    if (sortField == null) return null;
    final index = columns.indexWhere((c) => c.sortField == sortField);
    return index != -1 ? index : null;
  }
}

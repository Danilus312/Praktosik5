import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_input.dart';

class AuthorListScreen extends StatefulWidget {
  final Map<String, String> queryParams;
  const AuthorListScreen({super.key, required this.queryParams});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUrlToState(widget.queryParams);
    });
  }

  @override
  void didUpdateWidget(covariant AuthorListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParams != widget.queryParams) {
      _syncUrlToState(widget.queryParams);
    }
  }

  void _syncUrlToState(Map<String, String> params) {
    final query = AuthorQuery.fromQueryParams(params);
    context.read<AuthorListNotifier>().applyQuery(query);
  }

  void _pushQuery(AuthorQuery next) {
    final queryParams = next.toQueryParams();
    final uri = Uri(
        path: '/authors',
        queryParameters: queryParams.isEmpty ? null : queryParams);
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final q = notifier.query;
    final res = notifier.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список авторов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SearchInput(
                    initialValue: q.search,
                    hintText: 'Поиск по фамилии или стране...',
                    onChanged: (val) => _pushQuery(q.copyWith(search: val)),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (val) =>
                      _pushQuery(q.copyWith(includeDeleted: val)),
                ),
              ],
            ),
          ),
          if (notifier.hasSelection)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Выбрано: ${notifier.selected.length}'),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => notifier.deleteSelected(),
                    child: const Text('Удалить выбранных'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              LoadStatus.error =>
                Center(child: Text(notifier.error ?? 'Ошибка')),
              LoadStatus.idle || LoadStatus.success => res.items.isEmpty
                  ? const Center(child: Text('Авторы не найдены'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return ListView.builder(
                            itemCount: res.items.length,
                            itemBuilder: (context, index) {
                              final a = res.items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  title: Text(a.fullName),
                                  subtitle: Text(
                                      'Страна: ${a.country}, Родился: ${a.birthYear}'),
                                ),
                              );
                            },
                          );
                        }
                        return EntityTable<Author>(
                          items: res.items,
                          idOf: (a) => a.id,
                          selected: notifier.selected,
                          onToggleSelect: (id) => notifier.toggleSelection(id),
                          sortField: q.sortField,
                          sortAscending: q.sortAscending,
                          onSort: (f) => _pushQuery(
                            q.copyWith(
                              sortField: f,
                              sortAscending:
                                  f == q.sortField ? !q.sortAscending : true,
                            ),
                          ),
                          columns: [
                            TableColumnSpec(
                                label: 'Фамилия Имя',
                                sortField: 'lastName',
                                build: (a) => Text(a.fullName)),
                            TableColumnSpec(
                                label: 'Страна',
                                sortField: 'country',
                                build: (a) => Text(a.country)),
                            TableColumnSpec(
                                label: 'Год рождения',
                                sortField: 'birthYear',
                                numeric: true,
                                build: (a) => Text('${a.birthYear}')),
                          ],
                          actions: (a) => [
                            if (a.isDeleted)
                              IconButton(
                                  icon: const Icon(Icons.restore,
                                      color: Colors.green),
                                  onPressed: () => notifier.restore(a.id))
                            else
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.orange),
                                  onPressed: () => notifier.softDelete(a.id)),
                          ],
                        );
                      },
                    ),
            },
          ),
          PaginationBar(
            page: res.page,
            totalPages: res.totalPages,
            totalItems: res.total,
            size: res.size,
            onPageChange: (p) => _pushQuery(q.copyWith(page: p)),
            onSizeChange: (s) => _pushQuery(q.copyWith(size: s, page: 1)),
          ),
        ],
      ),
    );
  }
}

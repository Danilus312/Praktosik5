import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/book_repository.dart';
import '../repositories/cached_dictionary_repository.dart';
import '../state/book_list_notifier.dart';

class BookListScreen extends StatefulWidget {
  final Map<String, String>? queryParams;
  const BookListScreen({super.key, this.queryParams});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  Timer? _debounceTimer;

  List<Publisher> _publishers = seedPublishers;
  List<Genre> _genres = seedGenres;

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
    _applyQueryParams(widget.queryParams);
  }

  @override
  void didUpdateWidget(covariant BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryParams != oldWidget.queryParams) {
      _applyQueryParams(widget.queryParams);
    }
  }

  void _applyQueryParams(Map<String, String>? params) {
    if (params == null) return;
    final delay = int.tryParse(params['__delay'] ?? '');
    final fail = int.tryParse(params['__fail'] ?? '');
    if (delay != null || fail != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BookListNotifier>().updateQuery(
              (q) => q.copyWith(delay: delay, fail: fail),
            );
      });
    }
  }

  Future<void> _loadDictionaries() async {
    final dictRepo = context.read<CachedDictionaryRepository>();
    final pubs = await dictRepo.getPublishers();
    final gens = await dictRepo.getGenres();
    if (!mounted) return;
    setState(() {
      _publishers = pubs;
      _genres = gens;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<BookListNotifier>().updateQuery(
            (q) => q.copyWith(search: value, page: 1),
          );
    });
  }

  String _getGenreNames(List<int> genreIds) {
    if (genreIds.isEmpty) return '—';
    final names = genreIds
        .map((id) => _genres.firstWhere((g) => g.id == id, orElse: () => Genre(id: id, name: 'Жанр #$id')).name)
        .toList();
    return names.isEmpty ? '—' : names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final query = notifier.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.table_chart),
            label: const Text('Издательства'),
            onPressed: () {},
          ),
          TextButton.icon(
            icon: const Icon(Icons.badge),
            label: const Text('Читатели'),
            onPressed: () {},
          ),
          TextButton.icon(
            icon: const Icon(Icons.people),
            label: const Text('Авторы'),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Новая книга'),
            onPressed: () => context.go('/books/new'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Обновить данные',
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.reload(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Поиск по названию или ISBN...',
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: query.showDeleted ? Colors.grey.shade300 : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onPressed: () {
                        notifier.updateQuery(
                          (q) => q.copyWith(showDeleted: !q.showDeleted, page: 1),
                        );
                      },
                      child: const Text('Удалённые'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    DropdownButton<int?>(
                      value: query.genreId,
                      hint: const Text('Все жанры'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все жанры')),
                        ..._genres.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                      ],
                      onChanged: (val) {
                        notifier.updateQuery((q) => q.copyWith(genreId: val, page: 1));
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int?>(
                      value: query.publisherId,
                      hint: const Text('Все издательства'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все издательства')),
                        ..._publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (val) {
                        notifier.updateQuery((q) => q.copyWith(publisherId: val, page: 1));
                      },
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _yearFromController,
                        decoration: const InputDecoration(labelText: 'Год от', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) {
                          notifier.updateQuery((q) => q.copyWith(yearFrom: int.tryParse(v), page: 1));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _yearToController,
                        decoration: const InputDecoration(labelText: 'Год до', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) {
                          notifier.updateQuery((q) => q.copyWith(yearTo: int.tryParse(v), page: 1));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(context, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookListNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 4.0),
            ),
            SizedBox(height: 24),
            Text(
              'Загрузка данных с сервера...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (notifier.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 72, color: Colors.redAccent),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  notifier.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                onPressed: () => notifier.reload(),
              ),
            ],
          ),
        ),
      );
    }

    if (notifier.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'По заданным критериям книг не найдено',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                sortColumnIndex: _getSortColumnIndex(notifier.query.sortField),
                sortAscending: notifier.query.sortAscending,
                columns: [
                  DataColumn(
                    label: const Text('Название'),
                    onSort: (_, asc) => _changeSort('title', asc),
                  ),
                  const DataColumn(label: Text('ISBN')),
                  DataColumn(
                    label: const Text('Год'),
                    onSort: (_, asc) => _changeSort('year', asc),
                  ),
                  DataColumn(
                    label: const Text('Страниц'),
                    onSort: (_, asc) => _changeSort('pages', asc),
                  ),
                  const DataColumn(label: Text('Жанры')),
                  const DataColumn(label: Text('Действия')),
                ],
                rows: notifier.items.map((book) {
                  return DataRow(
                    cells: [
                      DataCell(Text(book.title)),
                      DataCell(Text(book.isbn)),
                      DataCell(Text('${book.year}')),
                      DataCell(Text('${book.pages}')),
                      DataCell(Text(_getGenreNames(book.genreIds))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Редактировать',
                              onPressed: () => context.go('/books/${book.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.orange),
                              tooltip: 'В корзину',
                              onPressed: () async {
                                await context.read<BookRepository>().softDelete(book.id);
                                notifier.reload();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              tooltip: 'Удалить навсегда',
                              onPressed: () async {
                                await context.read<BookRepository>().hardDelete(book.id);
                                notifier.reload();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        _buildPaginationBar(context, notifier),
      ],
    );
  }

  int? _getSortColumnIndex(String field) {
    switch (field) {
      case 'title':
        return 0;
      case 'year':
        return 2;
      case 'pages':
        return 3;
      default:
        return null;
    }
  }

  void _changeSort(String field, bool ascending) {
    context.read<BookListNotifier>().updateQuery(
          (q) => q.copyWith(sortField: field, sortAscending: ascending, page: 1),
        );
  }

  Widget _buildPaginationBar(BuildContext context, BookListNotifier notifier) {
    final query = notifier.query;
    final totalPages = (notifier.total / query.size).ceil().clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Строк: '),
          DropdownButton<int>(
            value: query.size,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5')),
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
            ],
            onChanged: (val) {
              if (val != null) {
                notifier.updateQuery((q) => q.copyWith(size: val, page: 1));
              }
            },
          ),
          const SizedBox(width: 24),
          Text('Всего: ${notifier.total}'),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: query.page > 1
                ? () => notifier.updateQuery((q) => q.copyWith(page: 1))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: query.page > 1
                ? () => notifier.updateQuery((q) => q.copyWith(page: q.page - 1))
                : null,
          ),
          Text('Стр. ${query.page} из $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: query.page < totalPages
                ? () => notifier.updateQuery((q) => q.copyWith(page: q.page + 1))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: query.page < totalPages
                ? () => notifier.updateQuery((q) => q.copyWith(page: totalPages))
                : null,
          ),
        ],
      ),
    );
  }
}
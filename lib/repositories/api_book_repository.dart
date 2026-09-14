import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  CancelToken? _searchCancelToken;

  ApiBookRepository(this._dio);

  Future<T> _retry<T>(Future<T> Function() action, {int attempts = 3}) async {
    int count = 0;
    while (true) {
      count++;
      try {
        return await action();
      } on NetworkException {
        if (count >= attempts) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * count));
      }
    }
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    _searchCancelToken?.cancel('new_search_initiated');
    _searchCancelToken = CancelToken();

    return _retry(() => guard(() async {
      try {
        final queryParams = <String, dynamic>{
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.genreId != null) 'genreId': q.genreId,
          if (q.publisherId != null) 'publisherId': q.publisherId,
          if (q.yearFrom != null) 'yearFrom': q.yearFrom,
          if (q.yearTo != null) 'yearTo': q.yearTo,
          if (q.includeDeleted) 'includeDeleted': true,
          if (q.delay != null && q.delay! > 0) '__delay': q.delay,
          if (q.fail != null && q.fail! > 0) '__fail': q.fail,
        };

        final response = await _dio.get(
          '/books',
          queryParameters: queryParams,
          cancelToken: _searchCancelToken,
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          final itemsRaw = data['items'] as List? ?? [];
          final items = itemsRaw
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
          final total = data['total'] as int? ?? items.length;
          final page = data['page'] as int? ?? q.page;
          final size = data['size'] as int? ?? q.size;
          return PageResult<Book>(
            items: items,
            total: total,
            page: page,
            size: size,
          );
        }

        if (data is List) {
          final items = data
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
          return PageResult<Book>(
            items: items,
            total: items.length,
            page: q.page,
            size: q.size,
          );
        }

        return PageResult<Book>(
          items: const [],
          total: 0,
          page: q.page,
          size: q.size,
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          return PageResult<Book>(
            items: const [],
            total: 0,
            page: q.page,
            size: q.size,
          );
        }
        rethrow;
      }
    }));
  }

  @override
  Future<Book?> findById(int id) => _retry(() => guard(() async {
        final response = await _dio.get('/books/$id');
        if (response.data == null) return null;
        return Book.fromJson(response.data as Map<String, dynamic>);
      }));

  @override
  Future<Book> create(Book book) => guard(() async {
        final response = await _dio.post(
          '/books',
          data: book.toJson(),
        );
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final response = await _dio.put(
          '/books/${book.id}',
          data: book.toJson(),
        );
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/books/$id');
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete('/books/$id', queryParameters: {'hard': 'true'});
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/books/$id/restore');
      });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post(
          '/books/bulk-delete',
          data: {'ids': ids},
        );
        return response.data['deletedCount'] as int? ?? ids.length;
      });
}
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/api_client.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_book_repository.dart';

void main() {
  group('ApiBookRepository Unit Tests', () {
    test('1. Успешный разбор списка книг из JSON (GET 200)', () async {
      final dio = buildDio();
      dio.httpClientAdapter = _MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          '{"items": [{"id": 1, "title": "1984", "isbn": "123", "year": 1949, "pages": 320, "publisherId": 1, "authorIds": [], "genreIds": [], "copiesTotal": 5, "copiesAvailable": 5}], "page": 1, "size": 10, "total": 1}',
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final repo = ApiBookRepository(dio);
      final result = await repo.find(const BookQuery());

      expect(result.items.length, 1);
      expect(result.items.first.title, '1984');
    });

    test('2. Ошибка валидации 422 выбрасывает ValidationException с ошибками полей', () async {
      final dio = buildDio();
      dio.httpClientAdapter = _MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          '{"message": "Ошибка валидации", "errors": {"isbn": "Книга с таким ISBN уже существует"}}',
          422,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final repo = ApiBookRepository(dio);

      expect(
        () => repo.find(const BookQuery()),
        throwsA(isA<ValidationException>().having(
          (e) => e.errors['isbn'],
          'isbn error',
          contains('ISBN'),
        )),
      );
    });

    test('3. Ошибка конфликта 409 выбрасывает ConflictException', () async {
      final dio = buildDio();
      dio.httpClientAdapter = _MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          '{"message": "Конфликт: нет свободных экземпляров"}',
          409,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final repo = ApiBookRepository(dio);
      expect(() => repo.find(const BookQuery()), throwsA(isA<ConflictException>()));
    });

    test('4. Недоступность сервера или сбой сети выбрасывает NetworkException', () async {
      final dio = buildDio();
      dio.httpClientAdapter = _MockHttpAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      final repo = ApiBookRepository(dio);
      expect(() => repo.find(const BookQuery()), throwsA(isA<NetworkException>()));
    });

    test('5. Ошибка 404 выбрасывает NotFoundException', () async {
      final dio = buildDio();
      dio.httpClientAdapter = _MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          '{"message": "Книга не найдена"}',
          404,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final repo = ApiBookRepository(dio);
      expect(() => repo.find(const BookQuery()), throwsA(isA<NotFoundException>()));
    });
  });
}

class _MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}
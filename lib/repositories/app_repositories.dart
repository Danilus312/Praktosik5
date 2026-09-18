import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import 'book_repository.dart';

class PersistentLibraryRepository implements BookRepository {
  static const _booksKey = 'books_v2';
  static const _authorsKey = 'authors_v2';
  static const _genresKey = 'genres_v2';
  static const _publishersKey = 'publishers_v2';
  static const _readersKey = 'readers_v2';

  final SharedPreferences _prefs;

  List<Book> books = [];
  List<Author> authors = [];
  List<Genre> genres = [];
  List<Publisher> publishers = [];
  List<Reader> readers = [];

  PersistentLibraryRepository(this._prefs) {
    _restoreAll();
  }

  void _restoreAll() {
    books = _restoreList(_booksKey, seedBooks, (j) => Book.fromJson(j));
    authors = _restoreList(_authorsKey, seedAuthors, (j) => Author.fromJson(j));
    genres = _restoreList(_genresKey, seedGenres, (j) => Genre.fromJson(j));
    publishers = _restoreList(
        _publishersKey, seedPublishers, (j) => Publisher.fromJson(j));
    readers = _restoreList(_readersKey, seedReaders, (j) => Reader.fromJson(j));
  }

  List<T> _restoreList<T>(
      String key, List<T> fallback, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      _prefs.setString(key, jsonEncode(fallback));
      return [...fallback];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _prefs.setString(key, jsonEncode(fallback));
      return [...fallback];
    }
  }

  Future<void> saveBooks() async => _prefs.setString(
      _booksKey, jsonEncode(books.map((e) => e.toJson()).toList()));
  Future<void> saveAuthors() async => _prefs.setString(
      _authorsKey, jsonEncode(authors.map((e) => e.toJson()).toList()));
  Future<void> saveGenres() async => _prefs.setString(
      _genresKey, jsonEncode(genres.map((e) => e.toJson()).toList()));
  Future<void> savePublishers() async => _prefs.setString(
      _publishersKey, jsonEncode(publishers.map((e) => e.toJson()).toList()));
  Future<void> saveReaders() async => _prefs.setString(
      _readersKey, jsonEncode(readers.map((e) => e.toJson()).toList()));

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
          .toList();
    }

    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }

    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }

    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }

    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    final index = books.indexWhere((b) => b.id == id);
    return index != -1 ? books[index] : null;
  }

  @override
  Future<Book> create(Book book) => saveBook(book);

  @override
  Future<Book> update(Book book) => saveBook(book);

  @override
  Future<void> softDelete(int id) async {
    final i = books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    books[i] = books[i].copyWith(deletedAt: DateTime.now());
    await saveBooks();
  }

  @override
  Future<void> hardDelete(int id) async {
    books.removeWhere((b) => b.id == id);
    await saveBooks();
  }

  @override
  Future<void> restore(int id) async {
    final i = books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    books[i] = books[i].copyWith(clearDeletedAt: true);
    await saveBooks();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        books[i] = books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await saveBooks();
    return count;
  }

  bool isIsbnUnique(String isbn, int? excludeId) {
    final normalized = isbn.replaceAll('-', '').trim().toLowerCase();
    return !books.any((b) =>
        b.id != excludeId &&
        !b.isDeleted &&
        b.isbn.replaceAll('-', '').trim().toLowerCase() == normalized);
  }

  bool isEmailUnique(String email, int? excludeId) {
    final normalized = email.trim().toLowerCase();
    return !readers.any((r) =>
        r.id != excludeId &&
        !r.isDeleted &&
        r.email.trim().toLowerCase() == normalized);
  }

  int countBooksByPublisher(int publisherId) {
    return books
        .where((b) => b.publisherId == publisherId && !b.isDeleted)
        .length;
  }

  Future<Book> saveBook(Book book) async {
    if (book.id == 0) {
      final newId = books.isEmpty
          ? 1
          : (books.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      final newBook = Book(
        id: newId,
        title: book.title,
        isbn: book.isbn,
        year: book.year,
        pages: book.pages,
        publisherId: book.publisherId,
        authorIds: book.authorIds,
        genreIds: book.genreIds,
        copiesTotal: book.copiesTotal,
        copiesAvailable: book.copiesAvailable,
      );
      books.add(newBook);
      await saveBooks();
      return newBook;
    } else {
      final index = books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        books[index] = book;
        await saveBooks();
      }
      return book;
    }
  }

  Future<Reader> saveReader(Reader reader) async {
    if (reader.id == 0) {
      final newId = readers.isEmpty
          ? 1
          : (readers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      final created = Reader(
        id: newId,
        fullName: reader.fullName,
        email: reader.email,
        phone: reader.phone,
        card: reader.card,
      );
      readers.add(created);
      await saveReaders();
      return created;
    } else {
      final index = readers.indexWhere((r) => r.id == reader.id);
      if (index != -1) {
        readers[index] = reader;
        await saveReaders();
      }
      return reader;
    }
  }
}

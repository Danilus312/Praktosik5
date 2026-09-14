import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../repositories/book_repository.dart';

class BookListNotifier extends ChangeNotifier {
  final BookRepository _repository;

  List<Book> _items = [];
  int _total = 0;
  bool _isLoading = false;
  String? _errorMessage;
  BookQuery _query = const BookQuery();

  BookListNotifier(this._repository);

  List<Book> get items => _items;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookQuery get query => _query;

  Future<void> load({BookQuery? newQuery}) async {
    if (newQuery != null) {
      _query = newQuery;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.find(_query);
      _items = result.items;
      _total = result.total;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  void updateQuery(BookQuery Function(BookQuery current) update) {
    final updated = update(_query);
    load(newQuery: updated);
  }
}
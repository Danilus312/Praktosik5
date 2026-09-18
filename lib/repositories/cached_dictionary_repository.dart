import 'package:dio/dio.dart';
import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';

class CachedDictionaryRepository {
  final Dio _dio;

  List<Genre>? _cachedGenres;
  List<Publisher>? _cachedPublishers;
  List<Author>? _cachedAuthors;

  CachedDictionaryRepository(this._dio);

  Future<List<Genre>> getGenres() async {
    if (_cachedGenres != null) return _cachedGenres!;
    try {
      final res = await _dio.get('/genres');
      final list = (res.data['items'] ?? res.data) as List;
      _cachedGenres =
          list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _cachedGenres = [...seedGenres];
    }
    return _cachedGenres!;
  }

  Future<List<Publisher>> getPublishers() async {
    if (_cachedPublishers != null) return _cachedPublishers!;
    try {
      final res = await _dio.get('/publishers');
      final list = (res.data['items'] ?? res.data) as List;
      _cachedPublishers = list
          .map((e) => Publisher.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cachedPublishers = [...seedPublishers];
    }
    return _cachedPublishers!;
  }

  Future<List<Author>> getAuthors() async {
    if (_cachedAuthors != null) return _cachedAuthors!;
    try {
      final res = await _dio.get('/authors');
      final list = (res.data['items'] ?? res.data) as List;
      _cachedAuthors =
          list.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _cachedAuthors = [...seedAuthors];
    }
    return _cachedAuthors!;
  }
}

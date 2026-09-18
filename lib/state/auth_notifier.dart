import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_cached_user';
  static const _kLoginTime = 'auth_login_timestamp';

  final SharedPreferences _prefs;
  final Dio _dio;

  AppUser? _user;
  String? _accessToken;
  bool _isRefreshing = false;

  AuthNotifier(this._prefs, this._dio);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final userRaw = _prefs.getString(_kUser);
    final loginTime = _prefs.getInt(_kLoginTime);

    if (loginTime != null) {
      final sessionAge = DateTime.now().millisecondsSinceEpoch - loginTime;
      if (sessionAge > 12 * 3600 * 1000) {
        await logout();
        return;
      }
    }

    if (access == null) return;
    _accessToken = access;

    if (userRaw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      final res = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      final data = _safeMap(res.data);
      _user = AppUser.fromJson(data);
      await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && refresh != null) {
        try {
          await refreshTokens();
        } catch (_) {
          await logout();
        }
      } else if (e.response?.statusCode == 401) {
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    final data = _safeMap(res.data);
    _accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(_safeMap(data['user']));

    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, refreshToken);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setInt(_kLoginTime, DateTime.now().millisecondsSinceEpoch);

    notifyListeners();
  }

  Future<void> register(
      String username, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
      'fullName': fullName,
    });

    final data = _safeMap(res.data);
    _accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(_safeMap(data['user']));

    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, refreshToken);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setInt(_kLoginTime, DateTime.now().millisecondsSinceEpoch);

    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) {
      _isRefreshing = false;
      await logout();
      throw Exception('No refresh token');
    }

    try {
      final res = await _dio.post('/auth/refresh', data: {
        'refreshToken': refresh,
      });

      final data = _safeMap(res.data);
      _accessToken = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String?;

      await _prefs.setString(_kAccess, _accessToken!);
      if (newRefresh != null) {
        await _prefs.setString(_kRefresh, newRefresh);
      }
      notifyListeners();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kLoginTime);
    notifyListeners();
  }
}

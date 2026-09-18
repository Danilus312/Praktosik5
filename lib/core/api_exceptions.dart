import 'dart:convert';
import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Не удалось соединиться с сервером. Если сервер запущен, проверьте наличие ошибки CORS.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(
      [super.message = 'Недостаточно прав для этого действия.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException(
      [super.message = 'Ошибка на сервере. Попробуйте позже.']);
}

ApiException mapHttpError(int status, dynamic body) {
  dynamic parsed = body;
  if (parsed is String && parsed.trim().isNotEmpty) {
    try {
      parsed = jsonDecode(parsed);
    } catch (_) {}
  }

  final message = (parsed is Map && parsed['message'] is String)
      ? parsed['message'] as String
      : null;

  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 =>
      ForbiddenException(message ?? 'Недостаточно прав для этого действия.'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 =>
      ConflictException(message ?? 'Операция невозможна (конфликт данных).'),
    422 => ValidationException(
        message ?? 'Ошибка валидации',
        (parsed is Map && parsed['errors'] is Map)
            ? (parsed['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
            : const {},
      ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;

  if (e.response != null && e.response!.statusCode != null) {
    return mapHttpError(e.response!.statusCode!, e.response!.data);
  }

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Сервер не ответил вовремя (таймаут).'),
    DioExceptionType.connectionError => const NetworkException(
        'Не удалось соединиться с сервером. Если сервер запущен, проверьте наличие ошибки CORS.',
      ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

import 'package:dio/dio.dart';
import '../state/auth_notifier.dart';
import 'config.dart';

Dio buildDio({AuthNotifier? authNotifier}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authNotifier?.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${authNotifier!.accessToken}';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;

        if (status == 401 && !path.contains('/auth/') && authNotifier != null) {
          try {
            await authNotifier.refreshTokens();
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${authNotifier.accessToken}';

            final cloneDio = Dio(
              BaseOptions(
                baseUrl: apiBaseUrl,
                headers: {'Content-Type': 'application/json'},
              ),
            );
            final response = await cloneDio.fetch(opts);
            return handler.resolve(response);
          } catch (_) {
            await authNotifier.logout();
          }
        }
        return handler.reject(error);
      },
    ),
  );

  return dio;
}
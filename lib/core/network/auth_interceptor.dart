import 'package:dio/dio.dart';
import 'package:lynko/core/cache/cache_helper.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final bool withAuth = options.extra['withAuth'] ?? false;

    if (withAuth) {
      final token = await CacheHelper.getToken();

      if (token != null && token.isNotEmpty) {
        options.headers['token'] = token;
      }
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode == 401) {
      await CacheHelper.clearToken();
      // Optionally handle navigation or session clearing here
    }

    handler.next(err);
  }
}
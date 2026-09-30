import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('AUTH token present: ${token != null && token.isNotEmpty}');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    final withAuth = response.requestOptions.extra['withAuth'] == true;

    if (response.statusCode == 401 && withAuth) {
      await CacheHelper.clearToken();
      // TODO: navigate to login (e.g. via a navigatorKey or a Riverpod session provider)
    }

    handler.next(response);
  }
}
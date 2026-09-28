import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lynko/core/error/exception_handler.dart';
import 'auth_interceptor.dart';
import 'logging_interceptors.dart';

class DioHelper {
  DioHelper._();

  static late Dio _dio;

  static void init({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    bool enableLogger = true,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 100 && status < 600;
        },
      ),
    );

    _addInterceptors(enableLogger);
  }

  static Dio get dio => _dio;

  static void _addInterceptors(bool enableLogger) {
    _dio.interceptors.add(AuthInterceptor());
    if (enableLogger) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Logs the real error, then maps it with your existing handler.
  static Object _handle(Object e, StackTrace st) {
    debugPrint('DIO raw error: $e');
    if (e is DioException) {
      debugPrint('DIO type=${e.type} status=${e.response?.statusCode}');
      debugPrint('DIO url=${e.requestOptions.uri}');
      debugPrint('DIO msg=${e.message} error=${e.error}');
    }
    debugPrint('$st');
    return handleException(e);
  }

  static Future<Response> get({
    required String path,
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: query,
        options: Options(extra: {'withAuth': withAuth}),
      );
    } catch (e, st) {
      throw _handle(e, st);
    }
  }

  static Future<Response> post({
    required String path,
    dynamic data,
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: query,
        options: Options(extra: {'withAuth': withAuth}),
      );
    } catch (e, st) {
      throw _handle(e, st);
    }
  }

  static Future<Response> put({
    required String path,
    dynamic data,
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: query,
        options: Options(extra: {'withAuth': withAuth}),
      );
    } catch (e, st) {
      throw _handle(e, st);
    }
  }

  static Future<Response> delete({
    required String path,
    dynamic data,
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: query,
        options: Options(extra: {'withAuth': withAuth}),
      );
    } catch (e, st) {
      throw _handle(e, st);
    }
  }

  static Future<Response> postFormData({
    required String path,
    required FormData formData,
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        queryParameters: query,
        options: Options(
          extra: {'withAuth': withAuth},
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e, st) {
      throw _handle(e, st);
    }
  }
}
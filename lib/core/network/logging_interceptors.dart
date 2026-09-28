import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    log('╔════════════════════════════════════════════════════════════');
    log('║ 🚀 REQUEST');
    log('║ Method : ${options.method}');
    log('║ URL    : ${options.uri}');
    log('║ Headers: ${options.headers}');

    if (options.queryParameters.isNotEmpty) {
      log('║ Query  : ${options.queryParameters}');
    }

    if (options.data != null) {
      log('║ Body   : ${const JsonEncoder.withIndent('  ').convert(options.data)}');
    }

    log('╚════════════════════════════════════════════════════════════');

    handler.next(options);
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    log('╔════════════════════════════════════════════════════════════');
    log('║ ✅ RESPONSE');
    log('║ Status : ${response.statusCode}');
    log('║ URL    : ${response.requestOptions.uri}');

    final data = response.data.toString();

    if (data.length > 1000) {
      log('║ Body   : ${data.substring(0, 1000)}...');
    } else {
      log('║ Body   : $data');
    }

    log('╚════════════════════════════════════════════════════════════');

    handler.next(response);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) {
    log('╔════════════════════════════════════════════════════════════');
    log('║ ❌ ERROR');
    log('║ Status : ${err.response?.statusCode}');
    log('║ Method : ${err.requestOptions.method}');
    log('║ URL    : ${err.requestOptions.uri}');
    log('║ Message: ${err.message}');

    if (err.response?.data != null) {
      log('║ Response: ${err.response?.data}');
    }

    log('╚════════════════════════════════════════════════════════════');

    handler.next(err);
  }
}
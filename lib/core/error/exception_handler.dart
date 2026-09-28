import 'package:dio/dio.dart';
import 'package:lynko/core/error/app_exception.dart';

Exception handleException(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');

      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');

      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 400:
            return ServerException(
              error.response?.data['message'] ?? 'Bad request',
            );

          case 401:
            return const UnauthorizedException();

          case 403:
            return const ForbiddenException();

          case 404:
            return const NotFoundException();

          case 422:
            return ValidationException(
              error.response?.data['message'] ?? 'Validation failed',
            );

          case 500:
          case 502:
          case 503:
            return const ServerException();

          default:
            return UnknownException(
              error.response?.data['message'] ?? 'Unexpected server error',
            );
        }

      case DioExceptionType.cancel:
        return const UnknownException('Request cancelled');

      default:
        return const UnknownException();
    }
  }

  return const UnknownException();
}

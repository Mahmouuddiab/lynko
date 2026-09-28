abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Access denied']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong']);
}
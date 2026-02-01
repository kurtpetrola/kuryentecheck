class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  AuthException(
    super.message, {
    super.code = 'auth-error',
    super.originalError,
  });
}

class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code = 'network-error',
    super.originalError,
  });
}

class ServerException extends AppException {
  ServerException(
    super.message, {
    super.code = 'server-error',
    super.originalError,
  });
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code = 'validation-error'});
}

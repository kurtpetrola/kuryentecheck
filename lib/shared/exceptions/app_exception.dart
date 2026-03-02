/// Base exception class for all application-specific errors
class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception thrown for authentication-related errors
class AuthException extends AppException {
  AuthException(
    super.message, {
    super.code = 'auth-error',
    super.originalError,
  });
}

/// Exception thrown for general network connectivity issues
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code = 'network-error',
    super.originalError,
  });
}

/// Exception thrown for backend server errors
class ServerException extends AppException {
  ServerException(
    super.message, {
    super.code = 'server-error',
    super.originalError,
  });
}

/// Exception thrown when user input validation fails
class ValidationException extends AppException {
  ValidationException(super.message, {super.code = 'validation-error'});
}

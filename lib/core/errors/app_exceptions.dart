class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = 'An unexpected error occurred', this.prefix]);

  @override
  String toString() {
    return prefix != null ? "$prefix: $message" : message;
  }
}

class NetworkException extends AppException {
  NetworkException([String message = 'Please check your internet connection'])
    : super(message, 'Network Error');
}

class ServerException extends AppException {
  ServerException([String message = 'Server returned an invalid response'])
    : super(message, 'Server Error');
}

class CacheException extends AppException {
  CacheException([String message = 'Failed to load data from cache'])
    : super(message, 'Cache Error');
}

class AuthException extends AppException {
  AuthException([String message = 'Authentication failed'])
    : super(message, 'Auth Error');
}

class ValidationException extends AppException {
  ValidationException([String message = 'Invalid input provided'])
    : super(message, 'Validation Error');
}

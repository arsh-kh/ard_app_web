/// Base exception class for the application.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code: $message)';
}

/// Exception from local database operations.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

/// Exception from network operations.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Exception from authentication operations.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Exception from sync operations.
class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.originalError});
}

/// Exception when offline and operation requires network.
class OfflineException extends AppException {
  const OfflineException([String message = 'No internet connection'])
      : super(message, code: 'OFFLINE');
}

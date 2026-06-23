import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  factory AppException.fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return AppException('err_permission_denied', e.code);
      case 'unavailable':
      case 'network-request-failed':
        return AppException('noInternetConnection', e.code);
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppException('err_invalid_credentials', e.code);
      case 'email-already-in-use':
        return AppException('err_email_in_use', e.code);
      case 'weak-password':
        return AppException('weakPassword', e.code);
      default:
        return AppException('errorPrefix', e.code); // Fallback to generic error
    }
  }

  @override
  String toString() => message;
}

/// Base failure class for domain-level error handling.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure($code: $message)';
}

/// Failure from the local database.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Failure from network/Firebase operations.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Failure from authentication operations.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Failure from sync operations.
class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});
}

/// Failure from validation.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Failure when a resource is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Failure from permission/authorization issues.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// Failure for insufficient stock.
class InsufficientStockFailure extends Failure {
  final String productName;
  final double availableStock;
  final double requestedQuantity;

  const InsufficientStockFailure({
    required this.productName,
    required this.availableStock,
    required this.requestedQuantity,
  }) : super(
          'Insufficient stock for $productName. Available: $availableStock, Requested: $requestedQuantity',
        );
}

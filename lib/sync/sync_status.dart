/// Re-export the canonical SyncStatus from the database tables.
/// This file previously defined a conflicting SyncStatus enum with
/// `pending` instead of `pendingSync`. All code should use the
/// single definition from tables.dart.
export '../data/local_database/tables.dart' show SyncStatus;

/// Overall sync state for the application UI.
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncTime;
  final String? lastError;

  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncTime,
    this.lastError,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Returns true if everything is synced and no errors.
  bool get isFullySynced => pendingCount == 0 && failedCount == 0;

  /// Returns a human-readable status label.
  String get statusLabel {
    if (isSyncing) return 'Syncing...';
    if (!isOnline) return 'Offline';
    if (failedCount > 0) return '$failedCount failed';
    if (pendingCount > 0) return '$pendingCount pending';
    return 'All synced';
  }
}

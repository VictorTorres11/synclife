import 'package:equatable/equatable.dart';

/// Represents the current synchronization status
class SyncStatus extends Equatable {
  const SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingOperations,
    this.lastSyncTime,
    this.lastError,
  });

  final bool isOnline;
  final bool isSyncing;
  final int pendingOperations;
  final DateTime? lastSyncTime;
  final String? lastError;

  SyncStatus copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingOperations,
    DateTime? lastSyncTime,
    String? lastError,
  }) =>
      SyncStatus(
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        pendingOperations: pendingOperations ?? this.pendingOperations,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        lastError: lastError ?? this.lastError,
      );

  @override
  List<Object?> get props => [
        isOnline,
        isSyncing,
        pendingOperations,
        lastSyncTime,
        lastError,
      ];
}

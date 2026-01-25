import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/tasks/data/services/firebase_task_service.dart';
import '../../../features/tasks/data/services/offline_task_service.dart';
import '../../../features/tasks/domain/services/task_service.dart';
import '../models/sync_status.dart';
import '../services/compression_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/connectivity_service.dart';
import '../services/incremental_sync_service.dart';
import '../services/local_database_service.dart';
import '../services/retry_service.dart';
import '../services/sync_service.dart';

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl();
});

/// Provider for local database service
final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseServiceImpl();
});

/// Provider for remote task service (Firebase)
final remoteTaskServiceProvider = Provider<TaskService>((ref) {
  return FirebaseTaskService();
});

/// Provider for conflict resolution service
final conflictResolutionServiceProvider =
    Provider<ConflictResolutionService>((ref) {
  return ConflictResolutionServiceImpl();
});

/// Provider for compression service
final compressionServiceProvider = Provider<CompressionService>((ref) {
  return CompressionServiceImpl();
});

/// Provider for incremental sync service
final incrementalSyncServiceProvider = Provider<IncrementalSyncService>((ref) {
  final localDatabase = ref.read(localDatabaseServiceProvider);
  final compressionService = ref.read(compressionServiceProvider);

  return IncrementalSyncServiceImpl(
    localDatabase: localDatabase,
    compressionService: compressionService,
  );
});

/// Provider for retry service
final retryServiceProvider = Provider<RetryService>((ref) {
  return RetryServiceImpl();
});

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final connectivityService = ref.read(connectivityServiceProvider);
  final localDatabase = ref.read(localDatabaseServiceProvider);
  final remoteTaskService = ref.read(remoteTaskServiceProvider);
  final conflictResolutionService = ref.read(conflictResolutionServiceProvider);
  final compressionService = ref.read(compressionServiceProvider);
  final incrementalSyncService = ref.read(incrementalSyncServiceProvider);
  final retryService = ref.read(retryServiceProvider);

  return SyncServiceImpl(
    connectivityService: connectivityService,
    localDatabase: localDatabase,
    remoteTaskService: remoteTaskService,
    conflictResolutionService: conflictResolutionService,
    compressionService: compressionService,
    incrementalSyncService: incrementalSyncService,
    retryService: retryService,
  );
});

/// Provider for offline-first task service
final offlineTaskServiceProvider = Provider<TaskService>((ref) {
  final remoteTaskService = ref.read(remoteTaskServiceProvider);

  // For web platform, use Firebase service directly (no local database)
  if (kIsWeb) {
    return remoteTaskService;
  }

  // For mobile platforms, use offline-first service
  final localDatabase = ref.read(localDatabaseServiceProvider);
  final syncService = ref.read(syncServiceProvider);

  return OfflineTaskService(
    remoteTaskService: remoteTaskService,
    localDatabase: localDatabase,
    syncService: syncService,
  );
});

/// Provider for sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return syncService.syncStatus;
});

/// Provider for connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.read(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});

/// Provider for initializing sync services
final syncInitializationProvider = FutureProvider<void>((ref) async {
  // For web platform, skip sync service initialization (no local database)
  if (kIsWeb) {
    return;
  }

  // For mobile platforms, initialize sync service
  final syncService = ref.read(syncServiceProvider);
  await syncService.initialize();
});

/// Provider for pending operations count
final pendingOperationsCountProvider = Provider<int>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return syncStatus.when(
    data: (status) => status.pendingOperations,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for checking if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityStatus = ref.watch(connectivityStatusProvider);
  return connectivityStatus.when(
    data: (isOnline) => isOnline,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return syncStatus.when(
    data: (status) => status.isSyncing,
    loading: () => false,
    error: (_, __) => false,
  );
});

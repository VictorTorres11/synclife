import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../features/tasks/domain/models/task.dart';
import '../../../features/tasks/domain/models/update_task_request.dart';
import '../../../features/tasks/domain/services/task_service.dart';
import '../models/sync_conflict.dart';
import '../models/sync_delta.dart';
import '../models/sync_operation.dart';
import '../models/sync_status.dart';
import 'compression_service.dart';
import 'conflict_resolution_service.dart';
import 'connectivity_service.dart';
import 'incremental_sync_service.dart';
import 'local_database_service.dart';
import 'retry_service.dart';

/// Service for managing offline-first synchronization
abstract class SyncService {
  /// Current sync status
  Stream<SyncStatus> get syncStatus;

  /// Check if device is currently online
  bool get isOnline;

  /// Initialize the sync service
  Future<void> initialize();

  /// Queue a sync operation for later processing
  Future<void> queueOperation(SyncOperation operation);

  /// Sync all pending operations
  Future<void> syncPendingOperations();

  /// Force a full sync
  Future<void> forceSync();

  /// Perform incremental sync using deltas
  Future<void> incrementalSync({DateTime? since});

  /// Get sync optimization statistics
  Future<SyncOptimizationStats> getOptimizationStats();

  /// Dispose resources
  void dispose();
}

/// Implementation of SyncService with offline-first capabilities and optimizations
class SyncServiceImpl implements SyncService {
  SyncServiceImpl({
    required ConnectivityService connectivityService,
    required LocalDatabaseService localDatabase,
    required TaskService remoteTaskService,
    required ConflictResolutionService conflictResolutionService,
    required CompressionService compressionService,
    required IncrementalSyncService incrementalSyncService,
    required RetryService retryService,
  })  : _connectivityService = connectivityService,
        _localDatabase = localDatabase,
        _remoteTaskService = remoteTaskService,
        _conflictResolutionService = conflictResolutionService,
        _compressionService = compressionService,
        _incrementalSyncService = incrementalSyncService,
        _retryService = retryService {
    _syncStatusController = StreamController<SyncStatus>.broadcast();
    _currentStatus = const SyncStatus(
      isOnline: false,
      isSyncing: false,
      pendingOperations: 0,
    );
  }

  final ConnectivityService _connectivityService;
  final LocalDatabaseService _localDatabase;
  final TaskService _remoteTaskService;
  final ConflictResolutionService _conflictResolutionService;
  final CompressionService _compressionService;
  final IncrementalSyncService _incrementalSyncService;
  final RetryService _retryService;

  late final StreamController<SyncStatus> _syncStatusController;
  late SyncStatus _currentStatus;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _cleanupTimer;
  bool _isInitialized = false;
  DateTime? _lastIncrementalSync;

  // Enhanced retry configuration with priority-based configs
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _incrementalSyncInterval = Duration(minutes: 1);
  static const Duration _cleanupInterval = Duration(hours: 24);

  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  @override
  bool get isOnline => _currentStatus.isOnline;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _localDatabase.initialize();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _onConnectivityChanged,
    );

    // Check initial connectivity
    final initialConnectivity = await _connectivityService.isOnline;
    await _onConnectivityChanged(initialConnectivity);

    // Set up periodic sync when online
    _setupPeriodicSync();

    // Set up cleanup timer for old data
    _setupCleanupTimer();

    _isInitialized = true;
  }

  void _setupPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_currentStatus.isOnline && !_currentStatus.isSyncing) {
        // Prefer incremental sync for efficiency
        if (_lastIncrementalSync != null) {
          incrementalSync(since: _lastIncrementalSync);
        } else {
          syncPendingOperations();
        }
      }
    });
  }

  void _setupCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) async {
      // Clean up old deltas and conflicts
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      await _localDatabase.cleanupOldDeltas(cutoffDate);
      await _localDatabase.deleteOldConflicts(cutoffDate);
    });
  }

  Future<void> _onConnectivityChanged(bool isOnline) async {
    final wasOnline = _currentStatus.isOnline;

    _currentStatus = _currentStatus.copyWith(isOnline: isOnline);
    _emitStatus();

    // If we just came online, sync pending operations
    if (isOnline && !wasOnline) {
      await syncPendingOperations();
    }
  }

  @override
  Future<void> queueOperation(SyncOperation operation) async {
    // Enhance operation with compression if needed
    final enhancedOperation = await _enhanceOperation(operation);

    await _localDatabase.insertSyncOperation(enhancedOperation);

    final pendingCount = await _localDatabase.getPendingSyncOperationsCount();
    _currentStatus = _currentStatus.copyWith(pendingOperations: pendingCount);
    _emitStatus();

    // If online, try to sync immediately with priority handling
    if (_currentStatus.isOnline && !_currentStatus.isSyncing) {
      if (operation.priority == SyncPriority.critical) {
        // Critical operations sync immediately
        unawaited(syncPendingOperations());
      } else if (operation.priority == SyncPriority.high) {
        // High priority operations sync with short delay
        unawaited(Future.delayed(
          const Duration(seconds: 1),
          syncPendingOperations,
        ));
      }
      // Normal and low priority operations wait for periodic sync
    }
  }

  Future<SyncOperation> _enhanceOperation(SyncOperation operation) async {
    // Add compression if data is large enough
    if (_compressionService.shouldCompress(operation.data)) {
      final compressedData = await _compressionService.compress(operation.data);

      return operation.copyWith(
        data: compressedData.toMap(),
        isCompressed: true,
        checksum: compressedData.checksum,
      );
    }

    return operation;
  }

  @override
  Future<void> syncPendingOperations() async {
    if (_currentStatus.isSyncing || !_currentStatus.isOnline) {
      return;
    }

    _currentStatus = _currentStatus.copyWith(isSyncing: true);
    _emitStatus();

    try {
      final operations = await _localDatabase.getPendingSyncOperations();

      // Sort operations by priority and timestamp
      operations.sort((a, b) {
        final priorityComparison = _comparePriority(a.priority, b.priority);
        if (priorityComparison != 0) return priorityComparison;
        return a.timestamp.compareTo(b.timestamp);
      });

      // Try to optimize operations using incremental sync
      final optimizationStats =
          await _incrementalSyncService.calculateOptimization(operations);

      debugPrint('Sync optimization: $optimizationStats');

      for (final operation in operations) {
        try {
          await _processSyncOperationWithRetry(operation);
          await _localDatabase.deleteSyncOperation(operation.id);
        } catch (e) {
          debugPrint('Failed to sync operation ${operation.id}: $e');

          // Update retry count and error
          final updatedOperation = operation.copyWith(
            retryCount: operation.retryCount + 1,
            lastError: e.toString(),
          );

          // Use retry service to determine if we should continue retrying
          final retryConfig = _getRetryConfigForPriority(operation.priority);
          if (updatedOperation.retryCount >= retryConfig.maxRetries) {
            // Max retries reached, remove operation
            await _localDatabase.deleteSyncOperation(operation.id);
            debugPrint(
                'Max retries reached for operation ${operation.id}, removing');
          } else {
            // Update operation with retry info
            await _localDatabase.updateSyncOperation(updatedOperation);
          }
        }
      }

      final pendingCount = await _localDatabase.getPendingSyncOperationsCount();
      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        pendingOperations: pendingCount,
        lastSyncTime: DateTime.now(),
        lastError: null,
      );

      // Update last incremental sync time
      _lastIncrementalSync = DateTime.now();
    } catch (e) {
      debugPrint('Sync failed: $e');
      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    }

    _emitStatus();
  }

  int _comparePriority(SyncPriority a, SyncPriority b) {
    const priorityOrder = {
      SyncPriority.critical: 0,
      SyncPriority.high: 1,
      SyncPriority.normal: 2,
      SyncPriority.low: 3,
    };

    return (priorityOrder[a] ?? 2).compareTo(priorityOrder[b] ?? 2);
  }

  RetryConfig _getRetryConfigForPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return RetryConfig.critical();
      case SyncPriority.high:
        return RetryConfig.highPriority();
      case SyncPriority.low:
        return RetryConfig.lowPriority();
      case SyncPriority.normal:
        return const RetryConfig();
    }
  }

  Future<void> _processSyncOperationWithRetry(SyncOperation operation) async {
    final retryConfig = _getRetryConfigForPriority(operation.priority);

    return _retryService.executeWithRetry(
      () => _processSyncOperation(operation),
      config: retryConfig,
    );
  }

  Future<void> _processSyncOperation(SyncOperation operation) async {
    // Decompress data if needed
    Map<String, dynamic> operationData = operation.data;

    if (operation.isCompressed) {
      try {
        final compressedData = CompressedData.fromMap(operation.data);
        operationData = await _compressionService.decompress(compressedData);
      } catch (e) {
        debugPrint('Failed to decompress operation data: $e');
        rethrow;
      }
    }

    // Create a new operation with decompressed data for processing
    final processableOperation = operation.copyWith(
      data: operationData,
      isCompressed: false,
    );

    switch (processableOperation.type) {
      case SyncOperationType.createTask:
        await _syncCreateTask(processableOperation.data);
        break;
      case SyncOperationType.updateTask:
        await _syncUpdateTask(processableOperation.data);
        break;
      case SyncOperationType.deleteTask:
        await _syncDeleteTask(processableOperation.data);
        break;
      case SyncOperationType.completeTask:
        await _syncCompleteTask(processableOperation.data);
        break;
      case SyncOperationType.createBoard:
      case SyncOperationType.updateBoard:
      case SyncOperationType.joinBoard:
      case SyncOperationType.leaveBoard:
        // TODO: Implement board sync operations
        debugPrint('Board sync operations not yet implemented');
        break;
    }
  }

  Future<void> _syncCreateTask(Map<String, dynamic> data) async {
    // TODO: Implement proper CreateTaskRequest conversion
    // For now, we'll skip this operation as it requires proper request object creation
    debugPrint('Create task sync operation not yet fully implemented');
  }

  Future<void> _syncUpdateTask(Map<String, dynamic> data) async {
    final taskId = data['taskId'] as String;
    final localTask = await _localDatabase.getTask(taskId);

    if (localTask == null) {
      debugPrint('Local task not found for update sync: $taskId');
      return;
    }

    try {
      // Get the current remote version
      final remoteTask = await _remoteTaskService.getTask(taskId);

      if (remoteTask == null) {
        debugPrint('Remote task not found: $taskId');
        return;
      }

      // Check for conflicts
      final conflictType = _conflictResolutionService.detectTaskConflict(
        localTask,
        remoteTask,
      );

      Task taskToUpdate;
      if (conflictType != null) {
        // Resolve the conflict
        taskToUpdate = await _conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          conflictType,
        );

        // Log the conflict to database for monitoring
        final conflict = SyncConflict(
          id: '${taskId}_${DateTime.now().millisecondsSinceEpoch}',
          entityType: SyncEntityType.task,
          entityId: taskId,
          conflictType: conflictType,
          localData: localTask.toMap(),
          remoteData: remoteTask.toMap(),
          timestamp: DateTime.now(),
          resolution: ConflictResolution.lastWriteWins,
          resolvedAt: DateTime.now(),
        );
        await _localDatabase.insertConflict(conflict);
      } else {
        // No conflict, use local version
        taskToUpdate = localTask;
      }

      // Update the remote task
      final updateRequest = UpdateTaskRequest(
        title: taskToUpdate.title,
        description: taskToUpdate.description,
        assignedTo: taskToUpdate.assignedTo,
        recurrence: taskToUpdate.recurrence,
        dueDate: taskToUpdate.dueDate,
        isCompleted: taskToUpdate.isCompleted,
        tags: taskToUpdate.tags,
      );
      await _remoteTaskService.updateTask(taskId, updateRequest);

      // Update local task with the resolved version
      await _localDatabase.updateTask(taskToUpdate);
    } catch (e) {
      debugPrint('Failed to sync update task $taskId: $e');
      rethrow;
    }
  }

  Future<void> _syncDeleteTask(Map<String, dynamic> data) async {
    final taskId = data['taskId'] as String;
    await _remoteTaskService.deleteTask(taskId);
  }

  Future<void> _syncCompleteTask(Map<String, dynamic> data) async {
    final taskId = data['taskId'] as String;
    final localTask = await _localDatabase.getTask(taskId);

    if (localTask == null) {
      debugPrint('Local task not found for completion sync: $taskId');
      return;
    }

    try {
      // Get the current remote version
      final remoteTask = await _remoteTaskService.getTask(taskId);

      if (remoteTask == null) {
        debugPrint('Remote task not found: $taskId');
        return;
      }

      // Check specifically for completion status conflicts
      final conflictType = _conflictResolutionService.detectTaskConflict(
        localTask,
        remoteTask,
      );

      Task taskToComplete;
      if (conflictType == ConflictType.completionStatusConflict) {
        // Resolve using last-write-wins strategy
        taskToComplete = await _conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.completionStatusConflict,
        );

        // Log the conflict
        final conflict = SyncConflict(
          id: '${taskId}_completion_${DateTime.now().millisecondsSinceEpoch}',
          entityType: SyncEntityType.task,
          entityId: taskId,
          conflictType: ConflictType.completionStatusConflict,
          localData: localTask.toMap(),
          remoteData: remoteTask.toMap(),
          timestamp: DateTime.now(),
          resolution: ConflictResolution.lastWriteWins,
          resolvedAt: DateTime.now(),
        );
        await _localDatabase.insertConflict(conflict);
      } else {
        // No conflict, use local completion status
        taskToComplete = localTask;
      }

      // Update the remote task with resolved completion status
      await _remoteTaskService.completeTask(taskId);

      // Update local task
      await _localDatabase.updateTask(taskToComplete.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Failed to sync complete task $taskId: $e');
      rethrow;
    }
  }

  @override
  Future<void> forceSync() async {
    if (!_currentStatus.isOnline) {
      throw StateError('Cannot force sync while offline');
    }

    await syncPendingOperations();
  }

  @override
  Future<void> incrementalSync({DateTime? since}) async {
    if (!_currentStatus.isOnline) {
      debugPrint('Cannot perform incremental sync while offline');
      return;
    }

    if (_currentStatus.isSyncing) {
      debugPrint('Sync already in progress, skipping incremental sync');
      return;
    }

    _currentStatus = _currentStatus.copyWith(isSyncing: true);
    _emitStatus();

    try {
      final sinceTime = since ??
          _lastIncrementalSync ??
          DateTime.now().subtract(const Duration(hours: 24));

      // Get deltas since last sync
      final deltas = await _localDatabase.getDeltasSince(sinceTime);

      if (deltas.isNotEmpty) {
        debugPrint('Performing incremental sync with ${deltas.length} deltas');

        // Create delta batch for efficient processing
        final deltaBatch =
            await _incrementalSyncService.createDeltaBatch(deltas);

        // Apply deltas (this would normally send to server)
        await _incrementalSyncService.applyDeltas(deltas);

        debugPrint('Incremental sync completed successfully');
      }

      _lastIncrementalSync = DateTime.now();

      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastError: null,
      );
    } catch (e) {
      debugPrint('Incremental sync failed: $e');
      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    }

    _emitStatus();
  }

  @override
  Future<SyncOptimizationStats> getOptimizationStats() async {
    final operations = await _localDatabase.getPendingSyncOperations();
    return _incrementalSyncService.calculateOptimization(operations);
  }

  void _emitStatus() {
    _syncStatusController.add(_currentStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _cleanupTimer?.cancel();
    _syncStatusController.close();
    _connectivityService.dispose();
  }
}

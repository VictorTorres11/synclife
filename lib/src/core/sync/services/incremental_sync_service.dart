import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/sync_delta.dart';
import '../models/sync_operation.dart';
import 'compression_service.dart';
import 'local_database_service.dart';

/// Service for managing incremental synchronization
abstract class IncrementalSyncService {
  /// Create a delta for an entity change
  Future<SyncDelta> createDelta({
    required String entityId,
    required String entityType,
    required SyncChangeType changeType,
    required Map<String, dynamic> changes,
    String? previousVersion,
    String? currentVersion,
  });

  /// Create a batch of deltas for efficient processing
  Future<SyncDeltaBatch> createDeltaBatch(List<SyncDelta> deltas);

  /// Apply deltas to local data
  Future<void> applyDeltas(List<SyncDelta> deltas);

  /// Get deltas since a specific timestamp
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp);

  /// Optimize sync operations by converting to deltas
  Future<List<SyncDelta>> optimizeSyncOperations(
    List<SyncOperation> operations,
  );

  /// Calculate the size reduction from using deltas
  Future<SyncOptimizationStats> calculateOptimization(
    List<SyncOperation> operations,
  );
}

/// Implementation of IncrementalSyncService
class IncrementalSyncServiceImpl implements IncrementalSyncService {
  IncrementalSyncServiceImpl({
    required LocalDatabaseService localDatabase,
    required CompressionService compressionService,
  })  : _localDatabase = localDatabase,
        _compressionService = compressionService;

  final LocalDatabaseService _localDatabase;
  final CompressionService _compressionService;

  @override
  Future<SyncDelta> createDelta({
    required String entityId,
    required String entityType,
    required SyncChangeType changeType,
    required Map<String, dynamic> changes,
    String? previousVersion,
    String? currentVersion,
  }) async {
    return SyncDelta(
      entityId: entityId,
      entityType: entityType,
      changeType: changeType,
      timestamp: DateTime.now(),
      changes: changes,
      previousVersion: previousVersion,
      currentVersion: currentVersion,
    );
  }

  @override
  Future<SyncDeltaBatch> createDeltaBatch(List<SyncDelta> deltas) async {
    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';

    // Check if batch should be compressed
    final batchData = {
      'deltas': deltas.map((d) => d.toMap()).toList(),
    };

    final shouldCompress = _compressionService.shouldCompress(batchData);
    String? checksum;

    if (shouldCompress) {
      final compressedData = await _compressionService.compress(batchData);
      checksum = compressedData.checksum;
    }

    return SyncDeltaBatch(
      id: batchId,
      deltas: deltas,
      timestamp: DateTime.now(),
      isCompressed: shouldCompress,
      checksum: checksum,
    );
  }

  @override
  Future<void> applyDeltas(List<SyncDelta> deltas) async {
    // Sort deltas by timestamp to ensure correct order
    final sortedDeltas = List<SyncDelta>.from(deltas)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final delta in sortedDeltas) {
      try {
        await _applyDelta(delta);
      } catch (e) {
        debugPrint('Failed to apply delta ${delta.entityId}: $e');
        // Continue with other deltas even if one fails
      }
    }
  }

  Future<void> _applyDelta(SyncDelta delta) async {
    switch (delta.entityType.toLowerCase()) {
      case 'task':
        await _applyTaskDelta(delta);
        break;
      case 'board':
        await _applyBoardDelta(delta);
        break;
      default:
        debugPrint('Unknown entity type for delta: ${delta.entityType}');
    }
  }

  Future<void> _applyTaskDelta(SyncDelta delta) async {
    switch (delta.changeType) {
      case SyncChangeType.create:
        // Create new task from delta changes
        await _localDatabase.insertTaskFromDelta(delta);
        break;
      case SyncChangeType.update:
      case SyncChangeType.fieldUpdate:
        // Update existing task with delta changes
        await _localDatabase.updateTaskFromDelta(delta);
        break;
      case SyncChangeType.delete:
        // Delete task
        await _localDatabase.deleteTask(delta.entityId);
        break;
    }
  }

  Future<void> _applyBoardDelta(SyncDelta delta) async {
    switch (delta.changeType) {
      case SyncChangeType.create:
        await _localDatabase.insertBoardFromDelta(delta);
        break;
      case SyncChangeType.update:
      case SyncChangeType.fieldUpdate:
        await _localDatabase.updateBoardFromDelta(delta);
        break;
      case SyncChangeType.delete:
        await _localDatabase.deleteBoard(delta.entityId);
        break;
    }
  }

  @override
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp) async {
    return _localDatabase.getDeltasSince(timestamp);
  }

  @override
  Future<List<SyncDelta>> optimizeSyncOperations(
    List<SyncOperation> operations,
  ) async {
    final deltas = <SyncDelta>[];

    // Group operations by entity
    final operationsByEntity = <String, List<SyncOperation>>{};
    for (final operation in operations) {
      final entityId = _extractEntityId(operation);
      if (entityId != null) {
        operationsByEntity.putIfAbsent(entityId, () => []).add(operation);
      }
    }

    // Convert operations to deltas
    for (final entry in operationsByEntity.entries) {
      final entityId = entry.key;
      final entityOperations = entry.value;

      // Sort operations by timestamp
      entityOperations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Merge operations into deltas
      final entityDeltas = await _mergeOperationsToDeltas(
        entityId,
        entityOperations,
      );
      deltas.addAll(entityDeltas);
    }

    return deltas;
  }

  String? _extractEntityId(SyncOperation operation) {
    switch (operation.type) {
      case SyncOperationType.createTask:
      case SyncOperationType.updateTask:
      case SyncOperationType.deleteTask:
      case SyncOperationType.completeTask:
        return operation.data['taskId'] as String?;
      case SyncOperationType.createBoard:
      case SyncOperationType.updateBoard:
      case SyncOperationType.joinBoard:
      case SyncOperationType.leaveBoard:
        return operation.data['boardId'] as String?;
    }
  }

  Future<List<SyncDelta>> _mergeOperationsToDeltas(
    String entityId,
    List<SyncOperation> operations,
  ) async {
    final deltas = <SyncDelta>[];
    Map<String, dynamic>? previousState;

    for (final operation in operations) {
      final delta = await _operationToDelta(operation, previousState);
      if (delta != null) {
        deltas.add(delta);
        previousState = delta.changes;
      }
    }

    return deltas;
  }

  Future<SyncDelta?> _operationToDelta(
    SyncOperation operation,
    Map<String, dynamic>? previousState,
  ) async {
    final entityId = _extractEntityId(operation);
    if (entityId == null) return null;

    final entityType = _getEntityType(operation.type);
    final changeType = _getChangeType(operation.type);

    // Calculate only the changed fields
    final changes = <String, dynamic>{};

    if (previousState != null) {
      // Compare with previous state to find actual changes
      for (final entry in operation.data.entries) {
        if (previousState[entry.key] != entry.value) {
          changes[entry.key] = entry.value;
        }
      }
    } else {
      // First operation, include all data
      changes.addAll(operation.data);
    }

    // Skip if no actual changes
    if (changes.isEmpty && changeType != SyncChangeType.delete) {
      return null;
    }

    return SyncDelta(
      entityId: entityId,
      entityType: entityType,
      changeType: changeType,
      timestamp: operation.timestamp,
      changes: changes,
    );
  }

  String _getEntityType(SyncOperationType operationType) {
    switch (operationType) {
      case SyncOperationType.createTask:
      case SyncOperationType.updateTask:
      case SyncOperationType.deleteTask:
      case SyncOperationType.completeTask:
        return 'task';
      case SyncOperationType.createBoard:
      case SyncOperationType.updateBoard:
      case SyncOperationType.joinBoard:
      case SyncOperationType.leaveBoard:
        return 'board';
    }
  }

  SyncChangeType _getChangeType(SyncOperationType operationType) {
    switch (operationType) {
      case SyncOperationType.createTask:
      case SyncOperationType.createBoard:
        return SyncChangeType.create;
      case SyncOperationType.updateTask:
      case SyncOperationType.updateBoard:
      case SyncOperationType.joinBoard:
      case SyncOperationType.leaveBoard:
        return SyncChangeType.update;
      case SyncOperationType.deleteTask:
        return SyncChangeType.delete;
      case SyncOperationType.completeTask:
        return SyncChangeType.fieldUpdate;
    }
  }

  @override
  Future<SyncOptimizationStats> calculateOptimization(
    List<SyncOperation> operations,
  ) async {
    if (operations.isEmpty) {
      return const SyncOptimizationStats(
        originalOperations: 0,
        optimizedDeltas: 0,
        originalSizeBytes: 0,
        optimizedSizeBytes: 0,
      );
    }

    // Calculate original size
    final originalSize = operations.fold<int>(
      0,
      (sum, op) => sum + op.toMap().toString().length,
    );

    // Convert to deltas
    final deltas = await optimizeSyncOperations(operations);

    // Calculate optimized size
    final optimizedSize = deltas.fold<int>(
      0,
      (sum, delta) => sum + delta.toMap().toString().length,
    );

    return SyncOptimizationStats(
      originalOperations: operations.length,
      optimizedDeltas: deltas.length,
      originalSizeBytes: originalSize,
      optimizedSizeBytes: optimizedSize,
    );
  }
}

/// Statistics about sync optimization
class SyncOptimizationStats {
  const SyncOptimizationStats({
    required this.originalOperations,
    required this.optimizedDeltas,
    required this.originalSizeBytes,
    required this.optimizedSizeBytes,
  });

  final int originalOperations;
  final int optimizedDeltas;
  final int originalSizeBytes;
  final int optimizedSizeBytes;

  /// Reduction in number of operations
  int get operationReduction => originalOperations - optimizedDeltas;

  /// Reduction in data size
  int get sizeReduction => originalSizeBytes - optimizedSizeBytes;

  /// Percentage reduction in operations
  double get operationReductionPercentage => originalOperations > 0
      ? (operationReduction / originalOperations) * 100
      : 0.0;

  /// Percentage reduction in size
  double get sizeReductionPercentage =>
      originalSizeBytes > 0 ? (sizeReduction / originalSizeBytes) * 100 : 0.0;

  @override
  String toString() => 'SyncOptimizationStats('
      'operations: $originalOperations → $optimizedDeltas '
      '(${operationReductionPercentage.toStringAsFixed(1)}% reduction), '
      'size: ${originalSizeBytes}B → ${optimizedSizeBytes}B '
      '(${sizeReductionPercentage.toStringAsFixed(1)}% reduction))';
}

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../../features/tasks/domain/models/task.dart';
import '../models/sync_conflict.dart';

/// Service for resolving synchronization conflicts
abstract class ConflictResolutionService {
  /// Resolve a task conflict using the configured strategy
  Future<Task> resolveTaskConflict(
    Task localTask,
    Task remoteTask,
    ConflictType conflictType,
  );

  /// Detect conflicts between local and remote tasks
  ConflictType? detectTaskConflict(Task localTask, Task remoteTask);

  /// Log a conflict for debugging and monitoring
  void logConflict(SyncConflict conflict);

  /// Get conflict resolution statistics
  Map<String, int> getConflictStats();
}

/// Implementation of ConflictResolutionService
class ConflictResolutionServiceImpl implements ConflictResolutionService {
  ConflictResolutionServiceImpl() : _conflictStats = {};

  final Map<String, int> _conflictStats;

  @override
  Future<Task> resolveTaskConflict(
    Task localTask,
    Task remoteTask,
    ConflictType conflictType,
  ) async {
    // Create conflict record for logging
    final conflict = SyncConflict(
      id: '${localTask.id}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: SyncEntityType.task,
      entityId: localTask.id,
      conflictType: conflictType,
      localData: localTask.toMap(),
      remoteData: remoteTask.toMap(),
      timestamp: DateTime.now(),
    );

    Task resolvedTask;
    ConflictResolution resolution;

    switch (conflictType) {
      case ConflictType.completionStatusConflict:
        // Apply last-write-wins strategy for completion status
        resolvedTask = _resolveCompletionStatusConflict(localTask, remoteTask);
        resolution = ConflictResolution.lastWriteWins;
        break;

      case ConflictType.concurrentModification:
        // Merge non-conflicting data
        resolvedTask = _mergeTasks(localTask, remoteTask);
        resolution = ConflictResolution.merged;
        break;

      case ConflictType.deleteModifyConflict:
        // Remote was modified, local was deleted - keep remote
        resolvedTask = remoteTask;
        resolution = ConflictResolution.useRemote;
        break;

      case ConflictType.modifyDeleteConflict:
        // Local was modified, remote was deleted - keep local
        resolvedTask = localTask;
        resolution = ConflictResolution.useLocal;
        break;
    }

    // Log the resolved conflict
    final resolvedConflict = conflict.copyWith(
      resolution: resolution,
      resolvedAt: DateTime.now(),
    );
    logConflict(resolvedConflict);

    return resolvedTask;
  }

  @override
  ConflictType? detectTaskConflict(Task localTask, Task remoteTask) {
    // Check if both tasks have the same ID but different data
    if (localTask.id != remoteTask.id) {
      return null; // Not the same task
    }

    // Check for completion status conflicts
    if (localTask.isCompleted != remoteTask.isCompleted) {
      return ConflictType.completionStatusConflict;
    }

    // Check for concurrent modifications (different updatedAt times)
    if (localTask.updatedAt != remoteTask.updatedAt) {
      // Check if other fields are different
      if (_hasContentDifferences(localTask, remoteTask)) {
        return ConflictType.concurrentModification;
      }
    }

    return null; // No conflict detected
  }

  @override
  void logConflict(SyncConflict conflict) {
    // Update statistics
    final conflictKey =
        '${conflict.conflictType.name}_${conflict.resolution?.name ?? 'unresolved'}';
    _conflictStats[conflictKey] = (_conflictStats[conflictKey] ?? 0) + 1;

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Sync Conflict Resolved:');
      debugPrint(
          '  Entity: ${conflict.entityType.name} (${conflict.entityId})');
      debugPrint('  Type: ${conflict.conflictType.name}');
      debugPrint('  Resolution: ${conflict.resolution?.name ?? 'unresolved'}');
      debugPrint('  Timestamp: ${conflict.timestamp}');
    }

    // Log to developer console for production monitoring
    developer.log(
      'Sync conflict resolved',
      name: 'ConflictResolution',
      error: {
        'entityType': conflict.entityType.name,
        'entityId': conflict.entityId,
        'conflictType': conflict.conflictType.name,
        'resolution': conflict.resolution?.name,
        'timestamp': conflict.timestamp.toIso8601String(),
      },
    );
  }

  @override
  Map<String, int> getConflictStats() => Map.from(_conflictStats);

  /// Resolve completion status conflict using last-write-wins strategy
  Task _resolveCompletionStatusConflict(Task localTask, Task remoteTask) {
    // Use the task with the most recent updatedAt timestamp
    final useRemote = remoteTask.updatedAt.isAfter(localTask.updatedAt);

    if (useRemote) {
      // Remote is newer, use remote completion status but merge other fields
      return _mergeTasks(localTask, remoteTask).copyWith(
        isCompleted: remoteTask.isCompleted,
        updatedAt: remoteTask.updatedAt,
      );
    } else {
      // Local is newer, use local completion status but merge other fields
      return _mergeTasks(localTask, remoteTask).copyWith(
        isCompleted: localTask.isCompleted,
        updatedAt: localTask.updatedAt,
      );
    }
  }

  /// Merge two tasks, preferring the most recent data for each field
  Task _mergeTasks(Task localTask, Task remoteTask) {
    // For most fields, use last-write-wins based on updatedAt
    final useRemoteAsBase = remoteTask.updatedAt.isAfter(localTask.updatedAt);
    final baseTask = useRemoteAsBase ? remoteTask : localTask;
    final otherTask = useRemoteAsBase ? localTask : remoteTask;

    // Merge specific fields intelligently
    return baseTask.copyWith(
      // Keep the most recent title and description
      title: baseTask.title,
      description: baseTask.description,

      // Merge tags (union of both sets)
      tags: _mergeTags(localTask.tags, remoteTask.tags),

      // Keep the most recent assignment
      assignedTo: baseTask.assignedTo,

      // Keep the most recent due date
      dueDate: baseTask.dueDate,

      // Use the latest updatedAt timestamp
      updatedAt: useRemoteAsBase ? remoteTask.updatedAt : localTask.updatedAt,
    );
  }

  /// Merge tags from both tasks, removing duplicates
  List<String> _mergeTags(List<String> localTags, List<String> remoteTags) {
    final mergedTags = <String>{};
    mergedTags.addAll(localTags);
    mergedTags.addAll(remoteTags);
    return mergedTags.toList()..sort();
  }

  /// Check if two tasks have content differences (excluding timestamps)
  bool _hasContentDifferences(Task localTask, Task remoteTask) {
    return localTask.title != remoteTask.title ||
        localTask.description != remoteTask.description ||
        localTask.assignedTo != remoteTask.assignedTo ||
        localTask.dueDate != remoteTask.dueDate ||
        !_areTagsEqual(localTask.tags, remoteTask.tags) ||
        localTask.recurrence != remoteTask.recurrence;
  }

  /// Check if two tag lists are equal (order-independent)
  bool _areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) return false;
    final set1 = Set<String>.from(tags1);
    final set2 = Set<String>.from(tags2);
    return set1.containsAll(set2) && set2.containsAll(set1);
  }
}

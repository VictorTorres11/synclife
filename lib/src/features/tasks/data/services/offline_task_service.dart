import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/sync/models/sync_operation.dart';
import '../../../../core/sync/services/local_database_service.dart';
import '../../../../core/sync/services/sync_service.dart';
import '../../domain/models/create_task_request.dart';
import '../../domain/models/task.dart';
import '../../domain/models/update_task_request.dart';
import '../../domain/services/task_service.dart';

/// Offline-first implementation of TaskService
/// This service prioritizes local data and queues operations for sync
class OfflineTaskService implements TaskService {
  OfflineTaskService({
    required TaskService remoteTaskService,
    required LocalDatabaseService localDatabase,
    required SyncService syncService,
  })  : _remoteTaskService = remoteTaskService,
        _localDatabase = localDatabase,
        _syncService = syncService;

  final TaskService _remoteTaskService;
  final LocalDatabaseService _localDatabase;
  final SyncService _syncService;

  @override
  Future<List<Task>> getTasks(String boardId) async {
    try {
      // Ensure database is initialized
      await _localDatabase.initialize();

      // Always return local data first for immediate response
      final localTasks = await _localDatabase.getTasks(boardId);

      // If online, try to fetch from remote and update local cache
      if (_syncService.isOnline) {
        try {
          final remoteTasks = await _remoteTaskService.getTasks(boardId);

          // Update local cache with remote data
          for (final task in remoteTasks) {
            await _localDatabase.insertTask(task);
          }

          return remoteTasks;
        } catch (e) {
          debugPrint('Failed to fetch remote tasks, using local cache: $e');
          return localTasks;
        }
      }

      return localTasks;
    } catch (e) {
      debugPrint('Failed to get tasks: $e');
      return [];
    }
  }

  @override
  Future<Task?> getTask(String taskId) async {
    try {
      // Ensure database is initialized
      await _localDatabase.initialize();

      // Try local database first
      final localTask = await _localDatabase.getTask(taskId);

      // If online, try to get the latest version from remote
      if (_syncService.isOnline) {
        try {
          final remoteTask = await _remoteTaskService.getTask(taskId);

          if (remoteTask != null) {
            // Update local cache with remote data
            await _localDatabase.insertTask(remoteTask);
            return remoteTask;
          }
        } catch (e) {
          debugPrint('Failed to fetch remote task, using local cache: $e');
        }
      }

      return localTask;
    } catch (e) {
      debugPrint('Failed to get task: $e');
      return null;
    }
  }

  @override
  Future<Task> createTask(CreateTaskRequest request) async {
    // Ensure database is initialized
    await _localDatabase.initialize();

    // Generate a temporary ID for offline creation
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final task = Task(
      id: tempId,
      title: request.title,
      description: request.description,
      boardId: request.boardId,
      assignedTo: request.assignedTo,
      recurrence: request.recurrence,
      dueDate: request.dueDate,
      isCompleted: false,
      tags: request.tags,
      createdAt: now,
      updatedAt: now,
      createdBy: request.createdBy,
    );

    // Save to local database immediately
    await _localDatabase.insertTask(task);

    // Queue sync operation
    final syncOperation = SyncOperation(
      id: 'create_task_$tempId',
      type: SyncOperationType.createTask,
      data: task.toMap(),
      timestamp: now,
    );

    await _syncService.queueOperation(syncOperation);

    return task;
  }

  @override
  Future<Task> updateTask(String taskId, UpdateTaskRequest request) async {
    // Get current task from local database
    final currentTask = await _localDatabase.getTask(taskId);
    if (currentTask == null) {
      throw StateError('Task not found: $taskId');
    }

    // Create updated task
    final updatedTask = currentTask.copyWith(
      title: request.title ?? currentTask.title,
      description: request.description ?? currentTask.description,
      assignedTo: request.assignedTo ?? currentTask.assignedTo,
      recurrence: request.recurrence ?? currentTask.recurrence,
      dueDate: request.dueDate ?? currentTask.dueDate,
      isCompleted: request.isCompleted ?? currentTask.isCompleted,
      tags: request.tags ?? currentTask.tags,
      updatedAt: DateTime.now(),
    );

    // Update local database
    await _localDatabase.updateTask(updatedTask);

    // Queue sync operation
    final syncOperation = SyncOperation(
      id: 'update_task_$taskId',
      type: SyncOperationType.updateTask,
      data: {
        'id': taskId,
        'updates': request.toMap(),
      },
      timestamp: DateTime.now(),
    );

    await _syncService.queueOperation(syncOperation);

    return updatedTask;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Remove from local database
    await _localDatabase.deleteTask(taskId);

    // Queue sync operation
    final syncOperation = SyncOperation(
      id: 'delete_task_$taskId',
      type: SyncOperationType.deleteTask,
      data: {'taskId': taskId},
      timestamp: DateTime.now(),
    );

    await _syncService.queueOperation(syncOperation);
  }

  @override
  Future<void> completeTask(String taskId) async {
    // Get current task
    final currentTask = await _localDatabase.getTask(taskId);
    if (currentTask == null) {
      throw StateError('Task not found: $taskId');
    }

    // Update task as completed
    final completedTask = currentTask.copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
    );

    await _localDatabase.updateTask(completedTask);

    // Queue sync operation
    final syncOperation = SyncOperation(
      id: 'complete_task_$taskId',
      type: SyncOperationType.completeTask,
      data: {'taskId': taskId},
      timestamp: DateTime.now(),
    );

    await _syncService.queueOperation(syncOperation);
  }

  @override
  Stream<List<Task>> watchTasks(String boardId) {
    // For offline-first, we'll implement a simple polling mechanism
    // In a more sophisticated implementation, you might use database triggers
    // or a more complex reactive system

    return Stream.periodic(const Duration(seconds: 1), (_) => boardId)
        .asyncMap((boardId) => getTasks(boardId))
        .distinct();
  }

  @override
  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      final allTasks = await _localDatabase.getAllTasks();
      return allTasks.where((task) => task.assignedTo == userId).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by user: $e');
      return [];
    }
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    try {
      final allTasks = await _localDatabase.getAllTasks();
      return allTasks.where((task) {
        final dueDate = task.dueDate;
        if (dueDate == null) return false;
        return dueDate.isAfter(start) && dueDate.isBefore(end);
      }).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by date range: $e');
      return [];
    }
  }

  @override
  Future<List<Task>> getTasksByTags(List<String> tags) async {
    try {
      final allTasks = await _localDatabase.getAllTasks();
      return allTasks.where((task) {
        return task.tags.any((tag) => tags.contains(tag));
      }).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by tags: $e');
      return [];
    }
  }
}

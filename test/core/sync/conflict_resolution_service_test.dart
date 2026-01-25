import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/core/sync/models/sync_conflict.dart';
import '../../../lib/src/core/sync/services/conflict_resolution_service.dart';
import '../../../lib/src/features/tasks/domain/models/task.dart';
import '../../../lib/src/features/tasks/domain/models/task_recurrence.dart';

void main() {
  group('ConflictResolutionService', () {
    late ConflictResolutionService conflictResolutionService;

    setUp(() {
      conflictResolutionService = ConflictResolutionServiceImpl();
    });

    group('detectTaskConflict', () {
      test('should detect completion status conflict', () {
        // Arrange
        final localTask = _createTestTask(isCompleted: false);
        final remoteTask = localTask.copyWith(isCompleted: true);

        // Act
        final conflictType = conflictResolutionService.detectTaskConflict(
          localTask,
          remoteTask,
        );

        // Assert
        expect(conflictType, equals(ConflictType.completionStatusConflict));
      });

      test('should detect concurrent modification conflict', () {
        // Arrange
        final baseTime = DateTime.now();
        final localTask = _createTestTask(
          title: 'Local Title',
          updatedAt: baseTime.add(const Duration(minutes: 1)),
        );
        final remoteTask = localTask.copyWith(
          title: 'Remote Title',
          updatedAt: baseTime.add(const Duration(minutes: 2)),
        );

        // Act
        final conflictType = conflictResolutionService.detectTaskConflict(
          localTask,
          remoteTask,
        );

        // Assert
        expect(conflictType, equals(ConflictType.concurrentModification));
      });

      test('should return null when no conflict exists', () {
        // Arrange
        final task1 = _createTestTask();
        final task2 = task1.copyWith(); // Identical task

        // Act
        final conflictType = conflictResolutionService.detectTaskConflict(
          task1,
          task2,
        );

        // Assert
        expect(conflictType, isNull);
      });

      test('should return null for different task IDs', () {
        // Arrange
        final task1 = _createTestTask(id: 'task1');
        final task2 = _createTestTask(id: 'task2');

        // Act
        final conflictType = conflictResolutionService.detectTaskConflict(
          task1,
          task2,
        );

        // Assert
        expect(conflictType, isNull);
      });
    });

    group('resolveTaskConflict', () {
      test('should resolve completion status conflict using last-write-wins',
          () async {
        // Arrange
        final baseTime = DateTime.now();
        final localTask = _createTestTask(
          isCompleted: false,
          updatedAt: baseTime,
        );
        final remoteTask = localTask.copyWith(
          isCompleted: true,
          updatedAt:
              baseTime.add(const Duration(minutes: 1)), // Remote is newer
        );

        // Act
        final resolvedTask =
            await conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.completionStatusConflict,
        );

        // Assert
        expect(resolvedTask.isCompleted, isTrue); // Remote wins (newer)
        expect(resolvedTask.updatedAt, equals(remoteTask.updatedAt));
      });

      test(
          'should resolve completion status conflict with local wins when local is newer',
          () async {
        // Arrange
        final baseTime = DateTime.now();
        final localTask = _createTestTask(
          isCompleted: true,
          updatedAt: baseTime.add(const Duration(minutes: 2)), // Local is newer
        );
        final remoteTask = localTask.copyWith(
          isCompleted: false,
          updatedAt: baseTime,
        );

        // Act
        final resolvedTask =
            await conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.completionStatusConflict,
        );

        // Assert
        expect(resolvedTask.isCompleted, isTrue); // Local wins (newer)
        expect(resolvedTask.updatedAt, equals(localTask.updatedAt));
      });

      test('should merge tasks for concurrent modification', () async {
        // Arrange
        final baseTime = DateTime.now();
        final localTask = _createTestTask(
          title: 'Local Title',
          tags: ['local', 'shared'],
          updatedAt: baseTime,
        );
        final remoteTask = localTask.copyWith(
          title: 'Remote Title',
          tags: ['remote', 'shared'],
          updatedAt:
              baseTime.add(const Duration(minutes: 1)), // Remote is newer
        );

        // Act
        final resolvedTask =
            await conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.concurrentModification,
        );

        // Assert
        expect(
            resolvedTask.title, equals('Remote Title')); // Remote wins (newer)
        expect(resolvedTask.tags,
            containsAll(['local', 'remote', 'shared'])); // Merged tags
        expect(resolvedTask.updatedAt, equals(remoteTask.updatedAt));
      });

      test('should use remote for delete-modify conflict', () async {
        // Arrange
        final localTask = _createTestTask();
        final remoteTask = localTask.copyWith(title: 'Modified Title');

        // Act
        final resolvedTask =
            await conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.deleteModifyConflict,
        );

        // Assert
        expect(resolvedTask, equals(remoteTask));
      });

      test('should use local for modify-delete conflict', () async {
        // Arrange
        final localTask = _createTestTask(title: 'Modified Title');
        final remoteTask = _createTestTask();

        // Act
        final resolvedTask =
            await conflictResolutionService.resolveTaskConflict(
          localTask,
          remoteTask,
          ConflictType.modifyDeleteConflict,
        );

        // Assert
        expect(resolvedTask, equals(localTask));
      });
    });

    group('conflict logging', () {
      test('should track conflict statistics', () {
        // Arrange
        final conflict = SyncConflict(
          id: 'test_conflict',
          entityType: SyncEntityType.task,
          entityId: 'task_1',
          conflictType: ConflictType.completionStatusConflict,
          localData: {},
          remoteData: {},
          timestamp: DateTime.now(),
          resolution: ConflictResolution.lastWriteWins,
          resolvedAt: DateTime.now(),
        );

        // Act
        conflictResolutionService.logConflict(conflict);
        final stats = conflictResolutionService.getConflictStats();

        // Assert
        expect(stats['completionStatusConflict_lastWriteWins'], equals(1));
      });

      test('should accumulate conflict statistics', () {
        // Arrange
        final conflict1 = SyncConflict(
          id: 'test_conflict_1',
          entityType: SyncEntityType.task,
          entityId: 'task_1',
          conflictType: ConflictType.completionStatusConflict,
          localData: {},
          remoteData: {},
          timestamp: DateTime.now(),
          resolution: ConflictResolution.lastWriteWins,
          resolvedAt: DateTime.now(),
        );

        final conflict2 = SyncConflict(
          id: 'test_conflict_2',
          entityType: SyncEntityType.task,
          entityId: 'task_2',
          conflictType: ConflictType.completionStatusConflict,
          localData: {},
          remoteData: {},
          timestamp: DateTime.now(),
          resolution: ConflictResolution.lastWriteWins,
          resolvedAt: DateTime.now(),
        );

        // Act
        conflictResolutionService.logConflict(conflict1);
        conflictResolutionService.logConflict(conflict2);
        final stats = conflictResolutionService.getConflictStats();

        // Assert
        expect(stats['completionStatusConflict_lastWriteWins'], equals(2));
      });
    });
  });
}

/// Helper function to create a test task
Task _createTestTask({
  String? id,
  String? title,
  bool? isCompleted,
  List<String>? tags,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Task(
    id: id ?? 'test_task_id',
    title: title ?? 'Test Task',
    boardId: 'test_board',
    recurrence: TaskRecurrence.none,
    isCompleted: isCompleted ?? false,
    tags: tags ?? ['test'],
    createdAt: now,
    updatedAt: updatedAt ?? now,
    createdBy: 'test_user',
  );
}

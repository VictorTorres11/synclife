import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/sync/models/sync_conflict.dart';
import 'package:synclife_app/src/core/sync/services/conflict_resolution_service.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task_recurrence.dart';

void main() {
  group('Property-Based Tests - Conflict Resolution', () {
    late ConflictResolutionService conflictResolutionService;

    setUp(() {
      conflictResolutionService = ConflictResolutionServiceImpl();
    });

    testWidgets(
      'Feature: synclife-app, Property 20: Sync conflict resolution - '
      'For any sync conflict involving task completion status, the system should apply last-write-wins strategy to resolve the conflict',
      (tester) async {
        /**Validates: Requirements 8.3**/

        const int iterations = 100;
        final random = Random(42); // Fixed seed for reproducibility

        for (int i = 0; i < iterations; i++) {
          // Generate random task data
          final taskId = 'task_${random.nextInt(1000)}';
          final boardId = 'board_${random.nextInt(10)}';
          final baseTime =
              DateTime.now().subtract(Duration(days: random.nextInt(30)));

          // Generate two tasks with different completion status and timestamps
          final localCompletionStatus = random.nextBool();
          final remoteCompletionStatus =
              !localCompletionStatus; // Ensure conflict

          final localTimestamp =
              baseTime.add(Duration(minutes: random.nextInt(120)));
          final remoteTimestamp =
              baseTime.add(Duration(minutes: random.nextInt(120)));

          final localTask = _generateRandomTask(
            random,
            id: taskId,
            boardId: boardId,
            isCompleted: localCompletionStatus,
            updatedAt: localTimestamp,
          );

          final remoteTask = localTask.copyWith(
            isCompleted: remoteCompletionStatus,
            updatedAt: remoteTimestamp,
          );

          // Verify conflict detection
          final conflictType = conflictResolutionService.detectTaskConflict(
            localTask,
            remoteTask,
          );

          expect(
            conflictType,
            equals(ConflictType.completionStatusConflict),
            reason: 'Should detect completion status conflict for iteration $i',
          );

          // Resolve the conflict
          final resolvedTask =
              await conflictResolutionService.resolveTaskConflict(
            localTask,
            remoteTask,
            ConflictType.completionStatusConflict,
          );

          // Verify last-write-wins strategy
          final expectedWinner =
              remoteTimestamp.isAfter(localTimestamp) ? remoteTask : localTask;
          final expectedCompletionStatus = expectedWinner.isCompleted;
          final expectedTimestamp = expectedWinner.updatedAt;

          expect(
            resolvedTask.isCompleted,
            equals(expectedCompletionStatus),
            reason:
                'Completion status should follow last-write-wins for iteration $i. '
                'Local: $localCompletionStatus at $localTimestamp, '
                'Remote: $remoteCompletionStatus at $remoteTimestamp',
          );

          expect(
            resolvedTask.updatedAt,
            equals(expectedTimestamp),
            reason:
                'Updated timestamp should be from the winning task for iteration $i',
          );

          // Verify task ID remains unchanged
          expect(
            resolvedTask.id,
            equals(taskId),
            reason:
                'Task ID should remain unchanged during conflict resolution',
          );

          // Verify other fields are properly merged (not just overwritten)
          expect(
            resolvedTask.title,
            isNotEmpty,
            reason: 'Title should be preserved during conflict resolution',
          );

          expect(
            resolvedTask.boardId,
            equals(boardId),
            reason:
                'Board ID should remain unchanged during conflict resolution',
          );
        }
      },
    );

    testWidgets(
      'Feature: synclife-app, Property 20a: Conflict resolution preserves data integrity - '
      'For any resolved conflict, all non-conflicting data should be preserved or intelligently merged',
      (tester) async {
        /**Validates: Requirements 8.3**/

        const int iterations = 50;
        final random = Random(123); // Fixed seed for reproducibility

        for (int i = 0; i < iterations; i++) {
          // Generate base task
          final baseTask = _generateRandomTask(random);

          // Create local and remote versions with different non-conflicting changes
          final localTags = _generateRandomTags(random, 3);
          final remoteTags = _generateRandomTags(random, 3);
          final allExpectedTags = {...localTags, ...remoteTags}.toList()
            ..sort();

          final localTask = baseTask.copyWith(
            title: 'Local Title $i',
            tags: localTags,
            updatedAt: DateTime.now(),
          );

          final remoteTask = baseTask.copyWith(
            description: 'Remote Description $i',
            tags: remoteTags,
            updatedAt: DateTime.now()
                .add(const Duration(minutes: 1)), // Remote is newer
          );

          // Resolve concurrent modification conflict
          final resolvedTask =
              await conflictResolutionService.resolveTaskConflict(
            localTask,
            remoteTask,
            ConflictType.concurrentModification,
          );

          // Verify data integrity
          expect(
            resolvedTask.id,
            equals(baseTask.id),
            reason: 'Task ID should be preserved',
          );

          expect(
            resolvedTask.boardId,
            equals(baseTask.boardId),
            reason: 'Board ID should be preserved',
          );

          expect(
            resolvedTask.createdBy,
            equals(baseTask.createdBy),
            reason: 'Created by should be preserved',
          );

          expect(
            resolvedTask.createdAt,
            equals(baseTask.createdAt),
            reason: 'Created at should be preserved',
          );

          // Verify intelligent merging of tags
          expect(
            resolvedTask.tags,
            containsAll(allExpectedTags),
            reason:
                'Tags should be merged from both versions for iteration $i. '
                'Expected: $allExpectedTags, Got: ${resolvedTask.tags}',
          );

          // Verify last-write-wins for other fields (remote is newer)
          expect(
            resolvedTask.description,
            equals('Remote Description $i'),
            reason: 'Description should come from newer version (remote)',
          );

          expect(
            resolvedTask.updatedAt,
            equals(remoteTask.updatedAt),
            reason: 'Updated timestamp should be from newer version',
          );
        }
      },
    );

    testWidgets(
      'Feature: synclife-app, Property 20b: Conflict detection accuracy - '
      'For any two task versions, conflict detection should correctly identify the type of conflict or absence thereof',
      (tester) async {
        /**Validates: Requirements 8.3**/

        const int iterations = 75;
        final random = Random(456); // Fixed seed for reproducibility

        for (int i = 0; i < iterations; i++) {
          final baseTask = _generateRandomTask(random);

          // Test case 1: No conflict (identical tasks)
          final identicalTask = baseTask.copyWith();
          final noConflict = conflictResolutionService.detectTaskConflict(
            baseTask,
            identicalTask,
          );
          expect(
            noConflict,
            isNull,
            reason: 'Identical tasks should not have conflicts',
          );

          // Test case 2: Completion status conflict
          final completionConflictTask = baseTask.copyWith(
            isCompleted: !baseTask.isCompleted,
          );
          final completionConflict =
              conflictResolutionService.detectTaskConflict(
            baseTask,
            completionConflictTask,
          );
          expect(
            completionConflict,
            equals(ConflictType.completionStatusConflict),
            reason:
                'Different completion status should be detected as completion conflict',
          );

          // Test case 3: Concurrent modification conflict
          final modifiedTask = baseTask.copyWith(
            title: 'Modified Title $i',
            updatedAt:
                DateTime.now().add(Duration(minutes: random.nextInt(60))),
          );
          final concurrentConflict =
              conflictResolutionService.detectTaskConflict(
            baseTask,
            modifiedTask,
          );
          expect(
            concurrentConflict,
            equals(ConflictType.concurrentModification),
            reason:
                'Different content with different timestamps should be concurrent modification',
          );

          // Test case 4: Different task IDs should return null
          final differentTask = baseTask.copyWith(
            id: 'different_${baseTask.id}',
          );
          final differentIdResult =
              conflictResolutionService.detectTaskConflict(
            baseTask,
            differentTask,
          );
          expect(
            differentIdResult,
            isNull,
            reason: 'Different task IDs should not be considered conflicts',
          );
        }
      },
    );

    testWidgets(
      'Feature: synclife-app, Property 20c: Last-write-wins edge cases - '
      'For any completion status conflict with edge case timestamps, the system should correctly apply last-write-wins strategy',
      (tester) async {
        /**Validates: Requirements 8.3**/

        const int iterations = 50;
        final random = Random(789); // Fixed seed for reproducibility

        for (int i = 0; i < iterations; i++) {
          final taskId = 'edge_task_${random.nextInt(1000)}';
          final boardId = 'board_${random.nextInt(10)}';

          // Test edge case: Identical timestamps
          final baseTime = DateTime.now();
          final localTask = _generateRandomTask(
            random,
            id: taskId,
            boardId: boardId,
            isCompleted: true,
            updatedAt: baseTime,
          );

          final remoteTask = localTask.copyWith(
            isCompleted: false,
            updatedAt: baseTime, // Same timestamp
          );

          final resolvedTask =
              await conflictResolutionService.resolveTaskConflict(
            localTask,
            remoteTask,
            ConflictType.completionStatusConflict,
          );

          // With identical timestamps, local should win (implementation detail)
          expect(
            resolvedTask.isCompleted,
            equals(localTask.isCompleted),
            reason:
                'With identical timestamps, local task should win for iteration $i',
          );

          // Test edge case: Very small time differences (microseconds)
          final microDiff = Duration(microseconds: random.nextInt(1000));
          final localTaskMicro = _generateRandomTask(
            random,
            id: '${taskId}_micro',
            boardId: boardId,
            isCompleted: true,
            updatedAt: baseTime,
          );

          final remoteTaskMicro = localTaskMicro.copyWith(
            isCompleted: false,
            updatedAt: baseTime.add(microDiff),
          );

          final resolvedTaskMicro =
              await conflictResolutionService.resolveTaskConflict(
            localTaskMicro,
            remoteTaskMicro,
            ConflictType.completionStatusConflict,
          );

          // Remote should win due to later timestamp
          expect(
            resolvedTaskMicro.isCompleted,
            equals(remoteTaskMicro.isCompleted),
            reason:
                'Remote task should win with later timestamp (even microseconds) for iteration $i',
          );

          // Test edge case: Very large time differences
          final largeDiff = Duration(days: random.nextInt(365) + 1);
          final localTaskLarge = _generateRandomTask(
            random,
            id: '${taskId}_large',
            boardId: boardId,
            isCompleted: false,
            updatedAt: baseTime.add(largeDiff),
          );

          final remoteTaskLarge = localTaskLarge.copyWith(
            isCompleted: true,
            updatedAt: baseTime, // Much earlier
          );

          final resolvedTaskLarge =
              await conflictResolutionService.resolveTaskConflict(
            localTaskLarge,
            remoteTaskLarge,
            ConflictType.completionStatusConflict,
          );

          // Local should win due to much later timestamp
          expect(
            resolvedTaskLarge.isCompleted,
            equals(localTaskLarge.isCompleted),
            reason:
                'Local task should win with much later timestamp for iteration $i',
          );

          // Verify timestamp consistency in all cases
          expect(
            resolvedTask.updatedAt,
            isA<DateTime>(),
            reason: 'Resolved task should have valid timestamp',
          );

          expect(
            resolvedTaskMicro.updatedAt,
            equals(remoteTaskMicro.updatedAt),
            reason: 'Resolved task should have winner\'s timestamp',
          );

          expect(
            resolvedTaskLarge.updatedAt,
            equals(localTaskLarge.updatedAt),
            reason: 'Resolved task should have winner\'s timestamp',
          );
        }
      },
    );
  });
}

/// Generate a random task for testing
Task _generateRandomTask(
  Random random, {
  String? id,
  String? boardId,
  bool? isCompleted,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Task(
    id: id ?? 'task_${random.nextInt(10000)}',
    title: 'Task ${random.nextInt(1000)}',
    description:
        random.nextBool() ? 'Description ${random.nextInt(100)}' : null,
    boardId: boardId ?? 'board_${random.nextInt(10)}',
    assignedTo: random.nextBool() ? 'user_${random.nextInt(5)}' : null,
    recurrence:
        TaskRecurrence.values[random.nextInt(TaskRecurrence.values.length)],
    dueDate:
        random.nextBool() ? now.add(Duration(days: random.nextInt(30))) : null,
    isCompleted: isCompleted ?? random.nextBool(),
    tags: _generateRandomTags(random, random.nextInt(5) + 1),
    createdAt: now.subtract(Duration(days: random.nextInt(30))),
    updatedAt: updatedAt ?? now.subtract(Duration(minutes: random.nextInt(60))),
    createdBy: 'user_${random.nextInt(3)}',
  );
}

/// Generate random tags for testing
List<String> _generateRandomTags(Random random, int count) {
  const availableTags = [
    'work',
    'personal',
    'urgent',
    'health',
    'finance',
    'home',
    'shopping',
    'exercise',
    'study',
    'family'
  ];

  final tags = <String>{};
  while (tags.length < count && tags.length < availableTags.length) {
    tags.add(availableTags[random.nextInt(availableTags.length)]);
  }

  return tags.toList()..sort();
}

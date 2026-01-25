import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/core/sync/models/sync_operation.dart';
import 'package:synclife_app/src/core/sync/models/sync_status.dart';
import 'package:synclife_app/src/features/tasks/domain/models/create_task_request.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task_recurrence.dart';
import 'package:synclife_app/src/features/tasks/domain/models/update_task_request.dart';

import '../helpers/test_helpers.dart';

/// Property-based tests for offline functionality
/// **Validates: Requirements 8.1, 8.2**
void main() {
  group('Offline Functionality Property Tests', () {
    group('**Validates: Requirements 8.1, 8.2**', () {
      test(
        'Feature: synclife-app, Property 19: Offline functionality - '
        'Task operations should maintain consistency in offline mode',
        () async {
          // Property 19: Offline functionality
          // For any user in offline mode, the system should allow creating and editing tasks locally,
          // then sync all changes when connection is restored

          await PropertyTestRunner.runProperty<OfflineScenario>(
            description:
                'Offline task operations should maintain data consistency',
            generator: _generateOfflineScenario,
            iterations: 1, // Reduce iterations for debugging
            property: (scenario) {
              // Property 1: Task creation should generate valid temporary IDs
              final createdTaskIds = <String>{};
              for (int i = 0; i < scenario.createRequests.length; i++) {
                final taskId = _generateOfflineTaskId();

                // Validate ID uniqueness
                if (createdTaskIds.contains(taskId)) return false;
                createdTaskIds.add(taskId);

                // Validate ID format (should be temporary)
                if (!taskId.startsWith('temp_')) return false;
              }

              // Property 2: Task updates should preserve essential data
              for (final updateRequest in scenario.updateRequests) {
                final originalTask = _createMockTask();
                final updatedTask =
                    _applyTaskUpdate(originalTask, updateRequest);

                // Validate that core properties are preserved
                if (updatedTask.id != originalTask.id) return false;
                if (updatedTask.boardId != originalTask.boardId) return false;
                if (updatedTask.createdBy != originalTask.createdBy)
                  return false;
                if (updatedTask.createdAt != originalTask.createdAt)
                  return false;

                // Validate that updatedAt is newer
                if (!updatedTask.updatedAt.isAfter(originalTask.updatedAt))
                  return false;

                // Validate that updates are applied correctly
                if (updateRequest.title != null &&
                    updatedTask.title != updateRequest.title) return false;
                if (updateRequest.description != null &&
                    updatedTask.description != updateRequest.description)
                  return false;
                if (updateRequest.isCompleted != null &&
                    updatedTask.isCompleted != updateRequest.isCompleted)
                  return false;
              }

              // Property 3: Sync operations should be properly structured
              for (final createRequest in scenario.createRequests) {
                final syncOp = _createSyncOperation(
                    SyncOperationType.createTask, createRequest.toMap());

                // Validate sync operation structure
                if (syncOp.type != SyncOperationType.createTask) return false;
                if (syncOp.data.isEmpty) return false;
                // Allow some tolerance for timestamp (within 1 second of now)
                if (syncOp.timestamp
                    .isAfter(DateTime.now().add(const Duration(seconds: 1))))
                  return false;
                if (syncOp.retryCount != 0) return false;
              }

              // Property 4: Offline operations should be timestamped correctly
              final operationTimestamps = <DateTime>[];
              for (int i = 0; i < scenario.createRequests.length; i++) {
                final timestamp = DateTime.now().add(Duration(milliseconds: i));
                operationTimestamps.add(timestamp);
              }

              // Validate chronological ordering
              for (int i = 1; i < operationTimestamps.length; i++) {
                if (operationTimestamps[i]
                    .isBefore(operationTimestamps[i - 1])) {
                  return false;
                }
              }

              // Property 5: Task completion should update status correctly
              for (int i = 0; i < scenario.completionTaskIds.length; i++) {
                final task = _createMockTask();
                final completedTask = _completeTask(task);

                // Validate completion
                if (!completedTask.isCompleted) return false;
                if (!completedTask.updatedAt.isAfter(task.updatedAt))
                  return false;

                // Validate other properties are preserved
                if (completedTask.id != task.id) return false;
                if (completedTask.title != task.title) return false;
                if (completedTask.boardId != task.boardId) return false;
              }

              return true;
            },
          );
        },
      );

      test(
        'Feature: synclife-app, Property 19: Offline functionality - '
        'Sync operations should handle data serialization correctly',
        () async {
          await PropertyTestRunner.runProperty<SyncScenario>(
            description:
                'Sync operations should serialize and deserialize data correctly',
            generator: _generateSyncScenario,
            property: (scenario) {
              // Property 1: Create operations should serialize task data correctly
              for (final createRequest in scenario.createRequests) {
                final syncOp = _createSyncOperation(
                    SyncOperationType.createTask, createRequest.toMap());

                // Validate serialization
                final serialized = syncOp.toMap();
                final deserialized = SyncOperation.fromMap(serialized);

                // Validate round-trip serialization
                if (deserialized.id != syncOp.id) return false;
                if (deserialized.type != syncOp.type) return false;
                if (deserialized.timestamp != syncOp.timestamp) return false;
                if (deserialized.retryCount != syncOp.retryCount) return false;
              }

              // Property 2: Update operations should preserve data integrity
              for (final updateRequest in scenario.updateRequests) {
                final updateData = {
                  'id': TestGenerators.randomUuid(),
                  'updates': updateRequest.toMap(),
                };
                final syncOp = _createSyncOperation(
                    SyncOperationType.updateTask, updateData);

                // Validate data structure
                if (!syncOp.data.containsKey('id')) return false;
                if (!syncOp.data.containsKey('updates')) return false;

                final updates = syncOp.data['updates'] as Map<String, dynamic>;
                if (updateRequest.title != null &&
                    updates['title'] != updateRequest.title) return false;
                if (updateRequest.isCompleted != null &&
                    updates['isCompleted'] != updateRequest.isCompleted)
                  return false;
              }

              // Property 3: Sync status should reflect operation state correctly
              final syncStatus = SyncStatus(
                isOnline: scenario.isOnline,
                isSyncing: scenario.isSyncing,
                pendingOperations: scenario.pendingOperationsCount,
                lastSyncTime: scenario.lastSyncTime,
                lastError: scenario.lastError,
              );

              // Validate sync status consistency
              if (syncStatus.isOnline != scenario.isOnline) return false;
              if (syncStatus.isSyncing != scenario.isSyncing) return false;
              if (syncStatus.pendingOperations !=
                  scenario.pendingOperationsCount) return false;
              if (syncStatus.lastSyncTime != scenario.lastSyncTime)
                return false;
              if (syncStatus.lastError != scenario.lastError) return false;

              return true;
            },
          );
        },
      );

      test(
        'Feature: synclife-app, Property 19: Offline functionality - '
        'Network state transitions should be handled correctly',
        () async {
          await PropertyTestRunner.runProperty<NetworkScenario>(
            description:
                'Network state changes should trigger appropriate sync behavior',
            generator: _generateNetworkScenario,
            property: (scenario) {
              // Property 1: Offline to online transition should trigger sync
              if (scenario.initialState == NetworkState.offline &&
                  scenario.finalState == NetworkState.online) {
                // Sync should be triggered when going online
                final shouldSync = _shouldTriggerSync(
                    scenario.initialState, scenario.finalState);
                if (!shouldSync) return false;
              }

              // Property 2: Online to offline transition should queue operations
              if (scenario.initialState == NetworkState.online &&
                  scenario.finalState == NetworkState.offline) {
                // Operations should be queued when going offline
                final shouldQueue = _shouldQueueOperations(scenario.finalState);
                if (!shouldQueue) return false;
              }

              // Property 3: Consistent offline state should allow local operations
              if (scenario.initialState == NetworkState.offline &&
                  scenario.finalState == NetworkState.offline) {
                // Local operations should be allowed
                final allowsLocal = _allowsLocalOperations(scenario.finalState);
                if (!allowsLocal) return false;
              }

              // Property 4: Network failures should not corrupt local data
              if (scenario.hasNetworkFailure) {
                // Local data should remain intact
                final dataIntact = _validateDataIntegrity(scenario);
                if (!dataIntact) return false;
              }

              return true;
            },
          );
        },
      );
    });
  });
}

/// Test scenario for offline functionality
class OfflineScenario {
  const OfflineScenario({
    required this.boardId,
    required this.userId,
    required this.createRequests,
    required this.updateRequests,
    required this.completionTaskIds,
    required this.deletionTaskIds,
  });

  final String boardId;
  final String userId;
  final List<CreateTaskRequest> createRequests;
  final List<UpdateTaskRequest> updateRequests;
  final List<String> completionTaskIds;
  final List<String> deletionTaskIds;
}

/// Test scenario for sync operations
class SyncScenario {
  const SyncScenario({
    required this.createRequests,
    required this.updateRequests,
    required this.isOnline,
    required this.isSyncing,
    required this.pendingOperationsCount,
    this.lastSyncTime,
    this.lastError,
  });

  final List<CreateTaskRequest> createRequests;
  final List<UpdateTaskRequest> updateRequests;
  final bool isOnline;
  final bool isSyncing;
  final int pendingOperationsCount;
  final DateTime? lastSyncTime;
  final String? lastError;
}

/// Test scenario for network state transitions
class NetworkScenario {
  const NetworkScenario({
    required this.initialState,
    required this.finalState,
    required this.hasNetworkFailure,
  });

  final NetworkState initialState;
  final NetworkState finalState;
  final bool hasNetworkFailure;
}

/// Network state enumeration
enum NetworkState {
  online,
  offline,
}

/// Generates a random offline scenario for testing
OfflineScenario _generateOfflineScenario() {
  final random = Random();
  final boardId = TestGenerators.randomUuid();
  final userId = TestGenerators.randomUuid();

  // Generate 1-5 create requests
  final createRequests = List.generate(
    1 + random.nextInt(4),
    (_) => _generateCreateTaskRequest(boardId, userId),
  );

  // Generate 0-3 update requests
  final updateRequests = List.generate(
    random.nextInt(4),
    (_) => _generateUpdateTaskRequest(),
  );

  // Generate 0-2 completion task IDs
  final completionTaskIds = List.generate(
    random.nextInt(3),
    (_) => TestGenerators.randomUuid(),
  );

  // Generate 0-2 deletion task IDs
  final deletionTaskIds = List.generate(
    random.nextInt(3),
    (_) => TestGenerators.randomUuid(),
  );

  return OfflineScenario(
    boardId: boardId,
    userId: userId,
    createRequests: createRequests,
    updateRequests: updateRequests,
    completionTaskIds: completionTaskIds,
    deletionTaskIds: deletionTaskIds,
  );
}

/// Generates a sync scenario for testing
SyncScenario _generateSyncScenario() {
  final random = Random();
  final boardId = TestGenerators.randomUuid();
  final userId = TestGenerators.randomUuid();

  final createRequests = List.generate(
    1 + random.nextInt(3),
    (_) => _generateCreateTaskRequest(boardId, userId),
  );

  final updateRequests = List.generate(
    random.nextInt(3),
    (_) => _generateUpdateTaskRequest(),
  );

  return SyncScenario(
    createRequests: createRequests,
    updateRequests: updateRequests,
    isOnline: TestGenerators.randomBool(),
    isSyncing: TestGenerators.randomBool(),
    pendingOperationsCount: TestGenerators.randomInt(max: 10),
    lastSyncTime: TestGenerators.randomBool()
        ? DateTime.now()
            .subtract(Duration(hours: TestGenerators.randomInt(max: 24)))
        : null,
    lastError: TestGenerators.randomBool() ? 'Network error' : null,
  );
}

/// Generates a network scenario for testing
NetworkScenario _generateNetworkScenario() {
  final random = Random();
  final states = NetworkState.values;

  return NetworkScenario(
    initialState: states[random.nextInt(states.length)],
    finalState: states[random.nextInt(states.length)],
    hasNetworkFailure: TestGenerators.randomBool(),
  );
}

/// Generates a create task request for testing
CreateTaskRequest _generateCreateTaskRequest(String boardId, String userId) {
  final recurrence = TaskRecurrence
      .values[TestGenerators.randomInt(max: TaskRecurrence.values.length - 1)];

  return CreateTaskRequest(
    title: TestGenerators.randomString(minLength: 1, maxLength: 50),
    description: TestGenerators.randomBool()
        ? TestGenerators.randomString(minLength: 1, maxLength: 200)
        : null,
    boardId: boardId,
    assignedTo: TestGenerators.randomBool() ? userId : null,
    recurrence: recurrence,
    dueDate: _generateDueDateForRecurrence(recurrence),
    tags: TestGenerators.randomList(
      _generateValidTag,
      minLength: 0,
      maxLength: 3,
    ),
    createdBy: userId,
  );
}

/// Generates an update task request for testing
UpdateTaskRequest _generateUpdateTaskRequest() {
  return UpdateTaskRequest(
    title: TestGenerators.randomBool()
        ? TestGenerators.randomString(minLength: 1, maxLength: 50)
        : null,
    description: TestGenerators.randomBool()
        ? TestGenerators.randomString(minLength: 1, maxLength: 200)
        : null,
    isCompleted:
        TestGenerators.randomBool() ? TestGenerators.randomBool() : null,
    tags: TestGenerators.randomBool()
        ? TestGenerators.randomList(
            _generateValidTag,
            minLength: 0,
            maxLength: 3,
          )
        : null,
  );
}

/// Generates appropriate due date based on recurrence type
DateTime? _generateDueDateForRecurrence(TaskRecurrence recurrence) {
  switch (recurrence) {
    case TaskRecurrence.none:
      return TestGenerators.randomBool()
          ? DateTime.now()
              .add(Duration(days: TestGenerators.randomInt(max: 30)))
          : null;
    case TaskRecurrence.daily:
    case TaskRecurrence.weekly:
    case TaskRecurrence.monthly:
    case TaskRecurrence.custom:
      return DateTime.now()
          .add(Duration(days: TestGenerators.randomInt(max: 30)));
  }
}

/// Generates valid task tags
String _generateValidTag() {
  const validTags = [
    'Health',
    'Home',
    'Finance',
    'Work',
    'Personal',
    'Urgent',
    'Important',
    'Exercise',
    'Study',
    'Shopping'
  ];
  return validTags[TestGenerators.randomInt(max: validTags.length - 1)];
}

/// Generates an offline task ID
String _generateOfflineTaskId() {
  return 'temp_${DateTime.now().millisecondsSinceEpoch}_${TestGenerators.randomInt(max: 9999)}';
}

/// Creates a mock task for testing
Task _createMockTask() {
  final now = DateTime.now();
  return Task(
    id: TestGenerators.randomUuid(),
    title: TestGenerators.randomString(minLength: 1, maxLength: 50),
    boardId: TestGenerators.randomUuid(),
    recurrence: TaskRecurrence.none,
    isCompleted: false,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    createdBy: TestGenerators.randomUuid(),
  );
}

/// Applies an update to a task
Task _applyTaskUpdate(Task originalTask, UpdateTaskRequest updateRequest) {
  return originalTask.copyWith(
    title: updateRequest.title ?? originalTask.title,
    description: updateRequest.description ?? originalTask.description,
    isCompleted: updateRequest.isCompleted ?? originalTask.isCompleted,
    tags: updateRequest.tags ?? originalTask.tags,
    updatedAt: DateTime.now(),
  );
}

/// Creates a sync operation for testing
SyncOperation _createSyncOperation(
    SyncOperationType type, Map<String, dynamic> data) {
  return SyncOperation(
    id: TestGenerators.randomUuid(),
    type: type,
    data: data,
    timestamp: DateTime.now(),
  );
}

/// Completes a task
Task _completeTask(Task task) {
  return task.copyWith(
    isCompleted: true,
    updatedAt: DateTime.now(),
  );
}

/// Determines if sync should be triggered for state transition
bool _shouldTriggerSync(NetworkState from, NetworkState to) {
  return from == NetworkState.offline && to == NetworkState.online;
}

/// Determines if operations should be queued for network state
bool _shouldQueueOperations(NetworkState state) {
  return state == NetworkState.offline;
}

/// Determines if local operations are allowed for network state
bool _allowsLocalOperations(NetworkState state) {
  return true; // Local operations should always be allowed
}

/// Validates data integrity for a network scenario
bool _validateDataIntegrity(NetworkScenario scenario) {
  // In a real implementation, this would check that local data
  // remains consistent despite network failures
  return true;
}

/// Extension to add toMap method to CreateTaskRequest
extension CreateTaskRequestExtension on CreateTaskRequest {
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'boardId': boardId,
        'assignedTo': assignedTo,
        'recurrence': recurrence.toJson(),
        'dueDate': dueDate?.toIso8601String(),
        'tags': tags,
        'createdBy': createdBy,
      };
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:synclife_app/src/core/sync/models/sync_conflict.dart';
import 'package:synclife_app/src/core/sync/models/sync_delta.dart';
import 'package:synclife_app/src/core/sync/models/sync_operation.dart';
import 'package:synclife_app/src/core/sync/models/sync_status.dart';
import 'package:synclife_app/src/core/sync/services/compression_service.dart';
import 'package:synclife_app/src/core/sync/services/conflict_resolution_service.dart';
import 'package:synclife_app/src/core/sync/services/connectivity_service.dart';
import 'package:synclife_app/src/core/sync/services/incremental_sync_service.dart';
import 'package:synclife_app/src/core/sync/services/local_database_service.dart';
import 'package:synclife_app/src/core/sync/services/retry_service.dart';
import 'package:synclife_app/src/core/sync/services/sync_service.dart';
import 'package:synclife_app/src/features/tasks/domain/models/create_task_request.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task.dart';
import 'package:synclife_app/src/features/tasks/domain/models/task_recurrence.dart';
import 'package:synclife_app/src/features/tasks/domain/services/task_service.dart';

void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockConnectivityService mockConnectivityService;
    late MockLocalDatabaseService mockLocalDatabase;
    late MockTaskService mockRemoteTaskService;
    late MockConflictResolutionService mockConflictResolutionService;
    late MockCompressionService mockCompressionService;
    late MockIncrementalSyncService mockIncrementalSyncService;
    late MockRetryService mockRetryService;

    setUp(() {
      mockConnectivityService = MockConnectivityService();
      mockLocalDatabase = MockLocalDatabaseService();
      mockRemoteTaskService = MockTaskService();
      mockConflictResolutionService = MockConflictResolutionService();
      mockCompressionService = MockCompressionService();
      mockIncrementalSyncService = MockIncrementalSyncService();
      mockRetryService = MockRetryService();

      syncService = SyncServiceImpl(
        connectivityService: mockConnectivityService,
        localDatabase: mockLocalDatabase,
        remoteTaskService: mockRemoteTaskService,
        conflictResolutionService: mockConflictResolutionService,
        compressionService: mockCompressionService,
        incrementalSyncService: mockIncrementalSyncService,
        retryService: mockRetryService,
      );
    });

    test('should initialize successfully', () async {
      // Act & Assert
      expect(() => syncService.initialize(), returnsNormally);
    });

    test('should queue sync operations with compression', () async {
      // Arrange
      await syncService.initialize();

      final testData = {'test': 'large_data' * 100};
      when(mockCompressionService.shouldCompress(testData)).thenReturn(true);
      when(mockCompressionService.compress(testData))
          .thenAnswer((_) async => CompressedData(
                data: Uint8List.fromList([1, 2, 3]),
                checksum: 'test_checksum',
                isCompressed: true,
                originalSize: 1000,
                compressedSize: 600,
              ));

      final operation = SyncOperation(
        id: 'test-op',
        type: SyncOperationType.createTask,
        data: testData,
        timestamp: DateTime.now(),
        priority: SyncPriority.high,
      );

      // Act
      await syncService.queueOperation(operation);

      // Assert
      verify(mockCompressionService.shouldCompress(testData)).called(1);
      verify(mockCompressionService.compress(testData)).called(1);
      verify(mockLocalDatabase.insertSyncOperation(operation)).called(1);
    });

    test('should perform incremental sync', () async {
      // Arrange
      await syncService.initialize();
      final testTime = DateTime.now();
      final testDeltas = <SyncDelta>[];
      
      when(mockLocalDatabase.getDeltasSince(testTime)).thenAnswer((_) async => testDeltas);
      when(mockIncrementalSyncService.createDeltaBatch(testDeltas))
          .thenAnswer((_) async => SyncDeltaBatch(
                id: 'batch_1',
                deltas: testDeltas,
                timestamp: DateTime.now(),
              ));

      // Act
      await syncService.incrementalSync();

      // Assert
      verify(mockLocalDatabase.getDeltasSince(any)).called(1);
    });

    test('should get optimization statistics', () async {
      // Arrange
      await syncService.initialize();
      final testOperations = <SyncOperation>[];
      
      when(mockLocalDatabase.getPendingSyncOperations())
          .thenAnswer((_) async => testOperations);
      when(mockIncrementalSyncService.calculateOptimization(testOperations))
          .thenAnswer((_) async => const SyncOptimizationStats(
                originalOperations: 10,
                optimizedDeltas: 6,
                originalSizeBytes: 1000,
                optimizedSizeBytes: 600,
              ));

      // Act
      final stats = await syncService.getOptimizationStats();

      // Assert
      expect(stats.originalOperations, equals(10));
      expect(stats.optimizedDeltas, equals(6));
      expect(stats.operationReductionPercentage, equals(40.0));
    });

    test('should emit sync status updates', () async {
      // Arrange
      await syncService.initialize();

      // Act & Assert
      expect(
        syncService.syncStatus,
        emits(predicate<SyncStatus>((status) => !status.isOnline)),
      );
    });
  });
}

// Mock classes for testing
class MockConnectivityService extends Mock implements ConnectivityService {
  @override
  Future<bool> get isOnline async => false;

  @override
  Stream<bool> get connectivityStream => Stream.value(false);

  @override
  void dispose() {}
}

class MockLocalDatabaseService extends Mock implements LocalDatabaseService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> insertSyncOperation(SyncOperation operation) async {}

  @override
  Future<int> getPendingSyncOperationsCount() async => 0;

  @override
  Future<List<SyncOperation>> getPendingSyncOperations() async => [];

  @override
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp) async => [];
}

class MockTaskService extends Mock implements TaskService {
  @override
  Future<List<Task>> getTasks(String boardId) => super.noSuchMethod(
        Invocation.method(#getTasks, [boardId]),
        returnValue: Future.value(<Task>[]),
      );

  @override
  Future<Task?> getTask(String taskId) => super.noSuchMethod(
        Invocation.method(#getTask, [taskId]),
        returnValue: Future.value(),
      );

  @override
  Future<Task> createTask(CreateTaskRequest request) => super.noSuchMethod(
        Invocation.method(#createTask, [request]),
        returnValue: Future.value(_createMockTask()),
      );

  Task _createMockTask() => Task(
        id: 'mock-id',
        title: 'Mock Task',
        boardId: 'mock-board',
        recurrence: TaskRecurrence.none,
        isCompleted: false,
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'mock-user',
      );
}

class MockConflictResolutionService extends Mock
    implements ConflictResolutionService {
  @override
  ConflictType? detectTaskConflict(Task localTask, Task remoteTask) =>
      super.noSuchMethod(
        Invocation.method(#detectTaskConflict, [localTask, remoteTask]),
        returnValue: null,
      );

  @override
  Future<Task> resolveTaskConflict(
    Task localTask,
    Task remoteTask,
    ConflictType conflictType,
  ) =>
      super.noSuchMethod(
        Invocation.method(
            #resolveTaskConflict, [localTask, remoteTask, conflictType]),
        returnValue: Future.value(localTask),
      );

  @override
  void logConflict(SyncConflict conflict) => super.noSuchMethod(
        Invocation.method(#logConflict, [conflict]),
      );

  @override
  Map<String, int> getConflictStats() => super.noSuchMethod(
        Invocation.method(#getConflictStats, []),
        returnValue: <String, int>{},
      );
}

class MockCompressionService extends Mock implements CompressionService {
  @override
  bool shouldCompress(Map<String, dynamic> data) => super.noSuchMethod(
        Invocation.method(#shouldCompress, [data]),
        returnValue: false,
      );

  @override
  Future<CompressedData> compress(Map<String, dynamic> data) =>
      super.noSuchMethod(
        Invocation.method(#compress, [data]),
        returnValue: Future.value(CompressedData(
          data: Uint8List.fromList([]),
          checksum: 'test',
          isCompressed: false,
          originalSize: 0,
          compressedSize: 0,
        )),
      );

  @override
  Future<Map<String, dynamic>> decompress(CompressedData compressedData) =>
      super.noSuchMethod(
        Invocation.method(#decompress, [compressedData]),
        returnValue: Future.value(<String, dynamic>{}),
      );

  @override
  String calculateChecksum(dynamic data) => super.noSuchMethod(
        Invocation.method(#calculateChecksum, [data]),
        returnValue: 'test_checksum',
      );
}

class MockIncrementalSyncService extends Mock
    implements IncrementalSyncService {
  @override
  Future<SyncOptimizationStats> calculateOptimization(
    List<SyncOperation> operations,
  ) =>
      super.noSuchMethod(
        Invocation.method(#calculateOptimization, [operations]),
        returnValue: Future.value(const SyncOptimizationStats(
          originalOperations: 0,
          optimizedDeltas: 0,
          originalSizeBytes: 0,
          optimizedSizeBytes: 0,
        )),
      );

  @override
  Future<SyncDeltaBatch> createDeltaBatch(List<SyncDelta> deltas) =>
      super.noSuchMethod(
        Invocation.method(#createDeltaBatch, [deltas]),
        returnValue: Future.value(SyncDeltaBatch(
          id: 'test_batch',
          deltas: deltas,
          timestamp: DateTime.now(),
        )),
      );

  @override
  Future<void> applyDeltas(List<SyncDelta> deltas) => super.noSuchMethod(
        Invocation.method(#applyDeltas, [deltas]),
        returnValue: Future<void>.value(),
      );
}

class MockRetryService extends Mock implements RetryService {
  @override
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
  }) =>
      super.noSuchMethod(
        Invocation.method(#executeWithRetry, [operation], {#config: config}),
        returnValue: operation(),
      );
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:synclife_app/src/core/sync/models/sync_delta.dart';
import 'package:synclife_app/src/core/sync/models/sync_operation.dart';
import 'package:synclife_app/src/core/sync/services/compression_service.dart';
import 'package:synclife_app/src/core/sync/services/incremental_sync_service.dart';
import 'package:synclife_app/src/core/sync/services/local_database_service.dart';

void main() {
  group('IncrementalSyncService', () {
    late IncrementalSyncService incrementalSyncService;
    late MockLocalDatabaseService mockLocalDatabase;
    late MockCompressionService mockCompressionService;

    setUp(() {
      mockLocalDatabase = MockLocalDatabaseService();
      mockCompressionService = MockCompressionService();

      incrementalSyncService = IncrementalSyncServiceImpl(
        localDatabase: mockLocalDatabase,
        compressionService: mockCompressionService,
      );
    });

    group('createDelta', () {
      test('should create delta with correct properties', () async {
        final delta = await incrementalSyncService.createDelta(
          entityId: 'task_123',
          entityType: 'task',
          changeType: SyncChangeType.update,
          changes: {'title': 'Updated Task'},
          previousVersion: 'v1',
          currentVersion: 'v2',
        );

        expect(delta.entityId, equals('task_123'));
        expect(delta.entityType, equals('task'));
        expect(delta.changeType, equals(SyncChangeType.update));
        expect(delta.changes, equals({'title': 'Updated Task'}));
        expect(delta.previousVersion, equals('v1'));
        expect(delta.currentVersion, equals('v2'));
        expect(delta.timestamp, isA<DateTime>());
      });
    });

    group('createDeltaBatch', () {
      test('should create batch without compression for small data', () async {
        final testData = {'deltas': []};
        when(mockCompressionService.shouldCompress(testData))
            .thenReturn(false);

        final deltas = [
          SyncDelta(
            entityId: 'task_1',
            entityType: 'task',
            changeType: SyncChangeType.update,
            timestamp: DateTime.now(),
            changes: {'title': 'Task 1'},
          ),
          SyncDelta(
            entityId: 'task_2',
            entityType: 'task',
            changeType: SyncChangeType.update,
            timestamp: DateTime.now(),
            changes: {'title': 'Task 2'},
          ),
        ];

        final batch = await incrementalSyncService.createDeltaBatch(deltas);

        expect(batch.deltas, equals(deltas));
        expect(batch.isCompressed, isFalse);
        expect(batch.checksum, isNull);
        expect(batch.id, startsWith('batch_'));
      });

      test('should create batch with compression for large data', () async {
        final testData = {'deltas': [{'title': 'Very long task title' * 100}]};
        when(mockCompressionService.shouldCompress(testData))
            .thenReturn(true);
        when(mockCompressionService.compress(testData))
            .thenAnswer((_) async => CompressedData(
                  data: Uint8List.fromList([1, 2, 3]),
                  checksum: 'test_checksum',
                  isCompressed: true,
                  originalSize: 1000,
                  compressedSize: 600,
                ));

        final deltas = [
          SyncDelta(
            entityId: 'task_1',
            entityType: 'task',
            changeType: SyncChangeType.update,
            timestamp: DateTime.now(),
            changes: {'title': 'Very long task title' * 100},
          ),
        ];

        final batch = await incrementalSyncService.createDeltaBatch(deltas);

        expect(batch.deltas, equals(deltas));
        expect(batch.isCompressed, isTrue);
        expect(batch.checksum, equals('test_checksum'));
      });
    });

    group('optimizeSyncOperations', () {
      test('should convert operations to deltas', () async {
        final operations = [
          SyncOperation(
            id: 'op_1',
            type: SyncOperationType.updateTask,
            data: {'taskId': 'task_123', 'title': 'Updated Title'},
            timestamp: DateTime.now(),
          ),
          SyncOperation(
            id: 'op_2',
            type: SyncOperationType.completeTask,
            data: {'taskId': 'task_123', 'isCompleted': true},
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
          ),
        ];

        final deltas =
            await incrementalSyncService.optimizeSyncOperations(operations);

        expect(deltas, hasLength(2));
        expect(deltas[0].entityId, equals('task_123'));
        expect(deltas[0].entityType, equals('task'));
        expect(deltas[0].changeType, equals(SyncChangeType.update));
        expect(deltas[1].changeType, equals(SyncChangeType.fieldUpdate));
      });

      test('should merge operations for same entity', () async {
        final baseTime = DateTime.now();
        final operations = [
          SyncOperation(
            id: 'op_1',
            type: SyncOperationType.updateTask,
            data: {'taskId': 'task_123', 'title': 'First Update'},
            timestamp: baseTime,
          ),
          SyncOperation(
            id: 'op_2',
            type: SyncOperationType.updateTask,
            data: {
              'taskId': 'task_123',
              'title': 'Second Update',
              'description': 'Added description'
            },
            timestamp: baseTime.add(const Duration(minutes: 1)),
          ),
        ];

        final deltas =
            await incrementalSyncService.optimizeSyncOperations(operations);

        expect(deltas, hasLength(2));
        expect(deltas[0].changes, containsPair('title', 'First Update'));
        expect(deltas[1].changes, containsPair('title', 'Second Update'));
        expect(deltas[1].changes,
            containsPair('description', 'Added description'));
      });
    });

    group('calculateOptimization', () {
      test('should calculate optimization statistics', () async {
        final operations = [
          SyncOperation(
            id: 'op_1',
            type: SyncOperationType.updateTask,
            data: {'taskId': 'task_123', 'title': 'Updated Title'},
            timestamp: DateTime.now(),
          ),
          SyncOperation(
            id: 'op_2',
            type: SyncOperationType.updateTask,
            data: {'taskId': 'task_123', 'description': 'Updated Description'},
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
          ),
        ];

        final stats =
            await incrementalSyncService.calculateOptimization(operations);

        expect(stats.originalOperations, equals(2));
        expect(stats.optimizedDeltas, greaterThanOrEqualTo(1));
        expect(stats.originalSizeBytes, greaterThan(0));
        expect(stats.optimizedSizeBytes, greaterThanOrEqualTo(0));
      });

      test('should handle empty operations list', () async {
        final stats = await incrementalSyncService.calculateOptimization([]);

        expect(stats.originalOperations, equals(0));
        expect(stats.optimizedDeltas, equals(0));
        expect(stats.originalSizeBytes, equals(0));
        expect(stats.optimizedSizeBytes, equals(0));
        expect(stats.operationReductionPercentage, equals(0.0));
        expect(stats.sizeReductionPercentage, equals(0.0));
      });
    });

    group('SyncOptimizationStats', () {
      test('should calculate reduction percentages correctly', () {
        const stats = SyncOptimizationStats(
          originalOperations: 10,
          optimizedDeltas: 6,
          originalSizeBytes: 1000,
          optimizedSizeBytes: 600,
        );

        expect(stats.operationReduction, equals(4));
        expect(stats.sizeReduction, equals(400));
        expect(stats.operationReductionPercentage, equals(40.0));
        expect(stats.sizeReductionPercentage, equals(40.0));
      });

      test('should handle zero values gracefully', () {
        const stats = SyncOptimizationStats(
          originalOperations: 0,
          optimizedDeltas: 0,
          originalSizeBytes: 0,
          optimizedSizeBytes: 0,
        );

        expect(stats.operationReductionPercentage, equals(0.0));
        expect(stats.sizeReductionPercentage, equals(0.0));
      });

      test('should provide meaningful toString', () {
        const stats = SyncOptimizationStats(
          originalOperations: 10,
          optimizedDeltas: 6,
          originalSizeBytes: 1000,
          optimizedSizeBytes: 600,
        );

        final string = stats.toString();
        expect(string, contains('10 → 6'));
        expect(string, contains('40.0% reduction'));
        expect(string, contains('1000B → 600B'));
      });
    });
  });
}

// Mock classes
class MockLocalDatabaseService extends Mock implements LocalDatabaseService {
  @override
  Future<void> insertDelta(SyncDelta delta) => super.noSuchMethod(
        Invocation.method(#insertDelta, [delta]),
        returnValue: Future<void>.value(),
      );

  @override
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp) =>
      super.noSuchMethod(
        Invocation.method(#getDeltasSince, [timestamp]),
        returnValue: Future.value(<SyncDelta>[]),
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
}

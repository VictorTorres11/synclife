import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../features/tasks/domain/models/task.dart';
import '../models/sync_conflict.dart';
import '../models/sync_delta.dart';
import '../models/sync_operation.dart';

/// Service for managing local SQLite database
abstract class LocalDatabaseService {
  /// Initialize the database
  Future<void> initialize();

  /// Close the database
  Future<void> close();

  // Task operations
  Future<void> insertTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<Task?> getTask(String taskId);
  Future<List<Task>> getTasks(String boardId);
  Future<List<Task>> getAllTasks();

  // Sync operations
  Future<void> insertSyncOperation(SyncOperation operation);
  Future<void> updateSyncOperation(SyncOperation operation);
  Future<void> deleteSyncOperation(String operationId);
  Future<List<SyncOperation>> getPendingSyncOperations();
  Future<int> getPendingSyncOperationsCount();

  // Conflict logging
  Future<void> insertConflict(SyncConflict conflict);
  Future<List<SyncConflict>> getConflicts({int? limit});
  Future<void> deleteOldConflicts(DateTime before);

  // Delta operations for incremental sync
  Future<void> insertDelta(SyncDelta delta);
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp);
  Future<void> insertTaskFromDelta(SyncDelta delta);
  Future<void> updateTaskFromDelta(SyncDelta delta);
  Future<void> insertBoardFromDelta(SyncDelta delta);
  Future<void> updateBoardFromDelta(SyncDelta delta);
  Future<void> deleteBoard(String boardId);
  Future<void> cleanupOldDeltas(DateTime before);
}

/// SQLite implementation of LocalDatabaseService
class LocalDatabaseServiceImpl implements LocalDatabaseService {
  static const String _databaseName = 'synclife_local.db';
  static const int _databaseVersion = 1;

  Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        board_id TEXT NOT NULL,
        assigned_to TEXT,
        recurrence TEXT NOT NULL,
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        tags TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create sync operations table
    await db.execute('''
      CREATE TABLE sync_operations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        priority TEXT DEFAULT 'normal',
        is_compressed INTEGER DEFAULT 0,
        checksum TEXT
      )
    ''');

    // Create conflicts table
    await db.execute('''
      CREATE TABLE conflicts (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        resolution TEXT,
        resolved_at TEXT
      )
    ''');

    // Create deltas table for incremental sync
    await db.execute('''
      CREATE TABLE deltas (
        id TEXT PRIMARY KEY,
        entity_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        change_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        changes TEXT NOT NULL,
        previous_version TEXT,
        current_version TEXT
      )
    ''');

    // Create boards table (needed for delta operations)
    await db.execute('''
      CREATE TABLE boards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        member_ids TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_board_id ON tasks(board_id)');
    await db
        .execute('CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');
    await db.execute(
        'CREATE INDEX idx_sync_operations_timestamp ON sync_operations(timestamp)');
    await db.execute(
        'CREATE INDEX idx_conflicts_entity_id ON conflicts(entity_id)');
    await db.execute(
        'CREATE INDEX idx_conflicts_timestamp ON conflicts(timestamp)');
    await db.execute('CREATE INDEX idx_deltas_entity_id ON deltas(entity_id)');
    await db.execute('CREATE INDEX idx_deltas_timestamp ON deltas(timestamp)');
    await db.execute('CREATE INDEX idx_boards_owner_id ON boards(owner_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS sync_operations');
      await db.execute('DROP TABLE IF EXISTS conflicts');
      await db.execute('DROP TABLE IF EXISTS deltas');
      await db.execute('DROP TABLE IF EXISTS boards');
      await _onCreate(db, newVersion);
    }
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Database get _db {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  @override
  Future<void> insertTask(Task task) async {
    await _db.insert(
      'tasks',
      _taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(Task task) async {
    await _db.update(
      'tasks',
      _taskToMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<Task?> getTask(String taskId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (maps.isEmpty) return null;
    return _taskFromMap(maps.first);
  }

  @override
  Future<List<Task>> getTasks(String boardId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'created_at DESC',
    );

    return maps.map(_taskFromMap).toList();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );

    return maps.map(_taskFromMap).toList();
  }

  @override
  Future<void> insertSyncOperation(SyncOperation operation) async {
    await _db.insert(
      'sync_operations',
      _syncOperationToMap(operation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSyncOperation(SyncOperation operation) async {
    await _db.update(
      'sync_operations',
      _syncOperationToMap(operation),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  @override
  Future<void> deleteSyncOperation(String operationId) async {
    await _db.delete(
      'sync_operations',
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  @override
  Future<List<SyncOperation>> getPendingSyncOperations() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'sync_operations',
      orderBy: 'timestamp ASC',
    );

    return maps.map(_syncOperationFromMap).toList();
  }

  @override
  Future<int> getPendingSyncOperationsCount() async {
    final result =
        await _db.rawQuery('SELECT COUNT(*) as count FROM sync_operations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> insertConflict(SyncConflict conflict) async {
    await _db.insert(
      'conflicts',
      _conflictToMap(conflict),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncConflict>> getConflicts({int? limit}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'conflicts',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map(_conflictFromMap).toList();
  }

  @override
  Future<void> deleteOldConflicts(DateTime before) async {
    await _db.delete(
      'conflicts',
      where: 'timestamp < ?',
      whereArgs: [before.toIso8601String()],
    );
  }

  // Delta operations implementation
  @override
  Future<void> insertDelta(SyncDelta delta) async {
    await _db.insert(
      'deltas',
      _deltaToMap(delta),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncDelta>> getDeltasSince(DateTime timestamp) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'deltas',
      where: 'timestamp > ?',
      whereArgs: [timestamp.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return maps.map(_deltaFromMap).toList();
  }

  @override
  Future<void> insertTaskFromDelta(SyncDelta delta) async {
    final taskData = Map<String, dynamic>.from(delta.changes);
    taskData['id'] = delta.entityId;

    // Set default values if not provided
    taskData.putIfAbsent('created_at', () => delta.timestamp.toIso8601String());
    taskData.putIfAbsent('updated_at', () => delta.timestamp.toIso8601String());
    taskData.putIfAbsent('is_completed', () => false);
    taskData.putIfAbsent('tags', () => <String>[]);

    await _db.insert(
      'tasks',
      _taskMapToDbMap(taskData),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await insertDelta(delta);
  }

  @override
  Future<void> updateTaskFromDelta(SyncDelta delta) async {
    final currentTask = await getTask(delta.entityId);
    if (currentTask == null) {
      await insertTaskFromDelta(delta);
      return;
    }

    final updatedData = currentTask.toMap();
    updatedData.addAll(delta.changes);
    updatedData['updated_at'] = delta.timestamp.toIso8601String();

    await _db.update(
      'tasks',
      _taskMapToDbMap(updatedData),
      where: 'id = ?',
      whereArgs: [delta.entityId],
    );

    await insertDelta(delta);
  }

  @override
  Future<void> insertBoardFromDelta(SyncDelta delta) async {
    final boardData = Map<String, dynamic>.from(delta.changes);
    boardData['id'] = delta.entityId;

    boardData.putIfAbsent(
        'created_at', () => delta.timestamp.toIso8601String());
    boardData.putIfAbsent(
        'updated_at', () => delta.timestamp.toIso8601String());
    boardData.putIfAbsent('member_ids', () => <String>[]);

    await _db.insert(
      'boards',
      _boardMapToDbMap(boardData),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await insertDelta(delta);
  }

  @override
  Future<void> updateBoardFromDelta(SyncDelta delta) async {
    final updateData = Map<String, dynamic>.from(delta.changes);
    updateData['updated_at'] = delta.timestamp.toIso8601String();

    await _db.update(
      'boards',
      _boardMapToDbMap(updateData),
      where: 'id = ?',
      whereArgs: [delta.entityId],
    );

    await insertDelta(delta);
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    await _db.delete(
      'boards',
      where: 'id = ?',
      whereArgs: [boardId],
    );
  }

  @override
  Future<void> cleanupOldDeltas(DateTime before) async {
    await _db.delete(
      'deltas',
      where: 'timestamp < ?',
      whereArgs: [before.toIso8601String()],
    );
  }

  // Helper methods for data conversion
  Map<String, dynamic> _taskToMap(Task task) => {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'board_id': task.boardId,
        'assigned_to': task.assignedTo,
        'recurrence': task.recurrence.toJson(),
        'due_date': task.dueDate?.toIso8601String(),
        'is_completed': task.isCompleted ? 1 : 0,
        'tags': jsonEncode(task.tags),
        'created_at': task.createdAt.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
        'created_by': task.createdBy,
        'is_synced': 1,
      };

  Task _taskFromMap(Map<String, dynamic> map) => Task.fromMap({
        'id': map['id'],
        'title': map['title'],
        'description': map['description'],
        'boardId': map['board_id'],
        'assignedTo': map['assigned_to'],
        'recurrence': map['recurrence'],
        'dueDate': map['due_date'],
        'isCompleted': map['is_completed'] == 1,
        'tags': jsonDecode(map['tags'] as String),
        'createdAt': map['created_at'],
        'updatedAt': map['updated_at'],
        'createdBy': map['created_by'],
      });

  Map<String, dynamic> _syncOperationToMap(SyncOperation operation) => {
        'id': operation.id,
        'type': operation.type.name,
        'data': jsonEncode(operation.data),
        'timestamp': operation.timestamp.toIso8601String(),
        'retry_count': operation.retryCount,
        'last_error': operation.lastError,
        'priority': operation.priority.name,
        'is_compressed': operation.isCompressed ? 1 : 0,
        'checksum': operation.checksum,
      };

  SyncOperation _syncOperationFromMap(Map<String, dynamic> map) =>
      SyncOperation(
        id: map['id'] as String,
        type: SyncOperationType.values.firstWhere(
          (e) => e.name == map['type'] as String,
        ),
        data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
        timestamp: DateTime.parse(map['timestamp'] as String),
        retryCount: map['retry_count'] as int,
        lastError: map['last_error'] as String?,
        priority: SyncPriority.values.firstWhere(
          (e) => e.name == (map['priority'] as String? ?? 'normal'),
          orElse: () => SyncPriority.normal,
        ),
        isCompressed: (map['is_compressed'] as int? ?? 0) == 1,
        checksum: map['checksum'] as String?,
      );

  Map<String, dynamic> _conflictToMap(SyncConflict conflict) => {
        'id': conflict.id,
        'entity_type': conflict.entityType.name,
        'entity_id': conflict.entityId,
        'conflict_type': conflict.conflictType.name,
        'local_data': jsonEncode(conflict.localData),
        'remote_data': jsonEncode(conflict.remoteData),
        'timestamp': conflict.timestamp.toIso8601String(),
        'resolution': conflict.resolution?.name,
        'resolved_at': conflict.resolvedAt?.toIso8601String(),
      };

  SyncConflict _conflictFromMap(Map<String, dynamic> map) => SyncConflict(
        id: map['id'] as String,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == map['entity_type'] as String,
        ),
        entityId: map['entity_id'] as String,
        conflictType: ConflictType.values.firstWhere(
          (e) => e.name == map['conflict_type'] as String,
        ),
        localData:
            jsonDecode(map['local_data'] as String) as Map<String, dynamic>,
        remoteData:
            jsonDecode(map['remote_data'] as String) as Map<String, dynamic>,
        timestamp: DateTime.parse(map['timestamp'] as String),
        resolution: map['resolution'] != null
            ? ConflictResolution.values.firstWhere(
                (e) => e.name == map['resolution'] as String,
              )
            : null,
        resolvedAt: map['resolved_at'] != null
            ? DateTime.parse(map['resolved_at'] as String)
            : null,
      );

  // Helper methods for delta operations
  Map<String, dynamic> _deltaToMap(SyncDelta delta) => {
        'id': '${delta.entityId}_${delta.timestamp.millisecondsSinceEpoch}',
        'entity_id': delta.entityId,
        'entity_type': delta.entityType,
        'change_type': delta.changeType.name,
        'timestamp': delta.timestamp.toIso8601String(),
        'changes': jsonEncode(delta.changes),
        'previous_version': delta.previousVersion,
        'current_version': delta.currentVersion,
      };

  SyncDelta _deltaFromMap(Map<String, dynamic> map) => SyncDelta(
        entityId: map['entity_id'] as String,
        entityType: map['entity_type'] as String,
        changeType: SyncChangeType.values.firstWhere(
          (e) => e.name == map['change_type'] as String,
        ),
        timestamp: DateTime.parse(map['timestamp'] as String),
        changes: jsonDecode(map['changes'] as String) as Map<String, dynamic>,
        previousVersion: map['previous_version'] as String?,
        currentVersion: map['current_version'] as String?,
      );

  Map<String, dynamic> _taskMapToDbMap(Map<String, dynamic> taskData) => {
        'id': taskData['id'],
        'title': taskData['title'],
        'description': taskData['description'],
        'board_id': taskData['boardId'] ?? taskData['board_id'],
        'assigned_to': taskData['assignedTo'] ?? taskData['assigned_to'],
        'recurrence': taskData['recurrence'] is String
            ? taskData['recurrence']
            : jsonEncode(taskData['recurrence']),
        'due_date': taskData['dueDate'] ?? taskData['due_date'],
        'is_completed':
            taskData['isCompleted'] == true || taskData['is_completed'] == 1
                ? 1
                : 0,
        'tags': taskData['tags'] is String
            ? taskData['tags']
            : jsonEncode(taskData['tags']),
        'created_at': taskData['createdAt'] ?? taskData['created_at'],
        'updated_at': taskData['updatedAt'] ?? taskData['updated_at'],
        'created_by': taskData['createdBy'] ?? taskData['created_by'],
        'is_synced': 1,
      };

  Map<String, dynamic> _boardMapToDbMap(Map<String, dynamic> boardData) => {
        'id': boardData['id'],
        'name': boardData['name'],
        'description': boardData['description'],
        'type': boardData['type'],
        'owner_id': boardData['ownerId'] ?? boardData['owner_id'],
        'member_ids': boardData['memberIds'] is String
            ? boardData['memberIds']
            : jsonEncode(boardData['memberIds'] ?? boardData['member_ids']),
        'created_at': boardData['createdAt'] ?? boardData['created_at'],
        'updated_at': boardData['updatedAt'] ?? boardData['updated_at'],
        'is_synced': 1,
      };
}

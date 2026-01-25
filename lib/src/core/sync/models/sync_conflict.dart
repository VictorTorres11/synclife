import 'package:equatable/equatable.dart';

/// Represents a synchronization conflict between local and remote data
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.conflictType,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
    this.resolution,
    this.resolvedAt,
  });

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final ConflictType conflictType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime timestamp;
  final ConflictResolution? resolution;
  final DateTime? resolvedAt;

  /// Creates a SyncConflict from database map
  factory SyncConflict.fromMap(Map<String, dynamic> map) => SyncConflict(
        id: map['id'] as String,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == map['entityType'] as String,
        ),
        entityId: map['entityId'] as String,
        conflictType: ConflictType.values.firstWhere(
          (e) => e.name == map['conflictType'] as String,
        ),
        localData: Map<String, dynamic>.from(map['localData'] as Map),
        remoteData: Map<String, dynamic>.from(map['remoteData'] as Map),
        timestamp: DateTime.parse(map['timestamp'] as String),
        resolution: map['resolution'] != null
            ? ConflictResolution.values.firstWhere(
                (e) => e.name == map['resolution'] as String,
              )
            : null,
        resolvedAt: map['resolvedAt'] != null
            ? DateTime.parse(map['resolvedAt'] as String)
            : null,
      );

  /// Converts SyncConflict to database map
  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType.name,
        'entityId': entityId,
        'conflictType': conflictType.name,
        'localData': localData,
        'remoteData': remoteData,
        'timestamp': timestamp.toIso8601String(),
        'resolution': resolution?.name,
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  SyncConflict copyWith({
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    ConflictType? conflictType,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    DateTime? timestamp,
    ConflictResolution? resolution,
    DateTime? resolvedAt,
  }) =>
      SyncConflict(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        conflictType: conflictType ?? this.conflictType,
        localData: localData ?? this.localData,
        remoteData: remoteData ?? this.remoteData,
        timestamp: timestamp ?? this.timestamp,
        resolution: resolution ?? this.resolution,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        conflictType,
        localData,
        remoteData,
        timestamp,
        resolution,
        resolvedAt,
      ];
}

/// Types of entities that can have sync conflicts
enum SyncEntityType {
  task,
  board,
}

/// Types of conflicts that can occur
enum ConflictType {
  /// Both local and remote versions were modified
  concurrentModification,

  /// Local version was deleted while remote was modified
  deleteModifyConflict,

  /// Remote version was deleted while local was modified
  modifyDeleteConflict,

  /// Different completion status between local and remote
  completionStatusConflict,
}

/// How a conflict was resolved
enum ConflictResolution {
  /// Local version was kept
  useLocal,

  /// Remote version was kept
  useRemote,

  /// Data was merged from both versions
  merged,

  /// Last-write-wins strategy was applied
  lastWriteWins,
}

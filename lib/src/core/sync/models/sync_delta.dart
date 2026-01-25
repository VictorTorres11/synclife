import 'package:equatable/equatable.dart';

/// Represents a delta/change for incremental synchronization
class SyncDelta extends Equatable {
  const SyncDelta({
    required this.entityId,
    required this.entityType,
    required this.changeType,
    required this.timestamp,
    required this.changes,
    this.previousVersion,
    this.currentVersion,
  });

  final String entityId;
  final String entityType;
  final SyncChangeType changeType;
  final DateTime timestamp;
  final Map<String, dynamic> changes;
  final String? previousVersion;
  final String? currentVersion;

  factory SyncDelta.fromMap(Map<String, dynamic> map) => SyncDelta(
        entityId: map['entityId'] as String,
        entityType: map['entityType'] as String,
        changeType: SyncChangeType.values.firstWhere(
          (e) => e.name == map['changeType'] as String,
        ),
        timestamp: DateTime.parse(map['timestamp'] as String),
        changes: Map<String, dynamic>.from(map['changes'] as Map),
        previousVersion: map['previousVersion'] as String?,
        currentVersion: map['currentVersion'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'entityId': entityId,
        'entityType': entityType,
        'changeType': changeType.name,
        'timestamp': timestamp.toIso8601String(),
        'changes': changes,
        'previousVersion': previousVersion,
        'currentVersion': currentVersion,
      };

  @override
  List<Object?> get props => [
        entityId,
        entityType,
        changeType,
        timestamp,
        changes,
        previousVersion,
        currentVersion,
      ];
}

/// Types of changes for incremental sync
enum SyncChangeType {
  create,
  update,
  delete,
  fieldUpdate,
}

/// Represents a batch of sync deltas for efficient processing
class SyncDeltaBatch extends Equatable {
  const SyncDeltaBatch({
    required this.id,
    required this.deltas,
    required this.timestamp,
    this.isCompressed = false,
    this.checksum,
  });

  final String id;
  final List<SyncDelta> deltas;
  final DateTime timestamp;
  final bool isCompressed;
  final String? checksum;

  factory SyncDeltaBatch.fromMap(Map<String, dynamic> map) => SyncDeltaBatch(
        id: map['id'] as String,
        deltas: (map['deltas'] as List)
            .map((delta) => SyncDelta.fromMap(delta as Map<String, dynamic>))
            .toList(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        isCompressed: map['isCompressed'] as bool? ?? false,
        checksum: map['checksum'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'deltas': deltas.map((delta) => delta.toMap()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'isCompressed': isCompressed,
        'checksum': checksum,
      };

  @override
  List<Object?> get props => [id, deltas, timestamp, isCompressed, checksum];
}

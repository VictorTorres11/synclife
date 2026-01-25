import 'package:equatable/equatable.dart';

/// Represents a sync operation that needs to be processed
class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.lastError,
    this.priority = SyncPriority.normal,
    this.isCompressed = false,
    this.checksum,
  });

  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? lastError;
  final SyncPriority priority;
  final bool isCompressed;
  final String? checksum;

  /// Creates a SyncOperation from database map
  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
        id: map['id'] as String,
        type: SyncOperationType.values.firstWhere(
          (e) => e.name == map['type'] as String,
        ),
        data: Map<String, dynamic>.from(map['data'] as Map),
        timestamp: DateTime.parse(map['timestamp'] as String),
        retryCount: map['retryCount'] as int? ?? 0,
        lastError: map['lastError'] as String?,
        priority: SyncPriority.values.firstWhere(
          (e) => e.name == (map['priority'] as String? ?? 'normal'),
          orElse: () => SyncPriority.normal,
        ),
        isCompressed: map['isCompressed'] as bool? ?? false,
        checksum: map['checksum'] as String?,
      );

  /// Converts SyncOperation to database map
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
        'priority': priority.name,
        'isCompressed': isCompressed,
        'checksum': checksum,
      };

  SyncOperation copyWith({
    String? id,
    SyncOperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? lastError,
    SyncPriority? priority,
    bool? isCompressed,
    String? checksum,
  }) =>
      SyncOperation(
        id: id ?? this.id,
        type: type ?? this.type,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError ?? this.lastError,
        priority: priority ?? this.priority,
        isCompressed: isCompressed ?? this.isCompressed,
        checksum: checksum ?? this.checksum,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        data,
        timestamp,
        retryCount,
        lastError,
        priority,
        isCompressed,
        checksum,
      ];
}

/// Types of sync operations supported
enum SyncOperationType {
  createTask,
  updateTask,
  deleteTask,
  completeTask,
  createBoard,
  updateBoard,
  joinBoard,
  leaveBoard,
}

/// Priority levels for sync operations
enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

import 'package:equatable/equatable.dart';

/// Represents an activity event in a board
class BoardActivity extends Equatable {
  const BoardActivity({
    required this.id,
    required this.boardId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  final String id;
  final String boardId;
  final String userId;
  final String userName;
  final String userEmail;
  final BoardActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  /// Creates a BoardActivity from Firestore document data
  factory BoardActivity.fromMap(Map<String, dynamic> map) => BoardActivity(
        id: map['id'] as String,
        boardId: map['boardId'] as String,
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        userEmail: map['userEmail'] as String,
        type: BoardActivityType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => BoardActivityType.other,
        ),
        description: map['description'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  /// Converts BoardActivity to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'boardId': boardId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'type': type.name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  BoardActivity copyWith({
    String? id,
    String? boardId,
    String? userId,
    String? userName,
    String? userEmail,
    BoardActivityType? type,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      BoardActivity(
        id: id ?? this.id,
        boardId: boardId ?? this.boardId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        type: type ?? this.type,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
        metadata: metadata ?? this.metadata,
      );

  @override
  List<Object?> get props => [
        id,
        boardId,
        userId,
        userName,
        userEmail,
        type,
        description,
        timestamp,
        metadata,
      ];
}

/// Types of board activities
enum BoardActivityType {
  taskCreated,
  taskCompleted,
  taskUpdated,
  taskDeleted,
  userJoined,
  userLeft,
  inviteSent,
  inviteAccepted,
  boardUpdated,
  other,
}

/// Extension to get display information for activity types
extension BoardActivityTypeExtension on BoardActivityType {
  String get displayName {
    switch (this) {
      case BoardActivityType.taskCreated:
        return 'Tarefa criada';
      case BoardActivityType.taskCompleted:
        return 'Tarefa concluída';
      case BoardActivityType.taskUpdated:
        return 'Tarefa atualizada';
      case BoardActivityType.taskDeleted:
        return 'Tarefa removida';
      case BoardActivityType.userJoined:
        return 'Usuário entrou';
      case BoardActivityType.userLeft:
        return 'Usuário saiu';
      case BoardActivityType.inviteSent:
        return 'Convite enviado';
      case BoardActivityType.inviteAccepted:
        return 'Convite aceito';
      case BoardActivityType.boardUpdated:
        return 'Quadro atualizado';
      case BoardActivityType.other:
        return 'Atividade';
    }
  }

  String get iconName {
    switch (this) {
      case BoardActivityType.taskCreated:
        return 'add_task';
      case BoardActivityType.taskCompleted:
        return 'task_alt';
      case BoardActivityType.taskUpdated:
        return 'edit';
      case BoardActivityType.taskDeleted:
        return 'delete';
      case BoardActivityType.userJoined:
        return 'person_add';
      case BoardActivityType.userLeft:
        return 'person_remove';
      case BoardActivityType.inviteSent:
        return 'send';
      case BoardActivityType.inviteAccepted:
        return 'check_circle';
      case BoardActivityType.boardUpdated:
        return 'edit_note';
      case BoardActivityType.other:
        return 'info';
    }
  }
}

/// User presence information
class UserPresence extends Equatable {
  const UserPresence({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.isOnline,
    required this.lastSeen,
    this.currentActivity,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final bool isOnline;
  final DateTime lastSeen;
  final String? currentActivity;

  /// Creates a UserPresence from Firestore document data
  factory UserPresence.fromMap(Map<String, dynamic> map) => UserPresence(
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        userEmail: map['userEmail'] as String,
        isOnline: map['isOnline'] as bool,
        lastSeen: DateTime.parse(map['lastSeen'] as String),
        currentActivity: map['currentActivity'] as String?,
      );

  /// Converts UserPresence to Firestore document data
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'isOnline': isOnline,
        'lastSeen': lastSeen.toIso8601String(),
        'currentActivity': currentActivity,
      };

  UserPresence copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    bool? isOnline,
    DateTime? lastSeen,
    String? currentActivity,
  }) =>
      UserPresence(
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        currentActivity: currentActivity ?? this.currentActivity,
      );

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        isOnline,
        lastSeen,
        currentActivity,
      ];
}

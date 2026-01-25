import 'package:equatable/equatable.dart';

/// Represents a comment on a task
class TaskComment extends Equatable {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.content,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a TaskComment from Firestore document data
  factory TaskComment.fromMap(Map<String, dynamic> map) => TaskComment(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    content: map['content'] as String,
    authorId: map['authorId'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts TaskComment to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'content': content,
    'authorId': authorId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? content,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskComment(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    content: content ?? this.content,
    authorId: authorId ?? this.authorId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id, taskId, content, authorId, createdAt, updatedAt,
  ];
}
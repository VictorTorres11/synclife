import 'package:equatable/equatable.dart';

/// Represents a subtask within a main task
class Subtask extends Equatable {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String id;
  final String taskId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int order; // For ordering subtasks
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  /// Creates a Subtask from Firestore document data
  factory Subtask.fromMap(Map<String, dynamic> map) => Subtask(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    isCompleted: map['isCompleted'] as bool,
    order: map['order'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    createdBy: map['createdBy'] as String,
  );

  /// Converts Subtask to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'order': order,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    String? description,
    bool? isCompleted,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) => Subtask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    description: description ?? this.description,
    isCompleted: isCompleted ?? this.isCompleted,
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  List<Object?> get props => [
    id, taskId, title, description, isCompleted, order, createdAt, updatedAt, createdBy,
  ];
}
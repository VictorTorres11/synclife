import 'package:equatable/equatable.dart';
import 'task_recurrence.dart';

/// Represents a task in the SyncLife system
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.boardId,
    this.assignedTo,
    required this.recurrence,
    this.dueDate,
    required this.isCompleted,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String? description;
  final String boardId;
  final String? assignedTo;
  final TaskRecurrence recurrence;
  final DateTime? dueDate;
  final bool isCompleted;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  /// Creates a Task from Firestore document data
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    boardId: map['boardId'] as String,
    assignedTo: map['assignedTo'] as String?,
    recurrence: TaskRecurrence.fromJson(map['recurrence'] as String),
    dueDate: map['dueDate'] != null 
        ? DateTime.parse(map['dueDate'] as String) 
        : null,
    isCompleted: map['isCompleted'] as bool,
    tags: List<String>.from(map['tags'] as List),
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    createdBy: map['createdBy'] as String,
  );

  /// Converts Task to Firestore document data
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'boardId': boardId,
    'assignedTo': assignedTo,
    'recurrence': recurrence.toJson(),
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? boardId,
    String? assignedTo,
    TaskRecurrence? recurrence,
    DateTime? dueDate,
    bool? isCompleted,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    boardId: boardId ?? this.boardId,
    assignedTo: assignedTo ?? this.assignedTo,
    recurrence: recurrence ?? this.recurrence,
    dueDate: dueDate ?? this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  List<Object?> get props => [
    id, title, description, boardId, assignedTo, recurrence,
    dueDate, isCompleted, tags, createdAt, updatedAt, createdBy,
  ];
}
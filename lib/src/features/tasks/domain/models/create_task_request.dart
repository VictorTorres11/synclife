import 'package:equatable/equatable.dart';
import 'task_recurrence.dart';

/// Request model for creating a new task
class CreateTaskRequest extends Equatable {
  const CreateTaskRequest({
    required this.title,
    this.description,
    required this.boardId,
    this.assignedTo,
    required this.recurrence,
    this.dueDate,
    required this.tags,
    required this.createdBy,
  });

  final String title;
  final String? description;
  final String boardId;
  final String? assignedTo;
  final TaskRecurrence recurrence;
  final DateTime? dueDate;
  final List<String> tags;
  final String createdBy;

  /// Creates a copy of this request with the given fields replaced with new values
  CreateTaskRequest copyWith({
    String? title,
    String? description,
    String? boardId,
    String? assignedTo,
    TaskRecurrence? recurrence,
    DateTime? dueDate,
    List<String>? tags,
    String? createdBy,
  }) {
    return CreateTaskRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      boardId: boardId ?? this.boardId,
      assignedTo: assignedTo ?? this.assignedTo,
      recurrence: recurrence ?? this.recurrence,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        boardId,
        assignedTo,
        recurrence,
        dueDate,
        tags,
        createdBy,
      ];
}

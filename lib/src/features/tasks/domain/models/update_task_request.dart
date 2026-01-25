import 'package:equatable/equatable.dart';
import 'task_recurrence.dart';

/// Request model for updating an existing task
class UpdateTaskRequest extends Equatable {
  const UpdateTaskRequest({
    this.title,
    this.description,
    this.assignedTo,
    this.recurrence,
    this.dueDate,
    this.isCompleted,
    this.tags,
  });

  final String? title;
  final String? description;
  final String? assignedTo;
  final TaskRecurrence? recurrence;
  final DateTime? dueDate;
  final bool? isCompleted;
  final List<String>? tags;

  /// Converts UpdateTaskRequest to map for serialization
  Map<String, dynamic> toMap() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (recurrence != null) 'recurrence': recurrence!.toJson(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (tags != null) 'tags': tags,
      };

  @override
  List<Object?> get props => [
        title,
        description,
        assignedTo,
        recurrence,
        dueDate,
        isCompleted,
        tags,
      ];
}

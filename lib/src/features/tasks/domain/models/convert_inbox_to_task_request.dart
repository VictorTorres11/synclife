import 'package:equatable/equatable.dart';
import 'task_recurrence.dart';

/// Request model for converting an inbox item to a task
class ConvertInboxToTaskRequest extends Equatable {
  const ConvertInboxToTaskRequest({
    required this.inboxItemId,
    required this.boardId,
    this.assignedTo,
    required this.recurrence,
    this.dueDate,
    required this.tags,
  });

  final String inboxItemId;
  final String boardId;
  final String? assignedTo;
  final TaskRecurrence recurrence;
  final DateTime? dueDate;
  final List<String> tags;

  @override
  List<Object?> get props => [
    inboxItemId, boardId, assignedTo, recurrence, dueDate, tags,
  ];
}
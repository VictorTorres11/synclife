import 'package:equatable/equatable.dart';

/// Request model for creating a new subtask
class CreateSubtaskRequest extends Equatable {
  const CreateSubtaskRequest({
    required this.taskId,
    required this.title,
    this.description,
    required this.createdBy,
  });

  final String taskId;
  final String title;
  final String? description;
  final String createdBy;

  @override
  List<Object?> get props => [taskId, title, description, createdBy];
}
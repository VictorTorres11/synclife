import 'package:equatable/equatable.dart';

/// Request model for creating a new task comment
class CreateCommentRequest extends Equatable {
  const CreateCommentRequest({
    required this.taskId,
    required this.content,
    required this.authorId,
  });

  final String taskId;
  final String content;
  final String authorId;

  @override
  List<Object?> get props => [taskId, content, authorId];
}
import '../models/task_comment.dart';
import '../models/create_comment_request.dart';

/// Abstract interface for task comment operations
abstract class CommentService {
  /// Get all comments for a task
  Future<List<TaskComment>> getTaskComments(String taskId);

  /// Create a new comment on a task
  Future<TaskComment> createComment(CreateCommentRequest request);

  /// Update an existing comment
  Future<TaskComment> updateComment(String commentId, String newContent);

  /// Delete a comment
  Future<void> deleteComment(String commentId);

  /// Watch comments for a task in real-time
  Stream<List<TaskComment>> watchTaskComments(String taskId);
}
import '../models/subtask.dart';
import '../models/create_subtask_request.dart';

/// Abstract interface for subtask management operations
abstract class SubtaskService {
  /// Get all subtasks for a specific task
  Future<List<Subtask>> getSubtasks(String taskId);

  /// Create a new subtask
  Future<Subtask> createSubtask(CreateSubtaskRequest request);

  /// Update subtask title/description
  Future<Subtask> updateSubtask(String subtaskId, {String? title, String? description});

  /// Toggle subtask completion status
  Future<Subtask> toggleSubtaskCompletion(String subtaskId);

  /// Delete a subtask
  Future<void> deleteSubtask(String subtaskId);

  /// Reorder subtasks
  Future<void> reorderSubtasks(String taskId, List<String> subtaskIds);

  /// Watch subtasks for real-time updates
  Stream<List<Subtask>> watchSubtasks(String taskId);

  /// Get subtask completion statistics for a task
  Future<SubtaskStats> getSubtaskStats(String taskId);
}

/// Statistics for subtasks within a task
class SubtaskStats {
  const SubtaskStats({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  int get remaining => total - completed;
  double get completionPercentage => total > 0 ? (completed / total) * 100 : 0;
  bool get isFullyCompleted => total > 0 && completed == total;
}
import '../models/task.dart';
import '../models/create_task_request.dart';
import '../models/update_task_request.dart';

/// Abstract interface for task management operations
abstract class TaskService {
  /// Get all tasks for a specific board
  Future<List<Task>> getTasks(String boardId);

  /// Get a single task by ID
  Future<Task?> getTask(String taskId);

  /// Create a new task
  Future<Task> createTask(CreateTaskRequest request);

  /// Update an existing task
  Future<Task> updateTask(String taskId, UpdateTaskRequest request);

  /// Delete a task
  Future<void> deleteTask(String taskId);

  /// Mark a task as completed
  Future<void> completeTask(String taskId);

  /// Watch tasks for real-time updates
  Stream<List<Task>> watchTasks(String boardId);

  /// Get tasks by user assignment
  Future<List<Task>> getTasksByUser(String userId);

  /// Get tasks by due date range
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end);

  /// Get tasks by tags
  Future<List<Task>> getTasksByTags(List<String> tags);
}

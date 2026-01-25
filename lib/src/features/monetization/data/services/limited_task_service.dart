import '../../domain/models/user_limitations.dart';
import '../../domain/services/services.dart';
import '../../../tasks/domain/services/task_service.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/domain/models/create_task_request.dart';
import '../../../tasks/domain/models/update_task_request.dart';

/// Task service wrapper that enforces user limitations
class LimitedTaskService implements TaskService {
  LimitedTaskService({
    required TaskService taskService,
    required SubscriptionService subscriptionService,
  })  : _taskService = taskService,
        _subscriptionService = subscriptionService;

  final TaskService _taskService;
  final SubscriptionService _subscriptionService;

  @override
  Future<List<Task>> getTasks(String boardId) {
    return _taskService.getTasks(boardId);
  }

  @override
  Future<Task?> getTask(String taskId) {
    return _taskService.getTask(taskId);
  }

  @override
  Future<Task> createTask(CreateTaskRequest request) async {
    // Check if user can create more tasks
    final canCreate = await _subscriptionService.canPerformAction(
      request.createdBy,
      LimitationType.activeTasks,
    );

    if (!canCreate) {
      throw TaskLimitExceededException(
        'You have reached your task limit. Upgrade to Premium for unlimited tasks.',
      );
    }

    // Create the task
    final task = await _taskService.createTask(request);

    // Increment usage counter
    await _subscriptionService.incrementUsage(
      request.createdBy,
      LimitationType.activeTasks,
    );

    return task;
  }

  @override
  Future<Task> updateTask(String taskId, UpdateTaskRequest request) {
    return _taskService.updateTask(taskId, request);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Get the task to find the owner
    final task = await _taskService.getTask(taskId);
    if (task == null) return;

    // Delete the task
    await _taskService.deleteTask(taskId);

    // Decrement usage counter
    await _subscriptionService.decrementUsage(
      task.createdBy,
      LimitationType.activeTasks,
    );
  }

  @override
  Future<void> completeTask(String taskId) {
    return _taskService.completeTask(taskId);
  }

  @override
  Stream<List<Task>> watchTasks(String boardId) {
    return _taskService.watchTasks(boardId);
  }

  @override
  Future<List<Task>> getTasksByUser(String userId) {
    return _taskService.getTasksByUser(userId);
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) {
    return _taskService.getTasksByDateRange(start, end);
  }

  @override
  Future<List<Task>> getTasksByTags(List<String> tags) {
    return _taskService.getTasksByTags(tags);
  }
}

/// Exception thrown when user exceeds task limits
class TaskLimitExceededException implements Exception {
  const TaskLimitExceededException(this.message);

  final String message;

  @override
  String toString() => 'TaskLimitExceededException: $message';
}

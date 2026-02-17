import '../../domain/models/models.dart';
import '../../domain/services/services.dart';
import '../../domain/exceptions/exceptions.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/domain/models/create_task_request.dart';
import '../../../tasks/domain/models/task_recurrence.dart';
import '../../../tasks/domain/services/task_service.dart';

/// Service to handle conversion of reminders to tasks
/// 
/// This service orchestrates the process of converting a reminder into a full task,
/// including creating the task, copying relevant data, and cleaning up the original reminder.
class ReminderConversionService {
  /// Creates a new ReminderConversionService
  /// 
  /// Parameters:
  /// - [reminderService]: Service for reminder operations
  /// - [taskService]: Service for task operations
  const ReminderConversionService({
    required this.reminderService,
    required this.taskService,
  });

  /// Service for reminder CRUD operations
  final ReminderService reminderService;
  
  /// Service for task CRUD operations
  final TaskService taskService;

  /// Convert a reminder to a task
  /// 
  /// This method performs the following steps:
  /// 1. Creates a new task with the reminder's content as the title
  /// 2. Copies the reminder's tags to the new task
  /// 3. Deletes the original reminder
  /// 
  /// The conversion is atomic in the sense that if task creation fails,
  /// the reminder is not deleted. However, if reminder deletion fails after
  /// task creation, both the task and reminder will exist (acceptable trade-off).
  /// 
  /// Parameters:
  /// - [reminder]: The reminder to convert
  /// - [targetBoardId]: The board ID where the task should be created
  /// 
  /// Returns the created [Task] object.
  /// 
  /// Throws [ConversionException] if the conversion process fails.
  Future<Task> convertToTask({
    required Reminder reminder,
    required String targetBoardId,
  }) async {
    try {
      // Step 1: Create task from reminder
      // Use the reminder's content as the task title
      // Copy tags from reminder to task
      // Set default values for task-specific fields
      final task = await taskService.createTask(
        CreateTaskRequest(
          title: reminder.content,
          boardId: targetBoardId,
          tags: reminder.tags,
          createdBy: reminder.userId,
          recurrence: TaskRecurrence.none,
        ),
      );

      // Step 2: Delete the original reminder
      // This also decrements the user's reminder count
      await reminderService.deleteReminder(reminder.id, reminder.userId);

      // Step 3: Return the created task
      return task;
    } catch (e) {
      // Wrap any errors in a ConversionException for consistent error handling
      throw ConversionException(
        'Failed to convert reminder to task: ${e.toString()}',
        originalReminder: reminder,
      );
    }
  }
}

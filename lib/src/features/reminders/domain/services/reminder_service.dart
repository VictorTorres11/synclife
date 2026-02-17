import '../models/models.dart';

/// Abstract service interface for reminder operations
/// 
/// This interface defines the contract for reminder CRUD operations,
/// real-time synchronization, and limitation checks.
abstract class ReminderService {
  /// Create a new reminder
  /// 
  /// Creates a reminder with the specified content, board, tags, and priority.
  /// Automatically sets createdAt and updatedAt timestamps.
  /// 
  /// Throws [LimitExceededException] if free user has reached their reminder limit.
  /// 
  /// Parameters:
  /// - [content]: The reminder text content (required, max 500 chars)
  /// - [userId]: ID of the user creating the reminder (required)
  /// - [boardId]: ID of the board to organize the reminder (required)
  /// - [tags]: Optional list of tags for categorization
  /// - [priority]: Priority level (default: medium)
  /// 
  /// Returns the created [Reminder] with generated ID and timestamps.
  Future<Reminder> createReminder({
    required String content,
    required String userId,
    required String boardId,
    List<String> tags = const [],
    ReminderPriority priority = ReminderPriority.medium,
  });

  /// Get all reminders for a user
  /// 
  /// Retrieves all reminders owned by the specified user,
  /// ordered by creation date (most recent first).
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to fetch
  /// 
  /// Returns a list of [Reminder] objects.
  Future<List<Reminder>> getReminders(String userId);

  /// Get reminders filtered by board
  /// 
  /// Retrieves reminders for a specific user and board combination,
  /// ordered by creation date (most recent first).
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to fetch
  /// - [boardId]: ID of the board to filter by
  /// 
  /// Returns a list of [Reminder] objects for the specified board.
  Future<List<Reminder>> getRemindersByBoard(String userId, String boardId);

  /// Search reminders by content
  /// 
  /// Performs a case-insensitive partial match search on reminder content.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to search
  /// - [query]: Search query string (case-insensitive)
  /// 
  /// Returns a list of [Reminder] objects matching the search query.
  Future<List<Reminder>> searchReminders(String userId, String query);

  /// Update an existing reminder
  /// 
  /// Updates one or more fields of an existing reminder.
  /// Automatically updates the updatedAt timestamp.
  /// 
  /// Parameters:
  /// - [reminderId]: ID of the reminder to update
  /// - [content]: New content text (optional)
  /// - [boardId]: New board ID (optional)
  /// - [tags]: New tags list (optional)
  /// - [priority]: New priority level (optional)
  /// 
  /// Returns the updated [Reminder] object.
  Future<Reminder> updateReminder(
    String reminderId, {
    String? content,
    String? boardId,
    List<String>? tags,
    ReminderPriority? priority,
  });

  /// Delete a reminder
  /// 
  /// Permanently deletes a reminder and decrements the user's reminder count.
  /// 
  /// Parameters:
  /// - [reminderId]: ID of the reminder to delete
  /// - [userId]: ID of the user who owns the reminder (for security)
  /// 
  /// Returns a Future that completes when the deletion is successful.
  Future<void> deleteReminder(String reminderId, String userId);

  /// Watch reminders for real-time updates
  /// 
  /// Returns a stream that emits the user's reminders whenever they change.
  /// Useful for real-time UI updates.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to watch
  /// 
  /// Returns a [Stream] of reminder lists that updates in real-time.
  Stream<List<Reminder>> watchReminders(String userId);

  /// Watch reminders filtered by board for real-time updates
  /// 
  /// Returns a stream that emits reminders for a specific board whenever they change.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to watch
  /// - [boardId]: ID of the board to filter by
  /// 
  /// Returns a [Stream] of reminder lists for the specified board.
  Stream<List<Reminder>> watchRemindersByBoard(String userId, String boardId);

  /// Get reminder count for a user
  /// 
  /// Returns the total number of reminders owned by the user.
  /// Used for limitation checks.
  /// 
  /// Parameters:
  /// - [userId]: ID of the user whose reminders to count
  /// 
  /// Returns the count of reminders.
  Future<int> getReminderCount(String userId);
}

import '../models/inbox_item.dart';
import '../models/create_inbox_item_request.dart';
import '../models/convert_inbox_to_task_request.dart';
import '../models/task.dart';

/// Abstract interface for inbox management operations
abstract class InboxService {
  /// Get all inbox items for a user
  Future<List<InboxItem>> getInboxItems(String userId);

  /// Create a new inbox item (quick note)
  Future<InboxItem> createInboxItem(CreateInboxItemRequest request);

  /// Update an inbox item content
  Future<InboxItem> updateInboxItem(String itemId, String newContent);

  /// Delete an inbox item
  Future<void> deleteInboxItem(String itemId);

  /// Convert an inbox item to a task
  Future<Task> convertInboxItemToTask(ConvertInboxToTaskRequest request);

  /// Watch inbox items for real-time updates
  Stream<List<InboxItem>> watchInboxItems(String userId);

  /// Validate inbox item content
  bool validateInboxContent(String content);
}
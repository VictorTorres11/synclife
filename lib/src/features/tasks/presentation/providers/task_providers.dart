import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/providers/sync_providers.dart';
import '../../domain/models/task.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/services/task_service.dart';

/// Main task service provider - uses offline-first service
final taskServiceProvider = Provider<TaskService>((ref) {
  return ref.read(offlineTaskServiceProvider);
});

/// Provider for tasks by board ID
final tasksProvider =
    FutureProvider.family<List<Task>, String>((ref, boardId) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTasks(boardId);
});

/// Provider for watching tasks by board ID (real-time updates)
final watchTasksProvider =
    StreamProvider.family<List<Task>, String>((ref, boardId) {
  final taskService = ref.read(taskServiceProvider);
  return taskService.watchTasks(boardId);
});

/// Provider for tasks by user ID
final tasksByUserProvider =
    FutureProvider.family<List<Task>, String>((ref, userId) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTasksByUser(userId);
});

/// Provider for tasks by date range
final tasksByDateRangeProvider =
    FutureProvider.family<List<Task>, DateRange>((ref, dateRange) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTasksByDateRange(dateRange.start, dateRange.end);
});

/// Provider for tasks by tags
final tasksByTagsProvider =
    FutureProvider.family<List<Task>, List<String>>((ref, tags) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTasksByTags(tags);
});

/// Helper class for date range parameters
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// State notifier for managing inbox items
class InboxItemsNotifier extends StateNotifier<List<InboxItem>> {
  InboxItemsNotifier() : super([]);

  void addItem(InboxItem item) {
    state = [...state, item];
  }

  void updateItem(String itemId, String newContent) {
    state = state.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  void setItems(List<InboxItem> items) {
    state = items;
  }
}

/// Provider for managing inbox items
final inboxItemsProvider = StateNotifierProvider<InboxItemsNotifier, List<InboxItem>>((ref) {
  return InboxItemsNotifier();
});

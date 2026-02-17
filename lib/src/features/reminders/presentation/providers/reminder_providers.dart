import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/monetization/presentation/providers/monetization_providers.dart';
import '../../../../features/tasks/presentation/providers/task_providers.dart';
import '../../data/services/firebase_reminder_service.dart';
import '../../data/services/limited_reminder_service.dart';
import '../../data/services/reminder_conversion_service.dart';
import '../../domain/models/models.dart';
import '../../domain/services/reminder_service.dart';

/// Provider for LimitedReminderService
/// 
/// This service enforces reminder limitations for free users.
/// It checks if users can create more reminders and manages reminder counts.
final limitedReminderServiceProvider = Provider<LimitedReminderService>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return LimitedReminderService(
    firestore: FirebaseFirestore.instance,
    subscriptionService: subscriptionService,
  );
});

/// Provider for the main reminder service (Firebase implementation)
/// 
/// This is the primary service for all reminder CRUD operations.
/// It uses Firestore as the backend and integrates with the limitation service.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final limitationService = ref.watch(limitedReminderServiceProvider);
  return FirebaseReminderService(
    firestore: FirebaseFirestore.instance,
    limitationService: limitationService,
  );
});

/// Provider for reminder conversion service
/// 
/// This service handles the conversion of reminders to tasks,
/// including creating the task, copying data, and cleaning up the reminder.
final reminderConversionServiceProvider =
    Provider<ReminderConversionService>((ref) {
  final reminderService = ref.watch(reminderServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  return ReminderConversionService(
    reminderService: reminderService,
    taskService: taskService,
  );
});

/// Provider for watching reminders for a specific user (real-time updates)
/// 
/// This stream provider automatically updates when reminders are added,
/// updated, or deleted. It uses autoDispose to clean up when not in use.
/// 
/// Usage: `ref.watch(remindersStreamProvider(userId))`
final remindersStreamProvider =
    StreamProvider.autoDispose.family<List<Reminder>, String>((ref, userId) {
  final service = ref.watch(reminderServiceProvider);
  return service.watchReminders(userId);
});

/// Provider for board filter selection
/// 
/// Stores the currently selected board ID for filtering reminders.
/// Null means "All Boards" (no filter applied).
final selectedBoardFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Provider for search query
/// 
/// Stores the current search query string for filtering reminders by content.
/// Empty string means no search filter is applied.
final reminderSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider for filtered reminders based on board filter and search query
/// 
/// This derived provider combines the reminders stream with the current
/// board filter and search query to provide a filtered list of reminders.
/// 
/// Filters are applied in the following order:
/// 1. Board filter (if a board is selected)
/// 2. Search query (case-insensitive content matching)
final filteredRemindersProvider =
    Provider.autoDispose<AsyncValue<List<Reminder>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const AsyncValue.data([]);
  }

  final remindersAsync = ref.watch(remindersStreamProvider(user.id));
  final selectedBoard = ref.watch(selectedBoardFilterProvider);
  final searchQuery = ref.watch(reminderSearchQueryProvider);

  return remindersAsync.whenData((reminders) {
    var filtered = reminders;

    // Apply board filter
    if (selectedBoard != null && selectedBoard.isNotEmpty) {
      filtered = filtered.where((r) => r.boardId == selectedBoard).toList();
    }

    // Apply search filter (case-insensitive)
    if (searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      filtered = filtered
          .where((r) => r.content.toLowerCase().contains(queryLower))
          .toList();
    }

    return filtered;
  });
});

/// Provider for user limitations (already exists in monetization_providers.dart)
/// We're reusing the existing userLimitationsProvider from monetization
/// This is just a reference comment for clarity

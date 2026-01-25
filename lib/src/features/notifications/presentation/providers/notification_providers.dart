import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/device_token_service.dart';
import '../../data/services/firebase_notification_reaction_service.dart';
import '../../data/services/firebase_notification_service.dart';
import '../../data/services/notification_scheduler_service.dart';
import '../../data/services/scheduled_notification_service_impl.dart';
import '../../domain/models/notification_preferences.dart';
import '../../domain/models/notification_reaction.dart';
import '../../domain/models/notification_summary.dart';
import '../../domain/models/scheduled_notification.dart';
import '../../domain/services/notification_reaction_service.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/scheduled_notification_service.dart';

/// Provider for the notification reaction service
final notificationReactionServiceProvider =
    Provider<NotificationReactionService>((ref) {
  return FirebaseNotificationReactionService();
});

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FirebaseNotificationService();
});

/// Provider for the scheduled notification service
final scheduledNotificationServiceProvider =
    Provider<ScheduledNotificationService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return ScheduledNotificationServiceImpl(
    firestore: FirebaseFirestore.instance,
    notificationService: notificationService,
  );
});

/// Provider for the notification scheduler service
final notificationSchedulerServiceProvider =
    Provider<NotificationSchedulerService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  final scheduledService = ref.read(scheduledNotificationServiceProvider);
  return NotificationSchedulerService(
    firestore: FirebaseFirestore.instance,
    notificationService: notificationService,
    scheduledNotificationService: scheduledService,
  );
});

/// Provider for the device token service
final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(
    firestore: FirebaseFirestore.instance,
    messaging: FirebaseMessaging.instance,
  );
});

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getPreferences();
});

/// Provider for notification permissions status
final notificationPermissionsProvider = FutureProvider<bool>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.areNotificationsEnabled();
});

/// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getToken();
});

/// State notifier for managing notification preferences
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  NotificationPreferencesNotifier(this._notificationService)
      : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  final NotificationService _notificationService;

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _notificationService.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _notificationService.updatePreferences(preferences);
      state = AsyncValue.data(preferences);

      // Update scheduled notifications when preferences change
      // Note: In a real app, you'd get the current user ID from auth service
      // For now, this is a placeholder - the actual user ID should be injected
      // await _scheduledService.updateSchedulesForUser(currentUserId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> togglePushNotifications() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enablePushNotifications: !currentPrefs.enablePushNotifications,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> toggleDailySummary() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enableDailySummary: !currentPrefs.enableDailySummary,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> toggleTeamUpdates() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enableTeamUpdates: !currentPrefs.enableTeamUpdates,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> toggleNightSummary() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enableNightSummary: !currentPrefs.enableNightSummary,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> toggleTaskReminders() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enableTaskReminders: !currentPrefs.enableTaskReminders,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> toggleQuietHours() async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        enableQuietHours: !currentPrefs.enableQuietHours,
      );
      await updatePreferences(newPrefs);
    }
  }

  Future<void> updateMorningTime(TimeOfDay time) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(morningTime: time);
      await updatePreferences(newPrefs);
    }
  }

  Future<void> updateNightTime(TimeOfDay time) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(nightTime: time);
      await updatePreferences(newPrefs);
    }
  }

  Future<void> updateQuietHours(TimeOfDay start, TimeOfDay end) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final newPrefs = currentPrefs.copyWith(
        quietHoursStart: start,
        quietHoursEnd: end,
      );
      await updatePreferences(newPrefs);
    }
  }
}

/// Provider for the notification preferences notifier
final notificationPreferencesNotifierProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationPreferencesNotifier(notificationService);
});

/// Provider for foreground messages stream
final foregroundMessagesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.onForegroundMessage;
});

/// Provider for messages that opened the app
final messageOpenedAppProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.onMessageOpenedApp;
});

/// Provider for pending scheduled notifications
final pendingNotificationsProvider =
    FutureProvider.family<List<ScheduledNotification>, String>(
        (ref, userId) async {
  final scheduledService = ref.read(scheduledNotificationServiceProvider);
  return await scheduledService.getPendingNotifications(userId);
});

/// Provider for morning summary generation
final morningSummaryProvider =
    FutureProvider.family<MorningSummary, String>((ref, userId) async {
  final scheduledService = ref.read(scheduledNotificationServiceProvider);
  return await scheduledService.generateMorningSummary(userId);
});

/// Provider for night summary generation
final nightSummaryProvider =
    FutureProvider.family<NightSummary, String>((ref, userId) async {
  final scheduledService = ref.read(scheduledNotificationServiceProvider);
  return await scheduledService.generateNightSummary(userId);
});

/// Provider for notification statistics
final notificationStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final schedulerService = ref.read(notificationSchedulerServiceProvider);
  return await schedulerService.getNotificationStats(userId);
});

/// Provider for manual morning summary trigger
final triggerMorningSummaryProvider =
    Provider.family<Future<void> Function(), String>((ref, userId) {
  final schedulerService = ref.read(notificationSchedulerServiceProvider);
  return () => schedulerService.triggerMorningSummary(userId);
});

/// Provider for manual night summary trigger
final triggerNightSummaryProvider =
    Provider.family<Future<void> Function(), String>((ref, userId) {
  final schedulerService = ref.read(notificationSchedulerServiceProvider);
  return () => schedulerService.triggerNightSummary(userId);
});

/// Provider for notification reaction summary
final notificationReactionSummaryProvider =
    FutureProvider.family<NotificationReactionSummary?, String>(
        (ref, notificationId) async {
  final reactionService = ref.read(notificationReactionServiceProvider);
  return await reactionService.getReactionSummary(notificationId);
});

/// Provider for watching notification reaction summary
final watchNotificationReactionSummaryProvider =
    StreamProvider.family<NotificationReactionSummary, String>(
        (ref, notificationId) {
  final reactionService = ref.read(notificationReactionServiceProvider);
  return reactionService.watchReactionSummary(notificationId);
});

/// Provider for user's reaction to a notification
final userNotificationReactionProvider = FutureProvider.family<
    NotificationReaction?,
    ({String notificationId, String userId})>((ref, params) async {
  final reactionService = ref.read(notificationReactionServiceProvider);
  return await reactionService.getUserReaction(
    notificationId: params.notificationId,
    userId: params.userId,
  );
});

/// Provider for sending reactions
final sendReactionProvider = Provider.family<
    Future<void> Function(EmojiReaction),
    ({String notificationId, String userId})>((ref, params) {
  final reactionService = ref.read(notificationReactionServiceProvider);
  return (reaction) => reactionService.sendReaction(
        notificationId: params.notificationId,
        userId: params.userId,
        reaction: reaction,
      );
});

/// Provider for removing reactions
final removeReactionProvider = Provider.family<Future<void> Function(),
    ({String notificationId, String userId})>((ref, params) {
  final reactionService = ref.read(notificationReactionServiceProvider);
  return () => reactionService.removeReaction(
        notificationId: params.notificationId,
        userId: params.userId,
      );
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/notification_preferences.dart';
import '../../domain/models/scheduled_notification.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/scheduled_notification_service.dart';
import 'notification_preferences_sync_service.dart';

/// Service to coordinate scheduled notifications between client and server
class NotificationSchedulerService {
  NotificationSchedulerService({
    required FirebaseFirestore firestore,
    required NotificationService notificationService,
    required ScheduledNotificationService scheduledNotificationService,
  })  : _firestore = firestore,
        _notificationService = notificationService,
        _scheduledNotificationService = scheduledNotificationService,
        _preferencesSync = NotificationPreferencesSyncService(
          firestore: firestore,
        );

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final ScheduledNotificationService _scheduledNotificationService;
  final NotificationPreferencesSyncService _preferencesSync;

  /// Initialize scheduled notifications for a user
  Future<void> initializeScheduledNotifications(String userId) async {
    try {
      debugPrint('Initializing scheduled notifications for user $userId');

      // Get current preferences
      final preferences = await _notificationService.getPreferences();

      // Sync preferences to Firestore for Cloud Functions access
      await _preferencesSync.syncPreferencesToFirestore(userId, preferences);

      // Setup daily schedules
      await _scheduledNotificationService.setupDailySchedules(userId);

      debugPrint(
          'Successfully initialized scheduled notifications for user $userId');
    } catch (e) {
      debugPrint(
          'Error initializing scheduled notifications for user $userId: $e');
      rethrow;
    }
  }

  /// Update scheduled notifications when preferences change
  Future<void> updateScheduledNotifications(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      debugPrint('Updating scheduled notifications for user $userId');

      // Sync updated preferences to Firestore
      await _preferencesSync.syncPreferencesToFirestore(userId, preferences);

      // Update schedules based on new preferences
      await _scheduledNotificationService.updateSchedulesForUser(userId);

      debugPrint(
          'Successfully updated scheduled notifications for user $userId');
    } catch (e) {
      debugPrint('Error updating scheduled notifications for user $userId: $e');
      rethrow;
    }
  }

  /// Handle team activity notification
  Future<void> handleTeamActivity(
    String boardId,
    String actorUserId,
    String taskTitle,
    String action,
  ) async {
    try {
      // Get board information
      final boardDoc = await _firestore.collection('boards').doc(boardId).get();

      if (!boardDoc.exists) {
        debugPrint('Board $boardId not found');
        return;
      }

      final board = boardDoc.data()!;
      final memberIds = List<String>.from(board['memberIds'] ?? []);

      // Get actor information
      final actorDoc =
          await _firestore.collection('users').doc(actorUserId).get();
      final actorName = actorDoc.exists
          ? (actorDoc.data()?['displayName'] ?? 'Someone')
          : 'Someone';

      // Send notifications to other board members
      for (final memberId in memberIds) {
        if (memberId != actorUserId) {
          await _scheduledNotificationService.scheduleTeamActivityNotification(
            memberId,
            boardId,
            actorName,
            taskTitle,
            action,
          );
        }
      }

      debugPrint('Scheduled team activity notifications for board $boardId');
    } catch (e) {
      debugPrint('Error handling team activity notification: $e');
      rethrow;
    }
  }

  /// Clean up scheduled notifications for a user (e.g., when they delete their account)
  Future<void> cleanupUserNotifications(String userId) async {
    try {
      debugPrint('Cleaning up notifications for user $userId');

      // Delete preferences from Firestore
      await _preferencesSync.deletePreferencesFromFirestore(userId);

      // Cancel all pending notifications for the user
      final pendingNotifications =
          await _scheduledNotificationService.getPendingNotifications(userId);

      for (final notification in pendingNotifications) {
        await _scheduledNotificationService
            .cancelScheduledNotification(notification.id);
      }

      debugPrint('Successfully cleaned up notifications for user $userId');
    } catch (e) {
      debugPrint('Error cleaning up notifications for user $userId: $e');
      rethrow;
    }
  }

  /// Get notification statistics for a user
  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    try {
      final pendingNotifications =
          await _scheduledNotificationService.getPendingNotifications(userId);

      final stats = <String, dynamic>{
        'pendingCount': pendingNotifications.length,
        'morningSummaryCount': pendingNotifications
            .where((n) => n.type == ScheduledNotificationType.morningSummary)
            .length,
        'nightSummaryCount': pendingNotifications
            .where((n) => n.type == ScheduledNotificationType.nightSummary)
            .length,
        'teamActivityCount': pendingNotifications
            .where((n) => n.type == ScheduledNotificationType.teamActivity)
            .length,
        'taskReminderCount': pendingNotifications
            .where((n) => n.type == ScheduledNotificationType.taskReminder)
            .length,
      };

      return stats;
    } catch (e) {
      debugPrint('Error getting notification stats for user $userId: $e');
      return {};
    }
  }

  /// Manually trigger a morning summary for testing
  Future<void> triggerMorningSummary(String userId) async {
    try {
      final summary =
          await _scheduledNotificationService.generateMorningSummary(userId);
      await _scheduledNotificationService.scheduleMorningSummary(
        userId,
        DateTime.now().add(const Duration(seconds: 5)), // Send in 5 seconds
        summary,
      );

      debugPrint('Triggered morning summary for user $userId');
    } catch (e) {
      debugPrint('Error triggering morning summary for user $userId: $e');
      rethrow;
    }
  }

  /// Manually trigger a night summary for testing
  Future<void> triggerNightSummary(String userId) async {
    try {
      final summary =
          await _scheduledNotificationService.generateNightSummary(userId);
      await _scheduledNotificationService.scheduleNightSummary(
        userId,
        DateTime.now().add(const Duration(seconds: 5)), // Send in 5 seconds
        summary,
      );

      debugPrint('Triggered night summary for user $userId');
    } catch (e) {
      debugPrint('Error triggering night summary for user $userId: $e');
      rethrow;
    }
  }
}

import '../models/scheduled_notification.dart';
import '../models/notification_summary.dart';

/// Abstract service for managing scheduled notifications
abstract class ScheduledNotificationService {
  /// Schedule a morning summary notification for a user
  Future<void> scheduleMorningSummary(
    String userId,
    DateTime scheduledTime,
    MorningSummary summary,
  );

  /// Schedule a night summary notification for a user
  Future<void> scheduleNightSummary(
    String userId,
    DateTime scheduledTime,
    NightSummary summary,
  );

  /// Schedule a team activity notification
  Future<void> scheduleTeamActivityNotification(
    String userId,
    String boardId,
    String memberName,
    String taskTitle,
    String action,
  );

  /// Get pending scheduled notifications for a user
  Future<List<ScheduledNotification>> getPendingNotifications(String userId);

  /// Mark a scheduled notification as processed
  Future<void> markAsProcessed(String notificationId);

  /// Cancel a scheduled notification
  Future<void> cancelScheduledNotification(String notificationId);

  /// Generate morning summary data for a user
  Future<MorningSummary> generateMorningSummary(String userId);

  /// Generate night summary data for a user
  Future<NightSummary> generateNightSummary(String userId);

  /// Process all pending notifications (called by Cloud Function)
  Future<void> processPendingNotifications();

  /// Setup daily notification schedules for a user based on their preferences
  Future<void> setupDailySchedules(String userId);

  /// Update notification schedules when user preferences change
  Future<void> updateSchedulesForUser(String userId);

  /// Clean up old processed notifications
  Future<void> cleanupOldNotifications({int daysToKeep = 30});
}

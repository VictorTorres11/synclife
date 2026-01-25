import '../models/notification_preferences.dart';
import '../models/notification_reaction.dart';
import '../models/app_notification.dart';

/// Abstract notification service interface
abstract class NotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Request notification permissions from the user
  Future<bool> requestPermissions();

  /// Get the current FCM token for this device
  Future<String?> getToken();

  /// Subscribe to a topic for receiving notifications
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);

  /// Update user notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences);

  /// Get current notification preferences
  Future<NotificationPreferences> getPreferences();

  /// Send a notification to a specific user
  Future<void> sendNotificationToUser(String userId, String title, String body,
      {Map<String, dynamic>? data});

  /// Send a notification to a board/topic
  Future<void> sendNotificationToTopic(String topic, String title, String body,
      {Map<String, dynamic>? data});

  /// Handle foreground notification received
  Stream<Map<String, dynamic>> get onForegroundMessage;

  /// Handle notification tap when app is in background/terminated
  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled();

  /// Open app notification settings
  Future<void> openNotificationSettings();

  /// Send emoji reaction to a notification
  Future<void> sendReaction({
    required String notificationId,
    required String userId,
    required EmojiReaction reaction,
  });

  /// Remove emoji reaction from a notification
  Future<void> removeReaction({
    required String notificationId,
    required String userId,
  });

  // Notification Center Methods

  /// Get user's notifications
  Future<List<AppNotification>> getUserNotifications(String userId);

  /// Watch user's notifications in real-time
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Clear all read notifications for a user
  Future<void> clearReadNotifications();

  /// Create a new notification
  Future<AppNotification> createNotification(AppNotification notification);

  /// Get unread notification count
  Future<int> getUnreadCount(String userId);

  /// Set the current user ID for notification operations
  void setCurrentUserId(String userId);
}

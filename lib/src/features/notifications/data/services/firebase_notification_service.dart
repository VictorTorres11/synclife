import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/notification_preferences.dart';
import '../../domain/models/notification_reaction.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/services/notification_service.dart';
import 'firebase_notification_reaction_service.dart';
import 'notification_preferences_sync_service.dart';

/// Firebase implementation of the notification service
class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    FirebaseFirestore? firestore,
  })  : _messaging = FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _preferencesSync = NotificationPreferencesSyncService(
          firestore: firestore ?? FirebaseFirestore.instance,
        ),
        _reactionService = FirebaseNotificationReactionService(
          firestore: firestore ?? FirebaseFirestore.instance,
        );

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final NotificationPreferencesSyncService _preferencesSync;
  final FirebaseNotificationReactionService _reactionService;
  final StreamController<Map<String, dynamic>> _foregroundMessageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageOpenedController =
      StreamController.broadcast();

  static const String _preferencesKey = 'notification_preferences';
  String? _currentUserId; // Store current user ID for notification operations

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  @override
  Future<void> initialize() async {
    // Request permissions
    await requestPermissions();

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleNotificationAction(message);
      _foregroundMessageController.add(_messageToMap(message));
    });

    // Configure background message handling when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.messageId}');
      _handleNotificationAction(message);
      _messageOpenedController.add(_messageToMap(message));
    });

    // Handle initial message if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.messageId}');
      _handleNotificationAction(initialMessage);
      _messageOpenedController.add(_messageToMap(initialMessage));
    }

    // Configure background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  Future<bool> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
        'Notification permission status: ${settings.authorizationStatus}');

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } on Exception catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } on Exception catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } on Exception catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(preferences.toMap());
      await prefs.setString(_preferencesKey, preferencesJson);

      // Sync to Firestore for Cloud Functions access
      // Note: In a real app, you'd get the current user ID from auth service
      // For now, this is a placeholder - the actual user ID should be injected
      // await _preferencesSync.syncPreferencesToFirestore(currentUserId, preferences);

      debugPrint('Updated notification preferences');
    } on Exception catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);

      if (preferencesJson != null) {
        final preferencesMap =
            jsonDecode(preferencesJson) as Map<String, dynamic>;
        return NotificationPreferences.fromMap(preferencesMap);
      }
    } on Exception catch (e) {
      debugPrint('Error getting notification preferences: $e');
    }

    // Return default preferences if none found or error occurred
    return const NotificationPreferences();
  }

  @override
  Future<void> sendNotificationToUser(String userId, String title, String body,
      {Map<String, dynamic>? data}) async {
    // This would typically be handled by a backend service
    // For now, we'll just log the intent
    debugPrint('Would send notification to user $userId: $title - $body');
    if (data != null) {
      debugPrint('With data: $data');
    }
  }

  @override
  Future<void> sendNotificationToTopic(String topic, String title, String body,
      {Map<String, dynamic>? data}) async {
    // This would typically be handled by a backend service
    // For now, we'll just log the intent
    debugPrint('Would send notification to topic $topic: $title - $body');
    if (data != null) {
      debugPrint('With data: $data');
    }
  }

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _foregroundMessageController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _messageOpenedController.stream;

  @override
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> openNotificationSettings() async {
    // This would open the system notification settings
    // Implementation depends on platform-specific code
    debugPrint('Would open notification settings');
  }

  /// Sync notification preferences to Firestore for a specific user
  Future<void> syncPreferencesForUser(
      String userId, NotificationPreferences preferences) async {
    try {
      await _preferencesSync.syncPreferencesToFirestore(userId, preferences);
    } catch (e) {
      debugPrint('Error syncing preferences for user $userId: $e');
      rethrow;
    }
  }

  /// Get notification preferences from Firestore for a specific user
  Future<NotificationPreferences?> getPreferencesForUser(String userId) async {
    try {
      return await _preferencesSync.getPreferencesFromFirestore(userId);
    } catch (e) {
      debugPrint('Error getting preferences for user $userId: $e');
      return null;
    }
  }

  /// Convert RemoteMessage to Map for easier handling
  Map<String, dynamic> _messageToMap(RemoteMessage message) {
    return {
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'sentTime': message.sentTime?.millisecondsSinceEpoch,
    };
  }

  @override
  Future<void> sendReaction({
    required String notificationId,
    required String userId,
    required EmojiReaction reaction,
  }) async {
    await _reactionService.sendReaction(
      notificationId: notificationId,
      userId: userId,
      reaction: reaction,
    );
  }

  @override
  Future<void> removeReaction({
    required String notificationId,
    required String userId,
  }) async {
    await _reactionService.removeReaction(
      notificationId: notificationId,
      userId: userId,
    );
  }

  /// Handle notification actions (like emoji reactions)
  Future<void> _handleNotificationAction(RemoteMessage message) async {
    final data = message.data;

    // Check if this is a reaction action
    if (data.containsKey('action') && data['action'] == 'reaction') {
      final notificationId = data['notificationId'];
      final userId = data['userId'];
      final reactionValue = data['reaction'];

      if (notificationId != null && userId != null && reactionValue != null) {
        try {
          await _reactionService.processNotificationReaction(
            notificationId: notificationId,
            userId: userId,
            reactionValue: reactionValue,
          );
          debugPrint('Processed notification reaction: $reactionValue');
        } catch (e) {
          debugPrint('Error processing notification reaction: $e');
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundMessageController.close();
    _messageOpenedController.close();
  }

  // Notification Center Methods Implementation

  /// Set the current user ID for notification operations
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  @override
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .where((notification) => !notification.isExpired)
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .where((notification) => !notification.isExpired)
            .toList());
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) {
      throw Exception('User ID not set. Call setCurrentUserId first.');
    }

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearReadNotifications() async {
    if (_currentUserId == null) {
      throw Exception('User ID not set. Call setCurrentUserId first.');
    }

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing read notifications: $e');
      rethrow;
    }
  }

  @override
  Future<AppNotification> createNotification(
      AppNotification notification) async {
    try {
      final docRef = _notificationsCollection.doc(notification.id);
      await docRef.set(notification.toMap());
      return notification;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

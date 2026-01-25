import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service for managing device tokens in Firestore
class DeviceTokenService {
  DeviceTokenService({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firestore = firestore,
        _messaging = messaging;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  /// Register the current device token for a user
  Future<void> registerDeviceToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('No FCM token available');
        return;
      }

      final deviceInfo = {
        'token': token,
        'platform': _getPlatform(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Store token in user's device tokens subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .set(deviceInfo, SetOptions(merge: true));

      debugPrint('Device token registered for user: $userId');
    } on Exception catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }

  /// Remove the current device token for a user
  Future<void> unregisterDeviceToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('No FCM token available');
        return;
      }

      // Mark token as inactive instead of deleting for audit purposes
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .update({
        'isActive': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint('Device token unregistered for user: $userId');
    } on Exception catch (e) {
      debugPrint('Error unregistering device token: $e');
    }
  }

  /// Get all active device tokens for a user
  Future<List<String>> getUserDeviceTokens(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()['token'] as String).toList();
    } on Exception catch (e) {
      debugPrint('Error getting user device tokens: $e');
      return [];
    }
  }

  /// Clean up old/inactive device tokens
  Future<void> cleanupOldTokens(String userId) async {
    try {
      // Remove tokens older than 30 days that are inactive
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .where('isActive', isEqualTo: false)
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} old device tokens');
    } on Exception catch (e) {
      debugPrint('Error cleaning up old tokens: $e');
    }
  }

  /// Listen for token refresh and update in Firestore
  void listenForTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await registerDeviceToken(userId);
    });
  }

  /// Subscribe user to board notifications (only for mobile platforms)
  Future<void> subscribeToBoard(String boardId) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.subscribeToTopic('board_$boardId');
      debugPrint('Subscribed to board notifications: $boardId');
    } on Exception catch (e) {
      debugPrint('Error subscribing to board notifications: $e');
    }
  }

  /// Unsubscribe user from board notifications (only for mobile platforms)
  Future<void> unsubscribeFromBoard(String boardId) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.unsubscribeFromTopic('board_$boardId');
      debugPrint('Unsubscribed from board notifications: $boardId');
    } on Exception catch (e) {
      debugPrint('Error unsubscribing from board notifications: $e');
    }
  }

  /// Subscribe to user-specific notifications (only for mobile platforms)
  Future<void> subscribeToUserNotifications(String userId) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.subscribeToTopic('user_$userId');
      debugPrint('Subscribed to user notifications: $userId');
    } on Exception catch (e) {
      debugPrint('Error subscribing to user notifications: $e');
    }
  }

  /// Unsubscribe from user-specific notifications (only for mobile platforms)
  Future<void> unsubscribeFromUserNotifications(String userId) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions not supported on web platform');
      return;
    }

    try {
      await _messaging.unsubscribeFromTopic('user_$userId');
      debugPrint('Unsubscribed from user notifications: $userId');
    } on Exception catch (e) {
      debugPrint('Error unsubscribing from user notifications: $e');
    }
  }

  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }
}

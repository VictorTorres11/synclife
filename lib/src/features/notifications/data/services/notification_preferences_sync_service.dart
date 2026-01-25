import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/notification_preferences.dart';

/// Service to sync notification preferences to Firestore for Cloud Functions access
class NotificationPreferencesSyncService {
  NotificationPreferencesSyncService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Sync user notification preferences to Firestore
  Future<void> syncPreferencesToFirestore(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection('userNotificationPreferences')
          .doc(userId)
          .set(preferences.toMap());

      debugPrint(
          'Synced notification preferences for user $userId to Firestore');
    } catch (e) {
      debugPrint('Error syncing notification preferences to Firestore: $e');
      rethrow;
    }
  }

  /// Get user notification preferences from Firestore
  Future<NotificationPreferences?> getPreferencesFromFirestore(
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('userNotificationPreferences')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return NotificationPreferences.fromMap(doc.data()!);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting notification preferences from Firestore: $e');
      return null;
    }
  }

  /// Delete user notification preferences from Firestore
  Future<void> deletePreferencesFromFirestore(String userId) async {
    try {
      await _firestore
          .collection('userNotificationPreferences')
          .doc(userId)
          .delete();

      debugPrint(
          'Deleted notification preferences for user $userId from Firestore');
    } catch (e) {
      debugPrint('Error deleting notification preferences from Firestore: $e');
      rethrow;
    }
  }

  /// Listen to changes in user notification preferences
  Stream<NotificationPreferences?> watchPreferencesFromFirestore(
    String userId,
  ) {
    return _firestore
        .collection('userNotificationPreferences')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return NotificationPreferences.fromMap(doc.data()!);
      }
      return null;
    });
  }
}

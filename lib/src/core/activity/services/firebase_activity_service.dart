import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import 'activity_service.dart';

class FirebaseActivityService implements ActivityService {
  FirebaseActivityService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference get _activitiesCollection =>
      _firestore.collection('activities');

  @override
  Future<void> logActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? relatedEntityId,
  }) async {
    try {
      final activity = ActivityLog(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        title: title,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
        relatedEntityId: relatedEntityId,
      );

      await _activitiesCollection.doc(activity.id).set(activity.toMap());
    } catch (e) {
      // Log error but don't throw - activity logging shouldn't break the app
      print('Error logging activity: $e');
    }
  }

  @override
  Stream<List<ActivityLog>> getRecentActivities(String userId, {int limit = 10}) {
    try {
      return _activitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return ActivityLog.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing activity document ${doc.id}: $e');
                return null;
              }
            })
            .where((activity) => activity != null)
            .cast<ActivityLog>()
            .toList();
      }).handleError((error) {
        print('Error fetching activities for user $userId: $error');
        // Return empty list on error instead of throwing
        return <ActivityLog>[];
      });
    } catch (e) {
      print('Error setting up activities stream for user $userId: $e');
      // Return a stream with empty list if setup fails
      return Stream.value(<ActivityLog>[]);
    }
  }

  @override
  Stream<List<ActivityLog>> getUserActivities(
    String userId, {
    int limit = 50,
    DateTime? startAfter,
  }) {
    Query query = _activitiesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (startAfter != null) {
      query = query.startAfter([startAfter.toIso8601String()]);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> cleanupOldActivities(String userId, {int keepDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      final oldActivities = await _activitiesCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in oldActivities.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up old activities: $e');
    }
  }
}
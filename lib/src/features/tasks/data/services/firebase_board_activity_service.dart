import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/board_activity.dart';
import '../../domain/services/board_activity_service.dart';

/// Firebase implementation of board activity service
class FirebaseBoardActivityService implements BoardActivityService {
  FirebaseBoardActivityService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _activitiesCollection =>
      _firestore.collection('board_activities');

  CollectionReference get _presenceCollection =>
      _firestore.collection('user_presence');

  @override
  Future<BoardActivity> recordActivity({
    required String boardId,
    required String userId,
    required String userName,
    required String userEmail,
    required BoardActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = BoardActivity(
      id: _activitiesCollection.doc().id,
      boardId: boardId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      type: type,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _activitiesCollection.doc(activity.id).set(activity.toMap());

    return activity;
  }

  @override
  Future<List<BoardActivity>> getBoardActivities(
    String boardId, {
    int limit = 50,
  }) async {
    final querySnapshot = await _activitiesCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => BoardActivity.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<BoardActivity>> watchBoardActivities(
    String boardId, {
    int limit = 50,
  }) {
    return _activitiesCollection
        .where('boardId', isEqualTo: boardId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BoardActivity.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<List<BoardActivity>> getUserActivities(
    String boardId,
    String userId, {
    int limit = 20,
  }) async {
    final querySnapshot = await _activitiesCollection
        .where('boardId', isEqualTo: boardId)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => BoardActivity.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateUserPresence({
    required String boardId,
    required String userId,
    required String userName,
    required String userEmail,
    required bool isOnline,
    String? currentActivity,
  }) async {
    final presenceId = '${boardId}_$userId';
    final presence = UserPresence(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      isOnline: isOnline,
      lastSeen: DateTime.now(),
      currentActivity: currentActivity,
    );

    await _presenceCollection.doc(presenceId).set({
      ...presence.toMap(),
      'boardId': boardId,
    });

    // Set up automatic offline detection after 5 minutes of inactivity
    if (isOnline) {
      _scheduleOfflineUpdate(presenceId);
    }
  }

  @override
  Future<List<UserPresence>> getOnlineUsers(String boardId) async {
    final querySnapshot = await _presenceCollection
        .where('boardId', isEqualTo: boardId)
        .where('isOnline', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => UserPresence.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<UserPresence>> watchOnlineUsers(String boardId) {
    return _presenceCollection
        .where('boardId', isEqualTo: boardId)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                UserPresence.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<void> cleanupOldActivities(String boardId,
      {int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final querySnapshot = await _activitiesCollection
        .where('boardId', isEqualTo: boardId)
        .where('timestamp', isLessThan: cutoffDate.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Future<BoardActivityStats> getActivityStats(String boardId) async {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));

    // Get all activities for the board
    final allActivities = await getBoardActivities(boardId, limit: 1000);

    // Calculate statistics
    final activitiesLast24h = allActivities
        .where((activity) => activity.timestamp.isAfter(last24h))
        .length;

    final activitiesLast7d = allActivities
        .where((activity) => activity.timestamp.isAfter(last7d))
        .length;

    // Find most active user
    final userActivityCount = <String, int>{};
    for (final activity in allActivities) {
      userActivityCount[activity.userId] =
          (userActivityCount[activity.userId] ?? 0) + 1;
    }

    String? mostActiveUser;
    int maxActivities = 0;
    userActivityCount.forEach((userId, count) {
      if (count > maxActivities) {
        maxActivities = count;
        mostActiveUser = userId;
      }
    });

    // Count activities by type
    final activityByType = <BoardActivityType, int>{};
    for (final activity in allActivities) {
      activityByType[activity.type] = (activityByType[activity.type] ?? 0) + 1;
    }

    return BoardActivityStats(
      totalActivities: allActivities.length,
      activitiesLast24h: activitiesLast24h,
      activitiesLast7d: activitiesLast7d,
      mostActiveUser: mostActiveUser,
      activityByType: activityByType,
    );
  }

  /// Schedules an automatic offline update for a user after 5 minutes
  void _scheduleOfflineUpdate(String presenceId) {
    // In a real implementation, this would use a cloud function
    // or background task to automatically set users offline
    // after a period of inactivity

    // For now, we'll just add a comment about the intended behavior
    // This could be implemented using:
    // 1. Cloud Functions with scheduled triggers
    // 2. Client-side timers (less reliable)
    // 3. Firebase Realtime Database's onDisconnect() feature
  }
}

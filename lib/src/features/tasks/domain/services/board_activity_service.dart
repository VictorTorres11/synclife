import '../models/board_activity.dart';

/// Service interface for board activity management
abstract class BoardActivityService {
  /// Records a new activity in a board
  Future<BoardActivity> recordActivity({
    required String boardId,
    required String userId,
    required String userName,
    required String userEmail,
    required BoardActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  });

  /// Gets recent activities for a board
  Future<List<BoardActivity>> getBoardActivities(
    String boardId, {
    int limit = 50,
  });

  /// Watches board activities in real-time
  Stream<List<BoardActivity>> watchBoardActivities(
    String boardId, {
    int limit = 50,
  });

  /// Gets activities for a specific user in a board
  Future<List<BoardActivity>> getUserActivities(
    String boardId,
    String userId, {
    int limit = 20,
  });

  /// Updates user presence status
  Future<void> updateUserPresence({
    required String boardId,
    required String userId,
    required String userName,
    required String userEmail,
    required bool isOnline,
    String? currentActivity,
  });

  /// Gets online users for a board
  Future<List<UserPresence>> getOnlineUsers(String boardId);

  /// Watches online users in real-time
  Stream<List<UserPresence>> watchOnlineUsers(String boardId);

  /// Cleans up old activities (older than specified days)
  Future<void> cleanupOldActivities(String boardId, {int daysToKeep = 30});

  /// Gets activity statistics for a board
  Future<BoardActivityStats> getActivityStats(String boardId);
}

/// Statistics for board activities
class BoardActivityStats {
  const BoardActivityStats({
    required this.totalActivities,
    required this.activitiesLast24h,
    required this.activitiesLast7d,
    required this.mostActiveUser,
    required this.activityByType,
  });

  final int totalActivities;
  final int activitiesLast24h;
  final int activitiesLast7d;
  final String? mostActiveUser;
  final Map<BoardActivityType, int> activityByType;
}

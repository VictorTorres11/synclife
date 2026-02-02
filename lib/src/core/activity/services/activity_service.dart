import '../models/activity_log.dart';

abstract class ActivityService {
  /// Log a new activity for the user
  Future<void> logActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? relatedEntityId,
  });

  /// Get recent activities for a user
  Stream<List<ActivityLog>> getRecentActivities(String userId, {int limit = 10});

  /// Get all activities for a user with pagination
  Stream<List<ActivityLog>> getUserActivities(
    String userId, {
    int limit = 50,
    DateTime? startAfter,
  });

  /// Delete old activities (cleanup)
  Future<void> cleanupOldActivities(String userId, {int keepDays = 30});
}
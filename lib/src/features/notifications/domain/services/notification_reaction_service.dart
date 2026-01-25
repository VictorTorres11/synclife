import '../models/notification_reaction.dart';

/// Service for handling notification emoji reactions
abstract class NotificationReactionService {
  /// Send a reaction to a notification
  Future<void> sendReaction({
    required String notificationId,
    required String userId,
    required EmojiReaction reaction,
  });

  /// Remove a user's reaction from a notification
  Future<void> removeReaction({
    required String notificationId,
    required String userId,
  });

  /// Get reaction summary for a notification
  Future<NotificationReactionSummary?> getReactionSummary(
      String notificationId);

  /// Get all reactions for a notification
  Future<List<NotificationReaction>> getReactions(String notificationId);

  /// Get user's reaction for a notification
  Future<NotificationReaction?> getUserReaction({
    required String notificationId,
    required String userId,
  });

  /// Stream of reaction updates for a notification
  Stream<NotificationReactionSummary> watchReactionSummary(
      String notificationId);

  /// Process reaction from notification action (called by FCM)
  Future<void> processNotificationReaction({
    required String notificationId,
    required String userId,
    required String reactionValue,
  });
}

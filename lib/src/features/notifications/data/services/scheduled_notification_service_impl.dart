import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/notification_preferences.dart';
import '../../domain/models/notification_summary.dart';
import '../../domain/models/scheduled_notification.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/scheduled_notification_service.dart';
import '../../../auth/domain/models/user.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../gamification/domain/models/user_stats.dart';
import '../../../tasks/domain/models/board.dart';
import '../../../tasks/domain/models/task.dart';

/// Implementation of scheduled notification service
class ScheduledNotificationServiceImpl implements ScheduledNotificationService {
  ScheduledNotificationServiceImpl({
    required FirebaseFirestore firestore,
    required NotificationService notificationService,
  })  : _firestore = firestore,
        _notificationService = notificationService;

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  @override
  Future<void> scheduleMorningSummary(
    String userId,
    DateTime scheduledTime,
    MorningSummary summary,
  ) async {
    try {
      final notification = ScheduledNotification(
        id: _firestore.collection('scheduledNotifications').doc().id,
        userId: userId,
        type: ScheduledNotificationType.morningSummary,
        title:
            '${ScheduledNotificationType.morningSummary.emoji} Good Morning!',
        body: _generateMorningSummaryBody(summary),
        scheduledTime: scheduledTime,
        data: summary.toMap(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('scheduledNotifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint(
          'Scheduled morning summary for user $userId at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling morning summary: $e');
      rethrow;
    }
  }

  @override
  Future<void> scheduleNightSummary(
    String userId,
    DateTime scheduledTime,
    NightSummary summary,
  ) async {
    try {
      final notification = ScheduledNotification(
        id: _firestore.collection('scheduledNotifications').doc().id,
        userId: userId,
        type: ScheduledNotificationType.nightSummary,
        title: '${ScheduledNotificationType.nightSummary.emoji} Daily Recap',
        body: _generateNightSummaryBody(summary),
        scheduledTime: scheduledTime,
        data: summary.toMap(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('scheduledNotifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('Scheduled night summary for user $userId at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling night summary: $e');
      rethrow;
    }
  }

  @override
  Future<void> scheduleTeamActivityNotification(
    String userId,
    String boardId,
    String memberName,
    String taskTitle,
    String action,
  ) async {
    try {
      // Check if user has team notifications enabled
      final preferences = await _notificationService.getPreferences();
      if (!preferences.enableTeamUpdates) return;

      final notification = ScheduledNotification(
        id: _firestore.collection('scheduledNotifications').doc().id,
        userId: userId,
        type: ScheduledNotificationType.teamActivity,
        title: '${ScheduledNotificationType.teamActivity.emoji} Team Update',
        body: _generateTeamActivityBody(memberName, taskTitle, action),
        scheduledTime: DateTime.now(), // Send immediately
        data: {
          'boardId': boardId,
          'memberName': memberName,
          'taskTitle': taskTitle,
          'action': action,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('scheduledNotifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('Scheduled team activity notification for user $userId');
    } catch (e) {
      debugPrint('Error scheduling team activity notification: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScheduledNotification>> getPendingNotifications(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('scheduledNotifications')
          .where('userId', isEqualTo: userId)
          .where('isProcessed', isEqualTo: false)
          .where('scheduledTime',
              isLessThanOrEqualTo: DateTime.now().toIso8601String())
          .orderBy('scheduledTime')
          .get();

      return snapshot.docs
          .map((doc) => ScheduledNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markAsProcessed(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .update({
        'isProcessed': true,
        'processedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Marked notification $notificationId as processed');
    } catch (e) {
      debugPrint('Error marking notification as processed: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .delete();

      debugPrint('Cancelled scheduled notification $notificationId');
    } catch (e) {
      debugPrint('Error cancelling scheduled notification: $e');
      rethrow;
    }
  }

  @override
  Future<MorningSummary> generateMorningSummary(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get user stats for streak info
      final userStatsDoc =
          await _firestore.collection('userStats').doc(userId).get();
      final userStats = userStatsDoc.exists
          ? UserStats.fromMap(userStatsDoc.data()!)
          : UserStats.initial(userId);

      // Get today's tasks
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .where('dueDate',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('dueDate', isLessThan: endOfDay.toIso8601String())
          .get();

      final tasks =
          tasksSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
      final essentialTasks =
          tasks.where((task) => task.tags.contains('essential')).length;

      // Get board names for tasks
      final boardIds = tasks.map((task) => task.boardId).toSet();
      final boardsSnapshot = await _firestore
          .collection('boards')
          .where(FieldPath.documentId, whereIn: boardIds.toList())
          .get();

      final boardsMap = <String, String>{};
      for (final doc in boardsSnapshot.docs) {
        final board = Board.fromMap(doc.data());
        boardsMap[board.id] = board.name;
      }

      final taskSummaries = tasks
          .map((task) => TaskSummary(
                id: task.id,
                title: task.title,
                isEssential: task.tags.contains('essential'),
                tags: task.tags,
                boardName: boardsMap[task.boardId] ?? 'Unknown Board',
                dueTime: task.dueDate,
              ))
          .toList();

      // Get recent team updates (last 24 hours)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final teamUpdates = await _getRecentTeamUpdates(userId, yesterday);

      return MorningSummary(
        userId: userId,
        tasksForToday: taskSummaries,
        essentialTasksCount: essentialTasks,
        currentStreak: userStats.currentStreak,
        motivationalMessage: _generateMotivationalMessage(
            userStats.currentStreak, essentialTasks),
        weatherInfo: null, // Could integrate weather API later
        teamUpdates: teamUpdates,
      );
    } catch (e) {
      debugPrint('Error generating morning summary: $e');
      rethrow;
    }
  }

  @override
  Future<NightSummary> generateNightSummary(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get user stats
      final userStatsDoc =
          await _firestore.collection('userStats').doc(userId).get();
      final userStats = userStatsDoc.exists
          ? UserStats.fromMap(userStatsDoc.data()!)
          : UserStats.initial(userId);

      // Get today's completed tasks
      final completedTasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .where('updatedAt',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();

      final completedTasks = completedTasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();

      // Calculate XP gained today
      int xpGained = 0;
      final categoryBreakdown = <String, int>{};

      for (final task in completedTasks) {
        final taskXP =
            _calculateTaskXP(task.tags, task.tags.contains('essential'));
        xpGained += taskXP;

        final category = _getCategoryFromTags(task.tags);
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0) + taskXP;
      }

      // Calculate FluxoCoins earned (1 per 10 XP)
      final fluxoCoinsEarned = (xpGained / 10).floor();

      // Get board names for completed tasks
      final boardIds = completedTasks.map((task) => task.boardId).toSet();
      final boardsSnapshot = await _firestore
          .collection('boards')
          .where(FieldPath.documentId, whereIn: boardIds.toList())
          .get();

      final boardsMap = <String, String>{};
      for (final doc in boardsSnapshot.docs) {
        final board = Board.fromMap(doc.data());
        boardsMap[board.id] = board.name;
      }

      final completedTaskSummaries = completedTasks
          .map((task) => TaskSummary(
                id: task.id,
                title: task.title,
                isEssential: task.tags.contains('essential'),
                tags: task.tags,
                boardName: boardsMap[task.boardId] ?? 'Unknown Board',
              ))
          .toList();

      // Generate streak status
      final streakStatus = StreakStatus(
        current: userStats.currentStreak,
        longest: userStats.longestStreak,
        isActive: userStats.currentStreak > 0,
        message: _generateStreakMessage(
            userStats.currentStreak, userStats.longestStreak),
      );

      // Generate level progress
      final levelProgress = LevelProgress(
        currentLevel: userStats.level,
        currentXP: userStats.totalXP,
        xpForNextLevel: userStats.xpForNextLevel,
        progressPercentage: (userStats.xpProgressInCurrentLevel /
                userStats.xpNeededInCurrentLevel) *
            100,
        leveledUp: false, // This would be calculated in daily processing
      );

      // Get team performance
      final teamPerformance = await _getTeamPerformance(userId);

      // Get tomorrow's tasks preview
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startOfTomorrow =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));

      final tomorrowTasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .where('dueDate',
              isGreaterThanOrEqualTo: startOfTomorrow.toIso8601String())
          .where('dueDate', isLessThan: endOfTomorrow.toIso8601String())
          .limit(5)
          .get();

      final tomorrowTasks = tomorrowTasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .map((task) => TaskSummary(
                id: task.id,
                title: task.title,
                isEssential: task.tags.contains('essential'),
                tags: task.tags,
                boardName: boardsMap[task.boardId] ?? 'Unknown Board',
                dueTime: task.dueDate,
              ))
          .toList();

      return NightSummary(
        userId: userId,
        completedTasks: completedTaskSummaries,
        xpGained: xpGained,
        fluxoCoinsEarned: fluxoCoinsEarned,
        streakStatus: streakStatus,
        levelProgress: levelProgress,
        categoryBreakdown: categoryBreakdown,
        teamPerformance: teamPerformance,
        tomorrowPreview: tomorrowTasks,
      );
    } catch (e) {
      debugPrint('Error generating night summary: $e');
      rethrow;
    }
  }

  @override
  Future<void> processPendingNotifications() async {
    try {
      // Get all pending notifications that should be sent now
      final snapshot = await _firestore
          .collection('scheduledNotifications')
          .where('isProcessed', isEqualTo: false)
          .where('scheduledTime',
              isLessThanOrEqualTo: DateTime.now().toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        final notification = ScheduledNotification.fromMap(doc.data());

        // Check user's notification preferences and quiet hours
        final preferences = await _notificationService.getPreferences();
        final currentTime = TimeOfDay(
          hour: DateTime.now().hour,
          minute: DateTime.now().minute,
        );

        if (preferences.isInQuietHours(currentTime)) {
          debugPrint(
              'Skipping notification ${notification.id} due to quiet hours');
          continue;
        }

        // Send the notification
        await _notificationService.sendNotificationToUser(
          notification.userId,
          notification.title,
          notification.body,
          data: notification.data,
        );

        // Mark as processed
        await markAsProcessed(notification.id);

        debugPrint(
            'Processed notification ${notification.id} for user ${notification.userId}');
      }
    } catch (e) {
      debugPrint('Error processing pending notifications: $e');
      rethrow;
    }
  }

  @override
  Future<void> setupDailySchedules(String userId) async {
    try {
      final preferences = await _notificationService.getPreferences();
      final userProfileDoc =
          await _firestore.collection('userProfiles').doc(userId).get();

      if (!userProfileDoc.exists) {
        debugPrint('User profile not found for $userId');
        return;
      }

      final now = DateTime.now();

      // Schedule morning summary if enabled
      if (preferences.enableDailySummary) {
        final morningTime = DateTime(
          now.year,
          now.month,
          now.day + 1, // Tomorrow
          preferences.morningTime.hour,
          preferences.morningTime.minute,
        );

        final morningSummary = await generateMorningSummary(userId);
        await scheduleMorningSummary(userId, morningTime, morningSummary);
      }

      // Schedule night summary if enabled
      if (preferences.enableNightSummary) {
        final nightTime = DateTime(
          now.year,
          now.month,
          now.day,
          preferences.nightTime.hour,
          preferences.nightTime.minute,
        );

        // Only schedule if it's in the future
        if (nightTime.isAfter(now)) {
          final nightSummary = await generateNightSummary(userId);
          await scheduleNightSummary(userId, nightTime, nightSummary);
        }
      }

      debugPrint('Setup daily schedules for user $userId');
    } catch (e) {
      debugPrint('Error setting up daily schedules: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSchedulesForUser(String userId) async {
    try {
      // Cancel existing scheduled notifications for today/tomorrow
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final existingSnapshot = await _firestore
          .collection('scheduledNotifications')
          .where('userId', isEqualTo: userId)
          .where('isProcessed', isEqualTo: false)
          .where('scheduledTime', isGreaterThanOrEqualTo: now.toIso8601String())
          .where('scheduledTime',
              isLessThan:
                  tomorrow.add(const Duration(days: 1)).toIso8601String())
          .get();

      // Delete existing schedules
      final batch = _firestore.batch();
      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Setup new schedules
      await setupDailySchedules(userId);

      debugPrint('Updated schedules for user $userId');
    } catch (e) {
      debugPrint('Error updating schedules for user: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('scheduledNotifications')
          .where('isProcessed', isEqualTo: true)
          .where('processedAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('Cleaned up ${snapshot.docs.length} old notifications');
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
      rethrow;
    }
  }

  // Helper methods

  String _generateMorningSummaryBody(MorningSummary summary) {
    final taskCount = summary.tasksForToday.length;
    final essentialCount = summary.essentialTasksCount;

    if (taskCount == 0) {
      return "No tasks scheduled for today. Enjoy your free time! 🎉";
    }

    return "You have $taskCount tasks today${essentialCount > 0 ? ' ($essentialCount essential)' : ''}. ${summary.motivationalMessage}";
  }

  String _generateNightSummaryBody(NightSummary summary) {
    final completedCount = summary.completedTasks.length;
    final xp = summary.xpGained;

    if (completedCount == 0) {
      return "No tasks completed today. Tomorrow is a new opportunity! 💪";
    }

    return "Great job! You completed $completedCount tasks and earned $xp XP. ${summary.streakStatus.message}";
  }

  String _generateTeamActivityBody(
      String memberName, String taskTitle, String action) {
    switch (action) {
      case 'completed':
        return "$memberName completed '$taskTitle' 🎉";
      case 'created':
        return "$memberName created a new task: '$taskTitle'";
      case 'updated':
        return "$memberName updated '$taskTitle'";
      default:
        return "$memberName performed an action on '$taskTitle'";
    }
  }

  String _generateMotivationalMessage(int streak, int essentialTasks) {
    if (streak >= 7) {
      return "Amazing ${streak}-day streak! Keep the momentum going! 🔥";
    } else if (streak >= 3) {
      return "You're on a roll with a ${streak}-day streak! 🚀";
    } else if (essentialTasks > 0) {
      return "Focus on your $essentialTasks essential tasks to build your streak! 💪";
    } else {
      return "Every task completed is progress. You've got this! ⭐";
    }
  }

  String _generateStreakMessage(int current, int longest) {
    if (current == 0) {
      return "Ready to start a new streak tomorrow? 🌟";
    } else if (current == longest) {
      return "New personal record! ${current}-day streak! 🏆";
    } else {
      return "Keep going! ${current}-day streak (best: $longest days) 🔥";
    }
  }

  int _calculateTaskXP(List<String> tags, bool isEssential) {
    int baseXP = 10;

    if (isEssential) {
      baseXP += 5;
    }

    for (final tag in tags) {
      switch (tag.toLowerCase()) {
        case 'health':
          baseXP += 3;
          break;
        case 'work':
          baseXP += 2;
          break;
        case 'finance':
          baseXP += 4;
          break;
        case 'home':
          baseXP += 2;
          break;
        default:
          baseXP += 1;
      }
    }

    return baseXP;
  }

  String _getCategoryFromTags(List<String> tags) {
    const categoryPriority = ['Health', 'Finance', 'Work', 'Home'];

    for (final category in categoryPriority) {
      if (tags.any((tag) => tag.toLowerCase() == category.toLowerCase())) {
        return category;
      }
    }

    return 'Home';
  }

  Future<List<TeamUpdate>> _getRecentTeamUpdates(
      String userId, DateTime since) async {
    try {
      // Get user's boards
      final boardsSnapshot = await _firestore
          .collection('boards')
          .where('memberIds', arrayContains: userId)
          .where('type', isEqualTo: 'shared')
          .get();

      final teamUpdates = <TeamUpdate>[];

      for (final boardDoc in boardsSnapshot.docs) {
        final board = Board.fromMap(boardDoc.data());

        // Get recent task updates from other members
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('boardId', isEqualTo: board.id)
            .where('updatedAt', isGreaterThanOrEqualTo: since.toIso8601String())
            .orderBy('updatedAt', descending: true)
            .limit(5)
            .get();

        for (final taskDoc in tasksSnapshot.docs) {
          final task = Task.fromMap(taskDoc.data());

          // Skip user's own tasks
          if (task.assignedTo == userId) continue;

          // Get member name
          final memberDoc =
              await _firestore.collection('users').doc(task.assignedTo!).get();
          final memberName = memberDoc.exists
              ? (User.fromMap(memberDoc.data()!).displayName ?? 'Unknown User')
              : 'Unknown User';

          teamUpdates.add(TeamUpdate(
            boardName: board.name,
            memberName: memberName,
            action: task.isCompleted ? 'completed' : 'updated',
            taskTitle: task.title,
            timestamp: task.updatedAt,
          ));
        }
      }

      // Sort by timestamp and return most recent
      teamUpdates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return teamUpdates.take(3).toList();
    } catch (e) {
      debugPrint('Error getting recent team updates: $e');
      return [];
    }
  }

  Future<List<TeamPerformance>> _getTeamPerformance(String userId) async {
    try {
      // Get user's shared boards
      final boardsSnapshot = await _firestore
          .collection('boards')
          .where('memberIds', arrayContains: userId)
          .where('type', isEqualTo: 'shared')
          .get();

      final teamPerformance = <TeamPerformance>[];

      for (final boardDoc in boardsSnapshot.docs) {
        final board = Board.fromMap(boardDoc.data());

        // Get collective streak
        final collectiveStreakDoc = await _firestore
            .collection('collectiveStreaks')
            .doc(board.id)
            .get();

        final collectiveStreak = collectiveStreakDoc.exists
            ? (collectiveStreakDoc.data()!['currentStreak'] as int? ?? 0)
            : 0;

        // Calculate completion rate for today
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        final allTasksSnapshot = await _firestore
            .collection('tasks')
            .where('boardId', isEqualTo: board.id)
            .where('dueDate',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .get();

        final completedTasksSnapshot = await _firestore
            .collection('tasks')
            .where('boardId', isEqualTo: board.id)
            .where('dueDate',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('isCompleted', isEqualTo: true)
            .get();

        final totalTasks = allTasksSnapshot.docs.length;
        final completedTasks = completedTasksSnapshot.docs.length;
        final completionRate =
            totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

        // Find top performer (most tasks completed today)
        final memberTaskCounts = <String, int>{};
        for (final taskDoc in completedTasksSnapshot.docs) {
          final task = Task.fromMap(taskDoc.data());
          if (task.assignedTo != null) {
            memberTaskCounts[task.assignedTo!] =
                (memberTaskCounts[task.assignedTo!] ?? 0) + 1;
          }
        }

        String topPerformer = 'No one';
        if (memberTaskCounts.isNotEmpty) {
          final topPerformerId = memberTaskCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          final topPerformerDoc =
              await _firestore.collection('users').doc(topPerformerId).get();
          topPerformer = topPerformerDoc.exists
              ? (User.fromMap(topPerformerDoc.data()!).displayName ??
                  'Unknown User')
              : 'Unknown User';
        }

        teamPerformance.add(TeamPerformance(
          boardName: board.name,
          completionRate: completionRate,
          collectiveStreak: collectiveStreak,
          topPerformer: topPerformer,
        ));
      }

      return teamPerformance;
    } catch (e) {
      debugPrint('Error getting team performance: $e');
      return [];
    }
  }
}

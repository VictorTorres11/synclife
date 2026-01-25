import 'package:flutter_test/flutter_test.dart';

import 'package:synclife_app/src/features/notifications/domain/models/notification_summary.dart';
import 'package:synclife_app/src/features/notifications/domain/models/scheduled_notification.dart';

void main() {
  group('ScheduledNotificationService', () {
    group('Data Models', () {
      test('ScheduledNotification should serialize correctly', () {
        final notification = ScheduledNotification(
          id: 'test-id',
          userId: 'user-123',
          type: ScheduledNotificationType.morningSummary,
          title: 'Good Morning!',
          body: 'You have 3 tasks today',
          scheduledTime: DateTime(2024, 1, 15, 8, 0),
          data: {'taskCount': 3},
          createdAt: DateTime(2024, 1, 14, 20, 0),
          updatedAt: DateTime(2024, 1, 14, 20, 0),
        );

        final map = notification.toMap();

        expect(map['id'], equals('test-id'));
        expect(map['userId'], equals('user-123'));
        expect(map['type'], equals('morningSummary'));
        expect(map['title'], equals('Good Morning!'));
        expect(map['body'], equals('You have 3 tasks today'));
        expect(map['isProcessed'], equals(false));
        expect(map['data'], equals({'taskCount': 3}));
      });

      test('ScheduledNotification should deserialize correctly', () {
        final map = {
          'id': 'test-id',
          'userId': 'user-123',
          'type': 'nightSummary',
          'title': 'Daily Recap',
          'body': 'Great job today!',
          'scheduledTime': '2024-01-15T22:00:00.000Z',
          'data': {'xpGained': 50},
          'isProcessed': false,
          'processedAt': null,
          'createdAt': '2024-01-14T20:00:00.000Z',
          'updatedAt': '2024-01-14T20:00:00.000Z',
        };

        final notification = ScheduledNotification.fromMap(map);

        expect(notification.id, equals('test-id'));
        expect(notification.userId, equals('user-123'));
        expect(
            notification.type, equals(ScheduledNotificationType.nightSummary));
        expect(notification.title, equals('Daily Recap'));
        expect(notification.body, equals('Great job today!'));
        expect(notification.isProcessed, equals(false));
        expect(notification.processedAt, isNull);
        expect(notification.data, equals({'xpGained': 50}));
      });

      test('MorningSummary should serialize correctly', () {
        final summary = MorningSummary(
          userId: 'user-123',
          tasksForToday: [
            TaskSummary(
              id: 'task-1',
              title: 'Morning workout',
              isEssential: true,
              tags: ['health', 'essential'],
              boardName: 'Personal',
            ),
          ],
          essentialTasksCount: 1,
          currentStreak: 5,
          motivationalMessage: 'Keep going!',
          weatherInfo: null,
          teamUpdates: [],
        );

        final map = summary.toMap();

        expect(map['userId'], equals('user-123'));
        expect(map['essentialTasksCount'], equals(1));
        expect(map['currentStreak'], equals(5));
        expect(map['motivationalMessage'], equals('Keep going!'));
        expect(map['tasksForToday'], isA<List>());
        expect(map['teamUpdates'], isA<List>());
      });

      test('NightSummary should serialize correctly', () {
        final summary = NightSummary(
          userId: 'user-123',
          completedTasks: [
            TaskSummary(
              id: 'task-1',
              title: 'Completed workout',
              isEssential: true,
              tags: ['health'],
              boardName: 'Personal',
            ),
          ],
          xpGained: 50,
          fluxoCoinsEarned: 5,
          streakStatus: const StreakStatus(
            current: 5,
            longest: 10,
            isActive: true,
            message: 'Great streak!',
          ),
          levelProgress: const LevelProgress(
            currentLevel: 2,
            currentXP: 150,
            xpForNextLevel: 200,
            progressPercentage: 75.0,
            leveledUp: false,
          ),
          categoryBreakdown: {'Health': 30, 'Work': 20},
          teamPerformance: [],
          tomorrowPreview: [],
        );

        final map = summary.toMap();

        expect(map['userId'], equals('user-123'));
        expect(map['xpGained'], equals(50));
        expect(map['fluxoCoinsEarned'], equals(5));
        expect(map['categoryBreakdown'], equals({'Health': 30, 'Work': 20}));
        expect(map['completedTasks'], isA<List>());
        expect(map['streakStatus'], isA<Map>());
        expect(map['levelProgress'], isA<Map>());
      });
    });

    group('Notification Type Extensions', () {
      test('should provide correct display names', () {
        expect(ScheduledNotificationType.morningSummary.displayName,
            equals('Morning Summary'));
        expect(ScheduledNotificationType.teamActivity.displayName,
            equals('Team Activity'));
        expect(ScheduledNotificationType.nightSummary.displayName,
            equals('Night Summary'));
        expect(ScheduledNotificationType.taskReminder.displayName,
            equals('Task Reminder'));
      });

      test('should provide correct emojis', () {
        expect(ScheduledNotificationType.morningSummary.emoji, equals('🌅'));
        expect(ScheduledNotificationType.teamActivity.emoji, equals('👥'));
        expect(ScheduledNotificationType.nightSummary.emoji, equals('🌙'));
        expect(ScheduledNotificationType.taskReminder.emoji, equals('⏰'));
      });
    });

    group('Summary Models', () {
      test('TaskSummary should handle all properties correctly', () {
        final taskSummary = TaskSummary(
          id: 'task-1',
          title: 'Test Task',
          isEssential: true,
          tags: ['health', 'essential'],
          boardName: 'Personal Board',
          dueTime: DateTime(2024, 1, 15, 10, 30),
        );

        final map = taskSummary.toMap();

        expect(map['id'], equals('task-1'));
        expect(map['title'], equals('Test Task'));
        expect(map['isEssential'], equals(true));
        expect(map['tags'], equals(['health', 'essential']));
        expect(map['boardName'], equals('Personal Board'));
        expect(map['dueTime'], equals('2024-01-15T10:30:00.000'));
      });

      test('StreakStatus should handle all properties correctly', () {
        const streakStatus = StreakStatus(
          current: 7,
          longest: 15,
          isActive: true,
          message: 'Amazing streak!',
        );

        final map = streakStatus.toMap();

        expect(map['current'], equals(7));
        expect(map['longest'], equals(15));
        expect(map['isActive'], equals(true));
        expect(map['message'], equals('Amazing streak!'));
      });

      test('LevelProgress should handle all properties correctly', () {
        const levelProgress = LevelProgress(
          currentLevel: 3,
          currentXP: 250,
          xpForNextLevel: 300,
          progressPercentage: 83.33,
          leveledUp: true,
        );

        final map = levelProgress.toMap();

        expect(map['currentLevel'], equals(3));
        expect(map['currentXP'], equals(250));
        expect(map['xpForNextLevel'], equals(300));
        expect(map['progressPercentage'], equals(83.33));
        expect(map['leveledUp'], equals(true));
      });

      test('TeamUpdate should handle all properties correctly', () {
        final teamUpdate = TeamUpdate(
          boardName: 'Family Board',
          memberName: 'John Doe',
          action: 'completed',
          taskTitle: 'Take out trash',
          timestamp: DateTime(2024, 1, 15, 14, 30),
        );

        final map = teamUpdate.toMap();

        expect(map['boardName'], equals('Family Board'));
        expect(map['memberName'], equals('John Doe'));
        expect(map['action'], equals('completed'));
        expect(map['taskTitle'], equals('Take out trash'));
        expect(map['timestamp'], equals('2024-01-15T14:30:00.000'));
      });

      test('TeamPerformance should handle all properties correctly', () {
        const teamPerformance = TeamPerformance(
          boardName: 'Work Board',
          completionRate: 85.5,
          collectiveStreak: 12,
          topPerformer: 'Alice Smith',
        );

        final map = teamPerformance.toMap();

        expect(map['boardName'], equals('Work Board'));
        expect(map['completionRate'], equals(85.5));
        expect(map['collectiveStreak'], equals(12));
        expect(map['topPerformer'], equals('Alice Smith'));
      });
    });

    group('Edge Cases', () {
      test('ScheduledNotification should handle null processedAt', () {
        final notification = ScheduledNotification(
          id: 'test-id',
          userId: 'user-123',
          type: ScheduledNotificationType.morningSummary,
          title: 'Test',
          body: 'Test body',
          scheduledTime: DateTime.now(),
          data: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(notification.processedAt, isNull);
        expect(notification.isProcessed, isFalse);
      });

      test('TaskSummary should handle null dueTime', () {
        final taskSummary = TaskSummary(
          id: 'task-1',
          title: 'Test Task',
          isEssential: false,
          tags: [],
          boardName: 'Test Board',
        );

        final map = taskSummary.toMap();
        expect(map['dueTime'], isNull);
      });

      test('MorningSummary should handle empty lists', () {
        final summary = MorningSummary(
          userId: 'user-123',
          tasksForToday: [],
          essentialTasksCount: 0,
          currentStreak: 0,
          motivationalMessage: 'Start fresh!',
          weatherInfo: null,
          teamUpdates: [],
        );

        final map = summary.toMap();
        expect(map['tasksForToday'], isEmpty);
        expect(map['teamUpdates'], isEmpty);
        expect(map['essentialTasksCount'], equals(0));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:synclife_app/src/features/gamification/data/services/firebase_gamification_service.dart';
import 'package:synclife_app/src/features/gamification/domain/models/models.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_services.dart';

/// Property-based tests for gamification functionality
void main() {
  group('Gamification Property Tests', () {
    late FirebaseGamificationService gamificationService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      gamificationService = FirebaseGamificationService(
        firestore: fakeFirestore,
        taskService: MockTaskService(),
      );
    });

    group('Feature: synclife-app, Property 11: Daily XP calculation', () {
      test(
          'For any user with completed tasks, daily processing should calculate XP based on task completion and categorize it by tags',
          () async {
        // Validates: Requirements 4.1, 4.4

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Daily XP calculation should be consistent and categorized correctly',
          generator: () => _generateXPTestData(),
          property: (testData) async {
            final userId = testData['userId'] as String;
            final completedTaskIds =
                testData['completedTaskIds'] as List<String>;
            final expectedCategories =
                testData['expectedCategories'] as List<String>;

            // Get initial stats
            final initialStats = await gamificationService.getUserStats(userId);
            expect(initialStats, isNotNull);

            // Calculate daily XP
            final updatedStats = await gamificationService.calculateDailyXP(
                userId, completedTaskIds);

            // Property 1: XP should increase
            final xpGained = updatedStats.totalXP - initialStats!.totalXP;
            if (completedTaskIds.isNotEmpty) {
              expect(xpGained, greaterThan(0),
                  reason: 'XP should increase when tasks are completed');
            }

            // Property 2: Level should be calculated correctly based on total XP
            final expectedLevel =
                UserStats.calculateLevel(updatedStats.totalXP);
            expect(updatedStats.level, equals(expectedLevel),
                reason: 'Level should match calculated level from total XP');

            // Property 3: Category XP should be distributed correctly
            for (final category in expectedCategories) {
              final categoryXP = updatedStats.categoryXP[category] ?? 0;
              final initialCategoryXP = initialStats.categoryXP[category] ?? 0;
              expect(categoryXP, greaterThanOrEqualTo(initialCategoryXP),
                  reason: 'Category XP should not decrease');
            }

            // Property 4: FluxoCoins should be awarded based on XP (1 FluxoCoin per 10 XP)
            final expectedFluxoCoins =
                initialStats.fluxoCoins + (xpGained / 10).floor();
            expect(updatedStats.fluxoCoins, equals(expectedFluxoCoins),
                reason: 'FluxoCoins should be awarded at 1 per 10 XP rate');

            // Property 5: Updated timestamp should be recent
            final now = DateTime.now();
            final timeDiff = now.difference(updatedStats.updatedAt).inMinutes;
            expect(timeDiff, lessThan(5),
                reason: 'Updated timestamp should be recent');

            return true;
          },
          iterations: 100,
        );
      });
    });

    group('Feature: synclife-app, Property 12: Individual streak updates', () {
      test(
          'For any user who completed their essential tasks, the daily processing should increment their individual streak counter',
          () async {
        // Validates: Requirements 4.2

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Individual streak should update correctly based on essential task completion',
          generator: () => _generateStreakTestData(),
          property: (testData) async {
            final userId = testData['userId'] as String;
            final completedEssentialTasks =
                testData['completedEssentialTasks'] as bool;
            final daysSinceLastActive = testData['daysSinceLastActive'] as int;

            // Set up initial user stats with a specific last active date
            final now = DateTime.now();
            final lastActive =
                now.subtract(Duration(days: daysSinceLastActive));
            final initialStats = UserStats.initial(userId).copyWith(
              lastActive: lastActive,
              currentStreak: testData['initialStreak'] as int,
            );
            await fakeFirestore
                .collection('userStats')
                .doc(userId)
                .set(initialStats.toMap());

            // Update streak
            final updatedStats = await gamificationService.updateStreak(userId,
                completedEssentialTasks: completedEssentialTasks);

            // Property 1: If essential tasks completed and streak should continue, increment streak
            if (completedEssentialTasks && daysSinceLastActive <= 1) {
              final expectedStreak = daysSinceLastActive == 1
                  ? initialStats.currentStreak + 1
                  : initialStats.currentStreak;
              expect(updatedStats.currentStreak, equals(expectedStreak),
                  reason:
                      'Streak should increment when essential tasks completed consecutively');
            }

            // Property 2: If essential tasks not completed, streak should be 0
            if (!completedEssentialTasks) {
              expect(updatedStats.currentStreak, equals(0),
                  reason:
                      'Streak should be broken when essential tasks not completed');
            }

            // Property 3: If gap is too large, streak should reset to 1 (if completed) or 0 (if not)
            if (daysSinceLastActive > 1) {
              final expectedStreak = completedEssentialTasks ? 1 : 0;
              expect(updatedStats.currentStreak, equals(expectedStreak),
                  reason: 'Streak should reset when gap is too large');
            }

            // Property 4: Longest streak should never decrease
            expect(updatedStats.longestStreak,
                greaterThanOrEqualTo(initialStats.longestStreak),
                reason: 'Longest streak should never decrease');

            // Property 5: Last active should be updated to current time
            final timeDiff = now.difference(updatedStats.lastActive).inMinutes;
            expect(timeDiff, lessThan(5),
                reason: 'Last active should be updated to current time');

            return true;
          },
          iterations: 100,
        );
      });
    });

    group('Feature: synclife-app, Property 13: Collective streak requirements',
        () {
      test(
          'For any shared board, the collective streak should only increment if ALL members completed their essential tasks',
          () async {
        // Validates: Requirements 4.3

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Collective streak should require all members to complete essential tasks',
          generator: () => _generateCollectiveStreakTestData(),
          property: (testData) async {
            final boardId = testData['boardId'] as String;
            final memberCompletionStatus =
                testData['memberCompletionStatus'] as Map<String, bool>;
            final initialStreakValue = testData['initialStreak'] as int;

            // Set up initial collective streak
            final initialStreak = CollectiveStreak.initial(
                    boardId, memberCompletionStatus.keys.toList())
                .copyWith(currentStreak: initialStreakValue);
            await fakeFirestore
                .collection('collectiveStreaks')
                .doc(boardId)
                .set(initialStreak.toMap());

            // Update collective streak
            final updatedStreak = await gamificationService
                .updateCollectiveStreak(boardId, memberCompletionStatus);

            // Property 1: Streak should only increment if ALL members completed tasks
            final allCompleted =
                memberCompletionStatus.values.every((completed) => completed);
            if (allCompleted) {
              expect(
                  updatedStreak.currentStreak, greaterThan(initialStreakValue),
                  reason:
                      'Collective streak should increment when all members complete tasks');
            } else {
              expect(updatedStreak.currentStreak, equals(0),
                  reason:
                      'Collective streak should be broken when not all members complete tasks');
            }

            // Property 2: Longest streak should never decrease
            expect(updatedStreak.longestStreak,
                greaterThanOrEqualTo(initialStreak.longestStreak),
                reason: 'Longest collective streak should never decrease');

            // Property 3: Member list should be updated
            expect(updatedStreak.memberIds,
                containsAll(memberCompletionStatus.keys),
                reason: 'Member list should include all current members');

            // Property 4: Last streak date should be updated only if all completed
            if (allCompleted) {
              expect(updatedStreak.lastStreakDate, isNotNull,
                  reason:
                      'Last streak date should be set when all members complete');
            }

            return true;
          },
          iterations: 100,
        );
      });
    });

    group('Feature: synclife-app, Property 14: Intermediate state handling',
        () {
      test(
          'For any task marked and unmarked before daily processing, only the final state should be processed for XP and streak calculations',
          () async {
        // Validates: Requirements 4.6

        await PropertyTestRunner.runAsyncProperty<Map<String, dynamic>>(
          description:
              'Daily processing should only consider final task states, ignoring intermediate changes',
          generator: () => _generateIntermediateStateTestData(),
          property: (testData) async {
            final userId = testData['userId'] as String;
            final finalTaskStates = testData['finalTaskStates'] as List<bool>;

            // Set up initial user stats
            final initialStats = UserStats.initial(userId);
            await fakeFirestore
                .collection('userStats')
                .doc(userId)
                .set(initialStats.toMap());

            // Simulate tasks with their final states
            final taskIds = <String>[];
            for (int i = 0; i < finalTaskStates.length; i++) {
              final taskId = TestGenerators.randomUuid();
              taskIds.add(taskId);
            }

            // Get only the completed task IDs (final state)
            final completedTaskIds = <String>[];
            for (int i = 0; i < finalTaskStates.length; i++) {
              if (finalTaskStates[i]) {
                completedTaskIds.add(taskIds[i]);
              }
            }

            // Process daily XP (this should only consider final states)
            final updatedStats = await gamificationService.calculateDailyXP(
                userId, completedTaskIds);

            // Property 1: XP should be calculated based only on final completed tasks
            // Calculate expected XP using the same logic as the service
            int expectedXPGain = 0;
            for (final taskId in completedTaskIds) {
              // Simulate the XP calculation: base (10) + essential (5) + tag bonus (3 for Health)
              final xp = gamificationService
                  .calculateTaskXP(['Health'], isEssential: true);
              expectedXPGain += xp;
            }
            final actualXPGain = updatedStats.totalXP - initialStats.totalXP;
            expect(actualXPGain, equals(expectedXPGain),
                reason:
                    'XP should be calculated based only on final task states');

            // Property 2: Intermediate changes should not affect the calculation
            expect(updatedStats.totalXP,
                greaterThanOrEqualTo(initialStats.totalXP),
                reason: 'Total XP should never decrease');

            // Property 3: Level should be calculated correctly from final XP
            final expectedLevel =
                UserStats.calculateLevel(updatedStats.totalXP);
            expect(updatedStats.level, equals(expectedLevel),
                reason: 'Level should be calculated from final XP total');

            // Property 4: FluxoCoins should be awarded based on final XP gain
            final expectedFluxoCoins =
                initialStats.fluxoCoins + (actualXPGain / 10).floor();
            expect(updatedStats.fluxoCoins, equals(expectedFluxoCoins),
                reason: 'FluxoCoins should be based on final XP gain only');

            return true;
          },
          iterations: 100,
        );
      });
    });
  });
}

/// Generates test data for XP calculation property tests
Map<String, dynamic> _generateXPTestData() {
  final userId = TestGenerators.randomUuid();
  final taskCount = TestGenerators.randomInt(min: 0, max: 10);
  final completedTaskIds =
      List.generate(taskCount, (_) => TestGenerators.randomUuid());

  // Generate expected categories based on common task tags
  final categories = ['Health', 'Home', 'Finance', 'Work'];
  final expectedCategories = TestGenerators.randomList<String>(
    () => categories[
        TestGenerators.randomInt(min: 0, max: categories.length - 1)],
    minLength: 1,
    maxLength: 3,
  );

  return {
    'userId': userId,
    'completedTaskIds': completedTaskIds,
    'expectedCategories': expectedCategories,
  };
}

/// Generates test data for streak property tests
Map<String, dynamic> _generateStreakTestData() {
  final userId = TestGenerators.randomUuid();
  final completedEssentialTasks = TestGenerators.randomBool();
  final daysSinceLastActive = TestGenerators.randomInt(min: 0, max: 5);
  final initialStreak = TestGenerators.randomInt(min: 0, max: 30);

  return {
    'userId': userId,
    'completedEssentialTasks': completedEssentialTasks,
    'daysSinceLastActive': daysSinceLastActive,
    'initialStreak': initialStreak,
  };
}

/// Generates test data for collective streak property tests
Map<String, dynamic> _generateCollectiveStreakTestData() {
  final boardId = TestGenerators.randomUuid();
  final memberCount = TestGenerators.randomInt(min: 2, max: 8);
  final memberIds =
      List.generate(memberCount, (_) => TestGenerators.randomUuid());

  // Generate random completion status for each member
  final memberCompletionStatus = <String, bool>{};
  for (final memberId in memberIds) {
    memberCompletionStatus[memberId] = TestGenerators.randomBool();
  }

  final initialStreak = TestGenerators.randomInt(min: 0, max: 20);

  return {
    'boardId': boardId,
    'memberCompletionStatus': memberCompletionStatus,
    'initialStreak': initialStreak,
  };
}

/// Generates test data for intermediate state handling property tests
Map<String, dynamic> _generateIntermediateStateTestData() {
  final userId = TestGenerators.randomUuid();
  final taskCount = TestGenerators.randomInt(min: 1, max: 8);
  final finalTaskStates =
      List.generate(taskCount, (_) => TestGenerators.randomBool());

  return {
    'userId': userId,
    'finalTaskStates': finalTaskStates,
  };
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/models.dart';
import '../../domain/services/services.dart';
import '../../../tasks/domain/services/services.dart';

/// Firebase implementation of GamificationService
class FirebaseGamificationService implements GamificationService {
  FirebaseGamificationService({
    required FirebaseFirestore firestore,
    required TaskService taskService,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _userStatsCollection =>
      _firestore.collection('userStats');

  CollectionReference<Map<String, dynamic>> get _achievementsCollection =>
      _firestore.collection('achievements');

  CollectionReference<Map<String, dynamic>> get _collectiveStreaksCollection =>
      _firestore.collection('collectiveStreaks');

  CollectionReference<Map<String, dynamic>> get _streakValidationsCollection =>
      _firestore.collection('streakValidations');

  @override
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _userStatsCollection.doc(userId).get();
      if (!doc.exists) {
        // Create initial stats for new user
        final initialStats = UserStats.initial(userId);
        await _userStatsCollection.doc(userId).set(initialStats.toMap());
        return initialStats;
      }
      return UserStats.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final querySnapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Achievement.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user achievements: $e');
    }
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _userStatsCollection
          .orderBy('totalXP', descending: true)
          .limit(limit)
          .get();

      final leaderboardEntries = <LeaderboardEntry>[];

      for (final doc in querySnapshot.docs) {
        final userStats = UserStats.fromMap(doc.data());

        // Get user profile to get username
        final userDoc =
            await _firestore.collection('users').doc(userStats.userId).get();
        final username = userDoc.exists
            ? (userDoc.data()?['displayName'] as String? ??
                'User ${userStats.userId.substring(0, 8)}')
            : 'User ${userStats.userId.substring(0, 8)}';

        leaderboardEntries.add(LeaderboardEntry(
          userId: userStats.userId,
          username: username,
          level: userStats.level,
          totalXP: userStats.totalXP,
          currentStreak: userStats.currentStreak,
          avatarUrl:
              userDoc.exists ? (userDoc.data()?['photoURL'] as String?) : null,
        ));
      }

      return leaderboardEntries;
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  @override
  Future<UserStats> calculateDailyXP(
      String userId, List<String> completedTaskIds) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) {
        throw Exception('User stats not found');
      }

      int totalXPGained = 0;
      final Map<String, int> categoryXPGained = {
        'Health': 0,
        'Home': 0,
        'Finance': 0,
        'Work': 0,
      };

      // Calculate XP for each completed task
      for (final _ in completedTaskIds) {
        // Simulate task data - in real implementation, fetch actual task
        final taskTags = ['Health']; // This would come from actual task
        final isEssential = true; // This would come from actual task

        final xp = calculateTaskXP(taskTags, isEssential: isEssential);
        totalXPGained += xp;

        final category = getCategoryFromTags(taskTags);
        categoryXPGained[category] = (categoryXPGained[category] ?? 0) + xp;
      }

      // Update user stats
      final newTotalXP = userStats.totalXP + totalXPGained;
      final newLevel = UserStats.calculateLevel(newTotalXP);
      final newCategoryXP = Map<String, int>.from(userStats.categoryXP);

      categoryXPGained.forEach((category, xp) {
        newCategoryXP[category] = (newCategoryXP[category] ?? 0) + xp;
      });

      // Award FluxoCoins based on XP gained (1 FluxoCoin per 10 XP)
      final fluxoCoinsAwarded = (totalXPGained / 10).floor();

      final updatedStats = userStats.copyWith(
        totalXP: newTotalXP,
        level: newLevel,
        fluxoCoins: userStats.fluxoCoins + fluxoCoinsAwarded,
        categoryXP: newCategoryXP,
        lastActive: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userStatsCollection.doc(userId).set(updatedStats.toMap());
      return updatedStats;
    } catch (e) {
      throw Exception('Failed to calculate daily XP: $e');
    }
  }

  @override
  Future<UserStats> updateStreak(String userId,
      {required bool completedEssentialTasks}) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) {
        throw Exception('User stats not found');
      }

      final now = DateTime.now();

      int newCurrentStreak;
      int newLongestStreak = userStats.longestStreak;

      if (completedEssentialTasks) {
        // Check if last active was yesterday (streak continues) or today (same day)
        final daysSinceLastActive = now.difference(userStats.lastActive).inDays;

        if (daysSinceLastActive <= 1) {
          // Continue or maintain streak
          newCurrentStreak =
              userStats.currentStreak + (daysSinceLastActive == 1 ? 1 : 0);
        } else {
          // Streak broken, start new streak
          newCurrentStreak = 1;
        }

        // Update longest streak if current streak is longer
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else {
        // Essential tasks not completed, streak broken
        newCurrentStreak = 0;
      }

      final updatedStats = userStats.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastActive: now,
        updatedAt: now,
      );

      await _userStatsCollection.doc(userId).set(updatedStats.toMap());
      return updatedStats;
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  @override
  Future<UserStats> processDaily(String userId) async {
    try {
      // This would be called by the Cloud Function
      // For now, we'll implement a simplified version

      // Get user's completed tasks for today
      final completedTaskIds = <String>[]; // Placeholder

      // Calculate XP for completed tasks
      await calculateDailyXP(userId, completedTaskIds);

      // Update streak based on essential task completion
      final hasEssentialTasks = completedTaskIds.isNotEmpty; // Simplified logic
      final finalStats = await updateStreak(userId,
          completedEssentialTasks: hasEssentialTasks);

      // Check for new achievements
      await checkAndUnlockAchievements(userId);

      return finalStats;
    } catch (e) {
      throw Exception('Failed to process daily: $e');
    }
  }

  @override
  Future<UserStats> awardFluxoCoins(
      String userId, int amount, String reason) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) {
        throw Exception('User stats not found');
      }

      final updatedStats = userStats.copyWith(
        fluxoCoins: userStats.fluxoCoins + amount,
        updatedAt: DateTime.now(),
      );

      await _userStatsCollection.doc(userId).set(updatedStats.toMap());

      return updatedStats;
    } catch (e) {
      throw Exception('Failed to award FluxoCoins: $e');
    }
  }

  @override
  Future<UserStats> deductFluxoCoins(
      String userId, int amount, String reason) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) {
        throw Exception('User stats not found');
      }

      if (userStats.fluxoCoins < amount) {
        throw Exception('Insufficient FluxoCoins');
      }

      final updatedStats = userStats.copyWith(
        fluxoCoins: userStats.fluxoCoins - amount,
        updatedAt: DateTime.now(),
      );

      await _userStatsCollection.doc(userId).set(updatedStats.toMap());

      return updatedStats;
    } catch (e) {
      throw Exception('Failed to deduct FluxoCoins: $e');
    }
  }

  @override
  Future<List<Achievement>> checkAndUnlockAchievements(String userId) async {
    try {
      final userStats = await getUserStats(userId);
      if (userStats == null) {
        return [];
      }

      final unlockedAchievements = <Achievement>[];

      // Check for level-based achievements
      if (userStats.level >= 5) {
        // Example achievement logic
        final achievement = Achievement(
          id: 'level_5',
          title: 'Rising Star',
          description: 'Reach level 5',
          category: 'Progress',
          xpReward: 100,
          fluxoCoinReward: 50,
          iconPath: 'assets/achievements/level_5.png',
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );

        // Check if already unlocked
        final existingAchievements = await getUserAchievements(userId);
        final alreadyUnlocked =
            existingAchievements.any((a) => a.id == achievement.id);

        if (!alreadyUnlocked) {
          await _achievementsCollection.add({
            ...achievement.toMap(),
            'userId': userId,
          });
          unlockedAchievements.add(achievement);

          // Award the achievement rewards
          await awardFluxoCoins(userId, achievement.fluxoCoinReward,
              'Achievement: ${achievement.title}');
        }
      }

      return unlockedAchievements;
    } catch (e) {
      throw Exception('Failed to check achievements: $e');
    }
  }

  @override
  Stream<UserStats?> watchUserStats(String userId) {
    return _userStatsCollection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserStats.fromMap(doc.data()!) : null);
  }

  @override
  Future<CollectiveStreak> updateCollectiveStreak(
      String boardId, Map<String, bool> memberCompletionStatus) async {
    try {
      final doc = await _collectiveStreaksCollection.doc(boardId).get();
      CollectiveStreak collectiveStreak;

      if (!doc.exists) {
        // Create initial collective streak
        collectiveStreak = CollectiveStreak.initial(
            boardId, memberCompletionStatus.keys.toList());
      } else {
        collectiveStreak = CollectiveStreak.fromMap(doc.data()!);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if ALL members completed their essential tasks
      final allMembersCompleted =
          memberCompletionStatus.values.every((completed) => completed);

      int newCurrentStreak;
      int newLongestStreak = collectiveStreak.longestStreak;

      if (allMembersCompleted) {
        if (collectiveStreak.shouldContinueStreak(today)) {
          // Continue streak
          newCurrentStreak = collectiveStreak.currentStreak + 1;
        } else if (collectiveStreak.isStreakBroken(today)) {
          // Streak was broken, start new
          newCurrentStreak = 1;
        } else {
          // Same day, maintain streak
          newCurrentStreak = collectiveStreak.currentStreak;
        }

        // Update longest streak if current is longer
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else {
        // Not all members completed, streak broken
        newCurrentStreak = 0;
      }

      final updatedStreak = collectiveStreak.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        memberIds: memberCompletionStatus.keys.toList(),
        lastStreakDate:
            allMembersCompleted ? today : collectiveStreak.lastStreakDate,
        updatedAt: now,
      );

      await _collectiveStreaksCollection
          .doc(boardId)
          .set(updatedStreak.toMap());
      return updatedStreak;
    } catch (e) {
      throw Exception('Failed to update collective streak: $e');
    }
  }

  @override
  Future<CollectiveStreak?> getCollectiveStreak(String boardId) async {
    try {
      final doc = await _collectiveStreaksCollection.doc(boardId).get();
      if (!doc.exists) return null;
      return CollectiveStreak.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get collective streak: $e');
    }
  }

  @override
  Future<StreakValidation> validateEssentialTasks(
      String userId, DateTime date) async {
    try {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateKey';

      final doc = await _streakValidationsCollection.doc(docId).get();

      if (doc.exists) {
        return StreakValidation.fromMap(doc.data()!);
      }

      // If no validation exists, create one by checking tasks for that date
      // In a real implementation, this would query actual tasks
      final validation = StreakValidation(
        userId: userId,
        date: date,
        completedEssentialTasks: 0, // Would be calculated from actual tasks
        totalEssentialTasks: 0, // Would be calculated from actual tasks
        isStreakDay: false,
      );

      await _streakValidationsCollection.doc(docId).set(validation.toMap());
      return validation;
    } catch (e) {
      throw Exception('Failed to validate essential tasks: $e');
    }
  }

  @override
  Stream<CollectiveStreak?> watchCollectiveStreak(String boardId) {
    return _collectiveStreaksCollection.doc(boardId).snapshots().map(
        (doc) => doc.exists ? CollectiveStreak.fromMap(doc.data()!) : null);
  }

  @override
  Stream<List<Achievement>> watchUserAchievements(String userId) {
    return _achievementsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Achievement.fromMap(doc.data()))
            .toList());
  }

  @override
  int calculateTaskXP(List<String> tags, {required bool isEssential}) {
    // Base XP for any task
    int baseXP = 10;

    // Bonus XP for essential tasks
    if (isEssential) {
      baseXP += 5;
    }

    // Category-specific bonuses
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

  @override
  String getCategoryFromTags(List<String> tags) {
    // Priority order for categorization
    const categoryPriority = ['Health', 'Finance', 'Work', 'Home'];

    for (final category in categoryPriority) {
      if (tags.any((tag) => tag.toLowerCase() == category.toLowerCase())) {
        return category;
      }
    }

    // Default category if no specific tag found
    return 'Home';
  }
}

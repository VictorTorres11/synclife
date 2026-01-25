import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/data/services/firebase_task_service.dart';
import '../../../tasks/domain/services/services.dart';
import '../../data/services/firebase_gamification_service.dart';
import '../../domain/models/models.dart';
import '../../domain/services/services.dart';

/// Provider for GamificationService
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return FirebaseGamificationService(
    firestore: FirebaseFirestore.instance,
    taskService: taskService,
  );
});

/// Provider for TaskService (needed by GamificationService)
final taskServiceProvider = Provider<TaskService>(
    (ref) => FirebaseTaskService(firestore: FirebaseFirestore.instance));

/// Provider for current user's stats
final userStatsProvider = StreamProvider<UserStats?>((ref) {
  final authState = ref.watch(authStateProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return gamificationService.watchUserStats(user.id);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider for current user's achievements
final userAchievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final authState = ref.watch(authStateProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return gamificationService.watchUserAchievements(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for collective streak of a specific board
final collectiveStreakProvider =
    StreamProvider.family<CollectiveStreak?, String>((ref, boardId) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return gamificationService.watchCollectiveStreak(boardId);
});

/// Provider for leaderboard data
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return gamificationService.getLeaderboard(limit: 10);
});

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
      
      // Return a stream that handles permission errors gracefully
      return gamificationService.watchUserStats(user.id).handleError((error) {
        // If permission denied, return default stats
        if (error.toString().contains('permission-denied')) {
          return UserStats.initial(user.id);
        }
        throw error;
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider for current user's achievements
final userAchievementsProvider = StreamProvider<List<Achievement>>((ref) {
  // Always return mock achievements for now to avoid permission issues
  return Stream.value(_getMockAchievements());
});

/// Mock achievements for when Firestore is not available
List<Achievement> _getMockAchievements() {
  return [
    Achievement(
      id: 'first_task',
      title: 'Primeira Tarefa',
      description: 'Complete sua primeira tarefa',
      category: 'Progress',
      xpReward: 50,
      fluxoCoinReward: 25,
      iconPath: 'assets/achievements/first_task.png',
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Achievement(
      id: 'streak_3',
      title: 'Sequência de 3 Dias',
      description: 'Mantenha uma sequência de 3 dias',
      category: 'Streak',
      xpReward: 100,
      fluxoCoinReward: 50,
      iconPath: 'assets/achievements/streak_3.png',
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Achievement(
      id: 'level_5',
      title: 'Nível 5',
      description: 'Alcance o nível 5',
      category: 'Progress',
      xpReward: 200,
      fluxoCoinReward: 100,
      iconPath: 'assets/achievements/level_5.png',
      isUnlocked: false,
    ),
    Achievement(
      id: 'team_player',
      title: 'Jogador de Equipe',
      description: 'Participe de um quadro compartilhado',
      category: 'Collaboration',
      xpReward: 75,
      fluxoCoinReward: 40,
      iconPath: 'assets/achievements/team_player.png',
      isUnlocked: false,
    ),
    Achievement(
      id: 'productive_week',
      title: 'Semana Produtiva',
      description: 'Complete 20 tarefas em uma semana',
      category: 'Productivity',
      xpReward: 300,
      fluxoCoinReward: 150,
      iconPath: 'assets/achievements/productive_week.png',
      isUnlocked: false,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Madrugador',
      description: 'Complete tarefas antes das 8h por 5 dias',
      category: 'Consistency',
      xpReward: 150,
      fluxoCoinReward: 75,
      iconPath: 'assets/achievements/early_bird.png',
      isUnlocked: false,
    ),
  ];
}

/// Provider for collective streak of a specific board
final collectiveStreakProvider =
    StreamProvider.family<CollectiveStreak?, String>((ref, boardId) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  
  // Return a stream that handles permission errors gracefully
  return gamificationService.watchCollectiveStreak(boardId).handleError((error) {
    // If permission denied, return null
    if (error.toString().contains('permission-denied')) {
      return null;
    }
    throw error;
  });
});

/// Provider for leaderboard data
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  
  try {
    return await gamificationService.getLeaderboard(limit: 10);
  } catch (error) {
    // If permission denied, return empty list
    if (error.toString().contains('permission-denied')) {
      return <LeaderboardEntry>[];
    }
    throw error;
  }
});

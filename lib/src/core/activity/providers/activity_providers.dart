import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_log.dart';
import '../services/activity_service.dart';
import '../services/firebase_activity_service.dart';

/// Provider for the ActivityService implementation
final activityServiceProvider = Provider<ActivityService>((ref) {
  return FirebaseActivityService();
});

/// Provider for recent activities of the current user
final recentActivitiesProvider = StreamProvider.family<List<ActivityLog>, String>(
  (ref, userId) {
    final activityService = ref.watch(activityServiceProvider);
    
    // Return the real stream, but with error handling
    return activityService.getRecentActivities(userId, limit: 5).handleError((error) {
      print('Error in recentActivitiesProvider: $error');
      // Return empty list on error
      return <ActivityLog>[];
    });
  },
);

/// Fallback provider with mock data for development/testing
final mockRecentActivitiesProvider = Provider<List<ActivityLog>>((ref) {
  return [
    ActivityLog(
      id: 'mock-1',
      userId: 'current-user',
      type: ActivityType.taskCompleted,
      title: 'Tarefa concluída',
      description: 'Revisar documentação do projeto',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityLog(
      id: 'mock-2',
      userId: 'current-user',
      type: ActivityType.achievementUnlocked,
      title: 'Conquista desbloqueada',
      description: 'Primeira tarefa concluída!',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ActivityLog(
      id: 'mock-3',
      userId: 'current-user',
      type: ActivityType.taskCreated,
      title: 'Nova tarefa criada',
      description: 'Preparar apresentação',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityLog(
      id: 'mock-4',
      userId: 'current-user',
      type: ActivityType.streakMaintained,
      title: 'Sequência mantida',
      description: '3 dias consecutivos',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});

/// Provider for all user activities with pagination
final userActivitiesProvider = StreamProvider.family<List<ActivityLog>, String>(
  (ref, userId) {
    final activityService = ref.watch(activityServiceProvider);
    return activityService.getUserActivities(userId, limit: 20);
  },
);

/// Helper provider to log activities
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  final activityService = ref.watch(activityServiceProvider);
  return ActivityLogger(activityService);
});

/// Helper class to make logging activities easier
class ActivityLogger {
  const ActivityLogger(this._activityService);

  final ActivityService _activityService;

  Future<void> logTaskCreated(String userId, String taskTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.taskCreated,
      title: 'Nova tarefa criada',
      description: taskTitle,
    );
  }

  Future<void> logTaskCompleted(String userId, String taskTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.taskCompleted,
      title: 'Tarefa concluída',
      description: taskTitle,
    );
  }

  Future<void> logTaskUpdated(String userId, String taskTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.taskUpdated,
      title: 'Tarefa atualizada',
      description: taskTitle,
    );
  }

  Future<void> logBoardCreated(String userId, String boardTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.boardCreated,
      title: 'Novo quadro criado',
      description: boardTitle,
    );
  }

  Future<void> logAchievementUnlocked(String userId, String achievementTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.achievementUnlocked,
      title: 'Conquista desbloqueada',
      description: achievementTitle,
    );
  }

  Future<void> logStreakMaintained(String userId, int days) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.streakMaintained,
      title: 'Sequência mantida',
      description: '$days dias consecutivos',
    );
  }

  Future<void> logRewardPurchased(String userId, String rewardTitle) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.rewardPurchased,
      title: 'Recompensa adquirida',
      description: rewardTitle,
    );
  }

  Future<void> logProfileUpdated(String userId) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.profileUpdated,
      title: 'Perfil atualizado',
      description: 'Informações do perfil foram atualizadas',
    );
  }

  Future<void> logLogin(String userId) async {
    await _activityService.logActivity(
      userId: userId,
      type: ActivityType.loginActivity,
      title: 'Login realizado',
      description: 'Usuário fez login no aplicativo',
    );
  }
}
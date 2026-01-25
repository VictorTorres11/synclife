import '../models/models.dart';

/// Service interface for gamification functionality
abstract class GamificationService {
  /// Gets user statistics for the specified user
  Future<UserStats?> getUserStats(String userId);

  /// Gets user achievements for the specified user
  Future<List<Achievement>> getUserAchievements(String userId);

  /// Gets leaderboard data for top users
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10});

  /// Calculates and awards XP for completed tasks
  /// Returns the updated UserStats
  Future<UserStats> calculateDailyXP(
      String userId, List<String> completedTaskIds);

  /// Updates user streak based on task completion
  /// Returns the updated UserStats
  Future<UserStats> updateStreak(String userId,
      {required bool completedEssentialTasks});

  /// Updates collective streak for a shared board
  /// Returns the updated CollectiveStreak
  Future<CollectiveStreak> updateCollectiveStreak(
      String boardId, Map<String, bool> memberCompletionStatus);

  /// Gets collective streak for a board
  Future<CollectiveStreak?> getCollectiveStreak(String boardId);

  /// Validates essential task completion for streak calculation
  Future<StreakValidation> validateEssentialTasks(String userId, DateTime date);

  /// Processes daily gamification updates for a user
  /// This includes XP calculation, streak updates, and FluxoCoin rewards
  Future<UserStats> processDaily(String userId);

  /// Awards FluxoCoins to a user
  Future<UserStats> awardFluxoCoins(String userId, int amount, String reason);

  /// Deducts FluxoCoins from a user (for purchases)
  Future<UserStats> deductFluxoCoins(String userId, int amount, String reason);

  /// Checks and unlocks achievements for a user
  Future<List<Achievement>> checkAndUnlockAchievements(String userId);

  /// Watches user statistics changes in real-time
  Stream<UserStats?> watchUserStats(String userId);

  /// Watches user achievements changes in real-time
  Stream<List<Achievement>> watchUserAchievements(String userId);

  /// Watches collective streak changes in real-time
  Stream<CollectiveStreak?> watchCollectiveStreak(String boardId);

  /// Calculates XP for a specific task based on its tags and completion
  int calculateTaskXP(List<String> tags, {required bool isEssential});

  /// Gets the category for XP based on task tags
  String getCategoryFromTags(List<String> tags);
}

/// Leaderboard entry model
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.level,
    required this.totalXP,
    required this.currentStreak,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final int level;
  final int totalXP;
  final int currentStreak;
  final String? avatarUrl;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'level': level,
        'totalXP': totalXP,
        'currentStreak': currentStreak,
        'avatarUrl': avatarUrl,
      };

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) =>
      LeaderboardEntry(
        userId: map['userId'] as String,
        username: map['username'] as String,
        level: map['level'] as int,
        totalXP: map['totalXP'] as int,
        currentStreak: map['currentStreak'] as int,
        avatarUrl: map['avatarUrl'] as String?,
      );
}

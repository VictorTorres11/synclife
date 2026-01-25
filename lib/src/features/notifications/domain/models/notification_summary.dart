import 'package:equatable/equatable.dart';

/// Represents a morning summary notification data
class MorningSummary extends Equatable {
  const MorningSummary({
    required this.userId,
    required this.tasksForToday,
    required this.essentialTasksCount,
    required this.currentStreak,
    required this.motivationalMessage,
    required this.weatherInfo,
    required this.teamUpdates,
  });

  final String userId;
  final List<TaskSummary> tasksForToday;
  final int essentialTasksCount;
  final int currentStreak;
  final String motivationalMessage;
  final String? weatherInfo;
  final List<TeamUpdate> teamUpdates;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'tasksForToday': tasksForToday.map((t) => t.toMap()).toList(),
        'essentialTasksCount': essentialTasksCount,
        'currentStreak': currentStreak,
        'motivationalMessage': motivationalMessage,
        'weatherInfo': weatherInfo,
        'teamUpdates': teamUpdates.map((t) => t.toMap()).toList(),
      };

  @override
  List<Object?> get props => [
        userId,
        tasksForToday,
        essentialTasksCount,
        currentStreak,
        motivationalMessage,
        weatherInfo,
        teamUpdates,
      ];
}

/// Represents a night summary notification data
class NightSummary extends Equatable {
  const NightSummary({
    required this.userId,
    required this.completedTasks,
    required this.xpGained,
    required this.fluxoCoinsEarned,
    required this.streakStatus,
    required this.levelProgress,
    required this.categoryBreakdown,
    required this.teamPerformance,
    required this.tomorrowPreview,
  });

  final String userId;
  final List<TaskSummary> completedTasks;
  final int xpGained;
  final int fluxoCoinsEarned;
  final StreakStatus streakStatus;
  final LevelProgress levelProgress;
  final Map<String, int> categoryBreakdown;
  final List<TeamPerformance> teamPerformance;
  final List<TaskSummary> tomorrowPreview;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'completedTasks': completedTasks.map((t) => t.toMap()).toList(),
        'xpGained': xpGained,
        'fluxoCoinsEarned': fluxoCoinsEarned,
        'streakStatus': streakStatus.toMap(),
        'levelProgress': levelProgress.toMap(),
        'categoryBreakdown': categoryBreakdown,
        'teamPerformance': teamPerformance.map((t) => t.toMap()).toList(),
        'tomorrowPreview': tomorrowPreview.map((t) => t.toMap()).toList(),
      };

  @override
  List<Object?> get props => [
        userId,
        completedTasks,
        xpGained,
        fluxoCoinsEarned,
        streakStatus,
        levelProgress,
        categoryBreakdown,
        teamPerformance,
        tomorrowPreview,
      ];
}

/// Represents a task summary for notifications
class TaskSummary extends Equatable {
  const TaskSummary({
    required this.id,
    required this.title,
    required this.isEssential,
    required this.tags,
    required this.boardName,
    this.dueTime,
  });

  final String id;
  final String title;
  final bool isEssential;
  final List<String> tags;
  final String boardName;
  final DateTime? dueTime;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isEssential': isEssential,
        'tags': tags,
        'boardName': boardName,
        'dueTime': dueTime?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, title, isEssential, tags, boardName, dueTime];
}

/// Represents team activity update
class TeamUpdate extends Equatable {
  const TeamUpdate({
    required this.boardName,
    required this.memberName,
    required this.action,
    required this.taskTitle,
    required this.timestamp,
  });

  final String boardName;
  final String memberName;
  final String action; // 'completed', 'created', 'updated'
  final String taskTitle;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'boardName': boardName,
        'memberName': memberName,
        'action': action,
        'taskTitle': taskTitle,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [boardName, memberName, action, taskTitle, timestamp];
}

/// Represents streak status
class StreakStatus extends Equatable {
  const StreakStatus({
    required this.current,
    required this.longest,
    required this.isActive,
    required this.message,
  });

  final int current;
  final int longest;
  final bool isActive;
  final String message;

  Map<String, dynamic> toMap() => {
        'current': current,
        'longest': longest,
        'isActive': isActive,
        'message': message,
      };

  @override
  List<Object?> get props => [current, longest, isActive, message];
}

/// Represents level progress
class LevelProgress extends Equatable {
  const LevelProgress({
    required this.currentLevel,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.progressPercentage,
    required this.leveledUp,
  });

  final int currentLevel;
  final int currentXP;
  final int xpForNextLevel;
  final double progressPercentage;
  final bool leveledUp;

  Map<String, dynamic> toMap() => {
        'currentLevel': currentLevel,
        'currentXP': currentXP,
        'xpForNextLevel': xpForNextLevel,
        'progressPercentage': progressPercentage,
        'leveledUp': leveledUp,
      };

  @override
  List<Object?> get props => [
        currentLevel,
        currentXP,
        xpForNextLevel,
        progressPercentage,
        leveledUp,
      ];
}

/// Represents team performance summary
class TeamPerformance extends Equatable {
  const TeamPerformance({
    required this.boardName,
    required this.completionRate,
    required this.collectiveStreak,
    required this.topPerformer,
  });

  final String boardName;
  final double completionRate;
  final int collectiveStreak;
  final String topPerformer;

  Map<String, dynamic> toMap() => {
        'boardName': boardName,
        'completionRate': completionRate,
        'collectiveStreak': collectiveStreak,
        'topPerformer': topPerformer,
      };

  @override
  List<Object?> get props =>
      [boardName, completionRate, collectiveStreak, topPerformer];
}

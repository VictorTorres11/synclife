import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Represents user statistics and gamification data in the SyncLife system
class UserStats extends Equatable {
  const UserStats({
    required this.userId,
    required this.totalXP,
    required this.level,
    required this.fluxoCoins,
    required this.currentStreak,
    required this.longestStreak,
    required this.categoryXP,
    required this.lastActive,
    required this.updatedAt,
  });

  final String userId;
  final int totalXP;
  final int level;
  final int fluxoCoins;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> categoryXP;
  final DateTime lastActive;
  final DateTime updatedAt;

  /// Creates a UserStats from Firestore document data
  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
    userId: map['userId'] as String,
    totalXP: map['totalXP'] as int,
    level: map['level'] as int,
    fluxoCoins: map['fluxoCoins'] as int,
    currentStreak: map['currentStreak'] as int,
    longestStreak: map['longestStreak'] as int,
    categoryXP: Map<String, int>.from(map['categoryXP'] as Map),
    lastActive: DateTime.parse(map['lastActive'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts UserStats to Firestore document data
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalXP': totalXP,
    'level': level,
    'fluxoCoins': fluxoCoins,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'categoryXP': categoryXP,
    'lastActive': lastActive.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Creates initial UserStats for a new user
  factory UserStats.initial(String userId) => UserStats(
    userId: userId,
    totalXP: 0,
    level: 1,
    fluxoCoins: 0,
    currentStreak: 0,
    longestStreak: 0,
    categoryXP: const {
      'Health': 0,
      'Home': 0,
      'Finance': 0,
      'Work': 0,
    },
    lastActive: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Calculates level based on total XP
  /// Level formula: level = floor(sqrt(totalXP / 100)) + 1
  static int calculateLevel(int totalXP) {
    if (totalXP <= 0) return 1;
    return (math.sqrt(totalXP / 100)).floor() + 1;
  }

  /// Calculates XP required for next level
  int get xpForNextLevel {
    final nextLevel = level + 1;
    return (nextLevel - 1) * (nextLevel - 1) * 100;
  }

  /// Calculates XP progress towards next level
  int get xpProgressInCurrentLevel {
    final currentLevelMinXP = (level - 1) * (level - 1) * 100;
    return totalXP - currentLevelMinXP;
  }

  /// Calculates XP needed in current level for next level
  int get xpNeededInCurrentLevel {
    final currentLevelMinXP = (level - 1) * (level - 1) * 100;
    final nextLevelMinXP = level * level * 100;
    return nextLevelMinXP - currentLevelMinXP;
  }

  UserStats copyWith({
    String? userId,
    int? totalXP,
    int? level,
    int? fluxoCoins,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? categoryXP,
    DateTime? lastActive,
    DateTime? updatedAt,
  }) => UserStats(
    userId: userId ?? this.userId,
    totalXP: totalXP ?? this.totalXP,
    level: level ?? this.level,
    fluxoCoins: fluxoCoins ?? this.fluxoCoins,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    categoryXP: categoryXP ?? this.categoryXP,
    lastActive: lastActive ?? this.lastActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    userId, totalXP, level, fluxoCoins, currentStreak, longestStreak,
    categoryXP, lastActive, updatedAt,
  ];
}
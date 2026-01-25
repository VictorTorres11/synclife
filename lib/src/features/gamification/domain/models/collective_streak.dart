import 'package:equatable/equatable.dart';

/// Represents collective streak data for a shared board
class CollectiveStreak extends Equatable {
  const CollectiveStreak({
    required this.boardId,
    required this.currentStreak,
    required this.longestStreak,
    required this.memberIds,
    required this.lastStreakDate,
    required this.updatedAt,
  });

  final String boardId;
  final int currentStreak;
  final int longestStreak;
  final List<String> memberIds;
  final DateTime? lastStreakDate;
  final DateTime updatedAt;

  /// Creates a CollectiveStreak from Firestore document data
  factory CollectiveStreak.fromMap(Map<String, dynamic> map) => CollectiveStreak(
    boardId: map['boardId'] as String,
    currentStreak: map['currentStreak'] as int,
    longestStreak: map['longestStreak'] as int,
    memberIds: List<String>.from(map['memberIds'] as List),
    lastStreakDate: map['lastStreakDate'] != null 
        ? DateTime.parse(map['lastStreakDate'] as String)
        : null,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Converts CollectiveStreak to Firestore document data
  Map<String, dynamic> toMap() => {
    'boardId': boardId,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'memberIds': memberIds,
    'lastStreakDate': lastStreakDate?.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Creates initial CollectiveStreak for a new board
  factory CollectiveStreak.initial(String boardId, List<String> memberIds) => CollectiveStreak(
    boardId: boardId,
    currentStreak: 0,
    longestStreak: 0,
    memberIds: memberIds,
    lastStreakDate: null,
    updatedAt: DateTime.now(),
  );

  /// Checks if streak should continue based on date
  bool shouldContinueStreak(DateTime date) {
    if (lastStreakDate == null) return true;
    
    final daysDifference = date.difference(lastStreakDate!).inDays;
    return daysDifference == 1; // Streak continues if it's the next day
  }

  /// Checks if streak is broken based on date
  bool isStreakBroken(DateTime date) {
    if (lastStreakDate == null) return false;
    
    final daysDifference = date.difference(lastStreakDate!).inDays;
    return daysDifference > 1; // Streak broken if more than 1 day gap
  }

  CollectiveStreak copyWith({
    String? boardId,
    int? currentStreak,
    int? longestStreak,
    List<String>? memberIds,
    DateTime? lastStreakDate,
    DateTime? updatedAt,
  }) => CollectiveStreak(
    boardId: boardId ?? this.boardId,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    memberIds: memberIds ?? this.memberIds,
    lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    boardId, currentStreak, longestStreak, memberIds, lastStreakDate, updatedAt,
  ];
}
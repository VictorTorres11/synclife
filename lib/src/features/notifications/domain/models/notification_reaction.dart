import 'package:equatable/equatable.dart';

/// Available emoji reactions for notifications
enum EmojiReaction {
  thumbsUp('👍', 'thumbs_up'),
  heart('❤️', 'heart'),
  fire('🔥', 'fire'),
  clap('👏', 'clap'),
  rocket('🚀', 'rocket'),
  star('⭐', 'star');

  const EmojiReaction(this.emoji, this.value);

  final String emoji;
  final String value;

  static EmojiReaction fromValue(String value) {
    return EmojiReaction.values.firstWhere(
      (reaction) => reaction.value == value,
      orElse: () => EmojiReaction.thumbsUp,
    );
  }
}

/// Represents a user's reaction to a notification
class NotificationReaction extends Equatable {
  const NotificationReaction({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  final String id;
  final String notificationId;
  final String userId;
  final EmojiReaction reaction;
  final DateTime createdAt;

  factory NotificationReaction.fromMap(Map<String, dynamic> map) =>
      NotificationReaction(
        id: map['id'] as String,
        notificationId: map['notificationId'] as String,
        userId: map['userId'] as String,
        reaction: EmojiReaction.fromValue(map['reaction'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'notificationId': notificationId,
        'userId': userId,
        'reaction': reaction.value,
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationReaction copyWith({
    String? id,
    String? notificationId,
    String? userId,
    EmojiReaction? reaction,
    DateTime? createdAt,
  }) =>
      NotificationReaction(
        id: id ?? this.id,
        notificationId: notificationId ?? this.notificationId,
        userId: userId ?? this.userId,
        reaction: reaction ?? this.reaction,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        notificationId,
        userId,
        reaction,
        createdAt,
      ];
}

/// Aggregated reaction data for a notification
class NotificationReactionSummary extends Equatable {
  const NotificationReactionSummary({
    required this.notificationId,
    required this.reactionCounts,
    required this.userReactions,
    required this.totalReactions,
  });

  final String notificationId;
  final Map<EmojiReaction, int> reactionCounts;
  final Map<String, EmojiReaction> userReactions; // userId -> reaction
  final int totalReactions;

  factory NotificationReactionSummary.fromMap(Map<String, dynamic> map) {
    final reactionCountsMap =
        map['reactionCounts'] as Map<String, dynamic>? ?? {};
    final reactionCounts = <EmojiReaction, int>{};

    for (final entry in reactionCountsMap.entries) {
      final reaction = EmojiReaction.fromValue(entry.key);
      reactionCounts[reaction] = entry.value as int;
    }

    final userReactionsMap =
        map['userReactions'] as Map<String, dynamic>? ?? {};
    final userReactions = <String, EmojiReaction>{};

    for (final entry in userReactionsMap.entries) {
      userReactions[entry.key] = EmojiReaction.fromValue(entry.value as String);
    }

    return NotificationReactionSummary(
      notificationId: map['notificationId'] as String,
      reactionCounts: reactionCounts,
      userReactions: userReactions,
      totalReactions: map['totalReactions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'reactionCounts': reactionCounts.map(
          (reaction, count) => MapEntry(reaction.value, count),
        ),
        'userReactions': userReactions.map(
          (userId, reaction) => MapEntry(userId, reaction.value),
        ),
        'totalReactions': totalReactions,
      };

  /// Get the user's current reaction, if any
  EmojiReaction? getUserReaction(String userId) => userReactions[userId];

  /// Check if user has reacted with a specific emoji
  bool hasUserReacted(String userId, EmojiReaction reaction) =>
      userReactions[userId] == reaction;

  /// Get count for a specific reaction
  int getReactionCount(EmojiReaction reaction) => reactionCounts[reaction] ?? 0;

  /// Get the most popular reactions (up to 3)
  List<MapEntry<EmojiReaction, int>> getTopReactions({int limit = 3}) {
    final sortedReactions = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedReactions.take(limit).toList();
  }

  NotificationReactionSummary copyWith({
    String? notificationId,
    Map<EmojiReaction, int>? reactionCounts,
    Map<String, EmojiReaction>? userReactions,
    int? totalReactions,
  }) =>
      NotificationReactionSummary(
        notificationId: notificationId ?? this.notificationId,
        reactionCounts: reactionCounts ?? this.reactionCounts,
        userReactions: userReactions ?? this.userReactions,
        totalReactions: totalReactions ?? this.totalReactions,
      );

  @override
  List<Object?> get props => [
        notificationId,
        reactionCounts,
        userReactions,
        totalReactions,
      ];
}

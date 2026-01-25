import 'package:equatable/equatable.dart';

/// Settings configuration for a board
class BoardSettings extends Equatable {
  const BoardSettings({
    this.allowComments = true,
    this.enableNotifications = true,
    this.requireEssentialTasks = false,
    this.streakEnabled = true,
    this.autoSync = true,
    this.isPublic = false,
    this.allowInvites = true,
    this.allowRecurringTasks = true,
    this.allowTaskAssignment = true,
    this.enableXP = true,
    this.enableCollectiveStreaks = true,
    this.showLeaderboard = true,
  });

  final bool allowComments;
  final bool enableNotifications;
  final bool requireEssentialTasks;
  final bool streakEnabled;
  final bool autoSync;
  final bool isPublic;
  final bool allowInvites;
  final bool allowRecurringTasks;
  final bool allowTaskAssignment;
  final bool enableXP;
  final bool enableCollectiveStreaks;
  final bool showLeaderboard;

  /// Creates BoardSettings from Firestore document data
  factory BoardSettings.fromMap(Map<String, dynamic> map) => BoardSettings(
        allowComments: map['allowComments'] as bool? ?? true,
        enableNotifications: map['enableNotifications'] as bool? ?? true,
        requireEssentialTasks: map['requireEssentialTasks'] as bool? ?? false,
        streakEnabled: map['streakEnabled'] as bool? ?? true,
        autoSync: map['autoSync'] as bool? ?? true,
        isPublic: map['isPublic'] as bool? ?? false,
        allowInvites: map['allowInvites'] as bool? ?? true,
        allowRecurringTasks: map['allowRecurringTasks'] as bool? ?? true,
        allowTaskAssignment: map['allowTaskAssignment'] as bool? ?? true,
        enableXP: map['enableXP'] as bool? ?? true,
        enableCollectiveStreaks:
            map['enableCollectiveStreaks'] as bool? ?? true,
        showLeaderboard: map['showLeaderboard'] as bool? ?? true,
      );

  /// Converts BoardSettings to Firestore document data
  Map<String, dynamic> toMap() => {
        'allowComments': allowComments,
        'enableNotifications': enableNotifications,
        'requireEssentialTasks': requireEssentialTasks,
        'streakEnabled': streakEnabled,
        'autoSync': autoSync,
        'isPublic': isPublic,
        'allowInvites': allowInvites,
        'allowRecurringTasks': allowRecurringTasks,
        'allowTaskAssignment': allowTaskAssignment,
        'enableXP': enableXP,
        'enableCollectiveStreaks': enableCollectiveStreaks,
        'showLeaderboard': showLeaderboard,
      };

  BoardSettings copyWith({
    bool? allowComments,
    bool? enableNotifications,
    bool? requireEssentialTasks,
    bool? streakEnabled,
    bool? autoSync,
    bool? isPublic,
    bool? allowInvites,
    bool? allowRecurringTasks,
    bool? allowTaskAssignment,
    bool? enableXP,
    bool? enableCollectiveStreaks,
    bool? showLeaderboard,
  }) =>
      BoardSettings(
        allowComments: allowComments ?? this.allowComments,
        enableNotifications: enableNotifications ?? this.enableNotifications,
        requireEssentialTasks:
            requireEssentialTasks ?? this.requireEssentialTasks,
        streakEnabled: streakEnabled ?? this.streakEnabled,
        autoSync: autoSync ?? this.autoSync,
        isPublic: isPublic ?? this.isPublic,
        allowInvites: allowInvites ?? this.allowInvites,
        allowRecurringTasks: allowRecurringTasks ?? this.allowRecurringTasks,
        allowTaskAssignment: allowTaskAssignment ?? this.allowTaskAssignment,
        enableXP: enableXP ?? this.enableXP,
        enableCollectiveStreaks:
            enableCollectiveStreaks ?? this.enableCollectiveStreaks,
        showLeaderboard: showLeaderboard ?? this.showLeaderboard,
      );

  @override
  List<Object?> get props => [
        allowComments,
        enableNotifications,
        requireEssentialTasks,
        streakEnabled,
        autoSync,
        isPublic,
        allowInvites,
        allowRecurringTasks,
        allowTaskAssignment,
        enableXP,
        enableCollectiveStreaks,
        showLeaderboard,
      ];
}

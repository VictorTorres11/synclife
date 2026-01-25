import 'package:equatable/equatable.dart';

import 'notification_reaction.dart';

/// Types of notifications in the app
enum NotificationType {
  dailySummary,
  teamActivity,
  taskReminder,
  achievement,
  streakAlert,
  invitation,
  system,
}

/// Priority levels for notifications
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Represents a notification in the SyncLife app
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.priority,
    this.isRead = false,
    this.data = const {},
    this.imageUrl,
    this.actionUrl,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationPriority priority;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? actionUrl;
  final DateTime? expiresAt;

  /// Creates an AppNotification from Firestore document data
  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: NotificationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => NotificationType.system,
        ),
        title: map['title'] as String,
        body: map['body'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        isRead: map['isRead'] as bool? ?? false,
        data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
        imageUrl: map['imageUrl'] as String?,
        actionUrl: map['actionUrl'] as String?,
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
      );

  /// Converts AppNotification to Firestore document data
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'priority': priority.name,
        'isRead': isRead,
        'data': data,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  /// Checks if the notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Gets the time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Gets the appropriate icon for the notification type
  String get iconPath {
    switch (type) {
      case NotificationType.dailySummary:
        return 'assets/icons/daily_summary.png';
      case NotificationType.teamActivity:
        return 'assets/icons/team_activity.png';
      case NotificationType.taskReminder:
        return 'assets/icons/task_reminder.png';
      case NotificationType.achievement:
        return 'assets/icons/achievement.png';
      case NotificationType.streakAlert:
        return 'assets/icons/streak_alert.png';
      case NotificationType.invitation:
        return 'assets/icons/invitation.png';
      case NotificationType.system:
        return 'assets/icons/system.png';
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    NotificationPriority? priority,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    DateTime? expiresAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        priority: priority ?? this.priority,
        isRead: isRead ?? this.isRead,
        data: data ?? this.data,
        imageUrl: imageUrl ?? this.imageUrl,
        actionUrl: actionUrl ?? this.actionUrl,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        createdAt,
        priority,
        isRead,
        data,
        imageUrl,
        actionUrl,
        expiresAt,
      ];
}

/// Represents team activity data for notifications
class TeamActivityData {
  const TeamActivityData({
    required this.boardId,
    required this.boardName,
    required this.memberName,
    required this.memberId,
    required this.action,
    required this.taskTitle,
    this.taskId,
  });

  final String boardId;
  final String boardName;
  final String memberName;
  final String memberId;
  final String action; // 'completed', 'created', 'updated', 'joined'
  final String taskTitle;
  final String? taskId;

  Map<String, dynamic> toMap() => {
        'boardId': boardId,
        'boardName': boardName,
        'memberName': memberName,
        'memberId': memberId,
        'action': action,
        'taskTitle': taskTitle,
        'taskId': taskId,
      };

  factory TeamActivityData.fromMap(Map<String, dynamic> map) =>
      TeamActivityData(
        boardId: map['boardId'] as String,
        boardName: map['boardName'] as String,
        memberName: map['memberName'] as String,
        memberId: map['memberId'] as String,
        action: map['action'] as String,
        taskTitle: map['taskTitle'] as String,
        taskId: map['taskId'] as String?,
      );
}

/// Represents achievement data for notifications
class AchievementData {
  const AchievementData({
    required this.achievementId,
    required this.achievementTitle,
    required this.xpReward,
    required this.fluxoCoinReward,
    this.iconUrl,
  });

  final String achievementId;
  final String achievementTitle;
  final int xpReward;
  final int fluxoCoinReward;
  final String? iconUrl;

  Map<String, dynamic> toMap() => {
        'achievementId': achievementId,
        'achievementTitle': achievementTitle,
        'xpReward': xpReward,
        'fluxoCoinReward': fluxoCoinReward,
        'iconUrl': iconUrl,
      };

  factory AchievementData.fromMap(Map<String, dynamic> map) => AchievementData(
        achievementId: map['achievementId'] as String,
        achievementTitle: map['achievementTitle'] as String,
        xpReward: map['xpReward'] as int,
        fluxoCoinReward: map['fluxoCoinReward'] as int,
        iconUrl: map['iconUrl'] as String?,
      );
}

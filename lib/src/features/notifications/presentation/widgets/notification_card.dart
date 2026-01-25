import 'package:flutter/material.dart';

import '../../domain/models/app_notification.dart';

/// Widget displaying a single notification as a card
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: notification.isRead
                  ? null
                  : Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Body
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: notification.isRead
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Priority and Type Indicators
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Priority Badge
                          if (notification.priority !=
                              NotificationPriority.normal) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(notification.priority)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                notification.priority.name.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      _getPriorityColor(notification.priority),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getTypeDisplayName(notification.type),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getTypeColor(notification.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Unread Indicator
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.dailySummary:
        return Colors.blue;
      case NotificationType.teamActivity:
        return Colors.green;
      case NotificationType.taskReminder:
        return Colors.orange;
      case NotificationType.achievement:
        return Colors.purple;
      case NotificationType.streakAlert:
        return Colors.red;
      case NotificationType.invitation:
        return Colors.teal;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.dailySummary:
        return Icons.today;
      case NotificationType.teamActivity:
        return Icons.group;
      case NotificationType.taskReminder:
        return Icons.task_alt;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.streakAlert:
        return Icons.local_fire_department;
      case NotificationType.invitation:
        return Icons.person_add;
      case NotificationType.system:
        return Icons.settings;
    }
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.dailySummary:
        return 'Daily';
      case NotificationType.teamActivity:
        return 'Team';
      case NotificationType.taskReminder:
        return 'Task';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.streakAlert:
        return 'Streak';
      case NotificationType.invitation:
        return 'Invite';
      case NotificationType.system:
        return 'System';
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }
}

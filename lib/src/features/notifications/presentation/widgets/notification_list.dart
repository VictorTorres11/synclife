import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_notification.dart';
import '../providers/notification_center_providers.dart';
import 'notification_card.dart';

/// Widget displaying a list of notifications
class NotificationList extends ConsumerWidget {
  const NotificationList({
    super.key,
    this.filter,
  });

  final NotificationType? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = filter != null
        ? ref.watch(filteredNotificationsProvider(filter))
        : ref.watch(userNotificationsProvider);

    final theme = Theme.of(context);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(context, theme);
        }
        return _buildNotificationsList(context, notifications, ref);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(userNotificationsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter != null ? _getFilterIcon(filter!) : Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            filter != null
                ? 'No ${_getFilterName(filter!)} notifications'
                : 'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filter != null
                ? 'Check back later for updates!'
                : 'You\'ll see your notifications here when they arrive',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<AppNotification> notifications,
    WidgetRef ref,
  ) {
    // Group notifications by date
    final groupedNotifications = _groupNotificationsByDate(notifications);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final group = groupedNotifications[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            if (index == 0 ||
                groupedNotifications[index - 1].date != group.date) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _formatDateHeader(group.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],

            // Notification Cards
            ...group.notifications.map((notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: notification,
                    onTap: () =>
                        _handleNotificationTap(context, notification, ref),
                    onDismiss: () =>
                        _handleNotificationDismiss(notification, ref),
                  ),
                )),
          ],
        );
      },
    );
  }

  List<NotificationGroup> _groupNotificationsByDate(
      List<AppNotification> notifications) {
    final groups = <String, List<AppNotification>>{};

    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      groups[dateKey] = (groups[dateKey] ?? [])..add(notification);
    }

    return groups.entries
        .map((entry) => NotificationGroup(
              date: entry.key,
              notifications: entry.value,
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateHeader(String dateKey) {
    return dateKey;
  }

  IconData _getFilterIcon(NotificationType type) {
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

  String _getFilterName(NotificationType type) {
    switch (type) {
      case NotificationType.dailySummary:
        return 'daily summary';
      case NotificationType.teamActivity:
        return 'team activity';
      case NotificationType.taskReminder:
        return 'task reminder';
      case NotificationType.achievement:
        return 'achievement';
      case NotificationType.streakAlert:
        return 'streak alert';
      case NotificationType.invitation:
        return 'invitation';
      case NotificationType.system:
        return 'system';
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
    WidgetRef ref,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      ref
          .read(notificationActionsProvider.notifier)
          .markAsRead(notification.id);
    }

    // Handle navigation based on notification type and action URL
    if (notification.actionUrl != null) {
      // Navigate to specific screen based on action URL
      Navigator.of(context).pushNamed(notification.actionUrl!);
    } else {
      // Show notification details
      _showNotificationDetails(context, notification);
    }
  }

  void _handleNotificationDismiss(AppNotification notification, WidgetRef ref) {
    ref
        .read(notificationActionsProvider.notifier)
        .deleteNotification(notification.id);
  }

  void _showNotificationDetails(
      BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              Text(
                'Received: ${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} at ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Helper class for grouping notifications by date
class NotificationGroup {
  const NotificationGroup({
    required this.date,
    required this.notifications,
  });

  final String date;
  final List<AppNotification> notifications;
}

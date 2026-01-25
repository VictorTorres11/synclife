import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_notification.dart';
import '../providers/notification_center_providers.dart';
import '../widgets/notification_reaction_buttons.dart';

/// Widget displaying team activity feed with reactions
class TeamActivityFeed extends ConsumerWidget {
  const TeamActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamNotificationsAsync = ref.watch(teamActivityNotificationsProvider);
    final theme = Theme.of(context);

    return teamNotificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(context, theme);
        }
        return _buildActivityFeed(context, notifications, ref);
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
              'Error loading team activity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
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
            Icons.group_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No team activity yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join shared boards to see team activity here!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(
    BuildContext context,
    List<AppNotification> notifications,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildActivityCard(context, notification, ref),
        );
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    AppNotification notification,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final activityData = _parseTeamActivityData(notification.data);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Header
            Row(
              children: [
                // Activity Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getActivityColor(activityData?.action ?? '')
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getActivityIcon(activityData?.action ?? ''),
                    color: _getActivityColor(activityData?.action ?? ''),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Activity Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Time
                Text(
                  notification.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            // Board and Task Info
            if (activityData != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activityData.boardName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.task_alt,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activityData.taskTitle,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Reaction Buttons
            NotificationReactionButtons(
              notificationId: notification.id,
              userId: 'current-user-id', // TODO: Get from auth provider
            ),
          ],
        ),
      ),
    );
  }

  TeamActivityData? _parseTeamActivityData(Map<String, dynamic> data) {
    try {
      return TeamActivityData.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'created':
        return Colors.blue;
      case 'updated':
        return Colors.orange;
      case 'joined':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'created':
        return Icons.add_circle;
      case 'updated':
        return Icons.edit;
      case 'joined':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  void _handleReaction(String notificationId, String reaction, WidgetRef ref) {
    // Handle reaction logic here
    // This would typically call a service to save the reaction
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(content: Text('Reacted with $reaction')),
    );
  }
}

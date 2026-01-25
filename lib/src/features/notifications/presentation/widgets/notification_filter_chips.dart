import 'package:flutter/material.dart';

import '../../domain/models/app_notification.dart';

/// Widget displaying filter chips for notification types
class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final NotificationType? selectedFilter;
  final ValueChanged<NotificationType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All filter
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedFilter == null,
              onSelected: (selected) {
                onFilterChanged(selected ? null : selectedFilter);
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            ),
          ),

          // Type filters
          ...NotificationType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getTypeDisplayName(type)),
                  selected: selectedFilter == type,
                  onSelected: (selected) {
                    onFilterChanged(selected ? type : null);
                  },
                  selectedColor: _getTypeColor(type).withOpacity(0.2),
                  checkmarkColor: _getTypeColor(type),
                  avatar: selectedFilter == type
                      ? null
                      : Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: _getTypeColor(type),
                        ),
                ),
              )),
        ],
      ),
    );
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.dailySummary:
        return 'Daily Summary';
      case NotificationType.teamActivity:
        return 'Team Activity';
      case NotificationType.taskReminder:
        return 'Task Reminders';
      case NotificationType.achievement:
        return 'Achievements';
      case NotificationType.streakAlert:
        return 'Streak Alerts';
      case NotificationType.invitation:
        return 'Invitations';
      case NotificationType.system:
        return 'System';
    }
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
}

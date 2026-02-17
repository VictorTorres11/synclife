import 'package:flutter/material.dart';

import '../../domain/models/reminder.dart';
import '../../domain/models/reminder_priority.dart';

/// Widget displaying a single reminder as a card with actions
/// 
/// Displays reminder content, priority indicator, tags, and action buttons
/// for editing, deleting, and converting to a task.
/// 
/// The card is tappable to trigger the edit action, and includes three
/// action buttons at the bottom for edit, delete, and convert operations.
class ReminderCard extends StatelessWidget {
  /// Creates a ReminderCard
  /// 
  /// All parameters are required:
  /// - [reminder]: The reminder data to display
  /// - [onEdit]: Callback when edit button is pressed or card is tapped
  /// - [onDelete]: Callback when delete button is pressed
  /// - [onConvert]: Callback when convert to task button is pressed
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onConvert,
  });

  /// The reminder to display
  final Reminder reminder;
  
  /// Callback when the edit button is pressed or card is tapped
  final VoidCallback onEdit;
  
  /// Callback when the delete button is pressed
  final VoidCallback onDelete;
  
  /// Callback when the convert to task button is pressed
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Reminder: ${reminder.content}. ${_getPriorityLabel(reminder.priority)} priority. ${reminder.tags.isEmpty ? 'No tags' : 'Tags: ${reminder.tags.join(', ')}'}',
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Priority indicator and content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator with icon for better accessibility
                  Semantics(
                    label: '${_getPriorityLabel(reminder.priority)} priority',
                    child: Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(reminder.priority).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(reminder.priority),
                            size: 14,
                            color: _getPriorityColor(reminder.priority),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content text
                  Expanded(
                    child: Text(
                      reminder.content,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Tags
              if (reminder.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reminder.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: theme.textTheme.labelSmall,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Action buttons
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label: 'Actions',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    Semantics(
                      label: 'Edit reminder',
                      button: true,
                      hint: 'Double tap to edit this reminder',
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 24,
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),

                    // Delete button
                    Semantics(
                      label: 'Delete reminder',
                      button: true,
                      hint: 'Double tap to delete this reminder',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 24,
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),

                    // Convert to task button
                    Semantics(
                      label: 'Convert reminder to task',
                      button: true,
                      hint: 'Double tap to convert this reminder into a task',
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        iconSize: 24,
                        tooltip: 'Convert to Task',
                        onPressed: onConvert,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
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

  /// Get color for priority level
  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.green;
      case ReminderPriority.medium:
        return Colors.orange;
      case ReminderPriority.high:
        return Colors.red;
    }
  }

  /// Get icon for priority level (for accessibility)
  IconData _getPriorityIcon(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Icons.arrow_downward;
      case ReminderPriority.medium:
        return Icons.remove;
      case ReminderPriority.high:
        return Icons.arrow_upward;
    }
  }

  /// Get label for priority level (for accessibility)
  String _getPriorityLabel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.high:
        return 'High';
    }
  }
}

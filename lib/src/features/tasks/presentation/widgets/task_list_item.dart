import 'package:flutter/material.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_recurrence.dart';

/// Widget for displaying a single task item with swipe gestures
class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onPostpone,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onPostpone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - complete task
          onComplete();
          return false; // Don't actually dismiss, just trigger action
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left - postpone task
          onPostpone();
          return false; // Don't actually dismiss, just trigger action
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 32,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.orange,
        child: const Icon(
          Icons.schedule,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: task.isCompleted ? null : (_) => onComplete(),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
              color: task.isCompleted 
                  ? Colors.grey 
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) ...[
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: _getDueDateColor(task.dueDate!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(task.dueDate!),
                      style: TextStyle(
                        color: _getDueDateColor(task.dueDate!),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.recurrence != TaskRecurrence.none) ...[
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getRecurrenceText(task.recurrence),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: task.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
          trailing: task.assignedTo != null 
              ? const Icon(Icons.person, size: 20)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDate.isBefore(today)) {
      return Colors.red; // Overdue
    } else if (taskDate.isAtSameMomentAs(today)) {
      return Colors.orange; // Due today
    } else {
      return Colors.grey; // Future
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final difference = today.difference(taskDate).inDays;
      return '$difference day${difference == 1 ? '' : 's'} overdue';
    } else {
      final difference = taskDate.difference(today).inDays;
      return 'In $difference day${difference == 1 ? '' : 's'}';
    }
  }

  String _getRecurrenceText(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.monthly:
        return 'Monthly';
      case TaskRecurrence.custom:
        return 'Custom';
      case TaskRecurrence.none:
        return '';
    }
  }
}
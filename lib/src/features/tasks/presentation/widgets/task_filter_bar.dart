import 'package:flutter/material.dart';
import '../../domain/models/task_recurrence.dart';

/// Filter options for tasks
enum TaskFilter {
  all,
  pending,
  completed,
  overdue,
  today,
  thisWeek,
}

/// Widget for filtering and categorizing tasks
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.availableTags,
  });

  final TaskFilter selectedFilter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final List<String> availableTags;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TaskFilter.values.map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged(filter),
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Tag filters
        if (availableTags.isNotEmpty) ...[
          const Divider(height: 1),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.label_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: availableTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            final newTags = List<String>.from(selectedTags);
                            if (selected) {
                              newTags.add(tag);
                            } else {
                              newTags.remove(tag);
                            }
                            onTagsChanged(newTags);
                          },
                          selectedColor: _getTagColor(tag).withOpacity(0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getFilterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.thisWeek:
        return 'This Week';
    }
  }

  Color _getTagColor(String tag) {
    // Simple color mapping for different tag categories
    switch (tag.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'home':
        return Colors.orange;
      case 'finance':
        return Colors.purple;
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
import 'package:flutter/material.dart';
import '../../domain/models/create_task_request.dart';
import '../../domain/models/task_recurrence.dart';

/// Dialog for creating a new task
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({
    super.key,
    required this.onCreateTask,
    required this.availableTags,
    required this.boardId,
    required this.userId,
  });

  final Function(CreateTaskRequest) onCreateTask;
  final List<String> availableTags;
  final String boardId;
  final String userId;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _selectedDueDate;
  TaskRecurrence _selectedRecurrence = TaskRecurrence.none;
  List<String> _selectedTags = [];
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildDueDateField(),
                      const SizedBox(height: 16),
                      _buildRecurrenceField(),
                      const SizedBox(height: 16),
                      _buildTagsField(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createTask,
                  child: const Text('Create Task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      onTap: _selectDueDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Due Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDueDate != null
              ? _formatDate(_selectedDueDate!)
              : 'No due date',
          style: TextStyle(
            color: _selectedDueDate != null 
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceField() {
    return DropdownButtonFormField<TaskRecurrence>(
      initialValue: _selectedRecurrence,
      decoration: const InputDecoration(
        labelText: 'Recurrence',
        border: OutlineInputBorder(),
      ),
      items: TaskRecurrence.values.map((recurrence) {
        return DropdownMenuItem(
          value: recurrence,
          child: Text(_getRecurrenceText(recurrence)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRecurrence = value;
          });
        }
      },
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: widget.availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      setState(() {
        _selectedDueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
      });
    }
  }

  void _createTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = CreateTaskRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        boardId: widget.boardId,
        recurrence: _selectedRecurrence,
        dueDate: _selectedDueDate,
        tags: _selectedTags,
        createdBy: widget.userId,
      );
      
      widget.onCreateTask(request);
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today at ${_formatTime(date)}';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getRecurrenceText(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'No recurrence';
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.monthly:
        return 'Monthly';
      case TaskRecurrence.custom:
        return 'Custom';
    }
  }
}
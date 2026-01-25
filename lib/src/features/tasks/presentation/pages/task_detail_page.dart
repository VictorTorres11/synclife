import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_recurrence.dart';
import '../../domain/models/update_task_request.dart';

/// Page for displaying and editing task details
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.availableTags,
  });

  final Task task;
  final Function(String taskId, UpdateTaskRequest request) onUpdateTask;
  final Function(String taskId) onDeleteTask;
  final List<String> availableTags;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  late DateTime? _selectedDueDate;
  late TaskRecurrence _selectedRecurrence;
  late List<String> _selectedTags;
  late bool _isCompleted;
  
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedDueDate = widget.task.dueDate;
    _selectedRecurrence = widget.task.recurrence;
    _selectedTags = List.from(widget.task.tags);
    _isCompleted = widget.task.isCompleted;
    
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _hasChanges ? _saveChanges : null,
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Task'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompletionStatus(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildDueDateField(),
              const SizedBox(height: 16),
              _buildRecurrenceField(),
              const SizedBox(height: 16),
              _buildTagsField(),
              const SizedBox(height: 24),
              _buildMetadataSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _isCompleted ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCompleted ? 'Completed' : 'Pending',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isCompleted)
                    Text(
                      'Completed on ${_formatDate(widget.task.updatedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (_isEditing && !_isCompleted)
              ElevatedButton.icon(
                onPressed: _markAsCompleted,
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      enabled: _isEditing,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      enabled: _isEditing,
      maxLines: 4,
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      onTap: _isEditing ? _selectDueDate : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date',
          border: const OutlineInputBorder(),
          suffixIcon: _isEditing 
              ? const Icon(Icons.calendar_today)
              : null,
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
      onChanged: _isEditing ? (value) {
        if (value != null) {
          setState(() {
            _selectedRecurrence = value;
            _hasChanges = true;
          });
        }
      } : null,
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
              onSelected: _isEditing ? (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                  _hasChanges = true;
                });
              } : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Created', _formatDate(widget.task.createdAt)),
            _buildMetadataRow('Last Updated', _formatDate(widget.task.updatedAt)),
            _buildMetadataRow('Created By', widget.task.createdBy),
            if (widget.task.assignedTo != null)
              _buildMetadataRow('Assigned To', widget.task.assignedTo!),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
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
        initialTime: _selectedDueDate != null 
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
      );
      
      setState(() {
        _selectedDueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
        _hasChanges = true;
      });
    }
  }

  void _markAsCompleted() {
    setState(() {
      _isCompleted = true;
      _hasChanges = true;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = UpdateTaskRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        recurrence: _selectedRecurrence,
        dueDate: _selectedDueDate,
        isCompleted: _isCompleted,
        tags: _selectedTags,
      );
      
      widget.onUpdateTask(widget.task.id, request);
      
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
      _initializeFields();
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteTask(widget.task.id);
              context.pop(); // Go back to tasks list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
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
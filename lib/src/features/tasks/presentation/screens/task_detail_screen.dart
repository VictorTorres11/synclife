import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/main_layout.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_recurrence.dart';
import '../../domain/models/update_task_request.dart';
import '../providers/task_providers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.task,
  });

  final String taskId;
  final Task? task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // Always fetch the latest task data to ensure real-time updates
    final taskAsync = ref.watch(taskProvider(widget.taskId));

    return taskAsync.when(
      data: (task) {
        if (task == null) {
          return MainLayout(
            title: 'Tarefa não encontrada',
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tarefa não encontrada',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/tasks'),
                    child: const Text('Voltar para Tarefas'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildTaskDetail(task);
      },
      loading: () => const MainLayout(
        title: 'Carregando...',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => MainLayout(
        title: 'Erro',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text('Erro ao carregar tarefa: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/tasks'),
                child: const Text('Voltar para Tarefas'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(Task task) {
    return MainLayout(
      title: task.title,
      actions: [
        IconButton(
          onPressed: () => _showEditTaskDialog(task),
          icon: const Icon(Icons.edit),
          tooltip: 'Editar Tarefa',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: task.isCompleted ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (task.description != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  task.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (task.isCompleted) ...[
                          ElevatedButton.icon(
                            onPressed: () => _markAsIncomplete(task),
                            icon: const Icon(Icons.undo),
                            label: const Text('Marcar como Pendente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => _completeTask(task),
                            icon: const Icon(Icons.check),
                            label: const Text('Marcar como Concluída'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                        OutlinedButton.icon(
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete),
                          label: const Text('Excluir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Task details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes da Tarefa',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Due date
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Data de Vencimento',
                      value: task.dueDate != null
                          ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                          : 'Não definida',
                    ),

                    // Recurrence
                    _buildDetailRow(
                      icon: Icons.repeat,
                      label: 'Recorrência',
                      value: _getRecurrenceLabel(task.recurrence),
                    ),

                    // Tags
                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.label, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tags',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: task.tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Created date
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Criada em',
                      value: '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year} às ${task.createdAt.hour}:${task.createdAt.minute.toString().padLeft(2, '0')}',
                    ),

                    // Updated date
                    if (task.updatedAt != task.createdAt) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.update,
                        label: 'Atualizada em',
                        value: '${task.updatedAt.day}/${task.updatedAt.month}/${task.updatedAt.year} às ${task.updatedAt.hour}:${task.updatedAt.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRecurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'Nenhuma';
      case TaskRecurrence.daily:
        return 'Diária';
      case TaskRecurrence.weekly:
        return 'Semanal';
      case TaskRecurrence.monthly:
        return 'Mensal';
      case TaskRecurrence.custom:
        return 'Personalizada';
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.completeTask(task.id);

      // Invalidate providers to trigger real-time updates
      ref.invalidate(taskProvider(task.id));
      ref.invalidate(tasksProvider(task.boardId));
      ref.invalidate(watchTasksProvider(task.boardId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarefa "${task.title}" concluída! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao concluir tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditTaskDialog(Task task) async {
    final result = await showDialog<UpdateTaskRequest>(
      context: context,
      builder: (context) => _EditTaskDialog(task: task),
    );

    if (result != null) {
      try {
        final taskService = ref.read(taskServiceProvider);
        await taskService.updateTask(task.id, result);

        // Invalidate providers to trigger real-time updates
        ref.invalidate(taskProvider(task.id));
        ref.invalidate(tasksProvider(task.boardId));
        ref.invalidate(watchTasksProvider(task.boardId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tarefa "${task.title}" atualizada com sucesso! ✏️'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar tarefa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsIncomplete(Task task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Pendente'),
        content: Text(
          'Deseja marcar a tarefa "${task.title}" como pendente novamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateTask(
        task.id,
        const UpdateTaskRequest(isCompleted: false),
      );

      // Invalidate providers to trigger real-time updates
      ref.invalidate(taskProvider(task.id));
      ref.invalidate(tasksProvider(task.boardId));
      ref.invalidate(watchTasksProvider(task.boardId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarefa "${task.title}" marcada como pendente'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: Text(
          'Tem certeza que deseja excluir a tarefa "${task.title}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.deleteTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarefa "${task.title}" excluída'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate back to tasks page
        context.go('/tasks');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for editing task details
class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({required this.task});

  final Task task;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TaskRecurrence _selectedRecurrence = TaskRecurrence.none;
  List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Health',
    'Work',
    'Home',
    'Finance',
    'Personal',
    'Urgent',
    'Important',
    'Meeting',
    'Shopping',
    'Exercise'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedDate = widget.task.dueDate;
    _selectedRecurrence = widget.task.recurrence;
    _selectedTags = List.from(widget.task.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Tarefa'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da Tarefa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira um título para a tarefa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Due date picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_selectedDate == null
                        ? 'Sem data de vencimento'
                        : 'Vence em: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _selectDate,
                          tooltip: 'Alterar data',
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _selectedDate = null),
                            tooltip: 'Remover data',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Recurrence dropdown
                DropdownButtonFormField<TaskRecurrence>(
                  value: _selectedRecurrence,
                  decoration: const InputDecoration(
                    labelText: 'Recorrência',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskRecurrence.values.map((recurrence) {
                    return DropdownMenuItem(
                      value: recurrence,
                      child: Text(_getRecurrenceLabel(recurrence)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRecurrence = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Tags selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tags:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableTags.map((tag) {
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
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Salvar Alterações'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String _getRecurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'Nenhuma';
      case TaskRecurrence.daily:
        return 'Diária';
      case TaskRecurrence.weekly:
        return 'Semanal';
      case TaskRecurrence.monthly:
        return 'Mensal';
      case TaskRecurrence.custom:
        return 'Personalizada';
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdateTaskRequest(
      title: _titleController.text.trim() != widget.task.title 
          ? _titleController.text.trim() 
          : null,
      description: _descriptionController.text.trim() != (widget.task.description ?? '')
          ? (_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim())
          : null,
      dueDate: _datesEqual(_selectedDate, widget.task.dueDate) ? null : _selectedDate,
      recurrence: _selectedRecurrence != widget.task.recurrence ? _selectedRecurrence : null,
      tags: !_listsEqual(_selectedTags, widget.task.tags) ? _selectedTags : null,
    );

    // Only proceed if there are actual changes
    if (request.title != null || 
        request.description != null || 
        request.dueDate != null || 
        request.recurrence != null || 
        request.tags != null) {
      Navigator.of(context).pop(request);
    } else {
      // No changes made
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma alteração foi feita'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  bool _datesEqual(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return true;
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    for (int i = 0; i < list2.length; i++) {
      if (!list1.contains(list2[i])) return false;
    }
    return true;
  }
}
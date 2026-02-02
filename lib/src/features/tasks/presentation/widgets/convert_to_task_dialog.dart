import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/convert_inbox_to_task_request.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/models/task_recurrence.dart';
import '../providers/board_providers.dart';

class ConvertToTaskDialog extends ConsumerStatefulWidget {
  const ConvertToTaskDialog({
    super.key,
    required this.inboxItem,
    required this.onConvert,
  });

  final InboxItem inboxItem;
  final Function(ConvertInboxToTaskRequest) onConvert;

  @override
  ConsumerState<ConvertToTaskDialog> createState() => _ConvertToTaskDialogState();
}

class _ConvertToTaskDialogState extends ConsumerState<ConvertToTaskDialog> {
  Board? _selectedBoard;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  DateTime? _dueDate;
  final _tagsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBoardsAsync = ref.watch(userBoardsProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.task_alt,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Converter em Tarefa'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview of the note content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conteúdo da Anotação:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.inboxItem.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Board selection
            Text(
              'Selecionar Quadro *',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            userBoardsAsync.when(
              data: (boards) {
                if (boards.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Você precisa criar um quadro primeiro para converter anotações em tarefas.',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<Board>(
                  value: _selectedBoard,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Escolha um quadro...',
                    prefixIcon: const Icon(Icons.dashboard),
                  ),
                  items: boards.map((board) {
                    return DropdownMenuItem<Board>(
                      value: board,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getBoardColor(board),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              board.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (board.description?.isNotEmpty == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (board) {
                    setState(() {
                      _selectedBoard = board;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor, selecione um quadro';
                    }
                    return null;
                  },
                );
              },
              loading: () => Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Erro ao carregar quadros: $error',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recurrence selection
            Text(
              'Recorrência',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskRecurrence>(
              value: _recurrence,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: TaskRecurrence.values.map((recurrence) {
                return DropdownMenuItem<TaskRecurrence>(
                  value: recurrence,
                  child: Text(_getRecurrenceLabel(recurrence)),
                );
              }).toList(),
              onChanged: (recurrence) {
                setState(() {
                  _recurrence = recurrence ?? TaskRecurrence.none;
                });
              },
            ),

            const SizedBox(height: 16),

            // Due date selection
            Text(
              'Data de Vencimento',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? _formatDate(_dueDate!)
                          : 'Selecionar data (opcional)',
                      style: TextStyle(
                        color: _dueDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags input
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Digite tags separadas por vírgula (opcional)',
                prefixIcon: const Icon(Icons.tag),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedBoard == null ? null : _convertToTask,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Converter'),
        ),
      ],
    );
  }

  Color _getBoardColor(Board board) {
    // Generate a consistent color based on board ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[board.id.hashCode % colors.length];
  }

  String _getRecurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'Sem recorrência';
      case TaskRecurrence.daily:
        return 'Diariamente';
      case TaskRecurrence.weekly:
        return 'Semanalmente';
      case TaskRecurrence.monthly:
        return 'Mensalmente';
      case TaskRecurrence.custom:
        return 'Personalizada';
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _convertToTask() async {
    if (_selectedBoard == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final request = ConvertInboxToTaskRequest(
        inboxItemId: widget.inboxItem.id,
        boardId: _selectedBoard!.id,
        recurrence: _recurrence,
        dueDate: _dueDate,
        tags: tags,
      );

      widget.onConvert(request);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anotação convertida em tarefa no quadro "${_selectedBoard!.name}"',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erro ao converter: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
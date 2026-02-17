import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/tasks/domain/models/board.dart';
import '../../../../features/tasks/presentation/providers/board_providers.dart';
import '../../domain/models/models.dart';
import '../providers/reminder_providers.dart';

/// Dialog for converting a reminder to a task
/// 
/// This dialog allows users to convert a lightweight reminder into a full task.
/// It displays a preview of the reminder content and allows the user to select
/// the destination board for the new task.
class ConvertReminderDialog extends ConsumerStatefulWidget {
  const ConvertReminderDialog({
    super.key,
    required this.reminder,
  });

  /// The reminder to be converted
  final Reminder reminder;

  @override
  ConsumerState<ConvertReminderDialog> createState() =>
      _ConvertReminderDialogState();
}

/// State for ConvertReminderDialog
class _ConvertReminderDialogState extends ConsumerState<ConvertReminderDialog> {
  /// The board selected for the new task
  Board? _selectedBoard;
  
  /// Loading state during conversion
  bool _isLoading = false;

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
            // Reminder preview section
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
                  // Preview header
                  Row(
                    children: [
                      Text(
                        'Lembrete:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority indicator
                      _buildPriorityIndicator(theme),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Content
                  Text(
                    widget.reminder.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Tags (if any)
                  if (widget.reminder.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.reminder.tags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: theme.textTheme.labelSmall,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Confirmation message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O lembrete será convertido em uma tarefa e removido da lista de lembretes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
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
                // Set default board if not already set
                if (_selectedBoard == null && boards.isNotEmpty) {
                  // Try to find the reminder's current board
                  final reminderBoard = boards.firstWhere(
                    (board) => board.id == widget.reminder.boardId,
                    orElse: () => boards.first,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedBoard = reminderBoard;
                      });
                    }
                  });
                }

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
                            'Você precisa criar um quadro primeiro para converter lembretes em tarefas.',
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
                  initialValue: _selectedBoard,
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
                          if (board.id == widget.reminder.boardId) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (board) {
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
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        // Convert button
        ElevatedButton(
          onPressed: _isLoading || _selectedBoard == null
              ? null
              : _convertToTask,
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

  /// Build priority indicator widget
  Widget _buildPriorityIndicator(ThemeData theme) {
    final priorityConfig = _getPriorityConfig(widget.reminder.priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: priorityConfig['color'].withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityConfig['icon'],
            size: 14,
            color: priorityConfig['color'],
          ),
          const SizedBox(width: 4),
          Text(
            priorityConfig['label'],
            style: theme.textTheme.labelSmall?.copyWith(
              color: priorityConfig['color'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get priority configuration (color, icon, label)
  Map<String, dynamic> _getPriorityConfig(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return {
          'color': Colors.red,
          'icon': Icons.priority_high,
          'label': 'Alta',
        };
      case ReminderPriority.medium:
        return {
          'color': Colors.orange,
          'icon': Icons.remove,
          'label': 'Média',
        };
      case ReminderPriority.low:
        return {
          'color': Colors.green,
          'icon': Icons.arrow_downward,
          'label': 'Baixa',
        };
    }
  }

  /// Generate a consistent color based on board ID
  Color _getBoardColor(Board board) {
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

  /// Handle the conversion process
  Future<void> _convertToTask() async {
    if (_selectedBoard == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the conversion service
      final conversionService = ref.read(reminderConversionServiceProvider);

      // Convert the reminder to a task
      await conversionService.convertToTask(
        reminder: widget.reminder,
        targetBoardId: _selectedBoard!.id,
      );

      if (mounted) {
        // Close the dialog
        Navigator.of(context).pop(true); // Return true to indicate success

        // Show success message with navigation option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lembrete convertido em tarefa no quadro "${_selectedBoard!.name}"',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver Tarefa',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to task detail (optional - can be implemented later)
                // For now, we'll just close the snackbar
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
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
            duration: const Duration(seconds: 4),
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

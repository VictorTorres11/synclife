import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/monetization/presentation/widgets/upgrade_prompt_dialog.dart';
import '../../../../features/tasks/domain/models/board.dart';
import '../../../../features/tasks/presentation/providers/board_providers.dart';
import '../../domain/exceptions/reminder_exceptions.dart';
import '../../domain/models/reminder_priority.dart';
import '../providers/reminder_providers.dart';

/// Dialog for creating a new reminder
/// 
/// This dialog allows users to create reminders with:
/// - Content (required, max 500 chars)
/// - Board selection (required)
/// - Priority (optional, default: medium)
/// - Tags (optional)
/// 
/// The dialog checks user limitations before creating the reminder
/// and shows an upgrade prompt if the limit is reached.
class AddReminderDialog extends ConsumerStatefulWidget {
  const AddReminderDialog({
    super.key,
    this.selectedBoardId,
  });

  /// Optional pre-selected board ID
  final String? selectedBoardId;

  @override
  ConsumerState<AddReminderDialog> createState() => _AddReminderDialogState();
}

/// State for AddReminderDialog
class _AddReminderDialogState extends ConsumerState<AddReminderDialog> {
  /// Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  /// Controller for reminder content input
  final _contentController = TextEditingController();
  
  /// Controller for tag input field
  final _tagController = TextEditingController();
  
  /// Currently selected board ID
  String? _selectedBoardId;
  
  /// Currently selected priority level
  ReminderPriority _selectedPriority = ReminderPriority.medium;
  
  /// List of tags added to the reminder
  final List<String> _selectedTags = [];
  
  /// Loading state during reminder creation
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBoardId = widget.selectedBoardId;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBoardsAsync = ref.watch(userBoardsProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: userBoardsAsync.when(
                data: (boards) => _buildForm(context, boards),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildError(context, error),
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lightbulb_outline, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Novo Lembrete',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Semantics(
          label: 'Close dialog',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            tooltip: 'Fechar',
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, List<Board> boards) {
    // Set default board if not already set
    if (_selectedBoardId == null && boards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedBoardId = boards.first.id;
          });
        }
      });
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContentField(),
            const SizedBox(height: 16),
            _buildBoardSelectionField(boards),
            const SizedBox(height: 16),
            _buildPriorityField(),
            const SizedBox(height: 16),
            _buildTagsField(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Conteúdo *',
        hintText: 'Digite o conteúdo do lembrete...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        helperText: 'Máximo 500 caracteres',
      ),
      maxLines: 3,
      maxLength: 500,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'O conteúdo é obrigatório';
        }
        if (value.trim().length > 500) {
          return 'O conteúdo deve ter no máximo 500 caracteres';
        }
        return null;
      },
      autofocus: true,
    );
  }

  Widget _buildBoardSelectionField(List<Board> boards) {
    if (boards.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Você precisa criar um quadro antes de adicionar lembretes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedBoardId,
      decoration: const InputDecoration(
        labelText: 'Quadro *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.dashboard),
        helperText: 'Selecione o quadro para organizar este lembrete',
      ),
      items: boards.map((board) {
        return DropdownMenuItem(
          value: board.id,
          child: Row(
            children: [
              Icon(
                board.type.name == 'shared' ? Icons.group : Icons.lock,
                size: 16,
                color: board.type.name == 'shared' ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  board.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedBoardId = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, selecione um quadro';
        }
        return null;
      },
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioridade',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ReminderPriority>(
          segments: [
            ButtonSegment<ReminderPriority>(
              value: ReminderPriority.low,
              label: const Text('Baixa'),
              icon: Icon(
                Icons.arrow_downward,
                color: _selectedPriority == ReminderPriority.low
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
            ButtonSegment<ReminderPriority>(
              value: ReminderPriority.medium,
              label: const Text('Média'),
              icon: Icon(
                Icons.remove,
                color: _selectedPriority == ReminderPriority.medium
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
            ButtonSegment<ReminderPriority>(
              value: ReminderPriority.high,
              label: const Text('Alta'),
              icon: Icon(
                Icons.arrow_upward,
                color: _selectedPriority == ReminderPriority.high
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ],
          selected: {_selectedPriority},
          onSelectionChanged: _isLoading
              ? null
              : (Set<ReminderPriority> newSelection) {
                  setState(() {
                    _selectedPriority = newSelection.first;
                  });
                },
        ),
      ],
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Digite uma tag e pressione Enter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                enabled: !_isLoading,
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Add tag',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _isLoading ? null : () => _addTag(_tagController.text),
                tooltip: 'Adicionar tag',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ),
          ],
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                      },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar quadros',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _createReminder,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar Lembrete'),
        ),
      ],
    );
  }

  /// Adds a tag to the selected tags list
  /// 
  /// Trims whitespace and prevents duplicate tags.
  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_selectedTags.contains(trimmedTag)) {
      setState(() {
        _selectedTags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  Future<void> _createReminder() async {
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check if board is selected
    if (_selectedBoardId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione um quadro'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get current user
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderService = ref.read(reminderServiceProvider);
      
      await reminderService.createReminder(
        content: _contentController.text.trim(),
        userId: currentUser.id,
        boardId: _selectedBoardId!,
        tags: _selectedTags,
        priority: _selectedPriority,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembrete criado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on LimitExceededException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show upgrade prompt
        await UpgradePromptDialog.show(
          context,
          feature: 'Lembretes Ilimitados',
          description: 'Você atingiu o limite de ${e.maxCount} lembretes do plano gratuito.',
          benefits: const [
            'Lembretes ilimitados',
            'Tarefas ilimitadas',
            'Quadros ilimitados',
            'Membros ilimitados por quadro',
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar lembrete: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

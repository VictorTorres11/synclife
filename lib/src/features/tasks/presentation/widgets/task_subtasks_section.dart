import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/create_subtask_request.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TaskSubtasksSection extends ConsumerStatefulWidget {
  const TaskSubtasksSection({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<TaskSubtasksSection> createState() => _TaskSubtasksSectionState();
}

class _TaskSubtasksSectionState extends ConsumerState<TaskSubtasksSection> {
  final TextEditingController _subtaskController = TextEditingController();
  bool _isAddingSubtask = false;

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtarefas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isAddingSubtask = !_isAddingSubtask),
                  icon: Icon(_isAddingSubtask ? Icons.close : Icons.add),
                ),
              ],
            ),
            if (_isAddingSubtask) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Nova subtarefa...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubtask,
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // TODO: Implementar lista de subtarefas
            const Text('Lista de subtarefas será implementada aqui'),
          ],
        ),
      ),
    );
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // TODO: Implementar adição de subtarefa
    final request = CreateSubtaskRequest(
      taskId: widget.taskId,
      title: _subtaskController.text.trim(),
      description: '',
      createdBy: user.uid,
    );

    // TODO: Usar o request para criar a subtarefa
    print('Creating subtask: ${request.title}');

    _subtaskController.clear();
    setState(() => _isAddingSubtask = false);
  }
}
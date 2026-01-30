import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_type.dart';
import '../../domain/models/create_board_request.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Dialog for creating or editing a board
class CreateBoardDialog extends ConsumerStatefulWidget {
  const CreateBoardDialog({
    super.key,
    required this.onCreateBoard,
    this.boardToEdit,
  });

  final Function(CreateBoardRequest) onCreateBoard;
  final Board? boardToEdit;

  @override
  ConsumerState<CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends ConsumerState<CreateBoardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  BoardType _selectedType = BoardType.private;
  bool _isLoading = false;

  bool get _isEditing => widget.boardToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final board = widget.boardToEdit!;
      _nameController.text = board.name;
      _descriptionController.text = board.description ?? '';
      _selectedType = board.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Quadro' : 'Criar Novo Quadro'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Quadro',
                hintText: 'Digite o nome do quadro',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome do quadro é obrigatório';
                }
                if (value.trim().length < 2) {
                  return 'Nome deve ter pelo menos 2 caracteres';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (Opcional)',
                hintText: 'Digite a descrição do quadro',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo do Quadro',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<BoardType>(
                  title: const Text('Privado'),
                  subtitle: const Text('Apenas você pode ver e gerenciar este quadro'),
                  value: BoardType.private,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<BoardType>(
                  title: const Text('Compartilhado'),
                  subtitle: const Text('Convide outros para colaborar neste quadro'),
                  value: BoardType.shared,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
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
          onPressed: _isLoading ? null : _createBoard,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  Future<void> _createBoard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final request = CreateBoardRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        ownerId: currentUser.uid,
      );

      await widget.onCreateBoard(request);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Falha ao atualizar quadro: $e'
                : 'Falha ao criar quadro: $e'),
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
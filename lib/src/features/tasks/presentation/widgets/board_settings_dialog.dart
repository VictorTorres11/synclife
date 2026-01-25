import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/board.dart';
import '../../domain/models/board_settings.dart';
import '../providers/board_providers.dart';

/// Dialog for managing board settings and permissions
class BoardSettingsDialog extends ConsumerStatefulWidget {
  const BoardSettingsDialog({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  ConsumerState<BoardSettingsDialog> createState() =>
      _BoardSettingsDialogState();
}

class _BoardSettingsDialogState extends ConsumerState<BoardSettingsDialog> {
  late BoardSettings _settings;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.board.settings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Configurações - ${widget.board.name}'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // General Settings
              _buildSectionHeader('Configurações Gerais'),
              _buildSettingTile(
                title: 'Permitir comentários',
                subtitle: 'Membros podem comentar em tarefas',
                value: _settings.allowComments,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(allowComments: value);
                }),
              ),

              _buildSettingTile(
                title: 'Notificações de atividade',
                subtitle:
                    'Receber notificações quando membros completam tarefas',
                value: _settings.enableNotifications,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(enableNotifications: value);
                }),
              ),

              _buildSettingTile(
                title: 'Sincronização automática',
                subtitle: 'Sincronizar mudanças automaticamente',
                value: _settings.autoSync,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(autoSync: value);
                }),
              ),

              const SizedBox(height: 16),

              // Privacy Settings
              _buildSectionHeader('Privacidade'),
              _buildSettingTile(
                title: 'Quadro público',
                subtitle: 'Permitir que outros encontrem este quadro',
                value: _settings.isPublic,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(isPublic: value);
                }),
              ),

              _buildSettingTile(
                title: 'Permitir convites',
                subtitle: 'Membros podem convidar outros usuários',
                value: _settings.allowInvites,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(allowInvites: value);
                }),
              ),

              const SizedBox(height: 16),

              // Task Settings
              _buildSectionHeader('Configurações de Tarefas'),
              _buildSettingTile(
                title: 'Tarefas recorrentes',
                subtitle: 'Permitir criação de tarefas recorrentes',
                value: _settings.allowRecurringTasks,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(allowRecurringTasks: value);
                }),
              ),

              _buildSettingTile(
                title: 'Atribuição de tarefas',
                subtitle: 'Permitir atribuir tarefas a membros específicos',
                value: _settings.allowTaskAssignment,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(allowTaskAssignment: value);
                }),
              ),

              const SizedBox(height: 16),

              // Gamification Settings
              _buildSectionHeader('Gamificação'),
              _buildSettingTile(
                title: 'Sistema de XP',
                subtitle: 'Ganhar pontos de experiência por completar tarefas',
                value: _settings.enableXP,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(enableXP: value);
                }),
              ),

              _buildSettingTile(
                title: 'Streaks coletivos',
                subtitle:
                    'Contar streaks apenas quando todos os membros completam tarefas',
                value: _settings.enableCollectiveStreaks,
                onChanged: (value) => _updateSetting(() {
                  _settings =
                      _settings.copyWith(enableCollectiveStreaks: value);
                }),
              ),

              _buildSettingTile(
                title: 'Leaderboard',
                subtitle: 'Mostrar ranking de membros por XP',
                value: _settings.showLeaderboard,
                onChanged: (value) => _updateSetting(() {
                  _settings = _settings.copyWith(showLeaderboard: value);
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _hasChanges && !_isSaving ? _saveSettings : null,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _updateSetting(VoidCallback update) {
    setState(() {
      update();
      _hasChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final boardService = ref.read(boardServiceProvider);
      await boardService.updateBoard(widget.board.id, {
        'settings': _settings.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

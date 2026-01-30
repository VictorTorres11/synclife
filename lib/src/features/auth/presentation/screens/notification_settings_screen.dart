import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _taskReminders = true;
  bool _boardUpdates = true;
  bool _achievementNotifications = true;
  bool _weeklyDigest = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Configurações de Notificação',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Notifications
            _buildSectionCard(
              'Notificações Gerais',
              [
                _buildSwitchTile(
                  'Notificações Push',
                  'Receber notificações no dispositivo',
                  Icons.notifications,
                  _pushNotifications,
                  (value) => setState(() => _pushNotifications = value),
                ),
                _buildSwitchTile(
                  'Notificações por Email',
                  'Receber notificações por email',
                  Icons.email,
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Task Notifications
            _buildSectionCard(
              'Notificações de Tarefas',
              [
                _buildSwitchTile(
                  'Lembretes de Tarefas',
                  'Notificações sobre prazos de tarefas',
                  Icons.task_alt,
                  _taskReminders,
                  (value) => setState(() => _taskReminders = value),
                ),
                _buildSwitchTile(
                  'Atualizações de Quadros',
                  'Notificações sobre mudanças nos quadros',
                  Icons.dashboard,
                  _boardUpdates,
                  (value) => setState(() => _boardUpdates = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Gamification Notifications
            _buildSectionCard(
              'Gamificação',
              [
                _buildSwitchTile(
                  'Conquistas',
                  'Notificações sobre novas conquistas',
                  Icons.emoji_events,
                  _achievementNotifications,
                  (value) => setState(() => _achievementNotifications = value),
                ),
                _buildSwitchTile(
                  'Resumo Semanal',
                  'Receber resumo semanal de atividades',
                  Icons.calendar_view_week,
                  _weeklyDigest,
                  (value) => setState(() => _weeklyDigest = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sound & Vibration
            _buildSectionCard(
              'Som e Vibração',
              [
                _buildSwitchTile(
                  'Som',
                  'Reproduzir som nas notificações',
                  Icons.volume_up,
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                ),
                _buildSwitchTile(
                  'Vibração',
                  'Vibrar ao receber notificações',
                  Icons.vibration,
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Salvar Configurações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  void _saveSettings() {
    // In a real implementation, save settings to backend/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de notificação salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
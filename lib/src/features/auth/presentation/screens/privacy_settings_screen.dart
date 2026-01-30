import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';

/// Screen for managing privacy and data settings
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _profileVisibility = true;
  bool _activityTracking = false;
  bool _dataCollection = true;
  bool _analyticsOptIn = false;
  bool _marketingEmails = false;
  bool _shareWithPartners = false;
  bool _locationTracking = false;
  bool _crashReporting = true;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Privacidade',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Privacy
            _buildSectionCard(
              'Privacidade do Perfil',
              [
                _buildSwitchTile(
                  'Perfil Público',
                  'Permitir que outros usuários vejam seu perfil',
                  Icons.visibility,
                  _profileVisibility,
                  (value) => setState(() => _profileVisibility = value),
                ),
                _buildSwitchTile(
                  'Rastreamento de Atividade',
                  'Permitir rastreamento de atividades no app',
                  Icons.track_changes,
                  _activityTracking,
                  (value) => setState(() => _activityTracking = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data Collection
            _buildSectionCard(
              'Coleta de Dados',
              [
                _buildSwitchTile(
                  'Coleta de Dados de Uso',
                  'Permitir coleta de dados para melhorar o app',
                  Icons.data_usage,
                  _dataCollection,
                  (value) => setState(() => _dataCollection = value),
                ),
                _buildSwitchTile(
                  'Analytics',
                  'Compartilhar dados analíticos anônimos',
                  Icons.analytics,
                  _analyticsOptIn,
                  (value) => setState(() => _analyticsOptIn = value),
                ),
                _buildSwitchTile(
                  'Relatórios de Erro',
                  'Enviar relatórios de erro automaticamente',
                  Icons.bug_report,
                  _crashReporting,
                  (value) => setState(() => _crashReporting = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Marketing & Communications
            _buildSectionCard(
              'Marketing e Comunicações',
              [
                _buildSwitchTile(
                  'Emails de Marketing',
                  'Receber emails promocionais e novidades',
                  Icons.email,
                  _marketingEmails,
                  (value) => setState(() => _marketingEmails = value),
                ),
                _buildSwitchTile(
                  'Compartilhar com Parceiros',
                  'Permitir compartilhamento de dados com parceiros',
                  Icons.share,
                  _shareWithPartners,
                  (value) => setState(() => _shareWithPartners = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Location & Tracking
            _buildSectionCard(
              'Localização e Rastreamento',
              [
                _buildSwitchTile(
                  'Rastreamento de Localização',
                  'Permitir acesso à sua localização',
                  Icons.location_on,
                  _locationTracking,
                  (value) => setState(() => _locationTracking = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Management Actions
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Gerenciamento de Dados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Baixar Meus Dados'),
                    subtitle: const Text('Solicitar uma cópia dos seus dados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _requestDataDownload,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('Limpar Dados de Uso'),
                    subtitle: const Text('Remover dados de atividade coletados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _clearUsageData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.policy),
                    title: const Text('Política de Privacidade'),
                    subtitle: const Text('Ler nossa política de privacidade'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPrivacyPolicy,
                  ),
                ],
              ),
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

  void _requestDataDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Baixar Meus Dados'),
        content: const Text(
          'Sua solicitação de download de dados foi enviada. '
          'Você receberá um email com o link para download em até 48 horas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearUsageData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Dados de Uso'),
        content: const Text(
          'Tem certeza que deseja limpar todos os dados de uso coletados? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados de uso limpos com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidade'),
        content: const SingleChildScrollView(
          child: Text(
            'Esta é uma versão resumida da nossa política de privacidade.\n\n'
            '1. Coletamos apenas os dados necessários para o funcionamento do app.\n'
            '2. Seus dados pessoais são protegidos com criptografia.\n'
            '3. Não vendemos seus dados para terceiros.\n'
            '4. Você pode solicitar a exclusão dos seus dados a qualquer momento.\n'
            '5. Usamos cookies apenas para melhorar sua experiência.\n\n'
            'Para a versão completa, visite nosso site.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // In a real implementation, save settings to backend/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de privacidade salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
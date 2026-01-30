import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';

/// Screen for managing language and region preferences
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'pt_BR';
  String _selectedRegion = 'BR';
  String _dateFormat = 'dd/MM/yyyy';
  String _timeFormat = '24h';
  String _currency = 'BRL';

  final Map<String, String> _languages = {
    'pt_BR': 'Português (Brasil)',
    'en_US': 'English (United States)',
    'es_ES': 'Español (España)',
    'fr_FR': 'Français (France)',
    'de_DE': 'Deutsch (Deutschland)',
    'it_IT': 'Italiano (Italia)',
  };

  final Map<String, String> _regions = {
    'BR': 'Brasil',
    'US': 'Estados Unidos',
    'ES': 'Espanha',
    'FR': 'França',
    'DE': 'Alemanha',
    'IT': 'Itália',
  };

  final Map<String, String> _dateFormats = {
    'dd/MM/yyyy': 'DD/MM/AAAA (31/12/2024)',
    'MM/dd/yyyy': 'MM/DD/AAAA (12/31/2024)',
    'yyyy-MM-dd': 'AAAA-MM-DD (2024-12-31)',
    'dd-MM-yyyy': 'DD-MM-AAAA (31-12-2024)',
  };

  final Map<String, String> _timeFormats = {
    '24h': '24 horas (14:30)',
    '12h': '12 horas (2:30 PM)',
  };

  final Map<String, String> _currencies = {
    'BRL': 'Real Brasileiro (R\$)',
    'USD': 'Dólar Americano (\$)',
    'EUR': 'Euro (€)',
    'GBP': 'Libra Esterlina (£)',
  };

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Idioma e Região',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection
            _buildSectionCard(
              'Idioma',
              [
                _buildDropdownTile(
                  'Idioma do Aplicativo',
                  'Selecione o idioma da interface',
                  Icons.language,
                  _selectedLanguage,
                  _languages,
                  (value) => setState(() => _selectedLanguage = value!),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Region Selection
            _buildSectionCard(
              'Região',
              [
                _buildDropdownTile(
                  'Região',
                  'Selecione sua região',
                  Icons.public,
                  _selectedRegion,
                  _regions,
                  (value) => setState(() => _selectedRegion = value!),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Format Settings
            _buildSectionCard(
              'Formatos',
              [
                _buildDropdownTile(
                  'Formato de Data',
                  'Como as datas serão exibidas',
                  Icons.calendar_today,
                  _dateFormat,
                  _dateFormats,
                  (value) => setState(() => _dateFormat = value!),
                ),
                _buildDropdownTile(
                  'Formato de Hora',
                  'Como os horários serão exibidos',
                  Icons.access_time,
                  _timeFormat,
                  _timeFormats,
                  (value) => setState(() => _timeFormat = value!),
                ),
                _buildDropdownTile(
                  'Moeda',
                  'Moeda padrão para valores',
                  Icons.attach_money,
                  _currency,
                  _currencies,
                  (value) => setState(() => _currency = value!),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Preview Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visualização',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewItem(
                      'Data:',
                      _formatDatePreview(),
                    ),
                    _buildPreviewItem(
                      'Hora:',
                      _formatTimePreview(),
                    ),
                    _buildPreviewItem(
                      'Moeda:',
                      _formatCurrencyPreview(),
                    ),
                  ],
                ),
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

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDatePreview() {
    final now = DateTime.now();
    switch (_dateFormat) {
      case 'dd/MM/yyyy':
        return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      case 'MM/dd/yyyy':
        return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      case 'yyyy-MM-dd':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'dd-MM-yyyy':
        return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      default:
        return '${now.day}/${now.month}/${now.year}';
    }
  }

  String _formatTimePreview() {
    final now = DateTime.now();
    if (_timeFormat == '12h') {
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      return '${hour}:${now.minute.toString().padLeft(2, '0')} $period';
    } else {
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatCurrencyPreview() {
    switch (_currency) {
      case 'BRL':
        return 'R\$ 123,45';
      case 'USD':
        return '\$ 123.45';
      case 'EUR':
        return '€ 123,45';
      case 'GBP':
        return '£ 123.45';
      default:
        return 'R\$ 123,45';
    }
  }

  void _saveSettings() {
    // In a real implementation, save settings to backend/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de idioma e região salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
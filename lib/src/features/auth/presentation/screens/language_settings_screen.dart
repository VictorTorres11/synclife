import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../domain/models/language_preferences.dart';
import '../providers/language_providers.dart';

/// Screen for managing language and region preferences
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(languagePreferencesNotifierProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final supportedRegions = ref.watch(supportedRegionsProvider);

    return MainLayout(
      title: 'Language & Region',
      actions: [
        IconButton(
          onPressed: () => _showResetDialog(context, ref),
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to defaults',
        ),
      ],
      child: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading preferences: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(languagePreferencesNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (preferences) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-detection toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Auto-detect language and region'),
                  subtitle: const Text('Use device settings automatically'),
                  value: preferences.isAutoDetected,
                  onChanged: (value) {
                    if (value) {
                      ref
                          .read(languagePreferencesNotifierProvider.notifier)
                          .enableAutoDetection();
                    }
                  },
                  secondary: const Icon(Icons.auto_awesome),
                ),
              ),

              const SizedBox(height: 24),

              // Language Selection
              _buildSectionHeader('Language'),
              Card(
                child: Column(
                  children: supportedLanguages.map((language) {
                    return RadioListTile<String>(
                      title: Text(language.displayName),
                      subtitle: Text('Code: ${language.code}'),
                      value: language.code,
                      groupValue: preferences.languageCode,
                      onChanged: preferences.isAutoDetected
                          ? null
                          : (value) {
                              if (value != null) {
                                ref
                                    .read(languagePreferencesNotifierProvider
                                        .notifier)
                                    .updateLanguage(value);
                              }
                            },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Region Selection
              _buildSectionHeader('Region'),
              Card(
                child: Column(
                  children: supportedRegions.map((region) {
                    return RadioListTile<String>(
                      title: Text(region.displayName),
                      subtitle: Text('Code: ${region.code}'),
                      value: region.code,
                      groupValue: preferences.countryCode,
                      onChanged: preferences.isAutoDetected
                          ? null
                          : (value) {
                              if (value != null) {
                                ref
                                    .read(languagePreferencesNotifierProvider
                                        .notifier)
                                    .updateRegion(value);
                              }
                            },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Format Settings
              _buildSectionHeader('Format Settings'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Date Format'),
                      subtitle: Text(preferences.dateFormat),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showDateFormatDialog(context, ref, preferences),
                      enabled: !preferences.isAutoDetected,
                    ),
                    ListTile(
                      title: const Text('Time Format'),
                      subtitle: Text(preferences.timeFormat),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showTimeFormatDialog(context, ref, preferences),
                      enabled: !preferences.isAutoDetected,
                    ),
                    ListTile(
                      title: const Text('Timezone'),
                      subtitle: Text(preferences.timezone),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showTimezoneDialog(context, ref, preferences),
                      enabled: !preferences.isAutoDetected,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Current Settings Summary
              _buildSectionHeader('Current Settings'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Language', preferences.languageCode),
                      _buildInfoRow('Region', preferences.countryCode),
                      _buildInfoRow('Timezone', preferences.timezone),
                      _buildInfoRow('Date Format', preferences.dateFormat),
                      _buildInfoRow('Time Format', preferences.timeFormat),
                      _buildInfoRow('Auto-detected',
                          preferences.isAutoDetected ? 'Yes' : 'No'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDateFormatDialog(
    BuildContext context,
    WidgetRef ref,
    LanguagePreferences preferences,
  ) {
    final formats = ['MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return RadioListTile<String>(
              title: Text(format),
              subtitle: Text('Example: ${_formatExample(format)}'),
              value: format,
              groupValue: preferences.dateFormat,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(languagePreferencesNotifierProvider.notifier)
                      .updateDateFormat(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimeFormatDialog(
    BuildContext context,
    WidgetRef ref,
    LanguagePreferences preferences,
  ) {
    final formats = ['12h', '24h'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return RadioListTile<String>(
              title: Text(format == '12h' ? '12-hour' : '24-hour'),
              subtitle:
                  Text(format == '12h' ? 'Example: 2:30 PM' : 'Example: 14:30'),
              value: format,
              groupValue: preferences.timeFormat,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(languagePreferencesNotifierProvider.notifier)
                      .updateTimeFormat(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimezoneDialog(
    BuildContext context,
    WidgetRef ref,
    LanguagePreferences preferences,
  ) {
    final timezones = [
      'UTC',
      'America/New_York',
      'America/Los_Angeles',
      'America/Sao_Paulo',
      'Europe/London',
      'Europe/Paris',
      'Asia/Tokyo',
      'Australia/Sydney',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timezone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: timezones.map((timezone) {
              return RadioListTile<String>(
                title: Text(timezone),
                value: timezone,
                groupValue: preferences.timezone,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(languagePreferencesNotifierProvider.notifier)
                        .updateTimezone(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all language and region settings to defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(languagePreferencesNotifierProvider.notifier)
                  .resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _formatExample(String format) {
    final now = DateTime.now();
    switch (format) {
      case 'MM/dd/yyyy':
        return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      case 'dd/MM/yyyy':
        return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      case 'yyyy-MM-dd':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'dd-MM-yyyy':
        return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      default:
        return format;
    }
  }
}

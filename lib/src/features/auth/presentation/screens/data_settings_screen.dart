import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';

/// Screen for managing data and storage settings
class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  // Data settings state
  bool _offlineStorageEnabled = true;
  bool _autoSyncEnabled = true;
  bool _wifiOnlySyncEnabled = false;
  bool _compressDataEnabled = true;
  bool _cacheImagesEnabled = true;
  String _cacheSize = '45.2 MB';
  String _offlineDataSize = '12.8 MB';
  String _totalAppSize = '58.0 MB';

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Data & Storage',
      actions: [
        IconButton(
          onPressed: () => _showStorageAnalysisDialog(context),
          icon: const Icon(Icons.analytics),
          tooltip: 'Storage Analysis',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Overview
            _buildSectionHeader('Storage Overview'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStorageRow(
                        'Total App Size', _totalAppSize, Colors.blue),
                    const SizedBox(height: 8),
                    _buildStorageRow('Cache Data', _cacheSize, Colors.orange),
                    const SizedBox(height: 8),
                    _buildStorageRow(
                        'Offline Data', _offlineDataSize, Colors.green),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _clearCache(context),
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Clear Cache'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _analyzeStorage(context),
                            icon: const Icon(Icons.analytics),
                            label: const Text('Analyze'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sync Settings
            _buildSectionHeader('Synchronization'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto Sync'),
                    subtitle: const Text('Automatically sync data when online'),
                    value: _autoSyncEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoSyncEnabled = value;
                      });
                      if (!value) {
                        _showAutoSyncWarningDialog(context);
                      }
                    },
                    secondary: const Icon(Icons.sync),
                  ),
                  SwitchListTile(
                    title: const Text('WiFi Only Sync'),
                    subtitle: const Text('Only sync when connected to WiFi'),
                    value: _wifiOnlySyncEnabled,
                    onChanged: _autoSyncEnabled
                        ? (value) {
                            setState(() {
                              _wifiOnlySyncEnabled = value;
                            });
                          }
                        : null,
                    secondary: const Icon(Icons.wifi),
                  ),
                  ListTile(
                    title: const Text('Sync Frequency'),
                    subtitle: const Text('How often to sync data'),
                    trailing: const Text('Real-time'),
                    onTap: () => _showSyncFrequencyDialog(context),
                    leading: const Icon(Icons.schedule),
                    enabled: _autoSyncEnabled,
                  ),
                  ListTile(
                    title: const Text('Manual Sync'),
                    subtitle: const Text('Sync data now'),
                    trailing: const Icon(Icons.sync),
                    onTap: () => _performManualSync(context),
                    leading: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Offline Settings
            _buildSectionHeader('Offline Storage'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Offline Storage'),
                    subtitle:
                        const Text('Store data locally for offline access'),
                    value: _offlineStorageEnabled,
                    onChanged: (value) {
                      setState(() {
                        _offlineStorageEnabled = value;
                      });
                      if (!value) {
                        _showOfflineWarningDialog(context);
                      }
                    },
                    secondary: const Icon(Icons.offline_bolt),
                  ),
                  ListTile(
                    title: const Text('Offline Data Limit'),
                    subtitle: const Text('Maximum offline storage size'),
                    trailing: const Text('100 MB'),
                    onTap: () => _showOfflineDataLimitDialog(context),
                    leading: const Icon(Icons.storage),
                    enabled: _offlineStorageEnabled,
                  ),
                  ListTile(
                    title: const Text('Clear Offline Data'),
                    subtitle: const Text('Remove all offline stored data'),
                    trailing: const Icon(Icons.delete),
                    onTap: () => _clearOfflineData(context),
                    leading: const Icon(Icons.delete_sweep),
                    enabled: _offlineStorageEnabled,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Performance Settings
            _buildSectionHeader('Performance'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Data Compression'),
                    subtitle: const Text('Compress data to save bandwidth'),
                    value: _compressDataEnabled,
                    onChanged: (value) {
                      setState(() {
                        _compressDataEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.compress),
                  ),
                  SwitchListTile(
                    title: const Text('Cache Images'),
                    subtitle: const Text('Cache profile images and avatars'),
                    value: _cacheImagesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _cacheImagesEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.image),
                  ),
                  ListTile(
                    title: const Text('Preload Data'),
                    subtitle: const Text('Preload frequently used data'),
                    trailing: const Text('Smart'),
                    onTap: () => _showPreloadSettingsDialog(context),
                    leading: const Icon(Icons.speed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Export/Import
            _buildSectionHeader('Data Management'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Export Data'),
                    subtitle: const Text('Download all your data'),
                    trailing: const Icon(Icons.download),
                    onTap: () => _exportData(context),
                    leading: const Icon(Icons.file_download),
                  ),
                  ListTile(
                    title: const Text('Import Data'),
                    subtitle: const Text('Import data from backup'),
                    trailing: const Icon(Icons.upload),
                    onTap: () => _importData(context),
                    leading: const Icon(Icons.file_upload),
                  ),
                  ListTile(
                    title: const Text('Backup Settings'),
                    subtitle: const Text('Configure automatic backups'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showBackupSettingsDialog(context),
                    leading: const Icon(Icons.backup),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildStorageRow(String label, String size, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          size,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including images and temporary files. '
          'The app may be slower until the cache is rebuilt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _cacheSize = '0.0 MB';
                _totalAppSize = '12.8 MB';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _analyzeStorage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Analysis'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage breakdown:'),
            SizedBox(height: 16),
            Text('• App binary: 8.5 MB'),
            Text('• User data: 4.3 MB'),
            Text('• Cache: 45.2 MB'),
            Text('  - Images: 32.1 MB'),
            Text('  - API responses: 8.7 MB'),
            Text('  - Other: 4.4 MB'),
            SizedBox(height: 16),
            Text('Recommendations:'),
            Text('• Clear image cache to save 32 MB'),
            Text('• Enable compression to reduce data usage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStorageAnalysisDialog(BuildContext context) {
    _analyzeStorage(context);
  }

  void _showAutoSyncWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Sync Disabled'),
        content: const Text(
          'Disabling auto sync means your data will not be automatically synchronized. '
          'You will need to manually sync to see updates from other devices or board members.',
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

  void _showOfflineWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Storage Disabled'),
        content: const Text(
          'Disabling offline storage means you will not be able to use the app without an internet connection. '
          'All data will need to be loaded from the server each time.',
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

  void _showSyncFrequencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Frequency'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how often to sync data:'),
            SizedBox(height: 16),
            Text('• Real-time: Instant updates (recommended)'),
            Text('• Every 5 minutes: Good balance'),
            Text('• Every 15 minutes: Battery saving'),
            Text('• Manual only: Maximum control'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _performManualSync(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Simulate sync completion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    });
  }

  void _showOfflineDataLimitDialog(BuildContext context) {
    final limits = ['50 MB', '100 MB', '200 MB', '500 MB', 'Unlimited'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Data Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: limits.map((limit) {
            return RadioListTile<String>(
              title: Text(limit),
              value: limit,
              groupValue: '100 MB',
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Offline limit set to $value')),
                );
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

  void _clearOfflineData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text(
          'This will remove all offline stored data. You will need an internet connection '
          'to access your tasks and boards until they are cached again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _offlineDataSize = '0.0 MB';
                _totalAppSize = '45.2 MB';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPreloadSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preload Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preload options:'),
            SizedBox(height: 16),
            Text('• Smart: Preload based on usage patterns'),
            Text('• All boards: Preload all board data'),
            Text('• Recent only: Preload recently accessed data'),
            Text('• None: No preloading'),
            SizedBox(height: 16),
            Text('Smart preloading is recommended for best performance.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your data will be exported as a JSON file and sent to your email address. '
          'This includes all tasks, boards, and settings but excludes sensitive information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Data export started. Check your email in a few minutes.'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _importData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Import data from a previously exported backup file. '
          'This will merge with your existing data, not replace it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File picker would open here')),
              );
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showBackupSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automatic backup options:'),
            SizedBox(height: 16),
            Text('• Daily: Backup every day at 2 AM'),
            Text('• Weekly: Backup every Sunday'),
            Text('• Monthly: Backup on the 1st of each month'),
            Text('• Manual only: No automatic backups'),
            SizedBox(height: 16),
            Text(
                'Backups are stored securely in the cloud and can be restored at any time.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

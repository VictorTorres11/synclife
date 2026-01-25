import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/advanced_backup.dart';
import '../providers/advanced_backup_providers.dart';

/// Widget for managing advanced backup features
class AdvancedBackupWidget extends ConsumerWidget {
  const AdvancedBackupWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(userBackupsProvider);
    final statisticsAsync = ref.watch(backupStatisticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Section
        statisticsAsync.when(
          data: (stats) => _buildStatisticsCard(context, stats),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Backup Configurations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Backup Configurations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateBackupDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Backup'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        backupsAsync.when(
          data: (backups) {
            if (backups.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildBackupsList(context, ref, backups);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(BuildContext context, BackupStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Backups',
                    stats.totalBackups.toString(),
                    Icons.backup,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Archives',
                    stats.totalArchives.toString(),
                    Icons.archive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Storage Used',
                    stats.formattedStorageUsed,
                    Icons.storage,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Success Rate',
                    '${stats.successRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            if (stats.nextScheduledBackup != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next backup: ${_formatDateTime(stats.nextScheduledBackup!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.backup_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No backup configurations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Create automated backups to keep your data safe.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList(
    BuildContext context,
    WidgetRef ref,
    List<AdvancedBackup> backups,
  ) {
    return Column(
      children: backups.map((backup) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: backup.isEnabled
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                _getBackupTypeIcon(backup.backupType),
                color: backup.isEnabled
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(backup.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${backup.backupType.name} • ${backup.frequency.name}'),
                if (backup.lastBackupAt != null)
                  Text(
                    'Last backup: ${_formatDateTime(backup.lastBackupAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (backup.frequency != BackupFrequency.manual)
                  Switch(
                    value: backup.isEnabled,
                    onChanged: (enabled) {
                      ref
                          .read(advancedBackupServiceProvider)
                          .toggleBackup(backup.id, enabled);
                    },
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'backup':
                        _performBackup(ref, backup.id);
                        break;
                      case 'archives':
                        _showArchives(context, ref, backup);
                        break;
                      case 'settings':
                        _showBackupSettings(context, ref, backup);
                        break;
                      case 'delete':
                        _deleteBackup(context, ref, backup);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'backup',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Run Now'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archives',
                      child: ListTile(
                        leading: Icon(Icons.archive),
                        title: Text('View Archives'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load backups',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  IconData _getBackupTypeIcon(BackupType type) {
    switch (type) {
      case BackupType.full:
        return Icons.backup;
      case BackupType.incremental:
        return Icons.update;
      case BackupType.differential:
        return Icons.compare_arrows;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showCreateBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup Configuration'),
        content: const Text(
            'This would open a form to create a new backup configuration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Create backup configuration
              ref.read(advancedBackupServiceProvider).createBackup(
                    userId: 'current_user_id',
                    name: 'Daily Backup',
                    backupType: BackupType.incremental,
                    frequency: BackupFrequency.daily,
                  );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _performBackup(WidgetRef ref, String backupId) {
    ref.read(advancedBackupServiceProvider).performBackup(backupId);
  }

  void _showArchives(
    BuildContext context,
    WidgetRef ref,
    AdvancedBackup backup,
  ) {
    // This would show a list of backup archives
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${backup.name} Archives'),
        content: const Text('This would show a list of backup archives.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBackupSettings(
    BuildContext context,
    WidgetRef ref,
    AdvancedBackup backup,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${backup.name} Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Include attachments'),
              value: backup.includeAttachments,
              onChanged: (value) {
                // Update settings
              },
            ),
            SwitchListTile(
              title: const Text('Enable encryption'),
              value: backup.encryptionEnabled,
              onChanged: (value) {
                // Update settings
              },
            ),
            ListTile(
              title: const Text('Retention period'),
              subtitle: Text('${backup.retentionDays} days'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Edit retention period
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Save settings
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBackup(
    BuildContext context,
    WidgetRef ref,
    AdvancedBackup backup,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup Configuration'),
        content: Text(
          'Are you sure you want to delete "${backup.name}"? This will also delete all associated backup archives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(advancedBackupServiceProvider).deleteBackup(backup.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_integration.dart';
import '../providers/calendar_integration_providers.dart';

/// Widget for managing calendar integrations
class CalendarIntegrationWidget extends ConsumerWidget {
  const CalendarIntegrationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationsAsync = ref.watch(userCalendarIntegrationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Connected Calendars',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddIntegrationDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Calendar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        integrationsAsync.when(
          data: (integrations) {
            if (integrations.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildIntegrationsList(context, ref, integrations);
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
            Icons.calendar_today_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No calendars connected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Connect your favorite calendar apps to sync tasks automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsList(
    BuildContext context,
    WidgetRef ref,
    List<CalendarIntegration> integrations,
  ) {
    return Column(
      children: integrations.map((integration) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getProviderIcon(integration.provider),
            title: Text(integration.accountName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(integration.provider.name.toUpperCase()),
                if (integration.lastSyncAt != null)
                  Text(
                    'Last sync: ${_formatDateTime(integration.lastSyncAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: integration.isEnabled,
                  onChanged: (enabled) {
                    ref
                        .read(calendarIntegrationServiceProvider)
                        .toggleIntegration(integration.id, enabled);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'sync':
                        _syncIntegration(ref, integration.id);
                        break;
                      case 'settings':
                        _showIntegrationSettings(context, ref, integration);
                        break;
                      case 'delete':
                        _deleteIntegration(context, ref, integration);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sync',
                      child: ListTile(
                        leading: Icon(Icons.sync),
                        title: Text('Sync Now'),
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
                        title: Text('Remove'),
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
            'Failed to load calendar integrations',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _getProviderIcon(CalendarProvider provider) {
    IconData iconData;
    Color? color;

    switch (provider) {
      case CalendarProvider.google:
        iconData = Icons.calendar_today;
        color = Colors.blue;
        break;
      case CalendarProvider.apple:
        iconData = Icons.calendar_month;
        color = Colors.grey[800];
        break;
      case CalendarProvider.outlook:
        iconData = Icons.calendar_view_month;
        color = Colors.blue[800];
        break;
      case CalendarProvider.caldav:
        iconData = Icons.cloud;
        color = Colors.grey[600];
        break;
    }

    return Icon(iconData, color: color);
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

  void _showAddIntegrationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Calendar Integration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CalendarProvider.values.map((provider) {
            return ListTile(
              leading: _getProviderIcon(provider),
              title: Text(provider.name.toUpperCase()),
              onTap: () {
                Navigator.of(context).pop();
                _addIntegration(context, ref, provider);
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

  void _addIntegration(
    BuildContext context,
    WidgetRef ref,
    CalendarProvider provider,
  ) {
    // In a real implementation, this would open the OAuth flow
    // or calendar selection dialog for the specific provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adding ${provider.name} calendar integration...'),
      ),
    );

    // Simulate adding an integration
    ref.read(calendarIntegrationServiceProvider).createIntegration(
          userId: 'current_user_id', // Would get from auth
          provider: provider,
          accountName: '${provider.name}@example.com',
          calendarId: 'primary',
        );
  }

  void _syncIntegration(WidgetRef ref, String integrationId) {
    ref
        .read(calendarIntegrationServiceProvider)
        .syncWithCalendar(integrationId);
  }

  void _showIntegrationSettings(
    BuildContext context,
    WidgetRef ref,
    CalendarIntegration integration,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${integration.accountName} Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Sync completed tasks'),
              value: integration.syncSettings.syncCompletedTasks,
              onChanged: (value) {
                // Update settings
              },
            ),
            SwitchListTile(
              title: const Text('Sync recurring tasks'),
              value: integration.syncSettings.syncRecurringTasks,
              onChanged: (value) {
                // Update settings
              },
            ),
            SwitchListTile(
              title: const Text('Include task descriptions'),
              value: integration.syncSettings.syncTaskDescriptions,
              onChanged: (value) {
                // Update settings
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

  void _deleteIntegration(
    BuildContext context,
    WidgetRef ref,
    CalendarIntegration integration,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Integration'),
        content: Text(
          'Are you sure you want to remove the integration with ${integration.accountName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(calendarIntegrationServiceProvider)
                  .deleteIntegration(integration.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

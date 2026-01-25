import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_providers.dart';

/// Widget that displays the current sync status
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return syncStatus.when(
      data: (status) => _buildStatusIndicator(context, status, isOnline),
      loading: () => const SizedBox.shrink(),
      error: (error, _) => _buildErrorIndicator(context, error.toString()),
    );
  }

  Widget _buildStatusIndicator(
      BuildContext context, dynamic status, bool isOnline) {
    final theme = Theme.of(context);

    if (!isOnline) {
      return _buildIndicator(
        context,
        icon: Icons.cloud_off,
        color: theme.colorScheme.error,
        tooltip: 'Offline - Changes will sync when connection is restored',
      );
    }

    if (status.isSyncing) {
      return _buildIndicator(
        context,
        icon: Icons.sync,
        color: theme.colorScheme.primary,
        tooltip: 'Syncing changes...',
        isAnimated: true,
      );
    }

    if (status.pendingOperations > 0) {
      return _buildIndicator(
        context,
        icon: Icons.cloud_queue,
        color: theme.colorScheme.secondary,
        tooltip: '${status.pendingOperations} changes pending sync',
        badge: status.pendingOperations.toString(),
      );
    }

    return _buildIndicator(
      context,
      icon: Icons.cloud_done,
      color: theme.colorScheme.primary,
      tooltip: 'All changes synced',
    );
  }

  Widget _buildErrorIndicator(BuildContext context, String error) {
    final theme = Theme.of(context);

    return _buildIndicator(
      context,
      icon: Icons.error_outline,
      color: theme.colorScheme.error,
      tooltip: 'Sync error: $error',
    );
  }

  Widget _buildIndicator(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tooltip,
    String? badge,
    bool isAnimated = false,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: 20,
      color: color,
    );

    if (isAnimated) {
      iconWidget = RotationTransition(
        turns: const AlwaysStoppedAnimation(0.5),
        child: iconWidget,
      );
    }

    if (badge != null) {
      iconWidget = Badge(
        label: Text(badge),
        child: iconWidget,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: iconWidget,
      ),
    );
  }
}

/// A more detailed sync status widget for settings or debug screens
class DetailedSyncStatus extends ConsumerWidget {
  const DetailedSyncStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildStatusRow('Connection', isOnline ? 'Online' : 'Offline'),
            syncStatus.when(
              data: (status) => Column(
                children: [
                  _buildStatusRow('Syncing', status.isSyncing ? 'Yes' : 'No'),
                  _buildStatusRow(
                      'Pending Operations', '${status.pendingOperations}'),
                  if (status.lastSyncTime != null)
                    _buildStatusRow(
                      'Last Sync',
                      _formatDateTime(status.lastSyncTime!),
                    ),
                  if (status.lastError != null)
                    _buildStatusRow('Last Error', status.lastError!,
                        isError: true),
                ],
              ),
              loading: () => _buildStatusRow('Status', 'Loading...'),
              error: (error, _) =>
                  _buildStatusRow('Error', error.toString(), isError: true),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isOnline
                      ? () => ref.read(syncServiceProvider).forceSync()
                      : null,
                  child: const Text('Force Sync'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: isError ? Colors.red : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
}

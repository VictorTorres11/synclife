import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_providers.dart';
import '../widgets/sync_status_indicator.dart';

/// Demo screen to showcase sync functionality
class SyncDemoScreen extends ConsumerWidget {
  const SyncDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingOperationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Demo'),
        actions: const [
          SyncStatusIndicator(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline-First Sync Demo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOnline ? Icons.wifi : Icons.wifi_off,
                          color: isOnline ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(isOnline ? 'Online' : 'Offline'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                    syncStatus.when(
                      data: (status) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Syncing: ${status.isSyncing ? "Yes" : "No"}'),
                          Text('Pending Operations: $pendingCount'),
                          if (status.lastSyncTime != null)
                            Text(
                                'Last Sync: ${_formatTime(status.lastSyncTime!)}'),
                          if (status.lastError != null)
                            Text(
                              'Last Error: ${status.lastError}',
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const DetailedSyncStatus(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final syncService = ref.read(syncServiceProvider);
                try {
                  await syncService.forceSync();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sync completed')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Force Sync'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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

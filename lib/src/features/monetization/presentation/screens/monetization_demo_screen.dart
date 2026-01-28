import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ad_banner_widget.dart';
import '../providers/monetization_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/services/services.dart';
import '../../domain/models/user_limitations.dart';

/// Demo screen showing how to integrate monetization features
class MonetizationDemoScreen extends ConsumerWidget {
  const MonetizationDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see monetization features'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.of(context).pushNamed('/subscription');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ad banner at the top (only for free users)
          const AdBannerWidget(
            placementId: AdPlacements.taskListBanner,
            height: 60,
          ),

          // Limitation warning for tasks
          const LimitationWarningWidget(
            limitationType: LimitationType.activeTasks,
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserStatusCard(ref, user.id),
                  const SizedBox(height: 16),
                  _buildLimitationsCard(ref, user.id),
                  const SizedBox(height: 16),
                  _buildActionsCard(ref, user.id, context),
                  const SizedBox(height: 16),

                  // Upgrade prompt for free users
                  const UpgradePromptWidget(
                    message: 'Unlock unlimited tasks and boards with Premium',
                  ),
                ],
              ),
            ),
          ),

          // Bottom ad banner (only for free users)
          const AdBannerWidget(
            placementId: AdPlacements.settingsBanner,
            height: 50,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(ref, user.id, context),
    );
  }

  Widget _buildUserStatusCard(WidgetRef ref, String userId) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider(userId));
    final isPremiumAsync = ref.watch(isPremiumProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isPremiumAsync.when(
              data: (isPremium) => Row(
                children: [
                  Icon(
                    isPremium ? Icons.star : Icons.person,
                    color: isPremium ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPremium ? 'Premium User' : 'Free User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  Icon(Icons.person, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              error: (_, __) => const Row(
                children: [
                  Icon(Icons.person, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Free User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            subscriptionAsync.when(
              data: (subscription) {
                if (subscription == null) {
                  return const Text('No subscription data');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan: ${subscription.plan.name.toUpperCase()}'),
                    Text('Status: ${subscription.status.name.toUpperCase()}'),
                    if (subscription.expiryDate != null)
                      Text('Expires: ${_formatDate(subscription.expiryDate!)}'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationsCard(WidgetRef ref, String userId) {
    final limitationsAsync = ref.watch(userLimitationsProvider(userId));
    final remainingTasksAsync = ref.watch(remainingTaskSlotsProvider(userId));
    final remainingBoardsAsync = ref.watch(remainingBoardSlotsProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Limits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            limitationsAsync.when(
              data: (limitations) => Column(
                children: [
                  remainingTasksAsync.when(
                    data: (remainingTasks) => _buildLimitRow(
                      'Active Tasks',
                      limitations.currentActiveTasks,
                      limitations.maxActiveTasks,
                      remainingTasks,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => _buildLimitRow(
                      'Active Tasks',
                      limitations.currentActiveTasks,
                      limitations.maxActiveTasks,
                      0,
                    ),
                  ),
                  remainingBoardsAsync.when(
                    data: (remainingBoards) => _buildLimitRow(
                      'Boards',
                      limitations.currentBoards,
                      limitations.maxBoards,
                      remainingBoards,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => _buildLimitRow(
                      'Boards',
                      limitations.currentBoards,
                      limitations.maxBoards,
                      0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        limitations.adsEnabled ? Icons.ads_click : Icons.block,
                        size: 16,
                        color: limitations.adsEnabled
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(limitations.adsEnabled ? 'Ads Enabled' : 'Ad-Free'),
                    ],
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(String label, int current, int max, int remaining) {
    final isUnlimited = max == -1;
    final percentage = isUnlimited ? 0.0 : (current / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(isUnlimited ? '$current / Unlimited' : '$current / $max'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: isUnlimited ? 0.0 : percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isUnlimited
                  ? Colors.green
                  : percentage > 0.8
                      ? Colors.red
                      : Colors.blue,
            ),
          ),
          if (!isUnlimited && remaining <= 5)
            Text(
              '$remaining slots remaining',
              style: TextStyle(
                fontSize: 12,
                color: remaining <= 2 ? Colors.red : Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(WidgetRef ref, String userId, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testTaskCreation(ref, userId, context),
              child: const Text('Test Create Task'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testBoardCreation(ref, userId, context),
              child: const Text('Test Create Board'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showInterstitialAd(ref, context),
              child: const Text('Show Interstitial Ad'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(WidgetRef ref, String userId, BuildContext context) {
    final canCreateTasksAsync = ref.watch(canPerformActionProvider(LimitationType.activeTasks));

    return canCreateTasksAsync.when(
      data: (canCreate) {
        if (!canCreate) {
          return FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Task limit reached. Upgrade to Premium for unlimited tasks.'),
                  action: SnackBarAction(
                    label: 'Upgrade',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/subscription');
                    },
                  ),
                ),
              );
            },
            backgroundColor: Colors.grey,
            child: const Icon(Icons.block),
          );
        }

        return FloatingActionButton(
          onPressed: () => _testTaskCreation(ref, userId, context),
          child: const Icon(Icons.add),
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Future<void> _testTaskCreation(WidgetRef ref, String userId, BuildContext context) async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      // Check if user can create tasks
      final canCreate = await subscriptionService.canPerformAction(
        userId,
        LimitationType.activeTasks,
      );

      if (!canCreate) {
        _showLimitDialog(context, 'Task limit reached',
            'You have reached your task limit. Upgrade to Premium for unlimited tasks.');
        return;
      }

      // Simulate task creation
      await subscriptionService.incrementUsage(
          userId, LimitationType.activeTasks);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _testBoardCreation(WidgetRef ref, String userId, BuildContext context) async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      // Check if user can create boards
      final canCreate = await subscriptionService.canPerformAction(
        userId,
        LimitationType.boards,
      );

      if (!canCreate) {
        _showLimitDialog(context, 'Board limit reached',
            'You have reached your board limit. Upgrade to Premium for unlimited boards.');
        return;
      }

      // Simulate board creation
      await subscriptionService.incrementUsage(userId, LimitationType.boards);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Board created successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showInterstitialAd(WidgetRef ref, BuildContext context) async {
    try {
      final adsService = ref.read(adsServiceProvider);
      final shown = await adsService
          .showInterstitialAd(AdPlacements.taskCompleteInterstitial);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(shown ? 'Ad shown successfully!' : 'No ad available')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error showing ad: $e')),
        );
      }
    }
  }

  void _showLimitDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

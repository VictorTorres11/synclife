import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription.dart';
import '../providers/monetization_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Section with subscription management actions (cancel, restore, etc.)
class SubscriptionActionsSection extends ConsumerWidget {
  const SubscriptionActionsSection({
    super.key,
    required this.subscription,
  });

  final Subscription? subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subscription == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isActive = subscription!.isActive;
    final isPremium = subscription!.effectivePlan == SubscriptionPlan.premium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Restore purchases button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleRestorePurchases(context, ref),
                icon: const Icon(Icons.restore),
                label: const Text('Restore Purchases'),
              ),
            ),

            if (isActive && isPremium) ...[
              const SizedBox(height: 12),

              // Cancel subscription button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Subscription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Subscription info
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Information',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          Icons.info_outline,
          'Subscriptions are managed through your device\'s app store (Google Play or App Store).',
        ),
        const SizedBox(height: 8),
        _buildInfoItem(
          context,
          Icons.schedule,
          'Cancellations take effect at the end of the current billing period.',
        ),
        const SizedBox(height: 8),
        _buildInfoItem(
          context,
          Icons.restore,
          'Use "Restore Purchases" if you\'ve purchased on another device.',
        ),
        const SizedBox(height: 8),
        _buildInfoItem(
          context,
          Icons.support,
          'Contact support if you have issues with your subscription.',
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRestorePurchases(
      BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to restore purchases')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Restoring purchases...'),
            ],
          ),
        ),
      );

      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restoredSubscriptions =
          await subscriptionService.restorePurchases(user.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (restoredSubscriptions.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh subscription data
          ref.invalidate(userSubscriptionProvider);
          ref.invalidate(userLimitationsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No purchases found to restore.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You\'ll continue to have access to Premium features until the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleCancelSubscription(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelSubscription(
      BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cancelling subscription...'),
            ],
          ),
        ),
      );

      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.cancelSubscription(user.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Subscription cancelled. You\'ll retain access until the end of your billing period.'),
            backgroundColor: Colors.orange,
          ),
        );

        // Refresh subscription data
        ref.invalidate(userSubscriptionProvider);
        ref.invalidate(userLimitationsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

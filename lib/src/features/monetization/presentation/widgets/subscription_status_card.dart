import 'package:flutter/material.dart';
import '../../domain/models/subscription.dart';

/// Card displaying current subscription status and details
class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    super.key,
    required this.subscription,
  });

  final Subscription? subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = subscription?.isActive ?? false;
    final isPremium = subscription?.effectivePlan == SubscriptionPlan.premium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.person,
                  color: isPremium ? Colors.amber : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? 'Premium' : 'Free',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isPremium ? Colors.amber : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(subscription?.status, colorScheme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(subscription?.status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (subscription != null) ...[
              const SizedBox(height: 16),

              // Subscription details
              if (subscription!.expiryDate != null) ...[
                _buildDetailRow(
                  context,
                  'Expires',
                  _formatDate(subscription!.expiryDate!),
                  Icons.schedule,
                ),
                const SizedBox(height: 8),
              ],

              if (subscription!.trialEndDate != null &&
                  subscription!.isInTrial) ...[
                _buildDetailRow(
                  context,
                  'Trial ends',
                  _formatDate(subscription!.trialEndDate!),
                  Icons.timer,
                ),
                const SizedBox(height: 8),
              ],

              if (subscription!.autoRenewing) ...[
                _buildDetailRow(
                  context,
                  'Auto-renewal',
                  'Enabled',
                  Icons.refresh,
                ),
              ] else if (isActive) ...[
                _buildDetailRow(
                  context,
                  'Auto-renewal',
                  'Disabled',
                  Icons.refresh_outlined,
                ),
              ],
            ],
            if (!isPremium) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to Premium for unlimited tasks, boards, and exclusive features!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SubscriptionStatus? status, ColorScheme colorScheme) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.orange;
      case SubscriptionStatus.pendingRenewal:
        return Colors.blue;
      case SubscriptionStatus.gracePeriod:
        return Colors.amber;
      case SubscriptionStatus.inactive:
      case null:
        return colorScheme.outline;
    }
  }

  String _getStatusText(SubscriptionStatus? status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.pendingRenewal:
        return 'Pending';
      case SubscriptionStatus.gracePeriod:
        return 'Grace Period';
      case SubscriptionStatus.inactive:
      case null:
        return 'Inactive';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Soon';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/subscription_management_screen.dart';

/// Dialog prompting users to upgrade to Premium
class UpgradePromptDialog extends ConsumerWidget {
  const UpgradePromptDialog({
    super.key,
    required this.feature,
    this.description,
    this.benefits = const [],
  });

  final String feature;
  final String? description;
  final List<String> benefits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Premium Feature',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$feature is a Premium feature.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Premium includes:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
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
                    'Upgrade now to unlock all Premium features!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToSubscription(context);
          },
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionManagementScreen(),
      ),
    );
  }

  /// Show upgrade prompt for a specific feature
  static Future<void> show(
    BuildContext context, {
    required String feature,
    String? description,
    List<String> benefits = const [],
  }) {
    return showDialog(
      context: context,
      builder: (context) => UpgradePromptDialog(
        feature: feature,
        description: description,
        benefits: benefits,
      ),
    );
  }
}

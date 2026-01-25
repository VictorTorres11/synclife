import 'package:flutter/material.dart';
import '../../domain/models/user_limitations.dart';

/// Card displaying current subscription benefits and limitations
class SubscriptionBenefitsCard extends StatelessWidget {
  const SubscriptionBenefitsCard({
    super.key,
    required this.limitations,
  });

  final UserLimitations limitations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = !limitations.adsEnabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium : Icons.info_outline,
                  color: isPremium ? Colors.amber : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? 'Premium Benefits' : 'Current Limitations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Task limitations
            _buildLimitationItem(
              context,
              'Active Tasks',
              limitations.maxActiveTasks == -1
                  ? 'Unlimited'
                  : '${limitations.currentActiveTasks}/${limitations.maxActiveTasks}',
              limitations.maxActiveTasks == -1
                  ? Icons.check_circle
                  : Icons.task_alt,
              limitations.maxActiveTasks == -1
                  ? Colors.green
                  : (limitations.canCreateMoreTasks
                      ? colorScheme.primary
                      : Colors.red),
            ),

            const SizedBox(height: 12),

            // Board limitations
            _buildLimitationItem(
              context,
              'Boards',
              limitations.maxBoards == -1
                  ? 'Unlimited'
                  : '${limitations.currentBoards}/${limitations.maxBoards}',
              limitations.maxBoards == -1
                  ? Icons.check_circle
                  : Icons.dashboard,
              limitations.maxBoards == -1
                  ? Colors.green
                  : (limitations.canCreateMoreBoards
                      ? colorScheme.primary
                      : Colors.red),
            ),

            const SizedBox(height: 12),

            // Board members limitation
            _buildLimitationItem(
              context,
              'Board Members',
              limitations.maxBoardMembers == -1
                  ? 'Unlimited'
                  : 'Up to ${limitations.maxBoardMembers}',
              limitations.maxBoardMembers == -1
                  ? Icons.check_circle
                  : Icons.group,
              limitations.maxBoardMembers == -1
                  ? Colors.green
                  : colorScheme.primary,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Premium features
            Text(
              'Features',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildFeatureItem(
              context,
              'Calendar Integration',
              limitations.canUseCalendarIntegration,
            ),

            const SizedBox(height: 8),

            _buildFeatureItem(
              context,
              'Advanced Backup',
              limitations.canUseAdvancedBackup,
            ),

            const SizedBox(height: 8),

            _buildFeatureItem(
              context,
              'Premium Themes',
              limitations.canUsePremiumThemes,
            ),

            const SizedBox(height: 8),

            _buildFeatureItem(
              context,
              'Ad-Free Experience',
              !limitations.adsEnabled,
            ),

            if (!isPremium) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.upgrade,
                      color: colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to Premium to unlock all features and remove limitations!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
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

  Widget _buildLimitationItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    bool available,
  ) {
    final theme = Theme.of(context);
    final color = available ? Colors.green : theme.colorScheme.outline;

    return Row(
      children: [
        Icon(
          available ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: available ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

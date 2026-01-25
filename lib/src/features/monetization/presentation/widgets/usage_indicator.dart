import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_limitations.dart';
import '../providers/monetization_providers.dart';
import '../utils/premium_utils.dart';
import '../../domain/services/subscription_service.dart';

/// Widget showing current usage vs limits with upgrade prompt
class UsageIndicator extends ConsumerWidget {
  const UsageIndicator({
    super.key,
    required this.limitationType,
    this.showProgressBar = true,
    this.showUpgradeButton = true,
    this.compact = false,
  });

  final LimitationType limitationType;
  final bool showProgressBar;
  final bool showUpgradeButton;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = ref.watch(isPremiumProvider);
    final limitationsAsync = ref.watch(userLimitationsProvider);

    if (isPremium) {
      return _buildPremiumIndicator(context, theme);
    }

    return limitationsAsync.when(
      data: (limitations) => _buildUsageWidget(
        context,
        ref,
        theme,
        colorScheme,
        limitations,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPremiumIndicator(BuildContext context, ThemeData theme) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            'Unlimited',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Premium: Unlimited ${_getResourceName()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageWidget(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    limitations,
  ) {
    final current = _getCurrentUsage(limitations);
    final max = _getMaxUsage(limitations);
    final percentage = max > 0 ? current / max : 0.0;
    final isNearLimit = percentage >= 0.8;
    final isAtLimit = percentage >= 1.0;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$current/$max',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isAtLimit ? Colors.red : (isNearLimit ? Colors.orange : null),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isAtLimit) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.warning,
              size: 16,
              color: Colors.red,
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAtLimit
            ? colorScheme.errorContainer
            : (isNearLimit
                ? Colors.orange.withOpacity(0.1)
                : colorScheme.surfaceVariant),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtLimit
              ? colorScheme.error.withOpacity(0.3)
              : (isNearLimit
                  ? Colors.orange.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                size: 20,
                color: isAtLimit
                    ? colorScheme.error
                    : (isNearLimit
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_getResourceName()}: $current of $max used',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isAtLimit ? colorScheme.onErrorContainer : null,
                  ),
                ),
              ),
            ],
          ),
          if (showProgressBar) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtLimit
                    ? Colors.red
                    : (isNearLimit ? Colors.orange : colorScheme.primary),
              ),
            ),
          ],
          if (isAtLimit && showUpgradeButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => PremiumUtils.checkAndPromptForAction(
                  context,
                  ref,
                  limitationType,
                ),
                icon: const Icon(Icons.upgrade, size: 16),
                label: const Text('Upgrade to Premium'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCurrentUsage(limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return limitations.currentActiveTasks;
      case LimitationType.boards:
        return limitations.currentBoards;
      case LimitationType.boardMembers:
        return 0; // Not tracked globally
    }
  }

  int _getMaxUsage(limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return limitations.maxActiveTasks;
      case LimitationType.boards:
        return limitations.maxBoards;
      case LimitationType.boardMembers:
        return limitations.maxBoardMembers;
    }
  }

  String _getResourceName() {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'Tasks';
      case LimitationType.boards:
        return 'Boards';
      case LimitationType.boardMembers:
        return 'Board Members';
    }
  }

  IconData _getIcon() {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return Icons.task_alt;
      case LimitationType.boards:
        return Icons.dashboard;
      case LimitationType.boardMembers:
        return Icons.group;
    }
  }
}

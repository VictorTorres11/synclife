import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../monetization/presentation/providers/monetization_providers.dart';

/// Widget showing reminder usage for free users
/// 
/// Displays:
/// - Usage count (X/30 reminders used)
/// - Progress bar with color coding
/// - Warning banner when > 80% usage
/// - Upgrade button when at limit
/// - "Unlimited reminders" for premium users
class ReminderUsageIndicator extends ConsumerWidget {
  const ReminderUsageIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitationsAsync = ref.watch(currentUserLimitationsProvider);
    final isPremium = ref.watch(currentUserIsPremiumProvider);

    return limitationsAsync.when(
      data: (limitations) {
        // Premium users see unlimited message or nothing
        if (isPremium) {
          return _buildPremiumIndicator(context);
        }

        // Free users see usage indicator
        return _buildFreeUserIndicator(context, limitations, ref);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Builds indicator for premium users
  Widget _buildPremiumIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'Lembretes ilimitados',
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds indicator for free users
  Widget _buildFreeUserIndicator(
    BuildContext context,
    dynamic limitations,
    WidgetRef ref,
  ) {
    final current = limitations.currentReminders as int;
    final max = limitations.maxReminders as int;
    final percentage = limitations.reminderUsagePercentage as double;
    final canCreateMore = limitations.canCreateMoreReminders as bool;

    // Determine color based on usage percentage
    final Color progressColor;
    final Color backgroundColor;
    if (percentage >= 0.95) {
      // Red for >= 95%
      progressColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
    } else if (percentage >= 0.80) {
      // Yellow/Orange for >= 80%
      progressColor = Colors.orange.shade700;
      backgroundColor = Colors.orange.shade50;
    } else {
      // Green for < 80%
      progressColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
    }

    return Semantics(
      label: 'Reminder usage: $current of $max reminders used, ${(percentage * 100).toStringAsFixed(0)} percent',
      readOnly: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: progressColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usage text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$current/$max lembretes usados',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            
            // Warning banner when > 80% usage
            if (percentage > 0.80) ...[
              const SizedBox(height: 12),
              _buildWarningBanner(context, canCreateMore, ref),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds warning banner for high usage
  Widget _buildWarningBanner(
    BuildContext context,
    bool canCreateMore,
    WidgetRef ref,
  ) {
    final String message;
    final IconData icon;

    if (!canCreateMore) {
      // At limit
      message = 'Você atingiu o limite de lembretes. Faça upgrade para criar mais!';
      icon = Icons.block;
    } else {
      // Approaching limit
      message = 'Você está próximo do limite de lembretes. Considere fazer upgrade!';
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToSubscription(context),
              icon: const Icon(Icons.star, size: 18),
              label: const Text('Fazer Upgrade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to subscription screen
  void _navigateToSubscription(BuildContext context) {
    context.push('/subscription');
  }
}

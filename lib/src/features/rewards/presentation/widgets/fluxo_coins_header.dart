import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gamification/presentation/providers/gamification_providers.dart';

/// Widget displaying user's FluxoCoins balance at the top of the store
class FluxoCoinsHeader extends ConsumerWidget {
  const FluxoCoinsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: userStatsAsync.when(
        data: (userStats) {
          final fluxoCoins = userStats?.fluxoCoins ?? 0;
          return _buildHeader(context, fluxoCoins, theme);
        },
        loading: () => _buildLoadingHeader(context, theme),
        error: (error, stack) => _buildErrorHeader(context, theme),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int fluxoCoins, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.monetization_on,
            color: theme.colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            Text(
              '$fluxoCoins FluxoCoins',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showHowToEarnDialog(context),
          icon: Icon(
            Icons.help_outline,
            color: theme.colorScheme.onPrimary,
          ),
          tooltip: 'How to earn FluxoCoins',
        ),
      ],
    );
  }

  Widget _buildLoadingHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.monetization_on,
            color: theme.colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            SizedBox(
              width: 120,
              height: 20,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            color: theme.colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Unavailable',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            Text(
              'Error loading balance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHowToEarnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Earn FluxoCoins'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You can earn FluxoCoins by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _EarnMethodItem(
                icon: Icons.check_circle,
                title: 'Completing Tasks',
                description: 'Earn 1 FluxoCoin for every 10 XP gained',
              ),
              _EarnMethodItem(
                icon: Icons.local_fire_department,
                title: 'Maintaining Streaks',
                description: 'Bonus FluxoCoins for consistent daily completion',
              ),
              _EarnMethodItem(
                icon: Icons.group_add,
                title: 'Inviting Friends',
                description:
                    'Earn bonus when friends complete their first 5 tasks',
              ),
              _EarnMethodItem(
                icon: Icons.emoji_events,
                title: 'Unlocking Achievements',
                description: 'Each achievement rewards FluxoCoins',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _EarnMethodItem extends StatelessWidget {
  const _EarnMethodItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/gamification_providers.dart';

/// Widget displaying XP progress by category
class CategoryProgressChart extends ConsumerWidget {
  const CategoryProgressChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            userStatsAsync.when(
              data: (userStats) {
                if (userStats == null) {
                  return const Center(
                    child: Text('No category data available'),
                  );
                }
                return _buildCategoryProgress(context, userStats, theme);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(
      BuildContext context, UserStats userStats, ThemeData theme) {
    final categories = [
      CategoryData('Health', userStats.categoryXP['Health'] ?? 0,
          Icons.favorite, Colors.red),
      CategoryData(
          'Home', userStats.categoryXP['Home'] ?? 0, Icons.home, Colors.blue),
      CategoryData('Finance', userStats.categoryXP['Finance'] ?? 0,
          Icons.account_balance_wallet, Colors.green),
      CategoryData(
          'Work', userStats.categoryXP['Work'] ?? 0, Icons.work, Colors.orange),
    ];

    // Find max XP for scaling
    final maxXP = categories.map((c) => c.xp).reduce((a, b) => a > b ? a : b);

    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildCategoryBar(context, category, maxXP, theme),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBar(
      BuildContext context, CategoryData category, int maxXP, ThemeData theme) {
    final progress = maxXP > 0 ? category.xp / maxXP : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${category.xp} XP',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(category.color),
          minHeight: 8,
        ),
      ],
    );
  }
}

/// Data class for category information
class CategoryData {
  const CategoryData(this.name, this.xp, this.icon, this.color);

  final String name;
  final int xp;
  final IconData icon;
  final Color color;
}

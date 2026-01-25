import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/gamification_providers.dart';

/// Widget displaying user's achievements in a grid layout
class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full achievements screen
                    _showAllAchievements(context, ref);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            achievementsAsync.when(
              data: (achievements) {
                if (achievements.isEmpty) {
                  return _buildEmptyState(context, theme);
                }
                return _buildAchievementsGrid(context, achievements, theme);
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

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No achievements yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Complete tasks to unlock achievements!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(
      BuildContext context, List<Achievement> achievements, ThemeData theme) {
    // Show only the first 6 achievements in the dashboard
    final displayAchievements = achievements.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: displayAchievements.length,
      itemBuilder: (context, index) {
        final achievement = displayAchievements[index];
        return _buildAchievementCard(context, achievement, theme);
      },
    );
  }

  Widget _buildAchievementCard(
      BuildContext context, Achievement achievement, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showAchievementDetails(context, achievement),
      child: Container(
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAchievementIcon(achievement.category),
                color: achievement.isUnlocked
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            // Achievement Title
            Text(
              achievement.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: achievement.isUnlocked
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String category) {
    switch (category.toLowerCase()) {
      case 'progress':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'collaboration':
        return Icons.group;
      case 'completion':
        return Icons.check_circle;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('Unlocked', style: TextStyle(color: Colors.green)),
                ],
              ),
              if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Unlocked on ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text('Locked', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Rewards:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('${achievement.xpReward} XP'),
            Text('${achievement.fluxoCoinReward} FluxoCoins'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllAchievements(BuildContext context, WidgetRef ref) {
    // Navigate to full achievements screen
    // For now, just show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Achievements'),
        content:
            const Text('Full achievements screen would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

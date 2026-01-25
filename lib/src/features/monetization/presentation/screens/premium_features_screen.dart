import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/monetization_providers.dart';
import '../widgets/calendar_integration_widget.dart';
import '../widgets/advanced_backup_widget.dart';
import '../widgets/premium_themes_widget.dart';

/// Screen displaying premium features for subscribed users
class PremiumFeaturesScreen extends ConsumerWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider);
    final limitationsAsync = ref.watch(userLimitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: subscriptionAsync.when(
        data: (subscription) => limitationsAsync.when(
          data: (limitations) {
            if (!limitations.canUseCalendarIntegration &&
                !limitations.canUseAdvancedBackup &&
                !limitations.canUsePremiumThemes) {
              return _buildUpgradePrompt(context);
            }

            return _buildPremiumFeatures(context, limitations);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context, error),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context, limitations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock the full potential of SyncLife with these exclusive features.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Calendar Integration
          if (limitations.canUseCalendarIntegration) ...[
            _buildFeatureSection(
              context,
              title: 'Calendar Integration',
              description: 'Sync your tasks with external calendars',
              icon: Icons.calendar_today,
              child: const CalendarIntegrationWidget(),
            ),
            const SizedBox(height: 24),
          ],

          // Advanced Backup
          if (limitations.canUseAdvancedBackup) ...[
            _buildFeatureSection(
              context,
              title: 'Advanced Backup',
              description: 'Secure and automated data backups',
              icon: Icons.backup,
              child: const AdvancedBackupWidget(),
            ),
            const SizedBox(height: 24),
          ],

          // Premium Themes
          if (limitations.canUsePremiumThemes) ...[
            _buildFeatureSection(
              context,
              title: 'Premium Themes',
              description: 'Exclusive themes and customizations',
              icon: Icons.palette,
              child: const PremiumThemesWidget(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock calendar integration, advanced backup, and premium themes with a SyncLife Premium subscription.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/subscription');
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

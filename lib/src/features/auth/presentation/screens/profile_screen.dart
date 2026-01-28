import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../monetization/domain/models/user_limitations.dart';
import '../../../monetization/presentation/providers/monetization_providers.dart';
import '../../../monetization/presentation/widgets/subscription_status_card.dart';
import '../../../monetization/presentation/widgets/usage_indicator.dart';
import '../../domain/models/models.dart';
import '../providers/auth_providers.dart';
import '../widgets/account_actions_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_settings_list.dart';
import '../widgets/profile_stats_card.dart';

/// Screen displaying user profile and account management
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return MainLayout(
      title: 'Profile',
      actions: [
        IconButton(
          onPressed: () => _navigateToSettings(context),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
      child: authState.when(
        data: (user) {
          if (user == null) {
            return _buildNotLoggedInState(context, theme);
          }
          return _buildProfileContent(context, user, ref);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Not logged in',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view your profile',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user, WidgetRef ref) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          ProfileHeader(user: user),

          const SizedBox(height: 24),

          // Subscription Status
          subscriptionAsync.when(
            data: (subscription) => SubscriptionStatusCard(
              subscription: subscription,
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Usage Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const UsageIndicator(
                    limitationType: LimitationType.activeTasks,
                    showProgressBar: true,
                    showUpgradeButton: false,
                  ),
                  const SizedBox(height: 12),
                  const UsageIndicator(
                    limitationType: LimitationType.boards,
                    showProgressBar: true,
                    showUpgradeButton: false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats Card
          const ProfileStatsCard(),

          const SizedBox(height: 24),

          // Settings List
          const ProfileSettingsList(),

          const SizedBox(height: 24),

          // Account Actions
          const AccountActionsSection(),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}

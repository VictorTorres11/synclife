import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/monetization_providers.dart';
import '../widgets/subscription_actions_section.dart';
import '../widgets/subscription_benefits_card.dart';
import '../widgets/subscription_plans_list.dart';
import '../widgets/subscription_status_card.dart';

/// Screen for managing user subscription and viewing Premium benefits
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const MainLayout(
        title: 'Subscription',
        child: Center(
          child: Text('Please log in to manage your subscription'),
        ),
      );
    }

    final subscriptionAsync = ref.watch(userSubscriptionProvider);
    final limitationsAsync = ref.watch(userLimitationsProvider);
    final productsAsync = ref.watch(availableProductsProvider);

    return MainLayout(
      title: 'Subscription Management',
      child: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(userSubscriptionProvider)
            ..invalidate(userLimitationsProvider)
            ..invalidate(availableProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current subscription status
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
                error: (error, _) => Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Error loading subscription: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Current limitations and benefits
              limitationsAsync.when(
                data: (limitations) => SubscriptionBenefitsCard(
                  limitations: limitations,
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Error loading benefits: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Available subscription plans
              Text(
                'Available Plans',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              productsAsync.when(
                data: (products) => SubscriptionPlansList(
                  products: products,
                  currentSubscription: subscriptionAsync.value,
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Error loading plans: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subscription actions (cancel, restore, etc.)
              subscriptionAsync.when(
                data: (subscription) => SubscriptionActionsSection(
                  subscription: subscription,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Terms and privacy links
              _buildFooterLinks(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Open terms of service
              },
              child: const Text('Terms of Service'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Open privacy policy
              },
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Open support
              },
              child: const Text('Support'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Subscriptions are managed through your device\'s app store.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

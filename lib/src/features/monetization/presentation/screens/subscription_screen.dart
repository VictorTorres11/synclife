import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/services/subscription_service.dart';
import '../providers/monetization_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Screen for managing premium subscriptions
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to manage your subscription'),
        ),
      );
    }

    final subscriptionAsync = ref.watch(userSubscriptionProvider(user.id));
    final limitationsAsync = ref.watch(userLimitationsProvider(user.id));
    final productsAsync = ref.watch(availableProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current subscription status
            _buildSubscriptionStatus(context, subscriptionAsync),
            const SizedBox(height: 24),

            // Current limitations
            _buildCurrentLimitations(context, limitationsAsync),
            const SizedBox(height: 24),

            // Premium benefits
            _buildPremiumBenefits(context),
            const SizedBox(height: 24),

            // Available products
            _buildAvailableProducts(context, ref, productsAsync, user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(
      BuildContext context, AsyncValue<Subscription?> subscriptionAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Subscription',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            subscriptionAsync.when(
              data: (subscription) {
                if (subscription == null) {
                  return const Text('No subscription found');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan: ${subscription.plan.name.toUpperCase()}'),
                    Text('Status: ${subscription.status.name.toUpperCase()}'),
                    if (subscription.expiryDate != null)
                      Text('Expires: ${_formatDate(subscription.expiryDate!)}'),
                    if (subscription.isInTrial)
                      Text(
                          'Trial ends: ${_formatDate(subscription.trialEndDate!)}'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLimitations(
      BuildContext context, AsyncValue<UserLimitations> limitationsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Limits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            limitationsAsync.when(
              data: (limitations) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLimitationRow(
                    'Active Tasks',
                    limitations.currentActiveTasks,
                    limitations.maxActiveTasks,
                  ),
                  _buildLimitationRow(
                    'Boards',
                    limitations.currentBoards,
                    limitations.maxBoards,
                  ),
                  _buildLimitationRow(
                    'Board Members',
                    0, // This would need to be calculated
                    limitations.maxBoardMembers,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        limitations.adsEnabled ? Icons.ads_click : Icons.block,
                        size: 16,
                        color: limitations.adsEnabled
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(limitations.adsEnabled
                          ? 'Ads Enabled'
                          : 'Ad-Free Experience'),
                    ],
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationRow(String label, int current, int max) {
    final isUnlimited = max == -1;
    final percentage = isUnlimited ? 0.0 : (current / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(isUnlimited ? '$current / Unlimited' : '$current / $max'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: isUnlimited ? 0.0 : percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isUnlimited
                  ? Colors.green
                  : percentage > 0.8
                      ? Colors.red
                      : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefits(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Benefits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const _BenefitItem(
              icon: Icons.task_alt,
              title: 'Unlimited Tasks',
              description: 'Create as many tasks as you need',
            ),
            const _BenefitItem(
              icon: Icons.dashboard,
              title: 'Unlimited Boards',
              description: 'Organize with unlimited boards',
            ),
            const _BenefitItem(
              icon: Icons.group,
              title: 'Unlimited Members',
              description: 'Collaborate with unlimited team members',
            ),
            const _BenefitItem(
              icon: Icons.block,
              title: 'Ad-Free Experience',
              description: 'Enjoy the app without advertisements',
            ),
            const _BenefitItem(
              icon: Icons.calendar_today,
              title: 'Calendar Integration',
              description: 'Sync with your favorite calendar apps',
            ),
            const _BenefitItem(
              icon: Icons.backup,
              title: 'Advanced Backup',
              description: 'Enhanced backup and restore features',
            ),
            const _BenefitItem(
              icon: Icons.palette,
              title: 'Premium Themes',
              description: 'Access to exclusive themes and customizations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableProducts(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SubscriptionProduct>> productsAsync,
    String userId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Plans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              data: (products) => Column(
                children: products
                    .map((product) => _buildProductCard(
                          context,
                          ref,
                          product,
                          userId,
                        ))
                    .toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error loading products: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionProduct product,
    String userId,
  ) {
    final isYearly = product.billingPeriod == BillingPeriod.yearly;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.price,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    Text(
                      isYearly ? 'per year' : 'per month',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isYearly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Save 20%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _purchaseSubscription(ref, userId, product.plan),
                child: Text('Subscribe ${isYearly ? 'Yearly' : 'Monthly'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseSubscription(
    WidgetRef ref,
    String userId,
    SubscriptionPlan plan,
  ) async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.purchaseSubscription(userId, plan);

      // Show success message
      // Note: In a real app, you'd want to show this in the UI context
      print('Subscription purchase initiated for plan: $plan');
    } catch (e) {
      // Show error message
      print('Failed to purchase subscription: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

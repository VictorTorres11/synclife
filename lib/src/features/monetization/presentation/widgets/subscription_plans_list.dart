import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription.dart';
import '../../domain/services/subscription_service.dart';
import '../providers/monetization_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// List of available subscription plans with purchase options
class SubscriptionPlansList extends ConsumerWidget {
  const SubscriptionPlansList({
    super.key,
    required this.products,
    this.currentSubscription,
  });

  final List<SubscriptionProduct> products;
  final Subscription? currentSubscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No subscription plans available'),
        ),
      );
    }

    return Column(
      children: products
          .map((product) => _buildPlanCard(context, ref, product))
          .toList(),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, WidgetRef ref, SubscriptionProduct product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentPlan = currentSubscription?.plan == product.plan;
    final isYearly = product.billingPeriod == BillingPeriod.yearly;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentPlan ? 4 : 1,
      child: Container(
        decoration: isCurrentPlan
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary,
                  width: 2,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              product.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isYearly) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SAVE 20%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        isYearly ? '/year' : '/month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Plan features
              _buildFeaturesList(context),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(context, ref, product, isCurrentPlan),
              ),

              if (isCurrentPlan) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Current Plan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final theme = Theme.of(context);

    const features = [
      'Unlimited tasks and boards',
      'Unlimited board members',
      'Calendar integration',
      'Advanced backup & sync',
      'Premium themes',
      'Ad-free experience',
      'Priority support',
    ];

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    SubscriptionProduct product,
    bool isCurrentPlan,
  ) {
    if (isCurrentPlan) {
      return OutlinedButton(
        onPressed: null,
        child: const Text('Current Plan'),
      );
    }

    return ElevatedButton(
      onPressed: () => _handlePurchase(context, ref, product),
      child: Text(
          'Subscribe ${product.billingPeriod == BillingPeriod.yearly ? 'Yearly' : 'Monthly'}'),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    SubscriptionProduct product,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in to purchase a subscription')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing purchase...'),
            ],
          ),
        ),
      );

      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.purchaseSubscription(user.id, product.plan);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Purchase initiated! Please complete the payment in your app store.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

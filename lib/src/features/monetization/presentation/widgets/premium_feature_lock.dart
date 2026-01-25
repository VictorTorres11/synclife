import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/monetization_providers.dart';
import 'upgrade_prompt_dialog.dart';
import 'premium_feature_indicator.dart';

/// Widget that locks a feature behind Premium subscription
class PremiumFeatureLock extends ConsumerWidget {
  const PremiumFeatureLock({
    super.key,
    required this.child,
    required this.feature,
    this.description,
    this.benefits = const [],
    this.showIndicator = true,
    this.onTap,
  });

  final Widget child;
  final String feature;
  final String? description;
  final List<String> benefits;
  final bool showIndicator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    // If user is Premium, show the child normally
    if (isPremium) {
      return child;
    }

    // For free users, show locked version
    return Stack(
      children: [
        // Disabled/grayed out child
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: child,
          ),
        ),

        // Overlay with lock and Premium indicator
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _showUpgradePrompt(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: showIndicator
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            PremiumFeatureIndicator(showText: true),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUpgradePrompt(BuildContext context) {
    UpgradePromptDialog.show(
      context,
      feature: feature,
      description: description,
      benefits: benefits,
    );
  }
}

/// Widget that conditionally shows content based on Premium status
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.child,
    this.fallback,
    this.showUpgradePrompt = false,
    this.feature,
    this.description,
    this.benefits = const [],
  });

  final Widget child;
  final Widget? fallback;
  final bool showUpgradePrompt;
  final String? feature;
  final String? description;
  final List<String> benefits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    if (showUpgradePrompt && feature != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumFeatureIndicator(
              size: 32,
              showText: true,
            ),
            const SizedBox(height: 16),
            Text(
              '$feature is a Premium feature',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (description != null)
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showUpgradePrompt(context),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showUpgradePrompt(BuildContext context) {
    if (feature == null) return;

    UpgradePromptDialog.show(
      context,
      feature: feature!,
      description: description,
      benefits: benefits,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/monetization_providers.dart';
import '../../domain/models/user_limitations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/discrete_ad_service.dart';

/// Simple ad banner widget for basic ad placement
class AdBannerWidget extends ConsumerWidget {
  const AdBannerWidget({
    super.key,
    required this.placementId,
    this.height = 50.0,
  });

  final String placementId;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DiscreteAdBannerWidget(
      placementId: placementId,
      height: height,
    );
  }
}

/// Widget that displays discrete banner ads for free users
class DiscreteAdBannerWidget extends ConsumerStatefulWidget {
  const DiscreteAdBannerWidget({
    super.key,
    required this.placementId,
    this.height = 50.0,
    this.showOnlyWhenAppropriate = true,
    this.borderRadius = 8.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  final String placementId;
  final double height;
  final bool showOnlyWhenAppropriate;
  final double borderRadius;
  final EdgeInsets margin;

  @override
  ConsumerState<DiscreteAdBannerWidget> createState() =>
      _DiscreteAdBannerWidgetState();
}

class _DiscreteAdBannerWidgetState
    extends ConsumerState<DiscreteAdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoadAd() async {
    if (!mounted) return;

    final discreteAdService = ref.read(discreteAdServiceProvider);

    // Check if we should show ads and if frequency allows
    final canShow = await discreteAdService.canShowAd(widget.placementId);

    if (!canShow || !mounted) {
      setState(() {
        _shouldShow = false;
      });
      return;
    }

    // Check subscription status
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _shouldShow = false;
      });
      return;
    }

    final userLimitationsAsync = ref.read(userLimitationsProvider(user.id).future);
    final userLimitations = await userLimitationsAsync;
    if (!userLimitations.adsEnabled) {
      setState(() {
        _shouldShow = false;
      });
      return;
    }

    setState(() {
      _shouldShow = true;
    });

    // Load the ad
    final success =
        await discreteAdService.showBannerAdIfAllowed(widget.placementId);

    if (success && mounted) {
      setState(() {
        _isAdLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: _isAdLoaded && _bannerAd != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: AdWidget(ad: _bannerAd!),
            )
          : _buildDiscreteAdPlaceholder(),
    );
  }

  Widget _buildDiscreteAdPlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Advertisement',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that shows a discrete upgrade prompt for free users
class UpgradePromptWidget extends ConsumerWidget {
  const UpgradePromptWidget({
    super.key,
    this.message = 'Upgrade to Premium for unlimited access',
    this.showOnlyWhenLimited = true,
  });

  final String message;
  final bool showOnlyWhenLimited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    
    final userLimitationsAsync = ref.watch(userLimitationsProvider(user.id));

    return userLimitationsAsync.when(
      data: (limitations) {
        // Only show for free users with ads enabled
        if (!limitations.adsEnabled && showOnlyWhenLimited) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SyncLife Premium',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // Navigate to subscription screen
                  Navigator.of(context).pushNamed('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget that shows limitation warnings
class LimitationWarningWidget extends ConsumerWidget {
  const LimitationWarningWidget({
    super.key,
    required this.limitationType,
    this.warningThreshold = 0.8,
  });

  final LimitationType limitationType;
  final double warningThreshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    
    final limitationsAsync = ref.watch(userLimitationsProvider(user.id));

    return limitationsAsync.when(
      data: (limitations) {
        final shouldShowWarning = _shouldShowWarning(limitations);

        if (!shouldShowWarning) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getWarningMessage(limitations),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/subscription');
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  bool _shouldShowWarning(UserLimitations limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        if (limitations.maxActiveTasks == -1) return false;
        final usage =
            limitations.currentActiveTasks / limitations.maxActiveTasks;
        return usage >= warningThreshold;
      case LimitationType.boards:
        if (limitations.maxBoards == -1) return false;
        final usage = limitations.currentBoards / limitations.maxBoards;
        return usage >= warningThreshold;
      case LimitationType.boardMembers:
        // This would need additional logic to check current usage
        return false;
    }
  }

  String _getWarningMessage(UserLimitations limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        final remaining = limitations.remainingTaskSlots;
        return 'You have $remaining task slots remaining. Upgrade for unlimited tasks.';
      case LimitationType.boards:
        final remaining = limitations.remainingBoardSlots;
        return 'You have $remaining board slots remaining. Upgrade for unlimited boards.';
      case LimitationType.boardMembers:
        return 'Board member limit reached. Upgrade for unlimited members.';
    }
  }
}

/// Widget for showing interstitial ads at appropriate moments
class DiscreteInterstitialAdTrigger extends ConsumerWidget {
  const DiscreteInterstitialAdTrigger({
    super.key,
    required this.placementId,
    required this.child,
    this.triggerOnTap = false,
  });

  final String placementId;
  final Widget child;
  final bool triggerOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: triggerOnTap ? () => _maybeShowInterstitial(ref) : null,
      child: child,
    );
  }

  Future<void> _maybeShowInterstitial(WidgetRef ref) async {
    final discreteAdService = ref.read(discreteAdServiceProvider);
    await discreteAdService.showInterstitialAdWithTiming(placementId);
  }
}

/// Widget for offering rewarded ads
class RewardedAdOfferWidget extends ConsumerWidget {
  const RewardedAdOfferWidget({
    super.key,
    required this.placementId,
    required this.rewardDescription,
    required this.onRewardEarned,
    this.icon = Icons.play_circle_outline,
  });

  final String placementId;
  final String rewardDescription;
  final VoidCallback onRewardEarned;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    
    final limitationsAsync = ref.watch(userLimitationsProvider(user.id));

    return limitationsAsync.when(
      data: (limitations) {
        // Only show for free users
        if (!limitations.adsEnabled) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Watch Ad for Reward',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rewardDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRewardedAd(ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showRewardedAd(WidgetRef ref) async {
    final discreteAdService = ref.read(discreteAdServiceProvider);
    final rewardEarned = await discreteAdService.showRewardedAd(placementId);

    if (rewardEarned) {
      onRewardEarned();
    }
  }
}

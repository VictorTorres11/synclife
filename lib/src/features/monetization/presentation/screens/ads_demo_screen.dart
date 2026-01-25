import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/monetization_providers.dart';
import '../widgets/ad_banner_widget.dart';
import '../../domain/services/ads_service.dart';

/// Demo screen showing discrete advertisement system in action
class AdsSystemDemoScreen extends ConsumerStatefulWidget {
  const AdsSystemDemoScreen({super.key});

  @override
  ConsumerState<AdsSystemDemoScreen> createState() =>
      _AdsSystemDemoScreenState();
}

class _AdsSystemDemoScreenState extends ConsumerState<AdsSystemDemoScreen> {
  int _taskCompletions = 0;
  int _boardCreations = 0;
  Map<String, dynamic>? _adStats;

  @override
  void initState() {
    super.initState();
    _loadAdStats();
  }

  Future<void> _loadAdStats() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);
    final stats = await discreteAdService.getAdStatistics();
    setState(() {
      _adStats = stats;
    });
  }

  Future<void> _simulateTaskCompletion() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);

    setState(() {
      _taskCompletions++;
    });

    // Try to show interstitial ad (every 10th task completion)
    final adShown = await discreteAdService.showInterstitialAdWithTiming(
      AdPlacements.taskCompleteInterstitial,
    );

    if (adShown) {
      _showSnackBar('Interstitial ad shown after task completion!');
    }

    await _loadAdStats();
  }

  Future<void> _simulateBoardCreation() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);

    setState(() {
      _boardCreations++;
    });

    // Try to show interstitial ad (every 3rd board creation)
    final adShown = await discreteAdService.showInterstitialAdWithTiming(
      AdPlacements.boardCreateInterstitial,
    );

    if (adShown) {
      _showSnackBar('Interstitial ad shown after board creation!');
    }

    await _loadAdStats();
  }

  Future<void> _showRewardedAd() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);

    final rewardEarned = await discreteAdService.showRewardedAd(
      AdPlacements.extraCoinsRewarded,
    );

    if (rewardEarned) {
      _showSnackBar('Rewarded ad completed! You earned extra FluxoCoins!');
    } else {
      _showSnackBar('Rewarded ad not available or failed to show.');
    }

    await _loadAdStats();
  }

  Future<void> _clearAdData() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);
    await discreteAdService.clearAdData();

    setState(() {
      _taskCompletions = 0;
      _boardCreations = 0;
    });

    await _loadAdStats();
    _showSnackBar('Ad data cleared!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discrete Ads Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Ad Examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banner Advertisements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text('Task List Banner:'),
                    const SizedBox(height: 8),
                    const DiscreteAdBannerWidget(
                      placementId: AdPlacements.taskListBanner,
                      height: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text('Board List Banner:'),
                    const SizedBox(height: 8),
                    const DiscreteAdBannerWidget(
                      placementId: AdPlacements.boardListBanner,
                      height: 60,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Interstitial Ad Simulation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interstitial Advertisements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Task Completions: $_taskCompletions (ad every 10th)'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _simulateTaskCompletion,
                      child: const Text('Complete Task'),
                    ),
                    const SizedBox(height: 16),
                    Text('Board Creations: $_boardCreations (ad every 3rd)'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _simulateBoardCreation,
                      child: const Text('Create Board'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rewarded Ad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rewarded Advertisements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text('Watch an ad to earn extra FluxoCoins!'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showRewardedAd,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Rewarded Ad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ad Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ad Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: _loadAdStats,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_adStats != null) ...[
                      _buildStatRow(
                          'Ads Enabled', _adStats!['adsEnabled'].toString()),
                      _buildStatRow('Hourly Count',
                          '${_adStats!['hourlyCount']}/${_adStats!['maxAdsPerHour']}'),
                      _buildStatRow('Daily Count',
                          '${_adStats!['dailyCount']}/${_adStats!['maxAdsPerDay']}'),
                      _buildStatRow(
                          'Can Show Ad', _adStats!['canShowAd'].toString()),
                      if (_adStats!['lastAdTime'] != null)
                        _buildStatRow('Last Ad', _adStats!['lastAdTime']),
                    ] else
                      const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearAdData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Ad Data'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Premium Upgrade Prompt
            const UpgradePromptWidget(
              message: 'Remove all ads with SyncLife Premium!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

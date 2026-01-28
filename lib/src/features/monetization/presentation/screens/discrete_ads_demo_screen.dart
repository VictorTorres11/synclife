import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ad_banner_widget.dart';
import '../providers/monetization_providers.dart';
import '../../domain/services/ads_service.dart';
import '../../domain/models/user_limitations.dart';

/// Demo screen showcasing the discrete advertisement system
class DiscreteAdsDemoScreen extends ConsumerStatefulWidget {
  const DiscreteAdsDemoScreen({super.key});

  @override
  ConsumerState<DiscreteAdsDemoScreen> createState() =>
      _DiscreteAdsDemoScreenState();
}

class _DiscreteAdsDemoScreenState extends ConsumerState<DiscreteAdsDemoScreen> {
  int _taskCompletions = 0;
  int _boardCreations = 0;

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    final discreteAdService = ref.read(discreteAdServiceProvider);
    await discreteAdService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discrete Ads Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAdFrequencyInfo(),
            const SizedBox(height: 24),
            _buildTaskListSection(),
            const SizedBox(height: 24),
            _buildBoardListSection(),
            const SizedBox(height: 24),
            _buildRewardedAdSection(),
            const SizedBox(height: 24),
            _buildUpgradePromptSection(),
            const SizedBox(height: 24),
            _buildLimitationWarningSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discrete Advertisement System',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This demo showcases non-intrusive ad placement with intelligent frequency control. Ads are shown based on user actions and time intervals.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Task Completions',
                    _taskCompletions.toString(),
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Board Creations',
                    _boardCreations.toString(),
                    Icons.dashboard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdFrequencyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ad Frequency Control',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future:
                  ref.read(discreteAdServiceProvider).getAdAvailabilityInfo(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final info = snapshot.data!;
                return Column(
                  children: [
                    _buildInfoRow(
                      'Time until next ad',
                      info.timeUntilNextAd?.inMinutes.toString() ?? '0',
                      'minutes',
                    ),
                    _buildInfoRow(
                      'Remaining ads today',
                      info.remainingAdsToday.toString(),
                      'ads',
                    ),
                    _buildInfoRow(
                      'Remaining ads this session',
                      info.remainingAdsThisSession.toString(),
                      'ads',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task List with Banner Ad',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildTaskItem('Complete daily standup', false),
              _buildTaskItem('Review pull requests', false),
              _buildTaskItem('Update project documentation', true),

              // Discrete banner ad placement
              const DiscreteAdBannerWidget(
                placementId: AdPlacements.taskListBanner,
                height: 60,
              ),

              _buildTaskItem('Plan sprint retrospective', false),
              _buildTaskItem('Prepare presentation slides', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(String title, bool isCompleted) {
    return ListTile(
      leading: Checkbox(
        value: isCompleted,
        onChanged: (value) {
          if (value == true) {
            _simulateTaskCompletion();
          }
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing:
          isCompleted ? const Icon(Icons.check, color: Colors.green) : null,
    );
  }

  Widget _buildBoardListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Board List with Banner Ad',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildBoardItem('Personal Tasks', Icons.person, Colors.blue),
              _buildBoardItem('Work Projects', Icons.work, Colors.orange),

              // Discrete banner ad placement
              const DiscreteAdBannerWidget(
                placementId: AdPlacements.boardListBanner,
                height: 60,
              ),

              _buildBoardItem('Home & Family', Icons.home, Colors.green),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create New Board'),
                onTap: _simulateBoardCreation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoardItem(String title, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Navigate to board
      },
    );
  }

  Widget _buildRewardedAdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewarded Ads',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        RewardedAdOfferWidget(
          placementId: AdPlacements.extraCoinsRewarded,
          rewardDescription:
              'Watch an ad to earn 50 FluxoCoins for the rewards store',
          onRewardEarned: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 You earned 50 FluxoCoins!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpgradePromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upgrade Prompts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const UpgradePromptWidget(
          message: 'Remove ads and unlock unlimited features with Premium',
          showOnlyWhenLimited: false,
        ),
      ],
    );
  }

  Widget _buildLimitationWarningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Limitation Warnings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const LimitationWarningWidget(
          limitationType: LimitationType.activeTasks,
          warningThreshold: 0.6, // Show warning at 60% usage for demo
        ),
      ],
    );
  }

  void _simulateTaskCompletion() {
    setState(() {
      _taskCompletions++;
    });

    // Record user action for ad frequency tracking
    final discreteAdService = ref.read(discreteAdServiceProvider);
    discreteAdService.recordUserAction();

    // Show interstitial ad after certain number of completions
    if (_taskCompletions % 3 == 0) {
      discreteAdService.showInterstitialAdWithTiming(
        AdPlacements.taskCompleteInterstitial,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task completed! Total: $_taskCompletions'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _simulateBoardCreation() {
    setState(() {
      _boardCreations++;
    });

    // Record user action for ad frequency tracking
    final discreteAdService = ref.read(discreteAdServiceProvider);
    discreteAdService.recordUserAction();

    // Show interstitial ad for board creation
    discreteAdService.showInterstitialAdWithTiming(
      AdPlacements.boardCreateInterstitial,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Board created! Total: $_boardCreations'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

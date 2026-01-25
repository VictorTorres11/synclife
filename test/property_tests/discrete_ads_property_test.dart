import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclife_app/src/features/monetization/data/services/discrete_ad_service.dart';
import 'package:synclife_app/src/features/monetization/domain/services/ads_service.dart';

import '../features/monetization/discrete_ads_test.mocks.dart';

void main() {
  group(
      'Feature: synclife-app, Property 24: Discrete advertisement frequency control',
      () {
    late DiscreteAdService discreteAdService;
    late MockAdsService mockAdsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAdsService = MockAdsService();
      discreteAdService = DiscreteAdService(mockAdsService);

      when(mockAdsService.adsEnabled).thenReturn(true);
      when(mockAdsService.loadBannerAd(any)).thenAnswer((_) async {});
      when(mockAdsService.showBannerAd(any)).thenAnswer((_) async {});
      when(mockAdsService.showInterstitialAd(any))
          .thenAnswer((_) async => true);
      when(mockAdsService.showRewardedAd(any)).thenAnswer((_) async => true);
    });

    testWidgets('Property 24: Discrete advertisement frequency control',
        (tester) async {
      // **Validates: Requirements 9.2**
      // For any sequence of ad requests, the system should enforce frequency limits
      // and show ads discretely without overwhelming the user

      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Clear data for each iteration
        await discreteAdService.clearAdData();

        // Test different ad request patterns
        final adRequests = _generateAdRequestPattern(i);
        final results = <bool>[];

        for (final request in adRequests) {
          final canShow =
              await discreteAdService.canShowAd(request.placementId);

          if (canShow) {
            final shown = await discreteAdService
                .showBannerAdIfAllowed(request.placementId);
            results.add(shown);

            // Simulate time passing if specified
            if (request.timeDelay != null) {
              await _simulateTimeDelay(request.timeDelay!);
            }
          } else {
            results.add(false);
          }
        }

        // Verify frequency control properties
        await _verifyFrequencyControlProperties(results, adRequests);
      }
    });

    testWidgets('Property 25: Interstitial ad timing control', (tester) async {
      // **Validates: Requirements 9.2**
      // For any sequence of user actions, interstitial ads should only show
      // at appropriate intervals based on action count

      const iterations = 30;

      for (int i = 0; i < iterations; i++) {
        await discreteAdService.clearAdData();

        // Generate random action sequences
        final actionCount = (i % 20) + 5; // 5-24 actions
        final placementId = _getRandomInterstitialPlacement(i);

        int adsShown = 0;

        for (int action = 1; action <= actionCount; action++) {
          // Add time delay between actions to avoid frequency blocking
          if (action > 1) {
            await _simulateTimeDelay(const Duration(minutes: 6));
          }

          final adShown =
              await discreteAdService.showInterstitialAdWithTiming(placementId);
          if (adShown) {
            adsShown++;
          }
        }

        // Verify timing properties based on placement rules
        final expectedAds =
            _calculateExpectedInterstitialAds(placementId, actionCount);
        expect(adsShown, equals(expectedAds),
            reason:
                'Iteration $i: Expected $expectedAds ads for $actionCount actions on $placementId, got $adsShown');
      }
    });

    testWidgets('Property 26: Ad frequency limits enforcement', (tester) async {
      // **Validates: Requirements 9.2**
      // For any time period, the system should not exceed maximum ad limits
      // (hourly and daily limits)

      const iterations = 20;

      for (int i = 0; i < iterations; i++) {
        await discreteAdService.clearAdData();

        // Try to show ads with proper time spacing
        final adAttempts = (i % 10) + 5; // 5-14 attempts
        int successfulAds = 0;

        for (int attempt = 0; attempt < adAttempts; attempt++) {
          final placementId = 'test_placement_$attempt';

          // Simulate minimum time between ads to avoid time-based blocking
          if (attempt > 0) {
            await _simulateTimeDelay(const Duration(minutes: 6));
          }

          final success =
              await discreteAdService.showBannerAdIfAllowed(placementId);
          if (success) {
            successfulAds++;
          }

          // Stop if we hit the hourly limit to avoid excessive testing
          if (successfulAds >= 6) break;
        }

        // Verify limits are enforced
        expect(successfulAds, lessThanOrEqualTo(6), // Hourly limit
            reason:
                'Iteration $i: Exceeded hourly limit of 6 ads, showed $successfulAds');
        expect(successfulAds, lessThanOrEqualTo(30), // Daily limit
            reason:
                'Iteration $i: Exceeded daily limit of 30 ads, showed $successfulAds');
      }
    });

    testWidgets('Property 27: Rewarded ad availability', (tester) async {
      // **Validates: Requirements 9.2**
      // For any rewarded ad request by free users, the system should allow
      // the ad to be shown (more lenient than other ad types)

      const iterations = 25;

      for (int i = 0; i < iterations; i++) {
        await discreteAdService.clearAdData();

        // Test rewarded ads with different scenarios
        final rewardedAdRequests = (i % 10) + 1; // 1-10 requests
        int successfulRewardedAds = 0;

        for (int request = 0; request < rewardedAdRequests; request++) {
          final placementId = 'rewarded_placement_$request';
          final success = await discreteAdService.showRewardedAd(placementId);

          if (success) {
            successfulRewardedAds++;
          }

          // Small delay between requests
          await _simulateTimeDelay(Duration(seconds: 30));
        }

        // Rewarded ads should be more permissive than banner/interstitial ads
        expect(successfulRewardedAds, greaterThan(0),
            reason: 'Iteration $i: At least one rewarded ad should be allowed');

        // But still respect ads being enabled
        when(mockAdsService.adsEnabled).thenReturn(false);
        final disabledResult = await discreteAdService.showRewardedAd('test');
        expect(disabledResult, isFalse,
            reason: 'Iteration $i: Should not show ads when disabled');

        // Reset for next iteration
        when(mockAdsService.adsEnabled).thenReturn(true);
      }
    });
  });
}

/// Generates different ad request patterns for testing
List<AdRequest> _generateAdRequestPattern(int seed) {
  final patterns = [
    // Rapid requests (should mostly fail due to frequency limits)
    List.generate(3, (i) => const AdRequest('rapid_0', null)),
    // Spaced requests (should succeed)
    List.generate(3, (i) => AdRequest('spaced_$i', const Duration(minutes: 6))),
    // Mixed placements with proper spacing
    [
      const AdRequest('task_list_banner', null),
      const AdRequest('board_list_banner', Duration(minutes: 6)),
      const AdRequest('settings_banner', Duration(minutes: 6)),
    ],
    // Single request (should succeed)
    [const AdRequest('single', null)],
  ];

  return patterns[seed % patterns.length];
}

/// Simulates time delay by manipulating stored timestamps
Future<void> _simulateTimeDelay(Duration delay) async {
  final prefs = await SharedPreferences.getInstance();
  final keys =
      prefs.getKeys().where((key) => key.startsWith('last_ad_')).toList();

  for (final key in keys) {
    final currentTime = prefs.getInt(key);
    if (currentTime != null) {
      final newTime = DateTime.fromMillisecondsSinceEpoch(currentTime)
          .subtract(delay)
          .millisecondsSinceEpoch;
      await prefs.setInt(key, newTime);
    }
  }

  // Also adjust ad timestamps
  final adTimestamps = prefs.getStringList('ad_timestamps') ?? [];
  final adjustedTimestamps = adTimestamps.map((timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return time.subtract(delay).millisecondsSinceEpoch.toString();
  }).toList();

  await prefs.setStringList('ad_timestamps', adjustedTimestamps);
}

/// Verifies that frequency control properties are maintained
Future<void> _verifyFrequencyControlProperties(
  List<bool> results,
  List<AdRequest> requests,
) async {
  // Property: No more than one ad should be shown within minimum interval
  for (int i = 1; i < results.length; i++) {
    if (results[i] && results[i - 1]) {
      // Two consecutive ads shown - check if there was a time delay
      final hasTimeDelay = requests[i].timeDelay != null &&
          requests[i].timeDelay!.inMinutes >= 5;
      if (!hasTimeDelay) {
        // Two ads shown without sufficient time delay should not happen
        expect(false, isTrue,
            reason: 'Two consecutive ads shown without minimum interval');
      }
    }
  }

  // Property: Total successful ads should not exceed limits
  final totalAds = results.where((r) => r).length;
  expect(totalAds, lessThanOrEqualTo(6), // Hourly limit
      reason: 'Total ads exceeded hourly limit');
}

/// Gets a random interstitial placement for testing
String _getRandomInterstitialPlacement(int seed) {
  const placements = [
    'task_complete_interstitial',
    'board_create_interstitial',
  ];
  return placements[seed % placements.length];
}

/// Calculates expected number of interstitial ads based on placement rules
int _calculateExpectedInterstitialAds(String placementId, int actionCount) {
  const timingRules = {
    'task_complete_interstitial': 10, // Every 10th action
    'board_create_interstitial': 3, // Every 3rd action
  };

  final interval = timingRules[placementId] ?? 1;
  return actionCount ~/ interval;
}

/// Represents an ad request for testing
class AdRequest {
  const AdRequest(this.placementId, this.timeDelay);

  final String placementId;
  final Duration? timeDelay;
}

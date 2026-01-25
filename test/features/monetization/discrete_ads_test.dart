import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclife_app/src/features/monetization/data/services/discrete_ad_service.dart';
import 'package:synclife_app/src/features/monetization/domain/services/ads_service.dart';

import 'discrete_ads_test.mocks.dart';

@GenerateMocks([AdsService])
void main() {
  group('DiscreteAdService', () {
    late DiscreteAdService discreteAdService;
    late MockAdsService mockAdsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAdsService = MockAdsService();
      discreteAdService = DiscreteAdService(mockAdsService);

      // Setup default mock behavior
      when(mockAdsService.adsEnabled).thenReturn(true);
      when(mockAdsService.loadBannerAd(any)).thenAnswer((_) async {});
      when(mockAdsService.showBannerAd(any)).thenAnswer((_) async {});
      when(mockAdsService.showInterstitialAd(any))
          .thenAnswer((_) async => true);
      when(mockAdsService.showRewardedAd(any)).thenAnswer((_) async => true);
    });

    group('Frequency Control', () {
      test('should allow first ad immediately', () async {
        final canShow = await discreteAdService.canShowAd('test_placement');
        expect(canShow, isTrue);
      });

      test('should respect minimum interval between ads', () async {
        // Show first ad
        await discreteAdService.showBannerAdIfAllowed('test_placement');

        // Immediately try to show another - should be blocked
        final canShowImmediately =
            await discreteAdService.canShowAd('test_placement');
        expect(canShowImmediately, isFalse);
      });

      test('should allow ad after minimum interval passes', () async {
        // Show first ad
        await discreteAdService.showBannerAdIfAllowed('test_placement');

        // Simulate time passing by manipulating stored timestamp
        final prefs = await SharedPreferences.getInstance();
        final pastTime = DateTime.now().subtract(Duration(minutes: 6));
        await prefs.setInt(
            'last_ad_test_placement', pastTime.millisecondsSinceEpoch);

        final canShowAfterInterval =
            await discreteAdService.canShowAd('test_placement');
        expect(canShowAfterInterval, isTrue);
      });

      test('should enforce hourly ad limit', () async {
        // Simulate showing maximum ads per hour
        for (int i = 0; i < 6; i++) {
          await discreteAdService.showBannerAdIfAllowed('test_placement_$i');
        }

        // Next ad should be blocked
        final canShowMore = await discreteAdService.canShowAd('new_placement');
        expect(canShowMore, isFalse);
      });

      test('should enforce daily ad limit', () async {
        // Simulate showing maximum ads per day
        final prefs = await SharedPreferences.getInstance();
        final timestamps = <String>[];
        final now = DateTime.now();

        for (int i = 0; i < 30; i++) {
          final timestamp = now.subtract(Duration(minutes: i * 10));
          timestamps.add(timestamp.millisecondsSinceEpoch.toString());
        }

        await prefs.setStringList('ad_timestamps', timestamps);

        final canShowMore = await discreteAdService.canShowAd('test_placement');
        expect(canShowMore, isFalse);
      });
    });

    group('Interstitial Ad Timing', () {
      test('should show interstitial based on action count', () async {
        // Task completion interstitial should show every 10th action
        for (int i = 1; i < 10; i++) {
          final shouldShow = await discreteAdService
              .showInterstitialAdWithTiming('task_complete_interstitial');
          expect(shouldShow, isFalse, reason: 'Should not show on action $i');
        }

        // 10th action should trigger ad
        final shouldShowOnTenth = await discreteAdService
            .showInterstitialAdWithTiming('task_complete_interstitial');
        expect(shouldShowOnTenth, isTrue, reason: 'Should show on 10th action');
      });

      test('should reset counter after showing interstitial', () async {
        // Show interstitial on 10th action
        for (int i = 0; i < 10; i++) {
          await discreteAdService
              .showInterstitialAdWithTiming('task_complete_interstitial');
        }

        // Counter should be reset, so next action shouldn't trigger ad
        final shouldShowAfterReset = await discreteAdService
            .showInterstitialAdWithTiming('task_complete_interstitial');
        expect(shouldShowAfterReset, isFalse);
      });
    });

    group('Rewarded Ads', () {
      test('should show rewarded ad when requested', () async {
        final result =
            await discreteAdService.showRewardedAd('extra_coins_rewarded');
        expect(result, isTrue);
        verify(mockAdsService.showRewardedAd('extra_coins_rewarded')).called(1);
      });

      test('should not show rewarded ad when ads disabled', () async {
        when(mockAdsService.adsEnabled).thenReturn(false);

        final result =
            await discreteAdService.showRewardedAd('extra_coins_rewarded');
        expect(result, isFalse);
        verifyNever(mockAdsService.showRewardedAd(any));
      });
    });

    group('Ad Statistics', () {
      test('should provide accurate statistics', () async {
        // Show some ads
        await discreteAdService.showBannerAdIfAllowed('test_placement_1');
        await discreteAdService.showBannerAdIfAllowed('test_placement_2');

        final stats = await discreteAdService.getAdStatistics();

        expect(stats['adsEnabled'], isTrue);
        expect(stats['hourlyCount'], equals(2));
        expect(stats['dailyCount'], equals(2));
        expect(stats['maxAdsPerHour'], equals(6));
        expect(stats['maxAdsPerDay'], equals(30));
        expect(stats['lastAdTime'], isNotNull);
      });
    });

    group('Data Management', () {
      test('should clear ad data when requested', () async {
        // Show some ads to create data
        await discreteAdService.showBannerAdIfAllowed('test_placement');

        // Verify data exists
        final statsBefore = await discreteAdService.getAdStatistics();
        expect(statsBefore['dailyCount'], greaterThan(0));

        // Clear data
        await discreteAdService.clearAdData();

        // Verify data is cleared
        final statsAfter = await discreteAdService.getAdStatistics();
        expect(statsAfter['dailyCount'], equals(0));
      });

      test('should simulate ad interactions for testing', () async {
        await discreteAdService.simulateAdInteraction(
          'test_placement',
          interactions: 3,
          timeBetween: Duration(minutes: 6),
        );

        final stats = await discreteAdService.getAdStatistics();
        expect(stats['dailyCount'], equals(3));
      });
    });

    group('Error Handling', () {
      test('should handle ad loading failures gracefully', () async {
        when(mockAdsService.loadBannerAd(any))
            .thenThrow(Exception('Ad load failed'));

        final result =
            await discreteAdService.showBannerAdIfAllowed('test_placement');
        expect(result, isFalse);
      });

      test('should handle ad showing failures gracefully', () async {
        when(mockAdsService.showInterstitialAd(any))
            .thenThrow(Exception('Ad show failed'));

        final result = await discreteAdService
            .showInterstitialAdWithTiming('test_placement');
        expect(result, isFalse);
      });
    });
  });
}
